import 'package:material_ui/material_ui.dart';

import '../../loading/app_skeleton.dart';
import '../../theme/app_tokens.dart';

enum _Variant { elevated, filled, outlined, skeleton }

/// Kit card. Variants map to the elevated/filled/outlined Material cards.
///
/// Layout: [title] (titleMedium), [subtitle] (bodyMedium, onSurfaceVariant),
/// [child], then [actions] in a row aligned to the end. With [onTap] the card
/// is tappable and the ripple follows the card radius.
class AppCard extends StatelessWidget {
  const AppCard.elevated({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.actions = const [],
    this.onTap,
    this.padding,
  }) : _variant = _Variant.elevated,
       lines = 0,
       hasActions = false;

  const AppCard.filled({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.actions = const [],
    this.onTap,
    this.padding,
  }) : _variant = _Variant.filled,
       lines = 0,
       hasActions = false;

  const AppCard.outlined({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.actions = const [],
    this.onTap,
    this.padding,
  }) : _variant = _Variant.outlined,
       lines = 0,
       hasActions = false;

  /// Placeholder with the card shape: one title line, [lines] body lines (the
  /// last at 60% width) and, with [hasActions], a button-height bone.
  const AppCard.skeleton({super.key, this.lines = 3, this.hasActions = false})
    : _variant = _Variant.skeleton,
      title = null,
      subtitle = null,
      child = null,
      actions = const [],
      onTap = null,
      padding = null;

  final _Variant _variant;
  final String? title;
  final String? subtitle;
  final Widget? child;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final int lines;
  final bool hasActions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final pad = padding ?? EdgeInsets.all(tokens.spacing.md);

    if (_variant == _Variant.skeleton) {
      return Card(
        child: Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton.line(style: text.titleMedium),
              SizedBox(height: tokens.spacing.sm),
              for (var i = 0; i < lines; i++) ...[
                if (i > 0) SizedBox(height: tokens.spacing.xs),
                if (i == lines - 1 && lines > 1)
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: AppSkeleton.line(style: text.bodyMedium),
                  )
                else
                  AppSkeleton.line(style: text.bodyMedium),
              ],
              if (hasActions) ...[
                SizedBox(height: tokens.spacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppSkeleton.box(
                    width: tokens.size.controlLg * 3,
                    height: tokens.size.controlMd,
                    radius: tokens.radius.md,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final blocks = <Widget>[
      if (title != null || subtitle != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) Text(title!, style: text.titleMedium),
            if (title != null && subtitle != null)
              SizedBox(height: tokens.spacing.xs),
            if (subtitle != null)
              Text(
                subtitle!,
                style: text.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ?child,
      if (actions.isNotEmpty)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: actions,
          ),
        ),
    ];
    Widget content = Padding(
      padding: pad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) SizedBox(height: tokens.spacing.sm),
            blocks[i],
          ],
        ],
      ),
    );
    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }
    return switch (_variant) {
      _Variant.elevated => Card(child: content),
      _Variant.filled => Card.filled(child: content),
      // The card theme shape replaces the variant default, which drops the
      // outline; restore it here.
      _Variant.outlined => Card.outlined(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: content,
      ),
      _Variant.skeleton => const SizedBox.shrink(),
    };
  }
}
