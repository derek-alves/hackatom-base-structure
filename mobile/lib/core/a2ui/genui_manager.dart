import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:logging/logging.dart';

import '../network/api_client.dart';
import '../network/api_models.dart';
import 'agent_activity.dart';

/// Wires an A2UI [MessageProcessor] to the backend SSE [ApiClient].
class GenUiManager {
  GenUiManager({
    required this.apiClient,
    required this.sessionId,
    required CatalogImplementation catalog,
  }) : processor = MessageProcessor<ComponentImplementation>(
         catalogs: [catalog],
         defaultVersion: A2uiProtocolVersion.v1_0,
         validationConfig: ValidationConfig.relaxed,
       ) {
    _subs.add(processor.model.onSurfaceCreated.subscribe(_onSurfaceCreated));
    _subs.add(
      processor.model.onSurfaceDeleted.subscribe((id) {
        _surfaceErrors.remove(id)?.unsubscribe();
        _emit(SurfaceRemoved(id));
      }),
    );
    _subs.add(processor.model.onAction.subscribe(_onAction));
  }

  static final _log = Logger('GenUiManager');

  final ApiClient apiClient;
  final String sessionId;
  final MessageProcessor<ComponentImplementation> processor;

  final _controller = StreamController<AgentActivity>.broadcast();
  final _subs = <Subscription>[];
  final _surfaceErrors = <String, Subscription>{};
  bool _busy = false;
  bool _disposed = false;
  GenUiRequest? _lastRequest;

  SurfaceModel<ComponentImplementation>? surface(String id) =>
      processor.model.getSurface(id);

  Stream<AgentActivity> get activity => _controller.stream;

  bool get isBusy => _busy;

  Future<void> sendText(
    String text, {
    List<Attachment> attachments = const [],
  }) => _post(
    GenUiRequest(sessionId: sessionId, text: text, attachments: attachments),
  );

  /// Re-POSTs the last request that was actually sent (text or UI action).
  Future<void> retryLast() async {
    final request = _lastRequest;
    if (request != null) await _post(request);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final s in _subs) {
      s.unsubscribe();
    }
    for (final s in _surfaceErrors.values) {
      s.unsubscribe();
    }
    _surfaceErrors.clear();
    processor.dispose();
    _controller.close();
  }

  void _emit(AgentActivity a) {
    if (!_disposed) _controller.add(a);
  }

  void _onSurfaceCreated(SurfaceModel<ComponentImplementation> s) {
    _surfaceErrors.remove(s.id)?.unsubscribe();
    _surfaceErrors[s.id] = s.onError.subscribe((e) {
      // Logged only: never sent back to the agent, to avoid loops.
      _log.warning('Renderer error on ${s.id}: ${e.code} ${e.message}');
      _emit(SurfaceProblem(s.id, 'Não foi possível exibir este componente.'));
    });
    _emit(SurfaceShown(s.id));
  }

  void _onAction(A2uiRendererAction a) {
    final messages =
        RendererToAgentMessagePayload.of(
              ActionMessage(
                version: A2uiProtocolVersion.v1_0.jsonValue,
                action: a,
              ),
            ).toJson()['messages']
            as List;
    unawaited(
      _post(
        GenUiRequest(
          sessionId: sessionId,
          a2uiMessages: [
            for (final m in messages) Map<String, Object?>.from(m as Map),
          ],
        ),
      ),
    );
  }

  Future<void> _post(GenUiRequest request) async {
    if (_busy || _disposed) return;
    _busy = true;
    _lastRequest = request;
    // Lock the UI at once, before the network call, so no second action slips in.
    _emit(const AgentWorking('Processando...'));
    var finished = false;
    try {
      await for (final event in apiClient.streamGenUi(request)) {
        switch (event) {
          case StatusEvent(:final label):
            _emit(AgentWorking(label));
          case A2uiEvent(:final message):
            try {
              processor.processMessages(message);
            } on Object catch (e) {
              if (e is! A2uiError && e is! ArgumentError) rethrow;
              _log.warning('Invalid A2UI message: $e');
              _emit(
                const SurfaceProblem(
                  null,
                  'O agente enviou um componente inválido.',
                ),
              );
            }
          case TextEvent(:final markdown):
            _emit(AgentReplied(markdown));
          case ErrorEvent(:final message):
            _emit(AgentFailed(message));
          case DoneEvent():
            finished = true;
        }
        if (finished) break;
      }
    } on ApiException catch (e) {
      _emit(AgentFailed(e.message));
    } catch (e, st) {
      _log.severe('Unexpected error while handling agent stream', e, st);
      _emit(
        const AgentFailed('Erro inesperado ao processar a resposta do agente.'),
      );
    } finally {
      _busy = false;
      _emit(const AgentIdle());
    }
  }
}
