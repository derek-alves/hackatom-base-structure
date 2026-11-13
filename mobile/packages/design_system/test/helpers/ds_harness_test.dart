import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'ds_harness.dart';

void main() {
  testWidgets('pumpDs applies width and textScaler together', (t) async {
    late BuildContext ctx;
    await pumpDs(
      t,
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox();
        },
      ),
      width: 320,
      textScaler: const TextScaler.linear(2.0),
    );
    expect(MediaQuery.sizeOf(ctx).width, 320);
    expect(MediaQuery.textScalerOf(ctx), const TextScaler.linear(2.0));
  });
}
