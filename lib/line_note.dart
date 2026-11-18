import 'package:flutter/material.dart';

import 'tablet_filter_panel.dart';

class LineNoteButton extends StatelessWidget {
  const LineNoteButton({
    super.key,
    required this.item,
    required this.notes,
    required this.onChanged,
  });

  final String item;
  final String notes;
  final ValueChanged<String>? onChanged;

  Future<void> _edit(BuildContext context) async {
    var value = notes;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('明细备注'),
        content: SizedBox(
          width: 380,
          child: TextFormField(
            initialValue: notes,
            readOnly: onChanged == null,
            decoration: InputDecoration(labelText: item),
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            onChanged: (text) => value = text,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(onChanged == null ? '关闭' : '取消'),
          ),
          if (onChanged != null)
            TabletAction(
              '确定',
              primary: true,
              onPressed: () => Navigator.pop(context, value.trim()),
            ),
        ],
      ),
    );
    if (context.mounted && result != null) onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '$item 明细备注',
    onPressed: onChanged != null || notes.isNotEmpty
        ? () => _edit(context)
        : null,
    icon: Icon(notes.isEmpty ? Icons.note_add_outlined : Icons.sticky_note_2),
  );
}
