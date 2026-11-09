sealed class AgentActivity {
  const AgentActivity();
}

class AgentWorking extends AgentActivity {
  const AgentWorking(this.label);
  final String label;
}

class AgentReplied extends AgentActivity {
  const AgentReplied(this.markdown);
  final String markdown;
}

class SurfaceShown extends AgentActivity {
  const SurfaceShown(this.surfaceId);
  final String surfaceId;
}

class SurfaceRemoved extends AgentActivity {
  const SurfaceRemoved(this.surfaceId);
  final String surfaceId;
}

class SurfaceProblem extends AgentActivity {
  const SurfaceProblem(this.surfaceId, this.message);
  final String? surfaceId;
  final String message;
}

class AgentIdle extends AgentActivity {
  const AgentIdle();
}

class AgentFailed extends AgentActivity {
  const AgentFailed(this.message);
  final String message;
}
