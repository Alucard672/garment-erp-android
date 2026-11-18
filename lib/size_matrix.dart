import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'generated/api_schema.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';

class SizeMatrix extends StatelessWidget {
  const SizeMatrix({
    super.key,
    required this.style,
    required this.quantities,
    required this.onChanged,
    this.lineNotes = const {},
    this.onNoteChanged,
    this.editable = true,
  });

  final StyleDetail style;
  final Map<int, int> quantities;
  final void Function(int, int) onChanged;
  final Map<int, String> lineNotes;
  final void Function(int, String)? onNoteChanged;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final sizes = style.skus.map((sku) => sku.size).toSet();
    final colors = <String, Map<String, Sku>>{};
    for (final sku in style.skus) {
      colors.putIfAbsent(sku.color, () => {})[sku.size] = sku;
    }
    if (colors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('这个款号暂无可选规格。'),
      );
    }

    final table = DataTable(
      headingRowColor: const WidgetStatePropertyAll(salesTableHeader),
      headingTextStyle: const TextStyle(
        color: salesMuted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      headingRowHeight: 27,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 46,
      horizontalMargin: 9,
      columnSpacing: 8,
      columns: [
        const DataColumn(label: Text('颜色 / 尺码')),
        for (final size in sizes)
          DataColumn(
            label: Text(size),
            headingRowAlignment: MainAxisAlignment.center,
          ),
        const DataColumn(
          label: Text('小计'),
          headingRowAlignment: MainAxisAlignment.center,
        ),
        const DataColumn(label: Text('明细备注')),
      ],
      rows: [
        for (final (index, row) in colors.entries.indexed)
          DataRow(
            color: WidgetStatePropertyAll(
              index.isEven ? salesPaper : salesTableAlternate,
            ),
            cells: [
              DataCell(Text(row.key)),
              for (final size in sizes)
                DataCell(switch (row.value[size]) {
                  final sku? => Center(
                    child: _QuantityInput(
                      key: ValueKey(sku.id),
                      label: '${sku.color} ${sku.size} 数量',
                      quantity: quantities[sku.id] ?? 0,
                      enabled: editable,
                      onChanged: (value) => onChanged(sku.id, value),
                    ),
                  ),
                  null => const Center(
                    child: Text('—', style: TextStyle(color: salesMuted)),
                  ),
                }),
              DataCell(
                Center(
                  child: Text(
                    '${row.value.values.fold(0, (sum, sku) => sum + (quantities[sku.id] ?? 0))}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              DataCell(
                _noteAction(context, row.key, row.value.values.toList()),
              ),
            ],
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: table,
        ),
      ),
    );
  }

  Widget _noteAction(BuildContext context, String color, List<Sku> variants) {
    final hasNotes = variants.any(
      (sku) => lineNotes[sku.id]?.isNotEmpty == true,
    );
    final edit = editable ? onNoteChanged : null;
    return Tooltip(
      message: '$color 明细备注',
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          minimumSize: const Size(56, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: salesPrimary,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        onPressed: edit == null && !hasNotes
            ? null
            : () async {
                final changes = await showDialog<Map<int, String>>(
                  context: context,
                  builder: (context) => _ColorNotesDialog(
                    color: color,
                    variants: variants,
                    notes: lineNotes,
                    editable: edit != null,
                  ),
                );
                if (!context.mounted || edit == null || changes == null) return;
                for (final entry in changes.entries) {
                  edit(entry.key, entry.value);
                }
              },
        child: Text(hasNotes ? '查看备注' : '+ 备注'),
      ),
    );
  }
}

class _ColorNotesDialog extends StatefulWidget {
  const _ColorNotesDialog({
    required this.color,
    required this.variants,
    required this.notes,
    required this.editable,
  });

  final String color;
  final List<Sku> variants;
  final Map<int, String> notes;
  final bool editable;

  @override
  State<_ColorNotesDialog> createState() => _ColorNotesDialogState();
}

class _ColorNotesDialogState extends State<_ColorNotesDialog> {
  final _changes = <int, String>{};
  late int _selected = widget.variants
      .firstWhere(
        (sku) => widget.notes[sku.id]?.isNotEmpty == true,
        orElse: () => widget.variants.first,
      )
      .id;

  String _noteFor(int id) => _changes[id] ?? widget.notes[id] ?? '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.color} · 明细备注'),
    content: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selected,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '尺码'),
            items: [
              for (final sku in widget.variants)
                DropdownMenuItem(
                  value: sku.id,
                  child: Text(
                    '${sku.size}${_noteFor(sku.id).isEmpty ? '' : ' · 有备注'}',
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selected = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey(_selected),
            initialValue: _noteFor(_selected),
            readOnly: !widget.editable,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(hintText: '如：单独装箱'),
            onChanged: (value) => _changes[_selected] = value.trim(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.editable ? '取消' : '关闭'),
      ),
      if (widget.editable)
        TabletAction(
          '确定',
          primary: true,
          onPressed: () => Navigator.pop(context, _changes),
        ),
    ],
  );
}

class _QuantityInput extends StatelessWidget {
  const _QuantityInput({
    super.key,
    required this.label,
    required this.quantity,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final int quantity;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 50,
    child: Semantics(
      label: label,
      child: TextFormField(
        initialValue: quantity == 0 ? '' : quantity.toString(),
        enabled: enabled,
        decoration: InputDecoration(
          hintText: '0',
          counterText: '',
          filled: true,
          fillColor: quantity > 0 ? salesTint : salesPaper,
          isDense: true,
          constraints: const BoxConstraints(minHeight: 44),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 7,
          ),
        ),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        textAlign: TextAlign.center,
        maxLength: 8,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (text) => onChanged(int.tryParse(text) ?? 0),
      ),
    ),
  );
}
