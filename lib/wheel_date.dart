import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'sales_theme.dart';

DateTime? parseBusinessDate(String text) {
  final normalized = text.trim().replaceAll('/', '-');
  final date = DateTime.tryParse(normalized);
  return date != null &&
          date.year >= 1900 &&
          date.year <= 2200 &&
          date.toIso8601String().split('T').first == normalized
      ? date
      : null;
}

Future<DateTime?> showWheelDatePicker(
  BuildContext anchor, {
  DateTime? initial,
  required DateTime firstDate,
  required DateTime lastDate,
  VoidCallback? onManualInput,
}) async {
  final box = anchor.findRenderObject()! as RenderBox;
  final bounds = box.localToGlobal(Offset.zero) & box.size;
  final today = DateUtils.dateOnly(initial ?? DateTime.now());
  var selected = today.isBefore(firstDate)
      ? firstDate
      : today.isAfter(lastDate)
      ? lastDate
      : today;
  var manual = false;
  FocusManager.instance.primaryFocus?.unfocus();
  final date = await showGeneralDialog<DateTime>(
    context: anchor,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    barrierLabel: '收起日期选择器',
    transitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (context, _, _) => SafeArea(
      minimum: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, area) {
          final origin = (context.findRenderObject()! as RenderBox)
              .localToGlobal(Offset.zero);
          final field = bounds.shift(-origin);
          final width = math.min(264.0, area.maxWidth);
          final height = math.min(190.0, area.maxHeight);
          final below = area.maxHeight - field.bottom;
          final above = below < height && field.top > below;
          final top = (above ? field.top - height : field.bottom).clamp(
            0.0,
            area.maxHeight - height,
          );
          final left = (field.center.dx - width / 2).clamp(
            0.0,
            area.maxWidth - width,
          );
          final arrow = (field.center.dx - left - 6).clamp(8.0, width - 20);
          final pointer = SizedBox(
            height: 8,
            child: Stack(
              children: [
                Positioned(
                  left: arrow,
                  top: above ? -6 : 3,
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: const ColoredBox(
                      color: Colors.white,
                      child: SizedBox.square(dimension: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: Column(
                  children: [
                    if (!above) pointer,
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        elevation: 7,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 38,
                              child: Row(
                                children: [
                                  if (onManualInput != null)
                                    TextButton(
                                      onPressed: () {
                                        manual = true;
                                        Navigator.pop(context);
                                      },
                                      child: const Text('键盘输入'),
                                    ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, selected),
                                    child: const Text('关闭'),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: Localizations.override(
                                context: context,
                                locale: const Locale('zh', 'CN'),
                                delegates: const [
                                  GlobalCupertinoLocalizations.delegate,
                                ],
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  dateOrder: DatePickerDateOrder.ymd,
                                  initialDateTime: selected,
                                  minimumYear: firstDate.year,
                                  maximumYear: lastDate.year,
                                  minimumDate: firstDate,
                                  maximumDate: lastDate,
                                  itemExtent: 32,
                                  onDateTimeChanged: (date) => selected = date,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (above) pointer,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
  if (manual && anchor.mounted) onManualInput?.call();
  return date;
}

class WheelDateInput extends StatefulWidget {
  const WheelDateInput({
    super.key,
    required this.label,
    required this.controller,
    required this.decoration,
    required this.onChanged,
    this.onSubmitted,
    this.validator,
  });
  final String label;
  final TextEditingController controller;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<WheelDateInput> createState() => _WheelDateInputState();
}

class _WheelDateInputState extends State<WheelDateInput> {
  final _focus = FocusNode();
  bool _manual = false;

  Future<void> _pick() async {
    final date = await showWheelDatePicker(
      context,
      initial: parseBusinessDate(widget.controller.text),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      onManualInput: () {
        setState(() => _manual = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      },
    );
    if (!mounted || date == null) return;
    widget.controller.text = date.toIso8601String().split('T').first;
    widget.onChanged(widget.controller.text);
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_endTyping);
  }

  void _endTyping() {
    if (mounted && !_focus.hasFocus && _manual) setState(() => _manual = false);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (_, value, _) => TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          readOnly: !_manual,
          keyboardType: TextInputType.datetime,
          style: const TextStyle(fontSize: 12),
          onTap: _manual ? null : _pick,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          decoration: widget.decoration.copyWith(
            suffixIcon: IconButton(
              tooltip: value.text.isEmpty
                  ? '选择${widget.label}'
                  : '清空${widget.label}',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 28),
              icon: Icon(
                value.text.isEmpty ? Icons.arrow_drop_down : Icons.cancel,
                size: 16,
                color: salesMuted,
              ),
              onPressed: value.text.isEmpty
                  ? _pick
                  : () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
            ),
          ),
        ),
      );
}
