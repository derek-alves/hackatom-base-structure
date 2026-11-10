import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart' show A2uiMarkdown;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/a2ui/genui_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/composer_bar.dart';
import '../cubit/assistant_cubit.dart';
import '../cubit/assistant_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/markdown_message.dart';
import '../widgets/progress_banner.dart';
import '../widgets/unsupported_component_notice.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({
    super.key,
    required this.initialPrompt,
    this.initialAttachments = const [],
  });

  final String initialPrompt;
  final List<Attachment> initialAttachments;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final manager = GenUiManager(
          apiClient: context.read<ApiClient>(),
          sessionId: const Uuid().v4(),
          catalog: context.read<CatalogImplementation>(),
        );
        return AssistantCubit(manager)
          ..send(initialPrompt, attachments: initialAttachments);
      },
      child: const _AssistantView(),
    );
  }
}

class _AssistantView extends StatefulWidget {
  const _AssistantView();

  @override
  State<_AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<_AssistantView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: kThemeAnimationDuration,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssistantCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente')),
      body: BlocListener<AssistantCubit, AssistantState>(
        listenWhen: (a, b) =>
            a.entries.length != b.entries.length || a.status != b.status,
        listener: (context, state) => _scrollToEnd(),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<AssistantCubit, AssistantState>(
                builder: (context, state) => ListView(
                  controller: _scroll,
                  children: [
                    for (final e in state.entries)
                      KeyedSubtree(
                        key: ObjectKey(e),
                        // Surfaces take no taps while a request is in flight.
                        child: IgnorePointer(
                          ignoring: state.status == AssistantStatus.working,
                          child: _entry(context, cubit, e),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Banners stay outside the list so they are always visible.
            BlocBuilder<AssistantCubit, AssistantState>(
              builder: (context, state) => switch (state.status) {
                AssistantStatus.working => ProgressBanner(
                  label: state.progressLabel,
                ),
                AssistantStatus.failure => ErrorBanner(
                  message: state.errorMessage ?? 'Algo deu errado.',
                  onRetry: cubit.retry,
                ),
                AssistantStatus.idle => const SizedBox.shrink(),
              },
            ),
            BlocBuilder<AssistantCubit, AssistantState>(
              buildWhen: (a, b) => a.status != b.status,
              builder: (context, state) => ComposerBar(
                enabled: state.status != AssistantStatus.working,
                onSubmit: (s) => cubit.send(s.text, attachments: s.attachments),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, AssistantCubit cubit, AssistantEntry e) {
    final t = context.tokens;
    switch (e) {
      case UserEntry(:final text, :final hasImage):
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: EdgeInsets.all(t.spacing.sm),
            padding: EdgeInsets.all(t.spacing.sm),
            decoration: BoxDecoration(
              color: t.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(t.borderRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasImage) const Icon(Icons.image_outlined),
                if (text.isNotEmpty) Flexible(child: Text(text)),
              ],
            ),
          ),
        );
      case AgentTextEntry(:final markdown):
        return MarkdownMessage(markdown: markdown);
      case UiProblemEntry(:final message):
        return UnsupportedComponentNotice(message: message);
      case SurfaceEntry(:final surfaceId, :final problem):
        final surface = cubit.manager.surface(surfaceId);
        return Column(
          children: [
            if (surface != null)
              A2uiMarkdown(
                builder: (c, md, style) => MarkdownBody(data: md),
                child: A2uiSurface(key: ObjectKey(surface), surface: surface),
              ),
            if (problem != null) UnsupportedComponentNotice(message: problem),
          ],
        );
    }
  }
}
