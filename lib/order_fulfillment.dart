import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'customer_receipts.dart';
import 'generated/api_schema.dart';
import 'line_note.dart';
import 'record_pages.dart';
import 'list_filter_fields.dart';
import 'sales_amount.dart';
import 'sales_fields.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';
import 'search_picker.dart';
import 'shipment_settlement.dart';
import 'style_details.dart';

extension OrderQuantities on OrderRead {
  int get ordered => lines.fold(0, (sum, line) => sum + line.quantity);
  int get sent => lines.fold(0, (sum, line) => sum + line.sent);
  int get pending => ordered - sent;
  SalesDocumentStatus get fulfillmentStatus => pending == 0
      ? SalesDocumentStatus.fulfilled
      : sent == 0
      ? SalesDocumentStatus.waiting
      : SalesDocumentStatus.partial;
  String? get documentAmount => formatSalesDocumentAmount(
    lines.map((line) => (unitPrice: line.unitPrice, quantity: line.quantity)),
  );
}

class OrderFulfillment extends StatefulWidget {
  const OrderFulfillment({
    super.key,
    required this.api,
    required this.employee,
    required this.onNewCustomerOrder,
    this.onOpenDirectShipment,
    this.initialShipments = false,
  });

  final ErpApi api;
  final LoginResult employee;
  final VoidCallback onNewCustomerOrder;
  final VoidCallback? onOpenDirectShipment;
  final bool initialShipments;

  @override
  State<OrderFulfillment> createState() => OrderFulfillmentState();
}

class OrderFulfillmentState extends State<OrderFulfillment> {
  final _shipmentForm = GlobalKey<_ShipmentDetailState>();

  Future<bool> leaveActiveEntry() async =>
      await _shipmentForm.currentState?.allowLeave() ?? true;
  bool _pendingOnly = false;
  late int _tab = widget.initialShipments ? 1 : 0;
  int _revision = 0;
  OrderRead? _selected;

  String get _token => widget.employee.token;

  void _closeDetail() => setState(() {
    _selected = null;
    _revision++;
  });

  Future<void> _newShipment() async {
    final directShipment = widget.onOpenDirectShipment;
    if (directShipment != null) {
      final direct = await showDialog<bool>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('新增发货'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('按订货单发货'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('现货直接发货'),
            ),
          ],
        ),
      );
      if (!mounted || direct == null) return;
      if (direct) {
        directShipment();
        return;
      }
    }
    final order = await showDialog<OrderRead>(
      context: context,
      builder: (_) => SearchPicker<OrderRead>(
        title: '选择待发订货单',
        hint: '客户 / 订单号 / 款号',
        empty: '暂无待发订货单，请先在客户订单中保存订单。',
        label: (item) => item.code,
        code: (item) => '${item.customerName} · 待发 ${item.pending} 件',
        load: (query, page) async {
          final result = await _loadOrders(query, page, pendingOnly: true);
          return (items: result.items, hasNext: result.hasNext);
        },
      ),
    );
    if (mounted && order != null) setState(() => _selected = order);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected == null) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 3, 4, 5),
              child: Text(
                '单据列表',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            SalesTabs(
              labels: const ['订货单', '销售单'],
              selected: _tab,
              onSelect: (tab) async {
                if (!await leaveActiveEntry() || !mounted) return;
                setState(() {
                  _tab = tab;
                  _selected = null;
                });
              },
              action: TabletAction(
                '开单',
                primary: true,
                icon: Icons.add,
                onPressed: _tab == 0 ? widget.onNewCustomerOrder : _newShipment,
              ),
            ),
          ],
          const SizedBox(height: 3),
          Expanded(
            child: switch ((selected, _tab)) {
              (final order?, _) => _ShipmentDetail(
                key: _shipmentForm,
                api: widget.api,
                employee: widget.employee,
                order: order,
                onBack: _closeDetail,
              ),
              (_, 0) => _orders(),
              _ => _shipments(),
            },
          ),
        ],
      ),
    );
  }

  Future<RecordPageData<OrderRead>> _loadOrders(
    String query,
    int page, {
    required bool pendingOnly,
  }) => widget.api.list(
    token: _token,
    path: ApiPath.ordersList,
    decode: OrderRead.fromJson,
    search: query,
    page: page,
    query: {'pending': '$pendingOnly'},
  );

  Widget _orders() => RecordList<OrderRead>(
    key: ValueKey(_revision),
    title: '订货单列表',
    inlineCount: true,
    hint: '客户 / 订单号 / 款号',
    empty: _pendingOnly ? '暂无待发订单。请先在客户订单中保存订单。' : '暂无已确认订货单。',
    compact: true,
    rowColor: (order) => order.fulfillmentStatus.surface,
    legend: OrderStatusLegend(pendingOnly: _pendingOnly),
    salesSource: SalesListSource(
      api: widget.api,
      token: _token,
      path: ApiPath.ordersList,
      decode: OrderRead.fromJson,
      dateLabel: '订货日期',
      showOrderStatus: true,
      pendingOnly: _pendingOnly,
    ),
    filters: ListFilterSelect<bool>(
      label: '订单范围',
      value: _pendingOnly,
      valueText: _pendingOnly ? '待发订单' : '全部订单',
      options: const {true: '待发订单', false: '全部订单'},
      onSelected: (pending) => setState(() => _pendingOnly = pending),
    ),
    columns: const [
      (title: '订货单号', width: 136),
      (title: '客户', width: 83),
      (title: '交货日期', width: 82),
      (title: '订货数', width: 52),
      (title: '已发数', width: 52),
      (title: '待发数', width: 52),
      (title: '订货金额', width: 80),
      (title: '店员', width: 55),
      (title: '付款方式', width: 64),
      (title: '状态', width: 72),
      (title: '操作', width: 82),
    ],
    cells: (order) => [
      SalesRecordText(order.code, emphasized: true),
      SalesRecordText(order.customerName),
      SalesRecordText(order.dueDate),
      SalesRecordText('${order.ordered}'),
      SalesRecordText('${order.sent}'),
      SalesRecordText('${order.pending}'),
      SalesRecordText.currency(order.documentAmount),
      SalesRecordText(order.clerkName),
      SalesRecordText(order.paymentMethod?.label),
      SalesStatusLabel(order.fulfillmentStatus),
      SalesRecordAction(
        primary: order.pending > 0,
        onPressed: () => setState(() => _selected = order),
        label: order.pending > 0 ? '开单发货' : '查看订单',
      ),
    ],
    footer: (orders) => Container(
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        color: salesTableHeader,
        border: Border(top: BorderSide(color: salesLine)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        '本页 ${orders.length} 单　　订货 ${orders.fold(0, (sum, item) => sum + item.ordered)}'
        '　　已发 ${orders.fold(0, (sum, item) => sum + item.sent)}'
        '　　待发 ${orders.fold(0, (sum, item) => sum + item.pending)}',
        textAlign: TextAlign.end,
        style: const TextStyle(color: salesMuted, fontSize: 12),
      ),
    ),
  );

  Widget _shipments() => RecordList<ShipmentRead>(
    title: '发货单列表',
    inlineCount: true,
    hint: '发货单号 / 订货单号 / 客户',
    empty: '暂无已过账发货单。',
    compact: true,
    rowColor: (_) => SalesDocumentStatus.posted.surface,
    salesSource: SalesListSource(
      api: widget.api,
      token: _token,
      path: ApiPath.shipmentsList,
      decode: ShipmentRead.fromJson,
      dateLabel: '发货日期',
    ),
    columns: const [
      (title: '发货单号', width: 132),
      (title: '发货来源', width: 116),
      (title: '客户', width: 78),
      (title: '仓库', width: 62),
      (title: '实发', width: 46),
      (title: '发货日期', width: 76),
      (title: '发货金额', width: 72),
      (title: '店员', width: 52),
      (title: '付款方式', width: 61),
      (title: '状态', width: 70),
      (title: '操作', width: 59),
    ],
    cells: (shipment) => [
      SalesRecordText(shipment.code, emphasized: true),
      SalesRecordText(shipment.isDirect == true ? '现货直发' : shipment.orderCode),
      SalesRecordText(shipment.customer),
      SalesRecordText(shipment.warehouseName),
      SalesRecordText('${shipment.quantity}'),
      SalesRecordText(displayDate(shipment.postedAt)),
      SalesRecordText.currency(
        formatSalesDocumentAmount(
          shipment.lines.map(
            (line) => (unitPrice: line.unitPrice, quantity: line.quantity),
          ),
        ),
      ),
      SalesRecordText(shipment.clerkName),
      SalesRecordText(shipment.paymentMethod?.label),
      const SalesStatusLabel(SalesDocumentStatus.posted),
      SalesRecordAction(
        onPressed: () => showRecordDetail(
          context,
          title: '发货单 ${shipment.code}',
          expandInWorkspace: true,
          child: Column(
            children: [
              facts([
                if (shipment.isDirect == true) ('发货方式', '现货直发'),
                (
                  shipment.isDirect == true ? '关联单号' : '原订货单',
                  shipment.orderCode,
                ),
                ('客户', shipment.customer),
                ('发货仓库', shipment.warehouseName),
                if (shipment.clerkName case final clerk? when clerk.isNotEmpty)
                  ('店员', clerk),
                if (shipment.paymentMethod case final method?)
                  ('付款方式', method.label),
                if (shipment.grossAmount case final gross?) ('本单应收', '¥$gross'),
                if (shipment.paidAmount case final paid?) ('发货时实收', '¥$paid'),
                if (shipment.outstandingAmount case final outstanding?)
                  ('当前待收', '¥$outstanding'),
                if (shipment.receivableAmount case final amount?)
                  ('发货时欠款', '¥$amount'),
                ('实发件数', '${shipment.quantity}'),
                ('发货日期', displayDate(shipment.postedAt)),
                ('整单备注', shipment.notes ?? ''),
              ], maxColumns: 3),
              const SizedBox(height: 12),
              SalesPanel(
                child: SalesGrid(
                  columns: const [
                    (title: '图片', width: 70),
                    (title: '款号', width: 130),
                    (title: '颜色 / 尺码', width: 125),
                    (title: '成交单价', width: 92),
                    (title: '实发', width: 80),
                    (title: '明细备注', width: 145),
                  ],
                  rows: [
                    for (final line in shipment.lines)
                      [
                        if (line.styleId case final id?)
                          StylePhoto(
                            api: widget.api,
                            token: _token,
                            id: id,
                            label: '${line.styleCode} 款式图',
                          )
                        else
                          const Text('—'),
                        Text(
                          line.specialName?.isNotEmpty == true
                              ? line.specialName!
                              : line.styleCode,
                        ),
                        Text(
                          line.specialName?.isNotEmpty == true
                              ? '特殊货品'
                              : '${line.color} / ${line.size}',
                        ),
                        Text('¥${line.unitPrice}'),
                        Text('${line.quantity}'),
                        Text(line.notes ?? ''),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
        label: '详情',
      ),
    ],
  );
}

class _QuantityStatus extends StatelessWidget {
  const _QuantityStatus(this.quantity);

  final int quantity;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: quantity > 0 ? salesWarningSurface : salesTint,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      '待发 $quantity 件',
      style: TextStyle(
        fontSize: 12,
        color: quantity > 0 ? salesWarning : salesPrimary,
      ),
    ),
  );
}

class _ShipmentDetail extends StatefulWidget {
  const _ShipmentDetail({
    super.key,
    required this.order,
    required this.api,
    required this.employee,
    required this.onBack,
  });
  final OrderRead order;
  final ErpApi api;
  final LoginResult employee;
  final VoidCallback onBack;

  @override
  State<_ShipmentDetail> createState() => _ShipmentDetailState();
}

class _ShipmentDetailState extends State<_ShipmentDetail> {
  final _preferences = SharedPreferencesAsync();
  final _scroll = ScrollController(keepScrollOffset: false);
  late final Map<int, TextEditingController> _qty;
  final _stock = <int, int>{};
  final _lineNotes = <int, String>{};
  String _notes = '';
  WarehouseRead? _warehouse;
  StaffRead? _clerk;
  ShipmentWrite? _pending;
  String _paid = '';
  PaymentMethod? _paymentMethod;
  bool _loading = true;
  bool _posting = false;
  bool _confirmingBack = false;
  String? _error;

  String get _token => widget.employee.token;
  String get _key =>
      'erp.ship.${widget.api.storageServerKey}.${widget.employee.employeeId}.${widget.order.id}';

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.order.paymentMethod;
    _qty = {
      for (final line in widget.order.lines)
        line.id: TextEditingController(text: '0'),
    };
    _restore();
  }

  Future<void> _restore() async {
    try {
      final saved = await _preferences.getString(_key);
      if (saved != null && mounted) {
        final pending = ShipmentWrite.fromJson(
          jsonDecode(saved) as Map<String, dynamic>,
        );
        setState(() {
          _pending = pending;
          _notes = pending.notes ?? '';
          _paid = pending.paidAmount ?? '';
          _paymentMethod = pending.paymentMethod ?? widget.order.paymentMethod;
          for (final line in pending.lines) {
            _lineNotes[line.orderLineId] = line.notes ?? '';
            _qty[line.orderLineId]?.text = '${line.quantity}';
          }
        });
      } else if (mounted) {
        final kept = await _preferences.getString('$_key.entry');
        if (kept == null || !mounted) return;
        final data = jsonDecode(kept) as Map<String, dynamic>;
        final warehouse = WarehouseRead.fromJson(
          data['warehouse'] as Map<String, dynamic>,
        );
        final available = await widget.api.availability(
          _token,
          widget.order.id,
          warehouse.id,
        );
        if (!mounted) return;
        setState(() {
          _warehouse = warehouse;
          _stock.addEntries(
            available.lines.map(
              (line) => MapEntry(line.orderLineId, line.available),
            ),
          );
          _clerk = data['clerk'] == null
              ? null
              : StaffRead.fromJson(data['clerk'] as Map<String, dynamic>);
          _paid = data['paid'] as String;
          _paymentMethod = PaymentMethod.fromCode(
            data['payment_method'] as String?,
          );
          _notes = data['notes'] as String;
          for (final entry
              in (data['quantities'] as Map<String, dynamic>).entries) {
            _qty[int.parse(entry.key)]?.text = entry.value as String;
          }
          for (final entry
              in (data['line_notes'] as Map<String, dynamic>).entries) {
            _lineNotes[int.parse(entry.key)] = entry.value as String;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '无法读取上次发货请求。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final controller in _qty.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _quantity(int id) => int.tryParse(_qty[id]!.text) ?? 0;
  String? get _amount => formatSalesDocumentAmount([
    for (final line in widget.order.lines)
      if (_quantity(line.id) > 0)
        (unitPrice: line.unitPrice, quantity: _quantity(line.id)),
  ]);
  int _max(OrderLineRead line) => line.quantity - line.sent;
  bool get _canEdit => !_loading && !_posting && _pending == null;
  bool get _editable => _canEdit && _warehouse != null;
  String get _clerkLabel {
    if (_clerk case final clerk?) {
      return clerk.name.isEmpty ? clerk.username : clerk.name;
    }
    if (_pending?.clerkId case final id?) return '员工 #$id';
    return '默认当前操作员';
  }

  Future<bool> allowLeave() async {
    if (_posting || _confirmingBack) return false;
    if (_pending != null || !_qty.keys.any((id) => _quantity(id) > 0)) {
      return true;
    }
    _confirmingBack = true;
    try {
      final clear = await confirmClearDocument(context);
      if (!mounted || clear == null) return false;
      if (clear) {
        await _preferences.remove('$_key.entry');
      } else {
        await _preferences.setString(
          '$_key.entry',
          jsonEncode({
            'warehouse': _warehouse!.toJson(),
            'clerk': _clerk?.toJson(),
            'paid': _paid,
            'payment_method': _paymentMethod?.code,
            'notes': _notes,
            'quantities': _qty.map((id, value) => MapEntry('$id', value.text)),
            'line_notes': _lineNotes.map((id, value) => MapEntry('$id', value)),
          }),
        );
      }
      return true;
    } catch (_) {
      if (mounted) setState(() => _error = '无法处理单据录入内容，请重试。');
      return false;
    } finally {
      _confirmingBack = false;
    }
  }

  Future<void> _leave() async {
    if (await allowLeave() && mounted) widget.onBack();
  }

  Future<void> _chooseClerk() async {
    final clerk = await showDialog<StaffRead>(
      context: context,
      builder: (_) => SearchPicker<StaffRead>(
        title: '选择店员',
        hint: '搜索姓名或员工账号',
        label: (item) => item.name.isEmpty ? item.username : item.name,
        code: (item) => item.username,
        load: (query, page) async {
          final result = await widget.api.clerks(_token, query, page);
          return (items: result.results, hasNext: result.next != null);
        },
      ),
    );
    if (mounted && clerk != null) setState(() => _clerk = clerk);
  }

  Future<void> _chooseWarehouse() async {
    final choice = await showDialog<WarehouseRead>(
      context: context,
      builder: (_) => SearchPicker<WarehouseRead>(
        title: '选择出库仓库',
        hint: '搜索仓库名称或编号',
        empty: '暂无启用的仓库，请先在管理后台新增或启用仓库。',
        label: (item) => item.name,
        code: (item) => item.code,
        load: (query, page) async {
          final data = await widget.api.list(
            token: _token,
            path: ApiPath.warehousesList,
            decode: WarehouseRead.fromJson,
            search: query,
            page: page,
          );
          return (items: data.items, hasNext: data.hasNext);
        },
      ),
    );
    if (!mounted || choice == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final available = await widget.api.availability(
        _token,
        widget.order.id,
        choice.id,
      );
      if (!mounted) return;
      setState(() {
        _warehouse = choice;
        _stock
          ..clear()
          ..addEntries(
            available.lines.map(
              (line) => MapEntry(line.orderLineId, line.available),
            ),
          );
        for (final controller in _qty.values) {
          controller.text = '0';
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = requestFailure(error, '库存查询失败，请重试。'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final request =
        _pending ??
        ShipmentWrite(
          warehouseId: _warehouse!.id,
          clerkId: _clerk?.id,
          paidAmount: salesCentsText(
            shipmentPaidCents(_paid, _amount, _paymentMethod)!,
          ),
          paymentMethod: _paymentMethod,
          notes: _notes.trim(),
          requestKey: newRequestKey(),
          lines: [
            for (final line in widget.order.lines)
              if (_quantity(line.id) > 0)
                ShipmentItemWrite(
                  orderLineId: line.id,
                  quantity: _quantity(line.id),
                  notes: _lineNotes[line.id],
                ),
          ],
        );
    if (_pending == null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认本次发货'),
          content: Text(
            '${widget.order.code} 将从 ${_warehouse!.name} 发出 '
            '${request.lines.fold(0, (sum, line) => sum + line.quantity)} 件，实收 ¥${request.paidAmount}。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('返回修改'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认发货'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
    setState(() {
      _posting = true;
      _error = null;
      _pending = request;
    });
    try {
      await _preferences.setString(_key, jsonEncode(request.toJson()));
      final posted = await widget.api.ship(_token, widget.order.id, request);
      await _preferences.remove('$_key.entry');
      await _preferences.remove(_key);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发货单 ${posted.code} 已过账')));
      widget.onBack();
    } catch (error) {
      if (error is ApiFailure && error.status == 400) {
        await _preferences.remove(_key);
        if (mounted) setState(() => _pending = null);
      }
      if (mounted) {
        setState(() => _error = requestFailure(error, '发货结果暂未确认，请重试同一请求。'));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final total = _qty.keys.fold(0, (sum, id) => sum + _quantity(id));
    final invalid = order.lines.any((line) => _quantity(line.id) > _max(line));
    final hasPending = order.lines.any((line) => _max(line) > 0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _leave();
      },
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              children: [
                SalesTitle(
                  order.customerName,
                  subtitle: '${order.code} · 交期 ${order.dueDate}',
                  action: TabletAction(
                    '重选订单',
                    onPressed: _posting ? null : _leave,
                  ),
                ),
                const SizedBox(height: 12),
                if (order.pending > 0 || _pending != null) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final fieldWidth = width >= 700
                          ? (width - 16) / 3
                          : width;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: SalesChoiceField(
                              label: '出库仓库',
                              value: _warehouse?.name ?? '选择出库仓库',
                              selected: _warehouse != null,
                              icon: Icons.warehouse_outlined,
                              onTap: _canEdit && order.pending > 0
                                  ? _chooseWarehouse
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: Row(
                              children: [
                                Expanded(
                                  child: SalesChoiceField(
                                    label: '店员',
                                    value: _clerkLabel,
                                    selected:
                                        _clerk != null ||
                                        _pending?.clerkId != null,
                                    icon: Icons.person_outline,
                                    onTap: _canEdit ? _chooseClerk : null,
                                  ),
                                ),
                                if (_canEdit && _clerk != null)
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _clerk = null),
                                    tooltip: '恢复默认店员',
                                    icon: const Icon(Icons.clear),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: SalesNoteField(
                              key: ValueKey((
                                _pending?.requestKey,
                                _warehouse?.id,
                              )),
                              initialValue: _notes,
                              onChanged: _canEdit
                                  ? (value) => _notes = value
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ShipmentSettlement(
                    key: ValueKey((_warehouse?.id, _pending?.requestKey)),
                    total: _amount,
                    paid: _paid,
                    method: _paymentMethod,
                    onPaidChanged: _canEdit
                        ? (value) => setState(() => _paid = value)
                        : null,
                    onMethodChanged: _canEdit
                        ? (method) => setState(() => _paymentMethod = method)
                        : null,
                    onWriteOff: _canEdit && order.customerId != null
                        ? () => openCustomerReceipt(
                            context,
                            widget.api,
                            widget.employee,
                            order.customerId!,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
                SalesPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
                          spacing: 12,
                          children: [
                            const Text(
                              '订单商品与本次发货',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            _QuantityStatus(order.pending),
                            TabletAction(
                              '按待发数量填满',
                              onPressed: !_editable || !hasPending
                                  ? null
                                  : () => setState(() {
                                      for (final line in order.lines) {
                                        _qty[line.id]!.text = '${_max(line)}';
                                      }
                                    }),
                            ),
                          ],
                        ),
                      ),
                      if (_loading) const LinearProgressIndicator(minHeight: 2),
                      SalesGrid(
                        columns: const [
                          (title: '款式 / 色码', width: 250),
                          (title: '订货', width: 63),
                          (title: '已发', width: 63),
                          (title: '待发', width: 63),
                          (title: '仓库在库', width: 84),
                          (title: '本次发货', width: 190),
                          (title: '明细备注', width: 94),
                        ],
                        rows: [
                          for (final line in order.lines)
                            [
                              Row(
                                children: [
                                  if (line.styleId case final id?)
                                    StylePhoto(
                                      api: widget.api,
                                      token: _token,
                                      id: id,
                                      label: '${line.styleCode} 款式图',
                                    )
                                  else
                                    const Icon(
                                      Icons.checkroom_outlined,
                                      color: salesPrimary,
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.specialName?.isNotEmpty == true
                                              ? '特殊货品'
                                              : line.styleCode,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          line.styleName,
                                          style: const TextStyle(
                                            color: salesMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          line.specialName?.isNotEmpty == true
                                              ? '¥${line.unitPrice}'
                                              : '${line.color} / ${line.size} · ¥${line.unitPrice}',
                                          style: const TextStyle(
                                            color: salesMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text('${line.quantity}'),
                              Text('${line.sent}'),
                              Text('${line.quantity - line.sent}'),
                              Text(
                                _warehouse == null
                                    ? '—'
                                    : line.specialName?.isNotEmpty == true
                                    ? '—'
                                    : '${_stock[line.id] ?? 0}',
                              ),
                              Row(
                                children: [
                                  _step(line, -1, Icons.remove),
                                  const SizedBox(width: 5),
                                  SizedBox(
                                    width: 62,
                                    child: TextField(
                                      controller: _qty[line.id],
                                      enabled: _editable && _max(line) > 0,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(8),
                                      ],
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  _step(line, 1, Icons.add),
                                ],
                              ),
                              LineNoteButton(
                                item:
                                    '${line.styleCode} ${line.color} ${line.size}',
                                notes: _lineNotes[line.id] ?? '',
                                onChanged: _editable && _max(line) > 0
                                    ? (notes) => setState(
                                        () => _lineNotes[line.id] = notes,
                                      )
                                    : null,
                              ),
                            ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: salesSidebar,
              border: Border(top: BorderSide(color: salesLine)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error ??
                        (_pending != null
                            ? '有待确认的发货请求'
                            : _loading
                            ? '正在读取发货资料…'
                            : order.pending > 0 && _warehouse == null
                            ? '请选择出库仓库。'
                            : invalid
                            ? '发货数量超过待发数量。'
                            : '本次实发 $total 件 · 发后待发 ${order.pending - total} 件'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: salesPrimary,
                    ),
                  ),
                ),
                TabletAction(
                  _pending == null ? '确认发货' : '重试确认发货',
                  primary: true,
                  icon: Icons.check,
                  onPressed:
                      _loading ||
                          _posting ||
                          (_pending == null &&
                              (!_editable ||
                                  invalid ||
                                  total == 0 ||
                                  shipmentPaymentError(
                                        _paid,
                                        _amount,
                                        _paymentMethod,
                                      ) !=
                                      null))
                      ? null
                      : _post,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(OrderLineRead line, int delta, IconData icon) {
    final next = _quantity(line.id) + delta;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
      ),
      onPressed: !_editable || next < 0 || next > _max(line)
          ? null
          : () => setState(() => _qty[line.id]!.text = '$next'),
      child: Icon(icon, size: 16),
    );
  }
}
