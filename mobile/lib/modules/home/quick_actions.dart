import 'package:material_ui/material_ui.dart';

class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.prompt,
  });

  final String label;
  final IconData icon;
  final String prompt;
}

const kQuickActions = [
  QuickAction(
    label: 'Resumo de indicadores',
    icon: Icons.insights_outlined,
    prompt: 'Mostre um resumo dos indicadores das minhas tarefas',
  ),
  QuickAction(
    label: 'Minhas pendências',
    icon: Icons.checklist_outlined,
    prompt: 'Liste minhas tarefas pendentes para eu marcar as concluídas',
  ),
  QuickAction(
    label: 'Nova tarefa',
    icon: Icons.add_task_outlined,
    prompt: 'Quero cadastrar uma nova tarefa',
  ),
];
