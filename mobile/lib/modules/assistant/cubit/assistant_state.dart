import 'package:equatable/equatable.dart';

enum AssistantStatus { idle, working, failure }

sealed class AssistantEntry extends Equatable {
  const AssistantEntry();
}

class UserEntry extends AssistantEntry {
  const UserEntry(this.text, {this.hasImage = false});

  final String text;
  final bool hasImage;

  @override
  List<Object?> get props => [text, hasImage];
}

class AgentTextEntry extends AssistantEntry {
  const AgentTextEntry(this.markdown);

  final String markdown;

  @override
  List<Object?> get props => [markdown];
}

class SurfaceEntry extends AssistantEntry {
  const SurfaceEntry(this.surfaceId, {this.problem});

  final String surfaceId;
  final String? problem;

  @override
  List<Object?> get props => [surfaceId, problem];
}

class UiProblemEntry extends AssistantEntry {
  const UiProblemEntry(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AssistantState extends Equatable {
  const AssistantState({
    this.status = AssistantStatus.idle,
    this.progressLabel,
    this.entries = const [],
    this.errorMessage,
  });

  final AssistantStatus status;
  final String? progressLabel;
  final List<AssistantEntry> entries;
  final String? errorMessage;

  AssistantState copyWith({
    AssistantStatus? status,
    String? progressLabel,
    bool clearProgress = false,
    List<AssistantEntry>? entries,
    String? errorMessage,
    bool clearError = false,
  }) => AssistantState(
    status: status ?? this.status,
    progressLabel: clearProgress ? null : progressLabel ?? this.progressLabel,
    entries: entries ?? this.entries,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, progressLabel, entries, errorMessage];
}
