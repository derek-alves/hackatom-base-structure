import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_tokens.dart';

/// Adaptive date picker: [CupertinoDatePicker] in a bottom sheet on
/// iOS/macOS, Material [showDatePicker] elsewhere. Resolves to null when
/// dismissed.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (_) => _CupertinoDateSheet(
        theme: Theme.of(context),
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

class _CupertinoDateSheet extends StatefulWidget {
  const _CupertinoDateSheet({
    required this.theme,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final ThemeData theme;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CupertinoDateSheet> createState() => _CupertinoDateSheetState();
}

class _CupertinoDateSheetState extends State<_CupertinoDateSheet> {
  late DateTime _selected = _dateOnly(widget.initialDate);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    // The popup route lives above the app theme in the overlay; reuse it.
    return Theme(
      data: widget.theme,
      child: Builder(
        builder: (context) {
          final tokens = context.tokens;
          final scheme = Theme.of(context).colorScheme;
          return Material(
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(_selected),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: tokens.size.controlLg * 5,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: widget.initialDate,
                      minimumDate: widget.firstDate,
                      maximumDate: widget.lastDate,
                      onDateTimeChanged: (d) => _selected = _dateOnly(d),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
