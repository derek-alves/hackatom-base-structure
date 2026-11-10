# 0001 - Mobile A2UI stack

## Status
Accepted (spike passed on iOS and Android).

## Decision
- Flutter 3.47.9 (fvm, `.fvmrc`), Dart 3.13.x.
- A2UI renderer: `a2ui_flutter` 0.1.0 with `a2ui_core` 0.5.0, protocol v1.0.
- Resolved: json_schema_builder 0.1.7, flutter_bloc 9.1.1, flutter_markdown_plus 1.0.12.
- Material import: keep `package:flutter/material.dart`. `flutter analyze` on the fresh scaffold reports no deprecation, so `material_ui` is not added. Substituído pela ADR 0002.

## Spike result
`mobile/integration_test/a2ui_smoke_test.dart` renders a custom `Hello` component from a v1.0 `createSurface` message.
- iOS simulator (iPhone 17, iOS 26.3): PASS.
- Android emulator (Galaxy_S25_Plus_API_35, Android 15): PASS.
- API names matched the plan; no differences.

## Known limitations of a2ui_flutter 0.1.0
- No fallback widget for unknown components.
- No transport layer; the app must feed messages to `MessageProcessor`.
- `video_player` is a mandatory dependency.
- Upstream tests only macOS and web; mobile verified here by the smoke test only.

## Fallback considered
`genui` 0.10.4 (A2UI v0.9). Not needed.
