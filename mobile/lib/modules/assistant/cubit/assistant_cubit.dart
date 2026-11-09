import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/a2ui/agent_activity.dart';
import '../../../core/a2ui/genui_manager.dart';
import '../../../core/network/api_models.dart';
import 'assistant_state.dart';

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(this.manager) : super(const AssistantState()) {
    _sub = manager.activity.listen(_onActivity);
  }

  final GenUiManager manager;
  late final StreamSubscription<AgentActivity> _sub;
  String? _lastText;
  List<Attachment> _lastAttachments = const [];

  Future<void> send(
    String text, {
    List<Attachment> attachments = const [],
  }) async {
    if (state.status == AssistantStatus.working) return;
    _lastText = text;
    _lastAttachments = attachments;
    emit(
      state.copyWith(
        status: AssistantStatus.working,
        clearProgress: true,
        clearError: true,
        entries: [
          ...state.entries,
          UserEntry(text, hasImage: attachments.isNotEmpty),
        ],
      ),
    );
    await manager.sendText(text, attachments: attachments);
  }

  Future<void> retry() async {
    final text = _lastText;
    if (text == null || state.status == AssistantStatus.working) return;
    emit(
      state.copyWith(
        status: AssistantStatus.working,
        clearProgress: true,
        clearError: true,
      ),
    );
    await manager.sendText(text, attachments: _lastAttachments);
  }

  void _onActivity(AgentActivity a) {
    if (isClosed) return;
    switch (a) {
      case AgentWorking(:final label):
        emit(
          state.copyWith(status: AssistantStatus.working, progressLabel: label),
        );
      case AgentReplied(:final markdown):
        emit(
          state.copyWith(entries: [...state.entries, AgentTextEntry(markdown)]),
        );
      case SurfaceShown(:final surfaceId):
        emit(
          state.copyWith(entries: [...state.entries, SurfaceEntry(surfaceId)]),
        );
      case SurfaceRemoved(:final surfaceId):
        emit(
          state.copyWith(
            entries: [
              for (final e in state.entries)
                if (!(e is SurfaceEntry && e.surfaceId == surfaceId)) e,
            ],
          ),
        );
      case SurfaceProblem(:final surfaceId, :final message):
        final hasSurface =
            surfaceId != null &&
            state.entries.any(
              (e) => e is SurfaceEntry && e.surfaceId == surfaceId,
            );
        emit(
          state.copyWith(
            entries: hasSurface
                ? [
                    for (final e in state.entries)
                      if (e is SurfaceEntry && e.surfaceId == surfaceId)
                        SurfaceEntry(e.surfaceId, problem: message)
                      else
                        e,
                  ]
                : [...state.entries, UiProblemEntry(message)],
          ),
        );
      case AgentFailed(:final message):
        emit(
          state.copyWith(
            status: AssistantStatus.failure,
            errorMessage: message,
            clearProgress: true,
          ),
        );
      case AgentIdle():
        if (state.status == AssistantStatus.failure) return;
        emit(state.copyWith(status: AssistantStatus.idle, clearProgress: true));
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    manager.dispose();
    return super.close();
  }
}
