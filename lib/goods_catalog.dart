import 'package:flutter/material.dart';

import 'api.dart';
import 'generated/api_schema.dart';
import 'list_filter_fields.dart';
import 'record_pages.dart';
import 'sales_theme.dart';
import 'style_details.dart';
import 'tablet_filter_panel.dart';
import 'wheel_date.dart';

class GoodsCatalog extends StatefulWidget {
  const GoodsCatalog({
    super.key,
    required this.api,
    required this.token,
    required this.active,
    required this.pictures,
  });

  final ErpApi api;
  final String token;
  final bool active;
  final bool pictures;

  @override
  State<GoodsCatalog> createState() => _GoodsCatalogState();
}

class _GoodsCatalogState extends State<GoodsCatalog> {
  static const _attributes = {
    'color': '颜色',
    'category': '类别',
    'season': '季节',
    'brand': '品牌',
  };
  static const _statuses = {'active': '启用', 'disabled': '停用', 'all': '全部'};
  static const _images = {'': '全部', 'true': '有图', 'false': '无图'};
  final _inputs = {
    for (final key in ['search', 'operator', 'launch_from', 'launch_to'])
      key: TextEditingController(),
  };
  final _selected = <String, DictionaryEntry?>{};
  String _status = 'active';
  String _hasImage = '';
  String? _error;
  Map<String, String> _applied = const {'status': 'active'};
  int _revision = 0;

  @override
  void dispose() {
    for (final input in _inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  void _apply() {
    final params = <String, String>{
      'status': _status,
      if (_hasImage.isNotEmpty) 'has_image': _hasImage,
      for (final e in _selected.entries) e.key: ?e.value?.label,
      for (final key in ['search', 'operator'])
        if (_inputs[key]!.text.trim().isNotEmpty)
          key: _inputs[key]!.text.trim(),
    };
    for (final key in ['launch_from', 'launch_to']) {
      final value = _inputs[key]!.text.trim();
      if (value.isEmpty) continue;
      final date = parseBusinessDate(value);
      if (date == null) {
        setState(() => _error = '请输入有效的上架日期（YYYY-MM-DD）');
        return;
      }
      params[key] = displayDate(date.toIso8601String());
    }
    final from = params['launch_from'];
    final to = params['launch_to'];
    if (from != null && to != null && from.compareTo(to) > 0) {
      setState(() => _error = '截止日期不能早于起始日期');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _applied = params;
      _error = null;
      _revision++;
    });
  }

  void _clear() {
    for (final input in _inputs.values) {
      input.clear();
    }
    _selected.clear();
    _status = 'all';
    _hasImage = '';
    _apply();
  }

  Widget _input(String key, String label, String hint) => ListFilterLabel(
    label,
    child: TextField(
      key: ValueKey(key),
      controller: _inputs[key],
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 12),
      decoration: listFilterDecoration.copyWith(hintText: hint),
      onSubmitted: (_) => _apply(),
    ),
  );

  Widget _date(String key, String label) => ListFilterLabel(
    label,
    child: WheelDateInput(
      key: ValueKey(key),
      controller: _inputs[key]!,
      label: label,
      decoration: listFilterDecoration.copyWith(hintText: '年-月-日'),
      onChanged: (_) {},
      onSubmitted: (_) => _apply(),
    ),
  );

  Widget _filters() => TabletFilterPanel(
    error: _error,
    fields: [
      _input('search', '关键词', '款号 / 商品名称'),
      _date('launch_from', '上架日期从'),
      _date('launch_to', '上架日期至'),
      for (final attribute in _attributes.entries)
        styleDictionaryFilter(
          api: widget.api,
          token: widget.token,
          kind: attribute.key,
          label: attribute.value,
          value: _selected[attribute.key],
          onSelected: (item) => setState(() => _selected[attribute.key] = item),
        ),
      ListFilterSelect<String>(
        label: '商品状态',
        value: _status,
        valueText: _statuses[_status]!,
        options: _statuses,
        onSelected: (s) => setState(() => _status = s),
      ),
      _input('operator', '经办人', '姓名 / 账号'),
      ListFilterSelect<String>(
        label: '是否有图',
        value: _hasImage,
        valueText: _images[_hasImage]!,
        options: _images,
        onSelected: (s) => setState(() => _hasImage = s),
      ),
    ],
    actions: [
      TabletAction('查询', primary: true, onPressed: _apply),
      TabletAction('清除', onPressed: _clear),
    ],
  );

  Widget _photo(StyleCatalogRead item, {double size = 48}) => StylePhoto(
    key: ValueKey(item.id),
    api: widget.api,
    token: widget.token,
    id: item.id,
    label: '${item.code} 款式图',
    available: item.hasStyleImage,
    size: size,
    thumbnail: true,
  );

  void _details(StyleCatalogRead item) => showStyleDetails(
    context,
    widget.api,
    widget.token,
    id: item.id,
    code: item.code,
    hasImage: item.hasStyleImage,
  );

  String _price(StyleCatalogRead item) =>
      item.salePrice == null ? '—' : '¥${item.salePrice}';

  Widget _gallery(List<StyleCatalogRead> items) => SliverPadding(
    padding: const EdgeInsets.all(8),
    sliver: SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 222,
        mainAxisExtent: 148 + MediaQuery.textScalerOf(context).scale(13) * 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SalesPanel(
          child: InkWell(
            onTap: () => _details(item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _photo(item, size: 180)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        item.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '上架 ${item.launchDate ?? '—'}',
                        style: const TextStyle(fontSize: 12, color: salesMuted),
                      ),
                      Text(
                        '售价 ${_price(item)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '总库存 ${item.totalStock ?? '—'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => RecordList<StyleCatalogRead>(
    active: widget.active,
    title: '货品查询',
    inlineCount: true,
    hint: '款号 / 商品名称',
    empty: '没有匹配的货品',
    filterRevision: _revision,
    queryToolbar: (_) => _filters(),
    load: (_, page) => widget.api.list(
      token: widget.token,
      path: ApiPath.stylesCatalogList,
      decode: StyleCatalogRead.fromJson,
      query: _applied,
      page: page,
    ),
    resultsSliver: widget.pictures ? _gallery : null,
    columns: const [
      (title: '图片', width: 68),
      (title: '款号', width: 104),
      (title: '商品名称', width: 130),
      (title: '类别', width: 78),
      (title: '售价', width: 84),
      (title: '总库存', width: 62),
      (title: '上架日期', width: 99),
      (title: '状态', width: 58),
      (title: '成分', width: 92),
      (title: '操作', width: 68),
    ],
    cells: (item) => [
      _photo(item),
      Text(item.code, style: const TextStyle(fontWeight: FontWeight.w700)),
      Text(item.name),
      Text(item.category ?? '—'),
      Text(_price(item)),
      Text('${item.totalStock ?? '—'}'),
      Text(item.launchDate ?? '—'),
      Text(item.active ? '启用' : '停用'),
      Text(item.composition ?? '—'),
      SalesRecordAction(label: '详情', onPressed: () => _details(item)),
    ],
  );
}
