import 'package:flutter/material.dart';

import 'api.dart';
import 'generated/api_schema.dart';
import 'list_filter_fields.dart';
import 'record_pages.dart';
import 'wheel_date.dart';
import 'tablet_filter_panel.dart';

class StockList extends StatefulWidget {
  const StockList({
    super.key,
    required this.api,
    required this.token,
    this.active = true,
  });
  final bool active;
  final ErpApi api;
  final String token;
  @override
  State<StockList> createState() => _StockListState();
}

class _StockListState extends State<StockList> {
  static const fields = {'style_code': '款号', 'style_name': '款号名称'};
  static const dictionary = {
    'color': '颜色',
    'size': '尺码',
    'season': '季节',
    'brand': '品牌',
    'category': '类别',
  };
  final _text = {
    for (final key in [...fields.keys, 'launch_from', 'launch_to'])
      key: TextEditingController(),
  };
  final _chosen = <String, DictionaryEntry>{};
  String _status = 'active';
  WarehouseRead? _warehouse;
  Map<String, String> _applied = {'status': 'active'};
  int _revision = 0;
  int _reset = 0;
  String? _error;

  void _apply() {
    final filters = <String, String>{
      for (final key in fields.keys)
        if (_text[key]!.text.trim().isNotEmpty) key: _text[key]!.text.trim(),
      for (final e in _chosen.entries) e.key: e.value.label,
      if (_status.isNotEmpty) 'status': _status,
      if (_warehouse != null) 'warehouse_id': _warehouse!.id.toString(),
    };
    for (final key in ['launch_from', 'launch_to']) {
      final raw = _text[key]!.text.trim();
      if (raw.isEmpty) continue;
      final date = parseBusinessDate(raw);
      if (date == null) {
        setState(() => _error = '请输入有效的上架日期（YYYY-MM-DD）');
        return;
      }
      filters[key] = displayDate(date.toIso8601String());
    }
    if (filters.containsKey('launch_from') &&
        filters.containsKey('launch_to') &&
        filters['launch_from']!.compareTo(filters['launch_to']!) > 0) {
      setState(() => _error = '截止日期不能早于起始日期');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _applied = filters;
      _error = null;
      _revision++;
    });
  }

  void _clear() {
    FocusManager.instance.primaryFocus?.unfocus();
    for (final controller in _text.values) {
      controller.clear();
    }
    setState(() {
      _chosen.clear();
      _warehouse = null;
      _status = '';
      _applied = {};
      _error = null;
      _reset++;
    });
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _date(String key, String label) => ListFilterLabel(
    label,
    child: WheelDateInput(
      label: label,
      controller: _text[key]!,
      decoration: listFilterDecoration.copyWith(hintText: '年-月-日'),
      onChanged: (_) {},
      onSubmitted: (_) => _apply(),
    ),
  );

  Widget _dictionary(String kind, String label) => styleDictionaryFilter(
    api: widget.api,
    token: widget.token,
    kind: kind,
    label: label,
    value: _chosen[kind],
    onSelected: (item) => setState(() {
      if (item == null) {
        _chosen.remove(kind);
      } else {
        _chosen[kind] = item;
      }
    }),
  );

  @override
  Widget build(BuildContext context) => RecordList<StockRead>(
    key: ValueKey(_reset),
    active: widget.active,
    filterRevision: _revision,
    title: '当前库存',

    inlineCount: true,
    hint: '综合搜索',
    empty: _applied.keys.any((k) => k != 'status') ? '没有匹配记录' : '暂无符合条件的库存流水。',
    queryToolbar: (keyword) => TabletFilterPanel(
      actions: [
        TabletAction('查询', primary: true, onPressed: _apply),
        TabletAction('清除', onPressed: _clear),
      ],
      error: _error,
      fields: [
        ListFilterLabel('综合搜索', child: keyword),
        for (final e in fields.entries)
          ListFilterLabel(
            e.value,
            child: TextField(
              key: ValueKey(e.key),
              controller: _text[e.key],
              style: const TextStyle(fontSize: 12),
              decoration: listFilterDecoration.copyWith(
                hintText: '输入${e.value}',
              ),
              onSubmitted: (_) => _apply(),
            ),
          ),
        _date('launch_from', '上架日期从'),
        _date('launch_to', '上架日期至'),
        ListFilterLookup<WarehouseRead>(
          label: '门店 / 仓库',
          allLabel: '全部仓库',
          value: _warehouse,
          name: (w) => w.name,
          code: (w) => w.code,
          onSelected: (w) => setState(() => _warehouse = w),
          load: (query, page) async {
            final result = await widget.api.list(
              token: widget.token,
              path: ApiPath.warehousesList,
              decode: WarehouseRead.fromJson,
              search: query,
              page: page,
              query: const {'include_inactive': 'true'},
            );
            return (items: result.items, hasNext: result.hasNext);
          },
        ),
        for (final e in dictionary.entries) _dictionary(e.key, e.value),
        ListFilterSelect<String>(
          label: '是否停用',
          value: _status,
          valueText: const {'active': '否', 'disabled': '是', '': '全部'}[_status]!,
          options: const {'': '全部', 'active': '否', 'disabled': '是'},
          onSelected: (s) => setState(() => _status = s),
        ),
      ],
    ),
    load: (query, page) => widget.api.list(
      token: widget.token,
      path: ApiPath.stockList,
      decode: StockRead.fromJson,
      search: query,
      page: page,
      query: _applied,
    ),
    columns: const [
      (title: '款号', width: 116),
      (title: '商品', width: 178),
      (title: '颜色', width: 96),
      (title: '尺码', width: 65),
      (title: '仓库', width: 132),
      (title: '在库', width: 75),
    ],
    cells: (item) => [
      Text(item.styleCode),
      Text(item.styleName),
      Text(item.color),
      Text(item.size),
      Text(item.warehouse),
      Text('${item.quantity}'),
    ],
  );
}
