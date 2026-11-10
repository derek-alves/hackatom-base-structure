import 'package:material_ui/material_ui.dart';

import '../../loading/app_skeleton.dart';
import '../../theme/app_tokens.dart';
import '../app_date_picker/show_app_date_picker.dart';
import '../app_size.dart';

enum _Kind { text, number, date, select, skeleton }

/// Kit text field. Variants: default, [AppTextField.number],
/// [AppTextField.date], [AppTextField.select] and [AppTextField.skeleton].
///
/// A single-line field is `tokens.size.controlSm/Md/Lg` tall (minimum: it
/// grows with large text scales or multiple lines). The outlined label floats
/// on the border, so a label adds no height.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.size = AppSize.md,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  }) : _kind = _Kind.text,
       onNumberChanged = null,
       invalidMessage = null,
       dateValue = null,
       onDateChanged = null,
       dateValidator = null,
       firstDate = null,
       lastDate = null,
       options = null,
       selectValue = null,
       onSelectChanged = null,
       hasLabel = true;

  /// Decimal field: emits a finite [num] (null when empty or invalid).
  ///
  /// Accepts an optional leading `-` and either pt-BR (`1.000`, `1.000,50`,
  /// `12,5`: dots group thousands, comma marks decimals) or plain digits with
  /// an optional dot decimal (`1.5`, `12.5`). A dot followed by groups of
  /// exactly 3 digits is a thousands separator, so `1.500` is 1500. Anything
  /// else (`NaN`, `Infinity`, hex, exponent, inner spaces) fails with
  /// [invalidMessage] before [validator] runs.
  const AppTextField.number({
    super.key,
    this.label,
    this.hint,
    this.helper,
    ValueChanged<num?>? onChanged,
    this.validator,
    String this.invalidMessage = 'Informe um número válido',
    this.size = AppSize.md,
  }) : _kind = _Kind.number,
       onNumberChanged = onChanged,
       onChanged = null,
       errorText = null,
       controller = null,
       initialValue = null,
       obscure = false,
       keyboardType = const TextInputType.numberWithOptions(decimal: true),
       maxLines = 1,
       minLines = null,
       prefix = null,
       suffix = null,
       enabled = true,
       focusNode = null,
       textInputAction = null,
       onSubmitted = null,
       dateValue = null,
       onDateChanged = null,
       dateValidator = null,
       firstDate = null,
       lastDate = null,
       options = null,
       selectValue = null,
       onSelectChanged = null,
       hasLabel = true;

  /// Read-only field showing `dd/MM/yyyy`; tapping opens [showAppDatePicker].
  /// [firstDate]/[lastDate] default to 1900-01-01 and 2100-12-31.
  const AppTextField.date({
    super.key,
    this.label,
    this.hint,
    DateTime? value,
    required ValueChanged<DateTime> onChanged,
    FormFieldValidator<DateTime?>? validator,
    this.firstDate,
    this.lastDate,
    this.size = AppSize.md,
  }) : _kind = _Kind.date,
       dateValue = value,
       onDateChanged = onChanged,
       dateValidator = validator,
       helper = null,
       errorText = null,
       controller = null,
       initialValue = null,
       onChanged = null,
       validator = null,
       obscure = false,
       keyboardType = null,
       maxLines = 1,
       minLines = null,
       prefix = null,
       suffix = null,
       enabled = true,
       focusNode = null,
       textInputAction = null,
       onSubmitted = null,
       onNumberChanged = null,
       invalidMessage = null,
       options = null,
       selectValue = null,
       onSelectChanged = null,
       hasLabel = true;

  /// Dropdown over [options].
  const AppTextField.select({
    super.key,
    this.label,
    this.hint,
    required List<String> this.options,
    String? value,
    required ValueChanged<String?> onChanged,
    this.validator,
    this.size = AppSize.md,
  }) : _kind = _Kind.select,
       selectValue = value,
       onSelectChanged = onChanged,
       helper = null,
       errorText = null,
       controller = null,
       initialValue = null,
       onChanged = null,
       obscure = false,
       keyboardType = null,
       maxLines = 1,
       minLines = null,
       prefix = null,
       suffix = null,
       enabled = true,
       focusNode = null,
       textInputAction = null,
       onSubmitted = null,
       onNumberChanged = null,
       invalidMessage = null,
       dateValue = null,
       onDateChanged = null,
       dateValidator = null,
       firstDate = null,
       lastDate = null,
       hasLabel = true;

  /// Placeholder: a single bone exactly as tall as the real single-line field
  /// for [size]. The real label floats on the border and adds no height, so
  /// [hasLabel] does not change the height either.
  const AppTextField.skeleton({
    super.key,
    this.hasLabel = true,
    this.size = AppSize.md,
  }) : _kind = _Kind.skeleton,
       label = null,
       hint = null,
       helper = null,
       errorText = null,
       controller = null,
       initialValue = null,
       onChanged = null,
       validator = null,
       obscure = false,
       keyboardType = null,
       maxLines = 1,
       minLines = null,
       prefix = null,
       suffix = null,
       enabled = true,
       focusNode = null,
       textInputAction = null,
       onSubmitted = null,
       onNumberChanged = null,
       invalidMessage = null,
       dateValue = null,
       onDateChanged = null,
       dateValidator = null,
       firstDate = null,
       lastDate = null,
       options = null,
       selectValue = null,
       onSelectChanged = null;

  final _Kind _kind;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final AppSize size;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<num?>? onNumberChanged;
  final String? invalidMessage;
  final DateTime? dateValue;
  final ValueChanged<DateTime>? onDateChanged;
  final FormFieldValidator<DateTime?>? dateValidator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final List<String>? options;
  final String? selectValue;
  final ValueChanged<String?>? onSelectChanged;
  final bool hasLabel;

  static double _height(BuildContext context, AppSize size) {
    final s = context.tokens.size;
    return switch (size) {
      AppSize.sm => s.controlSm,
      AppSize.md => s.controlMd,
      AppSize.lg => s.controlLg,
    };
  }

  InputDecoration _decoration(BuildContext context) {
    final tokens = context.tokens;
    final height = _height(context, size);
    final style = Theme.of(context).textTheme.bodyLarge!;
    final line = style.fontSize! * (style.height ?? 1.0);
    final multiline = maxLines != 1 || minLines != null;
    final vertical = multiline
        ? tokens.spacing.sm
        : ((height - line) / 2).clamp(0.0, double.infinity);
    final iconBox = BoxConstraints(minWidth: height, minHeight: height);
    return InputDecoration(
      isDense: true,
      labelText: label,
      hintText: hint,
      helperText: helper,
      errorText: errorText,
      constraints: BoxConstraints(minHeight: height),
      contentPadding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.md,
        vertical: vertical,
      ),
      prefixIcon: prefix,
      prefixIconConstraints: iconBox,
      suffixIcon: suffix,
      suffixIconConstraints: iconBox,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_kind) {
      case _Kind.skeleton:
        return AppSkeleton.box(
          height: _height(context, size),
          radius: context.tokens.radius.md,
        );
      case _Kind.text:
        return TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          validator: validator,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          enabled: enabled,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          decoration: _decoration(context),
        );
      case _Kind.number:
        return TextFormField(
          onChanged: (v) => onNumberChanged?.call(_parse(v)),
          validator: (v) {
            final text = v?.trim() ?? '';
            if (text.isNotEmpty && _parse(text) == null) return invalidMessage;
            return validator?.call(v);
          },
          keyboardType: keyboardType,
          decoration: _decoration(context),
        );
      case _Kind.date:
        return _DateField(
          decoration: _decoration(context),
          value: dateValue,
          onChanged: onDateChanged!,
          validator: dateValidator,
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(2100, 12, 31),
        );
      case _Kind.select:
        return DropdownButtonFormField<String>(
          // initialValue is not re-synced by the form field; re-key on change.
          key: ValueKey(selectValue),
          initialValue: selectValue,
          items: [
            for (final o in options!)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: onSelectChanged,
          validator: validator,
          isExpanded: true,
          decoration: _decoration(context),
        );
    }
  }

  // pt-BR: dots group thousands (1.000,50) or a comma marks decimals (12,5).
  static final _brNumber = RegExp(r'^(\d{1,3}(\.\d{3})+(,\d+)?|\d+,\d+)$');
  // Plain digits, or a dot decimal that is not a thousands group (1.5, 12.5).
  static final _plainNumber = RegExp(r'^\d+(\.\d+)?$');

  /// Parses [v] as a finite number, or null. See [AppTextField.number].
  static num? _parse(String v) {
    final text = v.trim();
    final negative = text.startsWith('-');
    final digits = negative ? text.substring(1) : text;
    final String normalized;
    if (_brNumber.hasMatch(digits)) {
      normalized = digits.replaceAll('.', '').replaceAll(',', '.');
    } else if (_plainNumber.hasMatch(digits)) {
      normalized = digits;
    } else {
      return null;
    }
    final value = num.tryParse('${negative ? '-' : ''}$normalized');
    return value != null && value.isFinite ? value : null;
  }
}

String _format(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/'
    '${d.year.toString().padLeft(4, '0')}';

class _DateField extends StatefulWidget {
  const _DateField({
    required this.decoration,
    required this.value,
    required this.onChanged,
    required this.validator,
    required this.firstDate,
    required this.lastDate,
  });

  final InputDecoration decoration;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final FormFieldValidator<DateTime?>? validator;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  late final TextEditingController _controller = TextEditingController(
    text: _text(widget.value),
  );
  DateTime? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(_DateField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _set(widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _text(DateTime? d) => d == null ? '' : _format(d);

  void _set(DateTime? d) {
    _value = d;
    _controller.text = _text(d);
  }

  DateTime _initial() {
    final v = _value ?? DateTime.now();
    final base = DateTime(v.year, v.month, v.day);
    if (base.isBefore(widget.firstDate)) return widget.firstDate;
    if (base.isAfter(widget.lastDate)) return widget.lastDate;
    return base;
  }

  Future<void> _pick() async {
    final picked = await showAppDatePicker(
      context,
      initialDate: _initial(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _set(picked));
    widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      onTap: _pick,
      validator: widget.validator == null
          ? null
          : (_) => widget.validator!(_value),
      decoration: widget.decoration,
    );
  }
}
