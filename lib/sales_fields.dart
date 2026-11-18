import 'package:flutter/material.dart';

import 'sales_theme.dart';
import 'tablet_filter_panel.dart';

class SalesNoteField extends StatelessWidget {
  const SalesNoteField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.compact = false,
  });

  final String initialValue;
  final ValueChanged<String>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => SalesFieldSurface(
    label: '整单备注',
    compact: compact,
    child: TextFormField(
      initialValue: initialValue,
      enabled: onChanged != null,
      onChanged: onChanged,
      maxLength: 1000,
      decoration: const InputDecoration(
        hintText: '选填',
        counterText: '',
        filled: false,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        hintStyle: TextStyle(color: salesMuted, fontWeight: FontWeight.w500),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: salesPrimary),
        ),
        disabledBorder: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class SalesFieldSurface extends StatelessWidget {
  const SalesFieldSurface({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(color: salesMuted, fontSize: 11)),
      const SizedBox(height: 2),
      Material(
        color: salesPaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: TabletFilterPanel.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(
              minHeight: compact ? TabletFilterPanel.fieldHeight : 40,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ),
    ],
  );
}

class SalesChoiceField extends StatelessWidget {
  const SalesChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool selected;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: SalesFieldSurface(
      label: label,
      compact: compact,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? salesInk : salesMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            icon,
            size: 16,
            color: onTap == null ? salesMuted : salesPrimary,
          ),
        ],
      ),
    ),
  );
}
