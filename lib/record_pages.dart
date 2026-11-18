import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'api.dart';
import 'generated/api_schema.dart';
import 'sales_theme.dart';
import 'wheel_date.dart';
import 'tablet_filter_panel.dart';
import 'list_filter_fields.dart';

const pageInsets = EdgeInsets.fromLTRB(4, 3, 4, 3);

typedef RecordColumn = ({String title, double width});

String displayDate(String value) => value.split('T').first;

class SalesRecordText extends StatelessWidget {
  const SalesRecordText(this.value, {super.key, this.emphasized = false})
    : _currency = false;
  const SalesRecordText.currency(this.value, {super.key})
    : emphasized = false,
      _currency = true;

  final String? value;
  final bool emphasized;
  final bool _currency;

  @override
  Widget build(BuildContext context) {
    final text = value;
    return Text(
      text == null || text.isEmpty
          ? '—'
          : _currency
          ? '¥$text'
          : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: emphasized ? FontWeight.w700 : null,
      ),
    );
  }
}

class SalesRecordAction extends StatelessWidget {
  const SalesRecordAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return primary
        ? FilledButton(style: style, onPressed: onPressed, child: Text(label))
        : OutlinedButton(
            style: style,
            onPressed: onPressed,
            child: Text(label),
          );
  }
}

class SalesStatusLabel extends StatelessWidget {
  const SalesStatusLabel(this.status, {super.key});

  final SalesDocumentStatus status;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: status.ink, shape: BoxShape.circle),
        child: const SizedBox.square(dimension: 6),
      ),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          status.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: status.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class OrderStatusLegend extends StatelessWidget {
  const OrderStatusLegend({super.key, this.pendingOnly = false});

  final bool pendingOnly;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Text('单据状态', style: TextStyle(color: salesMuted, fontSize: 12)),
      for (final status in [
        SalesDocumentStatus.waiting,
        SalesDocumentStatus.partial,
        if (!pendingOnly) SalesDocumentStatus.fulfilled,
      ])
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: status.surface,
            borderRadius: BorderRadius.circular(5),
          ),
          child: SalesStatusLabel(status),
        ),
    ],
  );
}

class SalesTitle extends StatelessWidget {
  const SalesTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle case final text?)
              Text(
                text,
                style: const TextStyle(color: salesMuted, fontSize: 12),
              ),
          ],
        ),
      ),
      if (action != null) const SizedBox(width: 10),
      ?action,
    ],
  );
}

class SalesTabs extends StatelessWidget {
  const SalesTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.action,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: salesPaper,
        border: Border(bottom: BorderSide(color: salesLine)),
      ),
      child: action == null
          ? tabs
          : Row(
              children: [
                Expanded(child: tabs),
                const SizedBox(width: 12),
                action!,
              ],
            ),
    );
  }

  Widget _tabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var index = 0; index < labels.length; index++)
          Semantics(
            selected: index == selected,
            child: InkWell(
              onTap: () => onSelect(index),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: salesPaper,
                  border: Border(
                    bottom: BorderSide(
                      color: index == selected
                          ? salesPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: index == selected ? salesPrimary : salesMuted,
                      fontWeight: index == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class SalesGrid extends StatelessWidget {
  const SalesGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.compact = false,
    this.rowKeys,
    this.rowColors,
  }) : assert(rowKeys == null || rowKeys.length == rows.length),
       assert(rowColors == null || rowColors.length == rows.length);
  final List<RecordColumn> columns;
  final List<List<Widget>> rows;
  final bool compact;

  final List<Key>? rowKeys;
  final List<Color>? rowColors;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) {
      final minimum = columns.fold(
        0.0,
        (total, column) => total + column.width,
      );
      final width = math.max(minimum, viewport.maxWidth);
      final cellPadding = EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      );
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Table(
            columnWidths: {
              for (var i = 0; i < columns.length; i++)
                i: FixedColumnWidth(columns[i].width / minimum * width),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              top: BorderSide(color: salesLine),
              horizontalInside: BorderSide(color: salesLine),
              verticalInside: BorderSide(color: salesLine),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: salesTableHeader),
                children: [
                  for (final column in columns)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      child: Text(
                        column.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: salesInk,
                        ),
                      ),
                    ),
                ],
              ),
              for (var index = 0; index < rows.length; index++)
                TableRow(
                  key: switch (rowKeys?[index]) {
                    final LocalKey key => key,
                    final key? => ValueKey(key),
                    null => null,
                  },
                  decoration: BoxDecoration(
                    color:
                        rowColors?[index] ??
                        (index.isEven ? salesPaper : salesTableAlternate),
                  ),
                  children: [
                    for (final cell in rows[index])
                      Padding(
                        padding: cellPadding,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: compact ? 30 : 28,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: cell,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}

class SalesListSource<T> {
  const SalesListSource({
    required this.api,
    required this.token,
    required this.path,
    required this.decode,
    required this.dateLabel,
    this.showOrderStatus = false,
    this.pendingOnly,
  });

  final ErpApi api;
  final String token;
  final String path;
  final T Function(Map<String, dynamic>) decode;
  final String dateLabel;
  final bool showOrderStatus;
  final bool? pendingOnly;
}

enum _OrderListStatus {
  all('', '全部状态'),
  pending('pending', '待发货'),
  partial('partial', '部分发货'),
  fulfilled('fulfilled', '已发齐');

  const _OrderListStatus(this.code, this.label);
  final String code;
  final String label;
}

class RecordList<T> extends StatefulWidget {
  const RecordList({
    super.key,
    required this.title,
    required this.hint,
    required this.empty,
    this.load,
    this.salesSource,
    required this.columns,
    required this.cells,
    this.initialQuery = '',
    this.inlineCount = false,
    this.compact = false,
    this.rowColor,
    this.legend,
    this.filters,
    this.queryToolbar,
    this.resultsSliver,

    this.active = true,
    this.filterRevision = 0,
    this.action,
    this.footer,
  }) : assert((load == null) != (salesSource == null));

  final String title;
  final String hint;
  final String empty;
  final RecordLoader<T>? load;
  final SalesListSource<T>? salesSource;
  final List<RecordColumn> columns;
  final List<Widget> Function(T) cells;
  final String initialQuery;
  final bool inlineCount;
  final bool compact;
  final Color Function(T)? rowColor;
  final Widget? legend;
  final Widget? filters;
  final Widget Function(Widget keyword)? queryToolbar;
  final Widget Function(List<T> items)? resultsSliver;

  final bool active;
  final int filterRevision;
  final Widget? action;
  final Widget Function(List<T>)? footer;

  @override
  State<RecordList<T>> createState() => _RecordListState<T>();
}

class _RecordListState<T> extends State<RecordList<T>> {
  late final TextEditingController _query;
  Timer? _debounce;
  int _page = 1;
  bool _refreshingSamePage = false;
  late Future<RecordPageData<T>> _future;
  Customer? _customer;
  StaffRead? _clerk;
  final _fromText = TextEditingController();
  final _toText = TextEditingController();
  String? _fromDate;
  String? _toDate;
  String? _dateError;
  _OrderListStatus _status = _OrderListStatus.all;

  Map<String, String> get _criteria => {
    if (_customer case final customer?) 'customer_id': customer.id.toString(),
    if (_clerk case final clerk?) 'clerk_id': clerk.id.toString(),
    'date_from': ?_fromDate,
    'date_to': ?_toDate,
    if (_status != _OrderListStatus.all) 'status': _status.code,
  };

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    _future = _fetch();
  }

  @override
  void didUpdateWidget(covariant RecordList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pendingOnly = widget.salesSource?.pendingOnly;
    if (pendingOnly != oldWidget.salesSource?.pendingOnly ||
        widget.filterRevision != oldWidget.filterRevision) {
      if (pendingOnly == true && _status == _OrderListStatus.fulfilled) {
        _status = _OrderListStatus.all;
      }
      _debounce?.cancel();
      _page = 1;
      _refreshingSamePage = false;
      _future = _fetch();
    } else if (!oldWidget.active && widget.active) {
      _refreshingSamePage = true;
      _future = _fetch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromText.dispose();
    _toText.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<RecordPageData<T>> _fetch() {
    final search = _query.text.trim();
    final source = widget.salesSource;
    if (source == null) return widget.load!(search, _page);
    return source.api.list(
      token: source.token,
      path: source.path,
      decode: source.decode,
      search: search,
      page: _page,
      query: {
        if (source.pendingOnly case final pendingOnly?)
          'pending': '$pendingOnly',
        ..._criteria,
      },
    );
  }

  void _load(int page, {VoidCallback? updateFilters}) {
    _debounce?.cancel();
    setState(() {
      updateFilters?.call();
      _refreshingSamePage = false;
      _page = page;
      _future = _fetch();
    });
  }

  Widget _searchField() => TextField(
    key: const ValueKey('list-keyword'),
    controller: _query,
    style: const TextStyle(fontSize: 12),
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: widget.queryToolbar != null ? '款号、名称或颜色' : widget.hint,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 32),
      prefixIcon: const Icon(Icons.search, color: salesMuted, size: 16),
    ),
    onSubmitted: (_) => _load(1),
    onChanged: (_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () => _load(1));
    },
  );

  void _applyDates({bool submitted = false}) {
    final from = parseBusinessDate(_fromText.text);
    final to = parseBusinessDate(_toText.text);
    String? error;
    if ((_fromText.text.isNotEmpty && from == null) ||
        (_toText.text.isNotEmpty && to == null)) {
      if (submitted ||
          (_fromText.text.length >= 10 && from == null) ||
          (_toText.text.length >= 10 && to == null)) {
        error = '请输入有效日期（YYYY-MM-DD）';
      }
      setState(() => _dateError = error);
      return;
    }
    if (from != null && to != null && from.isAfter(to)) {
      setState(() => _dateError = '截止日期不能早于起始日期');
      return;
    }
    final first = from == null ? null : displayDate(from.toIso8601String());
    final last = to == null ? null : displayDate(to.toIso8601String());
    if (first == _fromDate && last == _toDate) {
      setState(() => _dateError = null);
      return;
    }
    _load(
      1,
      updateFilters: () {
        _dateError = null;
        _fromDate = first;
        _toDate = last;
      },
    );
  }

  Widget _dateField(String label, TextEditingController controller) =>
      ListFilterLabel(
        label,
        child: WheelDateInput(
          key: ValueKey(label),
          label: label,
          controller: controller,
          decoration: listFilterDecoration.copyWith(
            isDense: false,
            hintText: '年-月-日',
          ),
          onChanged: (_) => _applyDates(),
          onSubmitted: (_) => _applyDates(submitted: true),
        ),
      );

  List<Widget> _salesFilters(SalesListSource<T> source) => [
    ListFilterLookup<Customer>(
      label: '客户',
      allLabel: '全部客户',
      value: _customer,
      name: (item) => item.name,
      code: (item) => item.code,
      load: (query, page) async {
        final result = await source.api.customers(source.token, query, page);
        return (items: result.results, hasNext: result.next != null);
      },
      onSelected: (item) => _load(1, updateFilters: () => _customer = item),
    ),
    _dateField('${source.dateLabel}从', _fromText),
    _dateField('${source.dateLabel}至', _toText),
    ListFilterLookup<StaffRead>(
      label: '店员',
      allLabel: '全部店员',
      value: _clerk,
      name: (item) => item.name.isEmpty ? item.username : item.name,
      code: (item) => item.username,
      load: (query, page) async {
        final result = await source.api.clerks(source.token, query, page);
        return (items: result.results, hasNext: result.next != null);
      },
      onSelected: (item) => _load(1, updateFilters: () => _clerk = item),
    ),
    if (source.showOrderStatus)
      ListFilterSelect<_OrderListStatus>(
        label: '状态',
        value: _status,
        valueText: _status.label,
        options: {
          for (final status in _OrderListStatus.values)
            if (source.pendingOnly != true ||
                status != _OrderListStatus.fulfilled)
              status: status.label,
        },
        onSelected: (status) => _load(1, updateFilters: () => _status = status),
      ),
  ];

  Widget _clearSalesFilters() => TabletAction(
    '清除筛选',
    onPressed:
        _criteria.isEmpty && _fromText.text.isEmpty && _toText.text.isEmpty
        ? null
        : () => _load(
            1,
            updateFilters: () {
              _customer = null;
              _clerk = null;
              _fromText.clear();
              _toText.clear();
              _fromDate = null;
              _toDate = null;
              _dateError = null;
              _status = _OrderListStatus.all;
            },
          ),
  );

  Widget _toolbar() {
    final source = widget.salesSource;
    if (widget.queryToolbar case final builder?) return builder(_searchField());
    if (source != null) {
      return TabletFilterPanel(
        fields: [
          ListFilterLabel('关键词', child: _searchField()),
          ?widget.filters,
          ..._salesFilters(source),
        ],
        actions: [_clearSalesFilters(), ?widget.action],
        error: _dateError,
      );
    }
    return TabletFilterPanel(
      fields: [
        ListFilterLabel('关键词', child: _searchField()),
        ?widget.filters,
      ],
      actions: [?widget.action],
    );
  }

  Widget _statusBar(RecordPageData<T> data) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: const BoxDecoration(
      color: salesPaper,
      border: Border(top: BorderSide(color: salesLine)),
    ),
    child: Wrap(
      spacing: 12,
      runSpacing: 2,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ?widget.legend,
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${data.count} 条记录'),
            if (_page > 1 || data.hasNext) ...[
              TextButton(
                onPressed: _page > 1 ? () => _load(_page - 1) : null,
                child: const Text('上一页'),
              ),
              Text('第 $_page 页'),
              TextButton(
                onPressed: data.hasNext ? () => _load(_page + 1) : null,
                child: const Text('下一页'),
              ),
            ],
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<RecordPageData<T>>(
    future: _future,
    builder: (context, snapshot) {
      final ready = snapshot.connectionState == ConnectionState.done;
      final data = ready || _refreshingSamePage ? snapshot.data : null;
      final items = data?.items ?? <T>[];
      final rowColor = widget.rowColor;
      final table = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.resultsSliver == null)
            SalesGrid(
              columns: widget.columns,
              rows: items.map(widget.cells).toList(),
              compact: widget.compact,

              rowColors: rowColor == null ? null : items.map(rowColor).toList(),
            ),
          if (!ready) const LinearProgressIndicator(minHeight: 2),
          if (ready && snapshot.hasError)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(requestFailure(snapshot.error!, '加载失败，请检查连接。')),
                  TabletAction('重试', onPressed: () => _load(_page)),
                ],
              ),
            ),
          if (data != null && items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Text(
                  _query.text.trim().isEmpty && _criteria.isEmpty
                      ? widget.empty
                      : '没有匹配记录',
                  style: const TextStyle(color: salesMuted),
                ),
              ),
            ),
          if (items.isNotEmpty && widget.footer != null) widget.footer!(items),
        ],
      );
      final toolbar = Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _toolbar(),
      );
      final status = data == null ? const SizedBox.shrink() : _statusBar(data);
      final heading = widget.inlineCount
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
      return Semantics(
        label: widget.inlineCount ? widget.title : null,
        child: ColoredBox(
          color: salesPaper,
          child: LayoutBuilder(
            builder: (context, bounds) {
              final limited =
                  bounds.maxHeight < 260 ||
                  bounds.maxWidth < 450 ||
                  MediaQuery.textScalerOf(context).scale(12) > 18;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Keep the active field mounted while the keyboard resizes the table.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: bounds.maxHeight * 0.65,
                    ),
                    child: SingleChildScrollView(
                      primary: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [heading, toolbar],
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: table),
                        if (widget.resultsSliver case final builder?)
                          builder(items),
                        if (limited) SliverToBoxAdapter(child: status),
                      ],
                    ),
                  ),
                  if (!limited) status,
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

Future<bool?> confirmClearDocument(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('返回前处理单据内容'),
    content: const Text('这张单据已有商品明细。下次打开时可以继续录入。'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('继续编辑'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('清空并返回'),
      ),
      TabletAction(
        '保留并返回',
        primary: true,
        onPressed: () => Navigator.pop(context, false),
      ),
    ],
  ),
);

class WorkspaceDetails extends StatefulWidget {
  const WorkspaceDetails({
    super.key,
    required this.section,
    required this.child,
  });
  final Object section;
  final Widget child;

  @override
  State<WorkspaceDetails> createState() => _WorkspaceDetailsState();
}

class _WorkspaceDetailsState extends State<WorkspaceDetails> {
  LocalHistoryEntry? _history;
  Widget? _detail;

  Future<void> open(String title, Widget child, bool scrollBody) {
    _history?.remove();
    final closed = Completer<void>();
    final entry = LocalHistoryEntry(
      onRemove: () {
        if (mounted && _history != null) {
          setState(() {
            _history = null;
            _detail = null;
          });
        }
        closed.complete();
      },
    );
    final route = ModalRoute.of(context);
    if (route == null) return Future.value();
    route.addLocalHistoryEntry(entry);
    setState(() {
      _history = entry;
      _detail = _recordDetailBody(title, child, scrollBody, entry.remove);
    });
    return closed.future;
  }

  void _reset() {
    final history = _history;
    _history = null;
    _detail = null;
    history?.remove();
  }

  @override
  void didUpdateWidget(covariant WorkspaceDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) _reset();
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(offstage: _detail != null, child: widget.child),
      ?_detail,
    ],
  );
}

Widget _recordDetailBody(
  String title,
  Widget child,
  bool scrollBody,
  VoidCallback close,
) => Material(
  color: salesCanvas,
  child: Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: salesPaper,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: '关闭',
              onPressed: close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: salesLine),
      Expanded(
        child: scrollBody
            ? ListView(padding: const EdgeInsets.all(10), children: [child])
            : child,
      ),
    ],
  ),
);

Future<void> showRecordDetail(
  BuildContext context, {
  required String title,
  required Widget child,
  double maxWidth = 700,
  bool scrollBody = true,
  bool expandInWorkspace = false,
}) {
  final workspace = expandInWorkspace
      ? context.findAncestorStateOfType<_WorkspaceDetailsState>()
      : null;
  if (workspace != null) return workspace.open(title, child, scrollBody);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭详情',
    pageBuilder: (context, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _recordDetailBody(
            title,
            child,
            scrollBody,
            () => Navigator.pop(context),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(1, 0), end: Offset.zero),
      ),
      child: child,
    ),
  );
}

Widget facts(
  List<(String, String)> fields, {
  int maxColumns = 1,
  (String, String)? fullWidthField,
}) => SalesPanel(
  padding: const EdgeInsets.all(12),
  child: LayoutBuilder(
    builder: (context, constraints) {
      const gap = 16.0;
      const minFieldWidth = 176.0;
      final width = constraints.maxWidth;
      final columns = ((width + gap) / (minFieldWidth + gap)).floor().clamp(
        1,
        maxColumns,
      );
      final fieldWidth = (width - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        children: [
          for (final field in fields) _factField(field, fieldWidth),
          if (fullWidthField case final field?) _factField(field, width),
        ],
      );
    },
  ),
);

Widget _factField((String, String) field, double width) {
  final (label, value) = field;
  return SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: math.min(108, width * .43),
            child: Text(label, style: const TextStyle(color: salesMuted)),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    ),
  );
}
