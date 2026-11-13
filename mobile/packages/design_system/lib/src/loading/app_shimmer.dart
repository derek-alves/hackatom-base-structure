import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_tokens.dart';

/// Animates [child] with the kit skeleton colors.
///
/// Returns [child] untouched when [enabled] is false or the platform asks for
/// reduced motion (`MediaQuery.disableAnimationsOf`).
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) return child;
    final skeleton = context.tokens.skeleton;
    return Shimmer.fromColors(
      baseColor: skeleton.base,
      highlightColor: skeleton.highlight,
      child: child,
    );
  }
}
