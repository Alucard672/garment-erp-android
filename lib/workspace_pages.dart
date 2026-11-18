import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'app_update_panel.dart';
import 'customer_receipts.dart';
import 'document_entry.dart';
import 'generated/api_schema.dart';
import 'goods_catalog.dart';
import 'order_fulfillment.dart';
import 'password_settings.dart';
import 'record_pages.dart';
import 'sales_shell.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';
import 'style_details.dart';
import 'stock_list.dart';

class WorkspacePages extends StatefulWidget {
  const WorkspacePages({
    super.key,
    required this.section,
    required this.api,
    required this.employee,
    required this.onNewOrder,
    this.scannedCode = '',
    this.beforeAppUpdate,
    this.onChangePassword,
    this.checkForUpdateOnOpen = false,
  });

  final SalesSection section;
  final ErpApi api;
  final LoginResult employee;
  final VoidCallback onNewOrder;
  final String scannedCode;
  final Future<void> Function()? beforeAppUpdate;
  final Future<void> Function(String, String)? onChangePassword;
  final bool checkForUpdateOnOpen;

  @override
  State<WorkspacePages> createState() => _WorkspacePagesState();
}

class _WorkspacePagesState extends State<WorkspacePages> {
  int _revision = 0;
  int _productTab = 0;
  int _returnTab = 0;
  bool _stockOpened = false;
  bool _catalogPictures = false;

  SalesSection get section => widget.section;
  ErpApi get api => widget.api;
  LoginResult get employee => widget.employee;
  VoidCallback get onNewOrder => widget.onNewOrder;

  String get _token => employee.token;

  Widget _entry(DocumentKind kind) => TabletAction(
    kind.title,
    primary: true,
    onPressed: () async {
      final created = await openDocumentEntry(
        context,
        kind: kind,
        api: api,
        employee: employee,
      );
      if (mounted && created == true) {
        setState(() => _revision++);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存。')));
      }
    },
    icon: Icons.add,
  );

  Widget _records<T>({
    required String title,
    required String path,
    required String hint,
    required String empty,
    required T Function(Map<String, dynamic>) decode,
    required List<RecordColumn> columns,
    required List<Widget> Function(T) cells,
    Widget? action,
    bool compact = false,
    Color Function(T)? rowColor,
    Widget? legend,
    bool includeOrderFilters = false,
  }) => _workspace(
    child: RecordList<T>(
      key: ValueKey(_revision),
      title: title,
      inlineCount: true,
      compact: compact,
      rowColor: rowColor,
      legend: legend,
      action: action,
      hint: hint,
      empty: empty,
      columns: columns,
      cells: cells,
      salesSource: includeOrderFilters
          ? SalesListSource(
              api: api,
              token: _token,
              path: path,
              decode: decode,
              dateLabel: '订货日期',
              showOrderStatus: true,
            )
          : null,
      load: includeOrderFilters
          ? null
          : (query, page) => api.list(
              token: _token,
              path: path,
              decode: decode,
              search: query,
              page: page,
            ),
    ),
  );

  Widget _workspace({required Widget child}) =>
      Padding(padding: pageInsets, child: child);

  Widget _details(
    BuildContext context,
    String title,
    List<(String, String)> values, {
    bool expandInWorkspace = false,
  }) => SalesRecordAction(
    label: '详情',
    onPressed: () => showRecordDetail(
      context,
      title: title,
      child: facts(values),
      expandInWorkspace: expandInWorkspace,
    ),
  );

  @override
  Widget build(BuildContext context) => switch (section) {
    SalesSection.products => _products(),
    SalesSection.customers => _workspace(child: _customerList(context)),
    SalesSection.customerReceivables => _customerReceivables(),
    SalesSection.suppliers => _workspace(child: _supplierList(context)),
    SalesSection.supplierPayables => _workspace(
      child: _accountNotice('厂家应付与付款记录尚未接入。'),
    ),
    SalesSection.orders => _orders(context),
    SalesSection.purchase => _purchases(context),
    SalesSection.returns => _returns(context),
    SalesSection.inventory => _inventory(),
    SalesSection.production => _production(context),
    SalesSection.staff => _staff(context),
    SalesSection.home => _workspace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('经营情况', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(
            child: _Analytics(api: api, token: _token),
          ),
        ],
      ),
    ),
    SalesSection.styleLookup => _workspace(child: _styleLookup()),
    SalesSection.orderLookup => _workspace(child: _orderLookup()),
    SalesSection.settings => _workspace(child: _settings(context)),
    SalesSection.fulfillment => throw StateError(
      'Use the fulfillment route for sales orders',
    ),
  };

  Widget _products() => _workspace(
    child: Column(
      children: [
        SalesTabs(
          labels: const ['货品查询', '库存管理'],
          action: _productTab == 0
              ? SegmentedButton<bool>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.list),
                      label: Text('列表'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.grid_view),
                      label: Text('图片'),
                    ),
                  ],
                  selected: {_catalogPictures},
                  onSelectionChanged: (value) =>
                      setState(() => _catalogPictures = value.single),
                )
              : null,
          selected: _productTab,
          onSelect: (tab) {
            if (_productTab == tab) return;
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() {
              _productTab = tab;
              if (tab == 1) _stockOpened = true;
            });
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: IndexedStack(
            index: _productTab,
            sizing: StackFit.expand,
            children: [
              GoodsCatalog(
                api: api,
                token: _token,
                active: _productTab == 0,
                pictures: _catalogPictures,
              ),
              if (_stockOpened)
                StockList(api: api, token: _token, active: _productTab == 1),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _styleLookup() => RecordList<Style>(
    title: '款号查询结果',
    inlineCount: true,
    initialQuery: widget.scannedCode,
    hint: '扫码枪输入或键入款号',
    empty: '暂无款号。',
    load: (query, page) => api.list(
      token: _token,
      path: ApiPath.stylesList,
      decode: Style.fromJson,
      search: query,
      page: page,
    ),
    columns: const [
      (title: '款号', width: 126),
      (title: '商品', width: 172),
      (title: '操作', width: 110),
    ],
    cells: (item) => [
      Text(item.code),
      Text(item.name),
      SalesRecordAction(
        label: '详情',
        onPressed: () => showStyleDetails(
          context,
          api,
          _token,
          id: item.id,
          code: item.code,
          hasImage: item.hasStyleImage,
        ),
      ),
    ],
  );

  Widget _orderLookup() => RecordList<OrderRead>(
    title: '订货单查询结果',
    inlineCount: true,
    initialQuery: widget.scannedCode,
    hint: '扫码枪输入或键入订货单号',
    empty: '暂无已确认订货单。',
    load: (query, page) => api.list(
      token: _token,
      path: ApiPath.ordersList,
      decode: OrderRead.fromJson,
      search: query,
      page: page,
    ),
    columns: const [
      (title: '订货单号', width: 163),
      (title: '客户', width: 156),
      (title: '待发', width: 90),
      (title: '操作', width: 105),
    ],
    cells: (item) => [
      Text(item.code),
      Text(item.customerName),
      Text('${item.pending}'),
      SalesRecordAction(
        label: '详情',
        onPressed: () =>
            showOrderDetails(context, item, api: api, token: _token),
      ),
    ],
  );

  Widget _customerReceivables() => _records<CustomerReceivable>(
    title: '客户应收',
    path: ApiPath.customersReceivablesList,
    hint: '客户名称 / 客户编号',
    empty: '暂无客户欠款或退货结余。',
    decode: CustomerReceivable.fromJson,
    columns: const [
      (title: '客户编号', width: 150),
      (title: '客户名称', width: 245),
      (title: '应收 / 结余（元）', width: 168),
      (title: '操作', width: 115),
    ],
    cells: (item) => [
      Text(item.code),
      Text(item.name),
      Text(
        item.receivableAmount.startsWith('-')
            ? '客户结余 ${item.receivableAmount.substring(1)}'
            : item.receivableAmount,
      ),
      SalesRecordAction(
        label: item.receivableAmount.startsWith('-') ? '查看' : '核销',
        onPressed: () async {
          final created = await openCustomerReceipt(
            context,
            api,
            employee,
            item.id,
          );
          if (mounted && created == true) setState(() => _revision++);
        },
      ),
    ],
  );

  Widget _accountNotice(String message) => Align(
    alignment: Alignment.topCenter,
    child: SizedBox(
      width: double.infinity,
      child: SalesPanel(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: const TextStyle(color: salesMuted)),
      ),
    ),
  );

  Widget _customerList(BuildContext context) => RecordList<Customer>(
    key: ValueKey(_revision),
    title: '客户档案',
    inlineCount: true,
    action: _entry(DocumentKind.customer),
    hint: '客户名称 / 客户编号',
    empty: '暂无客户。可点击「新增客户」。',
    load: (query, page) => api.list(
      token: _token,
      path: ApiPath.customersList,
      decode: Customer.fromJson,
      search: query,
      page: page,
    ),
    columns: const [
      (title: '客户编号', width: 180),
      (title: '客户名称', width: 236),
      (title: '操作', width: 110),
    ],
    cells: (item) => [
      Text(item.code),
      Text(item.name),
      _details(context, '客户详情', [('客户编号', item.code), ('客户名称', item.name)]),
    ],
  );

  Widget _supplierList(BuildContext context) => RecordList<SupplierRead>(
    title: '厂家档案',
    inlineCount: true,
    hint: '厂家名称 / 厂家编号',
    empty: '暂无厂家。可在管理后台录入供应商档案。',
    load: (query, page) => api.list(
      token: _token,
      path: ApiPath.suppliersList,
      decode: SupplierRead.fromJson,
      search: query,
      page: page,
    ),
    columns: const [
      (title: '厂家编号', width: 180),
      (title: '厂家名称', width: 236),
      (title: '操作', width: 110),
    ],
    cells: (item) => [
      Text(item.code),
      Text(item.name),
      _details(context, '厂家详情', [('厂家编号', item.code), ('厂家名称', item.name)]),
    ],
  );

  Widget _orders(BuildContext context) => _records<OrderRead>(
    title: '已确认订货单',
    path: ApiPath.ordersList,
    hint: '订单号 / 客户 / 款号',
    empty: '暂无已确认订单。可点击「新增客户订货」。',
    decode: OrderRead.fromJson,
    includeOrderFilters: true,
    compact: true,
    rowColor: (item) => item.fulfillmentStatus.surface,
    legend: const OrderStatusLegend(),
    action: TabletAction(
      '新增客户订货',
      primary: true,
      icon: Icons.add,
      onPressed: onNewOrder,
    ),
    columns: const [
      (title: '订单号', width: 136),
      (title: '客户', width: 91),
      (title: '交期', width: 88),
      (title: '订货数', width: 52),
      (title: '已发数', width: 52),
      (title: '待发数', width: 52),
      (title: '订货金额', width: 88),
      (title: '店员', width: 63),
      (title: '付款方式', width: 68),
      (title: '状态', width: 83),
      (title: '操作', width: 63),
    ],
    cells: (item) => [
      SalesRecordText(item.code, emphasized: true),
      SalesRecordText(item.customerName),
      SalesRecordText(item.dueDate),
      SalesRecordText('${item.ordered}'),
      SalesRecordText('${item.sent}'),
      SalesRecordText('${item.pending}'),
      SalesRecordText.currency(item.documentAmount),
      SalesRecordText(item.clerkName),
      SalesRecordText(item.paymentMethod?.label),
      SalesStatusLabel(item.fulfillmentStatus),
      SalesRecordAction(
        onPressed: () =>
            showOrderDetails(context, item, api: api, token: _token),
        label: '详情',
      ),
    ],
  );

  Widget _purchases(BuildContext context) => _records<PurchaseOrderRead>(
    title: '采购单列表',
    action: _entry(DocumentKind.purchase),
    path: ApiPath.purchasesList,
    hint: '采购单号 / 供应商 / 面辅料',
    empty: '暂无采购单。可点击「新增采购单」。',
    decode: PurchaseOrderRead.fromJson,
    columns: const [
      (title: '采购单号', width: 142),
      (title: '供应商', width: 170),
      (title: '采购日期', width: 130),
      (title: '预计到货', width: 130),
      (title: '采购明细', width: 100),
      (title: '操作', width: 100),
    ],
    cells: (item) => [
      Text(item.code),
      Text(item.supplierName),
      Text(item.orderedOn),
      Text(item.dueOn),
      Text('${item.lines.length} 项'),
      SalesRecordAction(
        label: '详情',
        onPressed: () => showRecordDetail(
          context,
          title: '采购单 ${item.code}',
          expandInWorkspace: true,
          child: Column(
            children: [
              facts([
                ('供应商', item.supplierName),
                ('预计到货', item.dueOn),
                ('整单备注', item.notes ?? ''),
              ]),
              const SizedBox(height: 8),
              SalesPanel(
                child: SalesGrid(
                  columns: const [
                    (title: '面辅料', width: 160),
                    (title: '数量', width: 100),
                    (title: '单价', width: 100),
                    (title: '明细备注', width: 145),
                  ],
                  rows: [
                    for (final line in item.lines)
                      [
                        Text(line.item),
                        Text('${line.quantity} ${line.unit}'),
                        Text('¥${line.unitPrice}'),
                        Text(line.notes ?? ''),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _returns(BuildContext context) => Column(
    children: [
      SalesTabs(
        labels: const ['销售退货单', '历史退货申请'],
        selected: _returnTab,
        onSelect: (value) => setState(() => _returnTab = value),
      ),
      Expanded(
        child: _returnTab == 1
            ? _legacyReturns(context)
            : _records<SalesReturnRead>(
                title: '销售退货单',
                action: _entry(DocumentKind.returns),
                path: ApiPath.salesReturnsList,
                hint: '退货单号 / 客户 / 款号',
                empty: '暂无销售退货单。',
                decode: SalesReturnRead.fromJson,
                columns: const [
                  (title: '退货单号', width: 160),
                  (title: '客户', width: 122),
                  (title: '入库仓库', width: 115),
                  (title: '退货金额', width: 105),
                  (title: '日期', width: 105),
                  (title: '操作', width: 90),
                ],
                cells: (item) => [
                  Text(item.code),
                  Text(item.customerName),
                  Text(item.warehouseName),
                  Text('¥${item.amount}'),
                  Text(displayDate(item.postedAt)),
                  _details(context, item.code, [
                    ('客户', item.customerName),
                    ('入库仓库', item.warehouseName),
                    ('退货金额', '¥${item.amount}'),
                    ('经手人', item.postedByName),
                    ('备注', item.notes ?? ''),
                    for (final line in item.lines)
                      (
                        '${line.styleCode ?? ''} ${line.styleName} ${line.color ?? ''} ${line.size ?? ''}'
                            .trim(),
                        '${line.quantity} 件 × ¥${line.unitPrice} ${line.notes ?? ''}',
                      ),
                  ], expandInWorkspace: true),
                ],
              ),
      ),
    ],
  );

  Widget _legacyReturns(BuildContext context) => _records<ReturnRequestRead>(
    title: '退货申请',
    path: ApiPath.returnsList,
    hint: '退货编号 / 发货单号 / 客户',
    empty: '暂无历史退货申请。',
    decode: ReturnRequestRead.fromJson,
    columns: const [
      (title: '退货编号', width: 146),
      (title: '原发货单', width: 160),
      (title: '客户', width: 145),
      (title: '款号', width: 105),
      (title: '申请数量', width: 92),
      (title: '申请日期', width: 104),
      (title: '操作', width: 101),
    ],
    cells: (item) => [
      Text(item.code),
      Text(item.shipmentCode),
      Text(item.customer),
      Text(
        item.specialName?.isNotEmpty == true
            ? item.specialName!
            : item.styleCode,
      ),
      Text('${item.quantity}'),
      Text(displayDate(item.createdAt)),
      _details(context, '退货申请 ${item.code}', [
        ('原发货单', item.shipmentCode),
        ('客户', item.customer),
        if (item.specialName case final name? when name.isNotEmpty)
          ('特殊货品', name)
        else
          ('款号', item.styleCode),
        ('申请数量', '${item.quantity} 件'),
        ('退货原因', item.reason),
        ('整单备注', item.notes ?? ''),
        ('明细备注', item.lineNotes ?? ''),
      ], expandInWorkspace: true),
    ],
  );

  Widget _inventory() => _workspace(
    child: _Inventory(
      key: ValueKey(_revision),
      api: api,
      token: _token,
      initialTab: _revision == 0 ? 0 : 2,
      action: _entry(DocumentKind.receipt),
    ),
  );

  Widget _production(BuildContext context) => _records<ProgressNoteRead>(
    title: '订单跟单记录',
    action: _entry(DocumentKind.progress),
    path: ApiPath.productionNotesList,
    hint: '订单号 / 款号 / 跟单内容',
    empty: '暂无跟单记录。可按已确认订货明细新增。',
    decode: ProgressNoteRead.fromJson,
    columns: const [
      (title: '原订货单', width: 159),
      (title: '款号 / 色码', width: 155),
      (title: '进度记录', width: 172),
      (title: '记录人', width: 94),
      (title: '日期', width: 102),
      (title: '操作', width: 102),
    ],
    cells: (item) => [
      Text(item.orderCode),
      Text('${item.styleCode} · ${item.color} / ${item.size}'),
      Text(item.note, maxLines: 2, overflow: TextOverflow.ellipsis),
      Text(item.author),
      Text(displayDate(item.recordedAt)),
      _details(context, '跟单详情', [
        ('订货单', item.orderCode),
        ('款号 / 色码', '${item.styleCode} · ${item.color} / ${item.size}'),
        ('记录人', item.author),
        ('记录', item.note),
        ('整单备注', item.notes ?? ''),
        ('明细备注', item.lineNotes ?? ''),
      ]),
    ],
  );

  Widget _staff(BuildContext context) => _records<StaffRead>(
    title: '员工档案',
    path: ApiPath.staffList,
    hint: '员工账号 / 姓名',
    empty: '暂无员工账号。',
    decode: StaffRead.fromJson,
    columns: const [
      (title: '员工账号', width: 160),
      (title: '姓名', width: 146),
      (title: '状态', width: 100),
      (title: '操作', width: 103),
    ],
    cells: (item) => [
      Text(item.username),
      Text(item.name.isEmpty ? '—' : item.name),
      Text(item.isActive == true ? '启用' : '停用'),
      _details(context, '员工详情', [
        ('员工账号', item.username),
        ('姓名', item.name),
        ('状态', item.isActive == true ? '启用' : '停用'),
      ]),
    ],
  );

  Widget _settings(BuildContext context) => ListView(
    children: [
      if (widget.onChangePassword case final change?) ...[
        PasswordSettingsPanel(onChange: change),
        const SizedBox(height: 8),
      ],
      AppUpdatePanel(
        beforeInstall: widget.beforeAppUpdate,
        checkOnOpen: widget.checkForUpdateOnOpen,
      ),
      const SizedBox(height: 9),
      facts([
        ('登录账号', employee.username),
        ('会话到期', employee.expiresAt.replaceFirst('T', ' ')),
        ('服务器地址', api.baseUrl),
      ]),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TabletAction(
          '复制服务器地址',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: api.baseUrl));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已复制服务器地址')));
            }
          },
          icon: Icons.copy,
        ),
      ),
    ],
  );
}

Future<void> showOrderDetails(
  BuildContext context,
  OrderRead order, {
  ErpApi? api,
  String? token,
}) {
  final styles = <String, List<OrderLineRead>>{};
  for (final line in order.lines) {
    if (line.specialName?.isNotEmpty != true) {
      styles.putIfAbsent(line.styleCode, () => []).add(line);
    }
  }
  final special = order.lines.where(
    (line) => line.specialName?.isNotEmpty == true,
  );
  return showRecordDetail(
    context,
    title: '订货单 ${order.code}',
    expandInWorkspace: true,
    child: Column(
      children: [
        facts(
          [
            ('客户', order.customerName),
            if (order.clerkName case final clerk? when clerk.isNotEmpty)
              ('店员', clerk),
            ('交货日期', order.dueDate),
            ('付款方式', order.paymentMethod?.label ?? '未指定'),
            ('状态', order.fulfillmentStatus.label),
            ('订货 / 已发', '${order.ordered} / ${order.sent} 件'),
          ],
          maxColumns: 3,
          fullWidthField: ('整单备注', order.notes ?? ''),
        ),
        for (final lines in styles.values) ...[
          const SizedBox(height: 8),
          _OrderSizeTable(lines: lines, api: api, token: token),
        ],
        if (special.isNotEmpty) ...[
          const SizedBox(height: 8),
          SalesPanel(
            child: SalesGrid(
              compact: true,
              columns: const [
                (title: '特殊货品', width: 172),
                (title: '销售价', width: 90),
                (title: '订货', width: 60),
                (title: '待发', width: 60),
                (title: '明细备注', width: 150),
              ],
              rows: [
                for (final line in special)
                  [
                    Text(line.specialName!),
                    Text('¥${line.unitPrice}'),
                    Text('${line.quantity}'),
                    Text('${line.quantity - line.sent}'),
                    Text(line.notes ?? ''),
                  ],
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _OrderSizeTable extends StatelessWidget {
  const _OrderSizeTable({required this.lines, this.api, this.token});

  final List<OrderLineRead> lines;
  final ErpApi? api;
  final String? token;

  @override
  Widget build(BuildContext context) {
    final sizes = lines.map((line) => line.size).toSet();
    final colors = <String, Map<String, OrderLineRead>>{};
    for (final line in lines) {
      colors.putIfAbsent(line.color, () => {})[line.size] = line;
    }
    final style = lines.first;
    final api = this.api;
    final token = this.token;
    final styleId = style.styleId;
    return SalesPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                if (api != null && token != null && styleId != null) ...[
                  StylePhoto(
                    api: api,
                    token: token,
                    id: styleId,
                    label: '${style.styleCode} 款式图',
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    '${style.styleCode}  ${style.styleName}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          SalesGrid(
            columns: [
              (title: '颜色 / 尺码', width: 100),
              for (final size in sizes) (title: size, width: 140),
            ],
            rows: [
              for (final row in colors.entries)
                [
                  Text(row.key),
                  for (final size in sizes)
                    if (row.value[size] case final line?)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '订货 ${line.quantity} · 待发 ${line.quantity - line.sent}',
                          ),
                          Text(
                            '¥${line.unitPrice}',
                            style: const TextStyle(color: salesMuted),
                          ),
                          if (line.notes case final notes?
                              when notes.isNotEmpty)
                            Text(
                              notes,
                              style: const TextStyle(color: salesMuted),
                            ),
                        ],
                      )
                    else
                      const Text('—', style: TextStyle(color: salesMuted)),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Analytics extends StatefulWidget {
  const _Analytics({required this.api, required this.token});
  final ErpApi api;
  final String token;

  @override
  State<_Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<_Analytics> {
  late Future<SalesSummary> _data;

  @override
  void initState() {
    super.initState();
    _data = widget.api.summary(widget.token);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SalesSummary>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ListView(
          children: [
            Text(requestFailure(snapshot.error!, '暂时无法加载统计。')),
            TabletAction(
              '刷新',
              onPressed: () =>
                  setState(() => _data = widget.api.summary(widget.token)),
            ),
          ],
        );
      }
      final summary = snapshot.data;
      if (summary == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        children: [
          LayoutBuilder(
            builder: (context, bounds) {
              final cols = ((bounds.maxWidth + 8) / 168).floor().clamp(1, 4);
              final width = (bounds.maxWidth - (cols - 1) * 8) / cols;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, count) in [
                    ('确认订货单', summary.orderCount),
                    ('已过账发货单', summary.shipmentCount),
                    ('订货件数', summary.ordered),
                    ('已发件数', summary.sent),
                  ])
                    SizedBox(
                      width: width,
                      child: SalesPanel(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(color: salesMuted),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$count',
                              style: const TextStyle(
                                color: salesPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          SalesPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '订货交付进度',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (summary.ordered == 0)
                  const Text(
                    '暂无已确认订货，录入后显示交付进度。',
                    style: TextStyle(color: salesMuted),
                  )
                else ...[
                  LinearProgressIndicator(
                    value: (summary.sent / summary.ordered).clamp(0.0, 1.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '已发 ${summary.sent} 件　待发 ${summary.ordered - summary.sent} 件',
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _Inventory extends StatefulWidget {
  const _Inventory({
    super.key,
    required this.api,
    required this.token,
    required this.initialTab,
    required this.action,
  });
  final ErpApi api;
  final String token;
  final int initialTab;
  final Widget action;

  @override
  State<_Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<_Inventory> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SalesTabs(
        labels: const ['库存总览', '库存流水', '入库单'],
        action: widget.action,
        selected: _tab,
        onSelect: (tab) => setState(() => _tab = tab),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: switch (_tab) {
          0 => StockList(api: widget.api, token: widget.token),
          1 => _movements(),
          _ => _receiptList(),
        },
      ),
    ],
  );

  Widget _receiptList() => RecordList<ReceiptRead>(
    title: '已过账入库单',
    hint: '入库单号 / 来源单号 / 仓库',
    empty: '暂无入库单。可点击「新增入库单」。',
    load: (query, page) => widget.api.list(
      token: widget.token,
      path: ApiPath.receiptsList,
      decode: ReceiptRead.fromJson,
      search: query,
      page: page,
    ),
    columns: const [
      (title: '入库单号', width: 173),
      (title: '来源单号', width: 132),
      (title: '仓库', width: 126),
      (title: '入库件数', width: 100),
      (title: '入库日期', width: 100),
      (title: '操作', width: 103),
    ],
    cells: (item) => [
      Text(item.code),
      Text(item.sourceRef),
      Text(item.warehouseName),
      Text('${item.lines.fold(0, (sum, line) => sum + line.quantity)}'),
      Text(displayDate(item.receivedAt)),
      SalesRecordAction(
        label: '详情',
        onPressed: () => showRecordDetail(
          context,
          title: '入库单 ${item.code}',
          expandInWorkspace: true,
          child: Column(
            children: [
              facts([
                ('来源单号', item.sourceRef),
                ('仓库', item.warehouseName),
                ('日期', displayDate(item.receivedAt)),
                ('整单备注', item.notes ?? ''),
              ]),
              const SizedBox(height: 8),
              SalesPanel(
                child: SalesGrid(
                  columns: const [
                    (title: '款号', width: 124),
                    (title: '商品', width: 155),
                    (title: '颜色 / 尺码', width: 119),
                    (title: '入库量', width: 86),
                    (title: '明细备注', width: 145),
                  ],
                  rows: [
                    for (final line in item.lines)
                      [
                        Text(line.styleCode),
                        Text(line.styleName),
                        Text('${line.color} / ${line.size}'),
                        Text('${line.quantity}'),
                        Text(line.notes ?? ''),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _movements() => RecordList<StockMovementRead>(
    title: '库存流水',
    hint: '来源单据 / 仓库 / 款号 / 颜色',
    empty: '暂无入库或发货记录。',
    load: (query, page) => widget.api.list(
      token: widget.token,
      path: ApiPath.stockMovementsList,
      decode: StockMovementRead.fromJson,
      search: query,
      page: page,
    ),
    columns: const [
      (title: '来源单据', width: 145),
      (title: '仓库', width: 108),
      (title: '款号 / 色码', width: 160),
      (title: '变动类型', width: 105),
      (title: '数量变动', width: 91),
      (title: '日期', width: 100),
    ],
    cells: (item) => [
      Text(item.sourceRef),
      Text(item.warehouseName),
      Text('${item.styleCode} · ${item.color} / ${item.size}'),
      Text(item.movementType),
      Text(item.quantity > 0 ? '+${item.quantity}' : '${item.quantity}'),
      Text(displayDate(item.recordedAt)),
    ],
  );
}
