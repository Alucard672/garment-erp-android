import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api.dart';
import 'generated/api_schema.dart';
import 'record_pages.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';

class StylePhoto extends StatefulWidget {
  const StylePhoto({
    super.key,
    required this.api,
    required this.token,
    required this.id,
    required this.label,
    this.kind = 'style_image',
    this.available,
    this.size = 48,
    this.thumbnail = false,
    this.expandable = true,
  });

  final ErpApi api;
  final String token;
  final int id;
  final String label;
  final String kind;
  final bool? available;
  final double size;
  final bool expandable;
  final bool thumbnail;

  @override
  State<StylePhoto> createState() => _StylePhotoState();
}

class _StylePhotoState extends State<StylePhoto> {
  Future<Uint8List?>? _photo;
  bool get _isThumbnail => widget.thumbnail || widget.size <= 48;

  void _loadPhoto() {
    _photo = widget.available == false
        ? null
        : widget.api.styleImage(
            widget.token,
            widget.id,
            kind: widget.kind,
            thumbnail: _isThumbnail,
          );
  }

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(StylePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id ||
        widget.api != oldWidget.api ||
        widget.token != oldWidget.token ||
        widget.kind != oldWidget.kind ||
        widget.size != oldWidget.size ||
        widget.thumbnail != oldWidget.thumbnail ||
        widget.available != oldWidget.available) {
      _loadPhoto();
    }
  }

  void _showImage(Uint8List bytes) {
    final label = widget.label;
    final original = _isThumbnail
        ? widget.api.styleImage(widget.token, widget.id, kind: widget.kind)
        : Future<Uint8List?>.value(bytes);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: salesCanvas,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: Text(label),
                actions: [
                  IconButton(
                    tooltip: '关闭大图',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FutureBuilder<Uint8List?>(
                    future: original,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final bytes = snapshot.data;
                      if (bytes == null) {
                        return Center(
                          child: Text(snapshot.hasError ? '图片加载失败。' : '暂无图片。'),
                        );
                      }
                      return InteractiveViewer(
                        maxScale: 5,
                        child: Center(
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                            semanticLabel: label,
                            errorBuilder: (_, _, _) => const Text('图片加载失败。'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _photo,
    builder: (context, snapshot) {
      final bytes = snapshot.connectionState == ConnectionState.done
          ? snapshot.data
          : null;
      return SizedBox.square(
        dimension: widget.size,
        child: Material(
          color: salesTint,
          borderRadius: BorderRadius.circular(7),
          clipBehavior: Clip.antiAlias,
          child: bytes == null
              ? Tooltip(
                  message: switch (snapshot.connectionState) {
                    ConnectionState.waiting => '图片加载中',
                    _ => snapshot.hasError ? '图片加载失败' : '暂无图片',
                  },
                  child: Icon(
                    snapshot.hasError
                        ? Icons.broken_image_outlined
                        : Icons.image_outlined,
                    color: salesMuted,
                  ),
                )
              : InkWell(
                  onTap: widget.expandable ? () => _showImage(bytes) : null,
                  child: Tooltip(
                    message: widget.expandable
                        ? '放大 ${widget.label}'
                        : widget.label,
                    child: Image.memory(
                      bytes,
                      cacheWidth: _isThumbnail ? 160 : null,
                      fit: _isThumbnail ? BoxFit.cover : BoxFit.contain,
                      semanticLabel: widget.label,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: salesMuted,
                      ),
                    ),
                  ),
                ),
        ),
      );
    },
  );
}

Future<void> showStyleDetails(
  BuildContext context,
  ErpApi api,
  String token, {
  required int id,
  required String code,
  bool? hasImage,
}) {
  return showRecordDetail(
    context,
    title: '款式 $code',
    maxWidth: 960,
    scrollBody: false,
    child: _StyleDetails(api: api, token: token, id: id, hasImage: hasImage),
  );
}

class _StyleDetails extends StatefulWidget {
  const _StyleDetails({
    required this.api,
    required this.token,
    required this.id,
    this.hasImage,
  });

  final ErpApi api;
  final String token;
  final int id;
  final bool? hasImage;

  @override
  State<_StyleDetails> createState() => _StyleDetailsState();
}

class _StyleDetailsState extends State<_StyleDetails> {
  late Future<StyleDetail> _request = _loadStyle();
  int _tab = 0;

  Future<StyleDetail> _loadStyle() => widget.api.style(widget.token, widget.id);

  @override
  Widget build(BuildContext context) => FutureBuilder<StyleDetail>(
    future: _request,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(requestFailure(snapshot.error!, '款式加载失败。')),
              const SizedBox(height: 12),
              TabletAction(
                '重试',
                onPressed: () => setState(() => _request = _loadStyle()),
              ),
            ],
          ),
        );
      }

      final style = snapshot.data;
      if (style == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: salesPaper,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SalesTabs(
                labels: const ['基础资料', '颜色尺码', '尺寸表', '洗护与标签'],
                selected: _tab,
                onSelect: (tab) => setState(() => _tab = tab),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: PageStorageKey(('style', style.id, _tab)),
              padding: const EdgeInsets.all(12),
              children: switch (_tab) {
                0 => _overview(style),
                1 => [_skuTable(style)],
                2 => _measurements(style.specification),
                _ => _careDetails(style),
              },
            ),
          ),
        ],
      );
    },
  );

  List<Widget> _overview(StyleDetail style) {
    final spec = style.specification;
    final profile = spec?.profile;
    final attributes = {
      for (final entry in profile?.attributes ?? const <AttributeRead>[])
        entry.attribute: entry.label,
    };
    final personnel = {
      for (final person in profile?.personnel ?? const <PersonnelRead>[])
        person.role: person.name,
    };
    final photo = StylePhoto(
      api: widget.api,
      token: widget.token,
      id: style.id,
      label: '${style.code} 款式图',
      available: spec?.hasStyleImage ?? style.hasStyleImage ?? widget.hasImage,
      size: 196,
    );
    final overview = _Fields([
      ('商品名称', style.name),
      ('品类', _nonEmpty(style.category) ?? attributes['category']),
      ('成分', style.composition),
      ('可选颜色', style.skus.map((sku) => sku.color).toSet().join('、')),
      ('可选尺码', style.skus.map((sku) => sku.size).toSet().join('、')),
      ('品牌', attributes['brand']),
      ('季节', attributes['season']),
      ('年份', profile?.year?.toString()),
      ('波段', attributes['wave']),
      ('上架日期', profile?.launchDate),
      ('等级', attributes['grade']),
      ('针型', attributes['gauge']),
    ]);
    return [
      SalesPanel(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 540) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [photo, const SizedBox(height: 16), overview],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                photo,
                const SizedBox(width: 24),
                Expanded(child: overview),
              ],
            );
          },
        ),
      ),
      _section(
        '人员信息',
        SalesPanel(
          padding: const EdgeInsets.all(12),
          child: _Fields([
            ('设计组', attributes['design_group']),
            ('设计师', personnel['designer']),
            ('设计助理', personnel['design_assistant']),
            ('制版师', personnel['pattern_maker']),
            ('工艺师', personnel['technician']),
          ]),
        ),
      ),
      _section(
        '备注与注意事项',
        facts([
          ('备注', profile?.remark ?? ''),
          ('注意事项', profile?.precautions ?? ''),
        ]),
      ),
    ];
  }

  List<Widget> _careDetails(StyleDetail style) {
    final spec = style.specification;
    final profile = spec?.profile;
    final care = spec?.careLabel;
    return [
      if (spec?.hasCareImage == true) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: StylePhoto(
            api: widget.api,
            token: widget.token,
            id: style.id,
            kind: 'care_image',
            label: '${style.code} 洗水唛图',
            size: 196,
          ),
        ),
        const SizedBox(height: 12),
      ],
      facts([
        ('纤维成分', care?.composition ?? ''),
        ('洗护说明', care?.care ?? ''),
        ('其他标注', care?.remark ?? ''),
        ('洗水工艺', profile?.washProcess ?? ''),
      ]),
    ];
  }
}

class _Fields extends StatelessWidget {
  const _Fields(this.entries);

  final List<(String, String?)> entries;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 16.0;
      final width = constraints.maxWidth;
      final columns = width >= 510 ? 3 : (width >= 280 ? 2 : 1);
      final fieldWidth = (width - (columns - 1) * spacing) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: 12,
        children: [
          for (final (label, value) in entries)
            SizedBox(
              width: fieldWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: salesMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _nonEmpty(value) ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

String? _nonEmpty(String? value) =>
    value?.trim().isNotEmpty == true ? value : null;

Widget _skuTable(StyleDetail style) {
  if (style.skus.isEmpty) return _empty('暂无颜色尺码。');
  return _table(
    const [('颜色', 130), ('尺码', 90), ('批发单价', 110)],
    [
      for (final sku in style.skus)
        [
          sku.color,
          sku.size,
          if (sku.wholesalePrice case final price?) '¥$price' else null,
        ],
    ],
  );
}

List<Widget> _measurements(StyleSpecificationRead? spec) {
  final sizes = spec?.sizeTable ?? [];
  final measurements = spec?.measurements ?? [];
  if (sizes.isEmpty && measurements.isEmpty) return [_empty('暂无尺寸资料。')];
  return [
    const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text('尺寸表（cm）', style: TextStyle(color: salesMuted)),
    ),
    if (sizes.isNotEmpty) _sizeTable(sizes),
    if (sizes.isNotEmpty && measurements.isNotEmpty) const SizedBox(height: 8),
    if (measurements.isNotEmpty)
      _table(
        const [('尺码', 70), ('测量部位', 132), ('标准尺寸', 104), ('允许偏差 ±', 108)],
        [
          for (final row in measurements)
            [row.size, row.point, row.value, row.tolerance],
        ],
      ),
  ];
}

Widget _sizeTable(List<SizeRowRead> rows) {
  final sizes = {
    for (final row in rows)
      for (final cell in row.values) cell.sizeId: cell.size,
  };
  return _table(
    [
      ('测量部位', 100),
      ('测量方法', 120),
      ('误差 ±', 68),
      ('档差', 65),
      ('纸样尺寸', 80),
      ('样版值', 73),
      for (final size in sizes.values) ('$size 洗水前', 89),
      for (final size in sizes.values) ('$size 洗水后', 89),
    ],
    rows.map((row) {
      final cells = {for (final cell in row.values) cell.sizeId: cell};
      return [
        row.point,
        row.method,
        row.tolerance,
        row.gradeDelta,
        row.patternSize,
        row.sampleSize,
        for (final id in sizes.keys) cells[id]?.beforeWash,
        for (final id in sizes.keys) cells[id]?.afterWash,
      ];
    }).toList(),
  );
}

Widget _table(List<(String, double)> headings, List<List<String?>> rows) =>
    SalesPanel(
      child: SalesGrid(
        columns: [
          for (final (title, width) in headings) (title: title, width: width),
        ],
        rows: [
          for (final row in rows)
            [
              for (final value in row)
                Text(value?.isNotEmpty == true ? value! : '—'),
            ],
        ],
      ),
    );

Widget _section(String title, Widget content) => Padding(
  padding: const EdgeInsets.only(top: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      content,
    ],
  ),
);

Widget _empty(String message) => SalesPanel(
  padding: const EdgeInsets.all(12),
  child: Text(message, style: const TextStyle(color: salesMuted)),
);
