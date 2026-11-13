import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Only the CI goldens (`goldens/ci/`) are versioned; platform goldens are
/// git-ignored, so they stay off and a fresh clone passes as is.
Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    AlchemistConfig.runWithConfig(
      config: const AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ),
      run: () async => testMain(),
    );
