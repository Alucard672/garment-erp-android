import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'generated/api_schema.dart';
import 'sales_theme.dart';

const listFilterDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
  suffixIconConstraints: BoxConstraints.tightFor(width: 24, height: 32),
);

class ListFilterLabel extends StatelessWidget {
  const ListFilterLabel(this.label, {super.key, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: salesMuted)),
      const SizedBox(height: 2),
      child,
    ],
  );
}

/// An anchored choice field for a fixed set of list filters.
class ListFilterSelect<V> extends StatelessWidget {
  const ListFilterSelect({
    super.key,
    required this.label,
    required this.valueText,
    required this.options,
    required this.onSelected,
    this.value,
  });

  final String label;
  final String valueText;
  final V? value;
  final Map<V, String> options;
  final ValueChanged<V> onSelected;

  @override
  Widget build(BuildContext context) => ListFilterLabel(
    label,
    child: PopupMenuButton<V>(
      tooltip: label,
      initialValue: value,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final entry in options.entries)
          PopupMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      child: InputDecorator(
        decoration: listFilterDecoration.copyWith(
          isDense:
              InputDecorationTheme.of(context).constraints?.hasTightHeight !=
              true,
          suffixIcon: const Icon(Icons.arrow_drop_down, size: 18),
        ),
        child: Text(
          valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ),
  );
}

/// Keeps typed lookup text separate from the selected server-side record.
class ListFilterLookup<T extends Object> extends StatefulWidget {
  const ListFilterLookup({
    super.key,
    required this.label,
    required this.allLabel,
    required this.value,
    required this.name,
    required this.code,
    required this.load,
    this.selectionOnly = false,
    required this.onSelected,
  });

  final String label;
  final String allLabel;
  final bool selectionOnly;
  final T? value;
  final String Function(T) name;
  final String Function(T) code;
  final Future<({List<T> items, bool hasNext})> Function(String, int) load;
  final ValueChanged<T?> onSelected;

  @override
  State<ListFilterLookup<T>> createState() => _ListFilterLookupState<T>();
}

class _ListFilterLookupState<T extends Object>
    extends State<ListFilterLookup<T>> {
  final _menu = MenuController();
  final _focus = FocusNode();
  final _input = TextEditingController();
  Timer? _debounce;
  int _revision = 0;
  int _page = 1;
  String _query = '';
  String? _error;
  List<T> _items = [];
  bool _loading = false;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _restoreSelection();
  }

  @override
  void didUpdateWidget(covariant ListFilterLookup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _restoreSelection();
  }

  void _restoreSelection() {
    final value = widget.value;
    _input.text = value == null ? '' : widget.name(value);
  }

  void _search(String query, int page, {bool debounce = false}) {
    _debounce?.cancel();
    final revision = ++_revision;
    setState(() {
      _query = query;
      _page = page;
      _loading = true;
      _error = null;
      _items = [];
      _hasNext = false;
    });
    Future<void> fetch() async {
      try {
        final result = await widget.load(query, page);
        if (!mounted || revision != _revision) return;
        setState(() {
          _loading = false;
          _items = result.items;
          _hasNext = result.hasNext;
        });
      } catch (e) {
        if (!mounted || revision != _revision) return;
        setState(() {
          _loading = false;
          _error = requestFailure(e, '加载失败，请重试');
        });
      }
    }

    if (debounce) {
      _debounce = Timer(const Duration(milliseconds: 250), fetch);
    } else {
      fetch();
    }
  }

  void _open() {
    if (_menu.isOpen) return;
    _search('', 1);
    _menu.open();
    _input.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _input.text.length,
    );
  }

  void _choose(T? value) {
    _menu.close();
    widget.onSelected(value);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListFilterLabel(
    widget.label,
    child: MenuAnchor(
      controller: _menu,
      childFocusNode: _focus,
      onClose: () {
        _debounce?.cancel();
        _revision++;
        _restoreSelection();
        _focus.unfocus();
      },
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(2),
        side: WidgetStatePropertyAll(BorderSide(color: salesLine)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
        minimumSize: WidgetStatePropertyAll(Size(180, 0)),
        maximumSize: WidgetStatePropertyAll(Size(300, 250)),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () => _choose(null),
          child: SizedBox(width: 126, child: Text(widget.allLabel)),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () => _search(_query, _page),
            child: Text('$_error · 重试'),
          ),
        if (!_loading && _error == null && _items.isEmpty)
          const Padding(padding: EdgeInsets.all(8), child: Text('没有匹配记录')),
        for (final item in _items)
          MenuItemButton(
            onPressed: () => _choose(item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name(item)),
                if (widget.code(item) != widget.name(item))
                  Text(
                    widget.code(item),
                    style: const TextStyle(color: salesMuted, fontSize: 11),
                  ),
              ],
            ),
          ),
        if (_page > 1)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () => _search(_query, _page - 1),
            child: const Text('上一页'),
          ),
        if (_hasNext)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: () => _search(_query, _page + 1),
            child: const Text('下一页'),
          ),
      ],
      builder: (context, menu, _) => TextField(
        readOnly: widget.selectionOnly,
        showCursor: !widget.selectionOnly,
        controller: _input,
        focusNode: _focus,
        style: const TextStyle(fontSize: 12),
        decoration: listFilterDecoration.copyWith(
          isDense:
              InputDecorationTheme.of(context).constraints?.hasTightHeight !=
              true,
          hintText: widget.allLabel,
          suffixIcon: IconButton(
            tooltip: '展开${widget.label}',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 28),
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            onPressed: () => menu.isOpen ? menu.close() : _open(),
          ),
        ),
        onTap: _open,
        onChanged: (value) {
          if (!menu.isOpen) menu.open();
          _search(value.trim(), 1, debounce: true);
        },
      ),
    ),
  );
}

Widget styleDictionaryFilter({
  required ErpApi api,
  required String token,
  required String kind,
  required String label,
  required DictionaryEntry? value,
  required ValueChanged<DictionaryEntry?> onSelected,
}) => ListFilterLookup<DictionaryEntry>(
  key: ValueKey(kind),
  label: label,
  allLabel: '全部$label',
  value: value,
  name: (item) => item.label,
  code: (item) => item.label,
  selectionOnly: true,
  onSelected: onSelected,
  load: (search, page) async {
    final result = await api.list(
      token: token,
      path: ApiPath.styleDictionaryList,
      decode: DictionaryEntry.fromJson,
      query: {'kind': kind},
      search: search,
      page: page,
    );
    return (items: result.items, hasNext: result.hasNext);
  },
);
