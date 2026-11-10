import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/core/network/api_models.dart';
import 'package:hackathon_starter/core/theme/app_theme.dart';
import 'package:hackathon_starter/shared/widgets/composer_bar.dart';
import 'package:image_picker/image_picker.dart';

Attachment _img() =>
    Attachment(bytes: Uint8List.fromList([1, 2]), mimeType: 'image/png');

Widget _bar({
  required List<ComposerSubmission> out,
  bool enabled = true,
  PickImage? pick,
}) => MaterialApp(
  theme: AppTheme.build(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: ComposerBar(
        onSubmit: out.add,
        enabled: enabled,
        pickImage: pick ?? (_) async => _img(),
      ),
    ),
  ),
);

Finder get _send => find.byKey(const Key('composer-send'));
bool _sendEnabled(WidgetTester t) =>
    t.widget<IconButton>(_send).onPressed != null;

void main() {
  testWidgets('send disabled when empty; enabled with text', (t) async {
    final out = <ComposerSubmission>[];
    await t.pumpWidget(_bar(out: out));
    expect(_sendEnabled(t), isFalse);
    await t.enterText(find.byType(TextField), 'oi');
    await t.pump();
    expect(_sendEnabled(t), isTrue);
    await t.tap(_send);
    await t.pump();
    expect(out.single.text, 'oi');
    expect(out.single.attachments, isEmpty);
    expect(find.text('oi'), findsNothing);
  });

  testWidgets('enabled with attachment only; chip removable', (t) async {
    final out = <ComposerSubmission>[];
    ImageSource? asked;
    await t.pumpWidget(
      _bar(
        out: out,
        pick: (s) async {
          asked = s;
          return _img();
        },
      ),
    );
    await t.tap(find.byKey(const Key('composer-camera')));
    await t.pumpAndSettle();
    expect(asked, ImageSource.camera);
    expect(find.byType(InputChip), findsOneWidget);
    expect(_sendEnabled(t), isTrue);
    await t.tap(find.byIcon(Icons.clear).first);
    await t.pump();
    expect(find.byType(InputChip), findsNothing);
    expect(_sendEnabled(t), isFalse);

    await t.tap(find.byKey(const Key('composer-gallery')));
    await t.pumpAndSettle();
    expect(asked, ImageSource.gallery);
    await t.tap(_send);
    await t.pump();
    expect(out.single.attachments, [_img()]);
  });

  testWidgets('disabled when enabled=false', (t) async {
    final out = <ComposerSubmission>[];
    await t.pumpWidget(_bar(out: out, enabled: false));
    await t.enterText(find.byType(TextField), 'oi');
    await t.pump();
    expect(_sendEnabled(t), isFalse);
    expect(t.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });
}
