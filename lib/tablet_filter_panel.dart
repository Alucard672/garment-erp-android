import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart' as td;

import 'sales_theme.dart';

/// Shared landscape filter geometry. Field labels live above the input.
class TabletFilterPanel extends StatelessWidget {
  const TabletFilterPanel({
    super.key,
    required this.fields,
    required this.actions,
    this.error,
  });

  final List<Widget> fields;
  final List<Widget> actions;
  final String? error;
  static const gap = 8.0;
  static const fieldHeight = 36.0;
  static const stroke = Color(0xffdcdcdc);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context);
    final height = fieldHeight + (scale.scale(12) - 12).clamp(0, 36);
    const outline = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: stroke),
    );
    return Theme(
      data: theme.copyWith(
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          constraints: BoxConstraints.tightFor(height: height),
          isDense: false,
          filled: true,
          fillColor: Colors.white,
          border: outline,
          enabledBorder: outline,
          focusedBorder: outline.copyWith(
            borderSide: const BorderSide(color: salesPrimary, width: 1.5),
          ),
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xff707681)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final minWidth = 110.0 + (scale.scale(12) - 12).clamp(0, 30) * 5;
            final actionWidth = 76.0 + (scale.scale(12) - 12).clamp(0, 30) * 2;
            // Short lists can keep the actions and every filter on one line.
            if (fields.length <= 7) {
              final minField = minWidth - 12;
              final actionsWidth =
                  actions.length * (actionWidth + gap) +
                  (actions.length > 1 ? 24 : 0);
              final inline =
                  bounds.maxWidth >=
                  fields.length * (minField + gap) + actionsWidth;
              final columns = ((bounds.maxWidth + gap) / (minWidth + gap))
                  .floor()
                  .clamp(1, fields.length);
              final width = (bounds.maxWidth - gap * (columns - 1)) / columns;
              final controls = Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.end,
                children: [
                  for (final action in actions)
                    SizedBox(height: height, child: action),
                ],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: [
                  if (inline)
                    Row(
                      spacing: gap,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (fields.length == 1) ...[
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                child: fields.single,
                              ),
                            ),
                          ),
                        ] else
                          for (final field in fields) Expanded(child: field),
                        for (final action in actions)
                          SizedBox(height: height, child: action),
                      ],
                    )
                  else ...[
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        for (final field in fields)
                          SizedBox(width: width, child: field),
                      ],
                    ),
                    controls,
                  ],
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
              );
            }
            final wide = bounds.maxWidth >= 6 * (minWidth + gap) + actionWidth;
            final available = bounds.maxWidth - (wide ? actionWidth + gap : 0);
            final columns = ((available + gap) / (minWidth + gap))
                .floor()
                .clamp(1, 6);
            final width = (available - gap * (columns - 1)) / columns;
            final rows = <Widget>[];
            for (var start = 0; start < fields.length; start += columns) {
              final index = start ~/ columns;
              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final field in fields.skip(start).take(columns)) ...[
                      if (field != fields[start]) const SizedBox(width: gap),
                      SizedBox(width: width, child: field),
                    ],
                    if (wide && index < actions.length) ...[
                      const Spacer(),
                      SizedBox(
                        width: actionWidth,
                        height: height,
                        child: actions[index],
                      ),
                    ],
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [
                ...rows,
                if (!wide || rows.length < 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: gap,
                    children: [
                      for (final b in actions.skip(wide ? rows.length : 0))
                        SizedBox(width: actionWidth, height: height, child: b),
                    ],
                  ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Main and secondary actions in the tablet sales workspace.
class TabletAction extends StatelessWidget {
  const TabletAction(
    this.label, {
    super.key,
    required this.onPressed,
    this.primary = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => td.TButton(
    size: td.TButtonSize.small,
    variant: primary ? td.TButtonVariant.fill : td.TButtonVariant.outline,
    colorPreset: primary
        ? td.TButtonColorPreset.primary
        : td.TButtonColorPreset.defaultTheme,
    icon: icon == null ? null : Icon(icon, size: 16),
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}
