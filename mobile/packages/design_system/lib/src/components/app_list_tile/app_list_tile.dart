import 'package:material_ui/material_ui.dart';

import '../../loading/app_skeleton.dart';
import '../../theme/app_tokens.dart';
import '../app_size.dart';

enum _Variant { standard, checkbox, navigation, skeleton }

/// Kit list tile. `.standard` and `.navigation` map to ListTile, `.checkbox`
/// to CheckboxListTile with the checkbox on the left.
///
/// The tile is at least `controlMd` high for [AppSize.sm], `controlLg` for
/// [AppSize.md] and `controlLg + spacing.md` for [AppSize.lg];
/// [AppListTile.skeleton] has the same height as a `.standard`
/// tile of the default size with the same flags. Long titles wrap.
class AppListTile extends StatelessWidget {
  const AppListTile.standard({
    super.key,
    required String this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.size = AppSize.md,
  }) : _variant = _Variant.standard,
       value = null,
       onChanged = null,
       hasLeading = false;

  const AppListTile.checkbox({
    super.key,
    required String this.title,
    this.subtitle,
    required bool this.value,
    required this.onChanged,
    this.size = AppSize.md,
  }) : _variant = _Variant.checkbox,
       leading = null,
       trailing = null,
       onTap = null,
       hasLeading = false;

  const AppListTile.navigation({
    super.key,
    required String this.title,
    this.subtitle,
    this.leading,
    required VoidCallback this.onTap,
    this.size = AppSize.md,
  }) : _variant = _Variant.navigation,
       trailing = null,
       value = null,
       onChanged = null,
       hasLeading = false;

  /// Placeholder with the height of a real tile with the same flags.
  const AppListTile.skeleton({
    super.key,
    this.hasLeading = false,
    bool hasSubtitle = true,
  }) : _variant = _Variant.skeleton,
       title = null,
       subtitle = hasSubtitle ? '' : null,
       leading = null,
       trailing = null,
       onTap = null,
       value = null,
       onChanged = null,
       size = AppSize.md;

  final _Variant _variant;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final AppSize size;
  final bool hasLeading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_variant == _Variant.skeleton) return _skeleton(context);

    final theme = Theme.of(context);
    final dense = size == AppSize.sm;
    final density = dense ? VisualDensity.compact : VisualDensity.standard;
    final minHeight = switch (size) {
      AppSize.sm => tokens.size.controlMd,
      AppSize.md => tokens.size.controlLg,
      AppSize.lg => tokens.size.controlLg + tokens.spacing.md,
    };
    final verticalPadding = size == AppSize.lg
        ? tokens.spacing.md
        : tokens.spacing.sm;
    final titleWidget = Text(title!);
    final subtitleWidget = subtitle == null ? null : Text(subtitle!);

    return switch (_variant) {
      // CheckboxListTile has no minTileHeight/minVerticalPadding, so the
      // per-size values go through the list tile theme.
      _Variant.checkbox => ListTileTheme(
        data: theme.listTileTheme.copyWith(
          minTileHeight: minHeight,
          minVerticalPadding: verticalPadding,
        ),
        child: CheckboxListTile(
          title: titleWidget,
          subtitle: subtitleWidget,
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          dense: dense,
          visualDensity: density,
        ),
      ),
      _Variant.navigation => ListTile(
        title: titleWidget,
        subtitle: subtitleWidget,
        leading: leading,
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
        dense: dense,
        visualDensity: density,
        minTileHeight: minHeight,
        minVerticalPadding: verticalPadding,
      ),
      _ => ListTile(
        title: titleWidget,
        subtitle: subtitleWidget,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        dense: dense,
        visualDensity: density,
        minTileHeight: minHeight,
        minVerticalPadding: verticalPadding,
      ),
    };
  }

  Widget _skeleton(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final tileTheme = theme.listTileTheme;
    final padding =
        tileTheme.contentPadding ??
        EdgeInsets.symmetric(horizontal: tokens.spacing.md);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: tokens.size.controlLg),
      child: Padding(
        padding: padding.add(EdgeInsets.symmetric(vertical: tokens.spacing.sm)),
        child: Row(
          children: [
            if (hasLeading) ...[
              AppSkeleton.circle(size: tokens.size.controlSm),
              SizedBox(width: tokens.spacing.md),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSkeleton.line(
                    width: tokens.size.controlLg * 3,
                    style:
                        tileTheme.titleTextStyle ?? theme.textTheme.bodyLarge,
                  ),
                  if (subtitle != null)
                    AppSkeleton.line(
                      width: tokens.size.controlLg * 2,
                      style:
                          tileTheme.subtitleTextStyle ??
                          theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
