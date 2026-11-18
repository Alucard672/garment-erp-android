import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'generated/api_schema.dart';
import 'list_filter_fields.dart';
import 'record_pages.dart';
import 'sales_fields.dart';
import 'special_goods.dart';
import 'sales_theme.dart';
import 'search_picker.dart';
import 'tablet_filter_panel.dart';
import 'wheel_date.dart';

enum DocumentKind {
  customer('新增客户', ApiPath.customersCreate),
  purchase('新增采购单', ApiPath.purchasesCreate),
  receipt('新增入库单', ApiPath.receiptsCreate),
  returns('开退货单', ApiPath.salesReturnsCreate),
  progress('新增跟单记录', ApiPath.productionNotesCreate);

  const DocumentKind(this.title, this.path);
  final String title;
  final String path;
}

Future<bool?> openDocumentEntry(
  BuildContext context, {
  required DocumentKind kind,
  required ErpApi api,
  required LoginResult employee,
}) => showGeneralDialog<bool>(
  context: context,
  pageBuilder: (_, _, _) => SafeArea(
    child: Align(
      alignment: Alignment.centerRight,
      child: _DocumentEntry(kind: kind, api: api, employee: employee),
    ),
  ),
  transitionBuilder: (_, animation, _, child) => SlideTransition(
    position: animation.drive(
      Tween(begin: const Offset(1, 0), end: Offset.zero),
    ),
    child: child,
  ),
);

class _PurchaseRow {
  final item = TextEditingController();
  final unit = TextEditingController();
  final quantity = TextEditingController();
  final price = TextEditingController();
  final notes = TextEditingController();

  void dispose() {
    item.dispose();
    unit.dispose();
    quantity.dispose();
    price.dispose();
    notes.dispose();
  }
}

class _ReceiptRow {
  _ReceiptRow(this.style, this.sku);

  final Style style;
  final Sku sku;
  final quantity = TextEditingController();
  final notes = TextEditingController();

  void dispose() {
    quantity.dispose();
    notes.dispose();
  }
}

class _DocumentEntry extends StatefulWidget {
  const _DocumentEntry({
    required this.kind,
    required this.api,
    required this.employee,
  });
  final DocumentKind kind;
  final ErpApi api;
  final LoginResult employee;

  @override
  State<_DocumentEntry> createState() => _DocumentEntryState();
}

class _DocumentEntryState extends State<_DocumentEntry> {
  final _form = GlobalKey<FormState>();
  final _preferences = SharedPreferencesAsync();
  final _fields = <String, TextEditingController>{};
  final _purchases = <_PurchaseRow>[];
  final _receipts = <_ReceiptRow>[];
  SupplierRead? _supplier;
  WarehouseRead? _warehouse;
  Customer? _customer;
  final _specials = <OrderItemWrite>[];
  OrderRead? _order;
  OrderLineRead? _orderLine;
  Map<String, dynamic>? _pending;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String get _token => widget.employee.token;
  String get _key =>
      'erp.create.${widget.api.storageServerKey}.${widget.employee.employeeId}.${widget.kind.name}';

  @override
  void initState() {
    super.initState();
    if (widget.kind == DocumentKind.purchase) {
      _purchases.add(_PurchaseRow());
      _field('ordered_on').text = displayDate(DateTime.now().toIso8601String());
    }
    _restore();
  }

  Future<void> _restore() async {
    try {
      final saved = await _preferences.getString(_key);
      if (saved != null && mounted) {
        setState(() => _pending = jsonDecode(saved) as Map<String, dynamic>);
      }
    } catch (_) {
      if (mounted) setState(() => _error = '无法读取上次的提交请求。');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    for (final row in _purchases) {
      row.dispose();
    }
    for (final row in _receipts) {
      row.dispose();
    }
    super.dispose();
  }

  TextEditingController _field(String name) =>
      _fields.putIfAbsent(name, TextEditingController.new);

  String _value(String name) => _field(name).text.trim();

  Future<T?> _pick<T>(
    String title,
    String path,
    T Function(Map<String, dynamic>) decode,
    String Function(T) label,
    String Function(T) code,
  ) => showDialog<T>(
    context: context,
    builder: (_) => SearchPicker<T>(
      title: title,
      hint: '搜索名称或编号',
      label: label,
      code: code,
      load: (query, page) async {
        final result = await widget.api.list(
          token: _token,
          path: path,
          decode: decode,
          search: query,
          page: page,
        );
        return (items: result.items, hasNext: result.hasNext);
      },
    ),
  );

  Future<void> _chooseSupplier() async {
    final selected = await _pick(
      '选择供应商',
      ApiPath.suppliersList,
      SupplierRead.fromJson,
      (item) => item.name,
      (item) => item.code,
    );
    if (mounted && selected != null) setState(() => _supplier = selected);
  }

  Future<void> _chooseWarehouse() async {
    final selected = await _pick(
      '选择仓库',
      ApiPath.warehousesList,
      WarehouseRead.fromJson,
      (item) => item.name,
      (item) => item.code,
    );
    if (mounted && selected != null) setState(() => _warehouse = selected);
  }

  Future<void> _chooseCustomer() async {
    final selected = await _pick(
      '选择客户',
      ApiPath.customersList,
      Customer.fromJson,
      (item) => item.name,
      (item) => item.code,
    );
    if (mounted && selected != null) setState(() => _customer = selected);
  }

  Future<void> _chooseOrder() async {
    final selected = await _pick(
      '选择原订货单',
      ApiPath.ordersList,
      OrderRead.fromJson,
      (item) => item.customerName,
      (item) => item.code,
    );
    if (mounted && selected != null) {
      setState(() {
        _order = selected;
        _orderLine = null;
      });
    }
  }

  Future<void> _addReceiptLine() async {
    final style = await _pick(
      '选择款号',
      ApiPath.stylesList,
      Style.fromJson,
      (item) => item.name,
      (item) => item.code,
    );
    if (!mounted || style == null) return;
    try {
      final details = await widget.api.style(_token, style.id);
      if (!mounted) return;
      final used = _receipts.map((row) => row.sku.id).toSet();
      final selected = await showDialog<Sku>(
        context: context,
        builder: (pickerContext) => SimpleDialog(
          title: Text('${style.code} · 选择色码'),
          children: [
            if (details.skus.every((sku) => used.contains(sku.id)))
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('没有可新增的色码。'),
              ),
            for (final sku in details.skus)
              if (!used.contains(sku.id))
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(pickerContext, sku),
                  child: Text('${sku.color} / ${sku.size}'),
                ),
          ],
        ),
      );
      if (mounted && selected != null) {
        setState(() => _receipts.add(_ReceiptRow(style, selected)));
      }
    } catch (error) {
      if (mounted) setState(() => _error = requestFailure(error, '加载色码失败。'));
    }
  }

  bool _validateSelection() {
    final message = switch (widget.kind) {
      DocumentKind.purchase when _supplier == null => '请选择供应商。',
      DocumentKind.receipt when _warehouse == null => '请选择入库仓库。',
      DocumentKind.receipt when _receipts.isEmpty => '请新增至少一行入库明细。',
      DocumentKind.returns when _customer == null => '请选择客户。',
      DocumentKind.returns when _warehouse == null => '请选择退货入库仓库。',
      DocumentKind.returns when _receipts.isEmpty && _specials.isEmpty =>
        '请添加退货明细。',
      DocumentKind.progress when _orderLine == null => '请选择原订货明细。',
      _ => null,
    };
    if (message == null) return true;
    setState(() => _error = message);
    return false;
  }

  Map<String, dynamic> _request() {
    final key = newRequestKey();
    return switch (widget.kind) {
      DocumentKind.customer => CustomerWrite(
        requestKey: key,
        code: _value('code'),
        name: _value('name'),
      ).toJson(),
      DocumentKind.purchase => PurchaseWrite(
        requestKey: key,
        supplierId: _supplier!.id,
        orderedOn: _value('ordered_on'),
        dueOn: _value('due_on'),
        notes: _value('notes'),
        lines: [
          for (final row in _purchases)
            PurchaseItemWrite(
              item: row.item.text.trim(),
              unit: row.unit.text.trim(),
              quantity: row.quantity.text.trim(),
              unitPrice: row.price.text.trim(),
              notes: row.notes.text.trim(),
            ),
        ],
      ).toJson(),
      DocumentKind.receipt => ReceiptWrite(
        requestKey: key,
        warehouseId: _warehouse!.id,
        sourceRef: _value('source_ref'),
        notes: _value('notes'),
        lines: [
          for (final row in _receipts)
            ReceiptLineWrite(
              skuId: row.sku.id,
              quantity: int.parse(row.quantity.text.trim()),
              notes: row.notes.text.trim(),
            ),
        ],
      ).toJson(),
      DocumentKind.returns => SalesReturnWrite(
        requestKey: key,
        customerId: _customer!.id,
        warehouseId: _warehouse!.id,
        notes: _value('notes'),
        lines: [
          for (final row in _receipts)
            OrderItemWrite(
              skuId: row.sku.id,
              quantity: int.parse(row.quantity.text.trim()),
              notes: row.notes.text.trim(),
            ),
          ..._specials,
        ],
      ).toJson(),
      DocumentKind.progress => ProgressWrite(
        requestKey: key,
        orderLineId: _orderLine!.id,
        note: _value('note'),
        notes: _value('notes'),
        lineNotes: _value('line_notes'),
      ).toJson(),
    };
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final previous = _pending;
    if (previous == null &&
        (!(_form.currentState?.validate() ?? false) || !_validateSelection())) {
      return;
    }
    final request = previous ?? _request();
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _preferences.setString(_key, jsonEncode(request));
      final legacyReturn =
          widget.kind == DocumentKind.returns &&
          request.containsKey('shipment_line_id');
      await widget.api.createDocument(
        _token,
        legacyReturn ? ApiPath.returnsCreate : widget.kind.path,
        request,
      );
      await _preferences.remove(_key);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      final pending = request;
      if (error is ApiFailure && error.status == 400) {
        try {
          await _preferences.remove(_key);
          if (mounted) setState(() => _pending = null);
        } catch (_) {
          if (mounted) setState(() => _pending = pending);
        }
      } else if (mounted) {
        setState(() => _pending = pending);
      }
      if (mounted) {
        setState(() {
          _error = requestFailure(error, '暂未确认提交结果，请重试同一请求。');
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _text(
    String label,
    TextEditingController controller, {
    bool required = true,
    int? limit,
    TextInputType? keyboard,
    String? Function(String)? check,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListFilterLabel(
      label,
      child: TextFormField(
        controller: controller,
        maxLength: limit,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          counterText: '',
          hintText: '请输入',
          constraints: BoxConstraints(minHeight: 36),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return '请填写$label';
          return check?.call(text);
        },
      ),
    ),
  );

  Widget _select(String label, String? value, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SalesChoiceField(
      compact: true,
      label: label,
      value: value ?? '未选择',
      selected: value != null,
      icon: Icons.search,
      onTap: onTap,
    ),
  );

  Widget _fieldPair(Widget left, Widget right) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 440
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, right],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 8),
              Expanded(child: right),
            ],
          ),
  );

  String? _intQuantity(String value, [int max = 99999999]) {
    final number = int.tryParse(value);
    return number == null || number < 1 || number > max
        ? '请输入 1 至 $max 的整数'
        : null;
  }

  String? _date(String value) {
    final date = DateTime.tryParse(value);
    return date == null || displayDate(date.toIso8601String()) != value
        ? '请输入 YYYY-MM-DD 格式的日期'
        : null;
  }

  Widget _dateInput(String label, String key) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ListFilterLabel(
      label,
      child: WheelDateInput(
        label: label,
        controller: _field(key),
        decoration: const InputDecoration(
          hintText: '年-月-日',
          constraints: BoxConstraints(minHeight: 36),
        ),
        onChanged: (_) {},
        validator: (value) => _date(value ?? ''),
      ),
    ),
  );

  String? _decimal(
    String value, {
    required int scale,
    required int digits,
    bool positive = false,
  }) {
    final pattern = RegExp('^[0-9]{1,$digits}(\\.[0-9]{1,$scale})?\$');
    if (!pattern.hasMatch(value) ||
        (positive && !RegExp('[1-9]').hasMatch(value))) {
      return '请输入有效数值，最多 $scale 位小数';
    }
    return null;
  }

  List<Widget> _inputs() => switch (widget.kind) {
    DocumentKind.customer => [
      _fieldPair(
        _text('客户编号', _field('code'), limit: 48),
        _text('客户名称', _field('name'), limit: 120),
      ),
    ],
    DocumentKind.purchase => [
      _fieldPair(
        _select('选择供应商', _supplier?.name, _chooseSupplier),
        _dateInput('采购日期', 'ordered_on'),
      ),
      _fieldPair(
        _dateInput('预计到货', 'due_on'),
        _text('整单备注', _field('notes'), required: false, limit: 1000),
      ),
      for (final row in _purchases) _purchaseRow(row),
      TabletAction(
        '新增采购明细',
        onPressed: _purchases.length >= 250
            ? null
            : () => setState(() => _purchases.add(_PurchaseRow())),
        icon: Icons.add,
      ),
    ],
    DocumentKind.receipt || DocumentKind.returns => [
      if (widget.kind == DocumentKind.returns)
        _fieldPair(
          _select('选择客户', _customer?.name, _chooseCustomer),
          _select('选择入库仓库', _warehouse?.name, _chooseWarehouse),
        )
      else
        _fieldPair(
          _select('选择入库仓库', _warehouse?.name, _chooseWarehouse),
          _text('来源单号', _field('source_ref'), limit: 80),
        ),
      _text('整单备注', _field('notes'), required: false, limit: 1000),
      for (final row in _receipts)
        SalesPanel(
          key: ObjectKey(row),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${row.style.code} · ${row.sku.color} / ${row.sku.size}${widget.kind == DocumentKind.returns ? '  ·  单价 ${row.sku.wholesalePrice ?? '未定价'}' : ''}',
                    ),
                  ),
                  IconButton(
                    tooltip: '移除该行',
                    onPressed: () {
                      setState(() => _receipts.remove(row));
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => row.dispose(),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              _fieldPair(
                _text(
                  widget.kind == DocumentKind.returns ? '退货件数' : '入库件数',
                  row.quantity,
                  keyboard: TextInputType.number,
                  check: _intQuantity,
                ),
                _text('明细备注', row.notes, required: false, limit: 500),
              ),
            ],
          ),
        ),
      const SizedBox(height: 10),
      TabletAction(
        widget.kind == DocumentKind.returns ? '添加退货款号' : '新增入库明细',
        onPressed: _receipts.length + _specials.length >= 250
            ? null
            : _addReceiptLine,
        icon: Icons.add,
      ),
      if (widget.kind == DocumentKind.returns) ...[
        for (final line in _specials)
          ListTile(
            title: Text(line.specialName!),
            subtitle: Text('单价 ${line.unitPrice} 元 · ${line.quantity} 件'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '移除该行',
              onPressed: () => setState(() => _specials.remove(line)),
            ),
          ),
        TabletAction(
          '特殊货品',
          onPressed: _receipts.length + _specials.length >= 250
              ? null
              : () async {
                  final line = await openSpecialGoods(context);
                  if (mounted && line != null) {
                    setState(() => _specials.add(line));
                  }
                },
        ),
      ],
    ],
    DocumentKind.progress => [
      _select('选择原订货单', _order?.code, _chooseOrder),
      if (_order != null)
        ListFilterLabel(
          '原订货明细',
          child: DropdownButtonFormField<OrderLineRead>(
            key: ValueKey(_order!.id),
            decoration: const InputDecoration(
              constraints: BoxConstraints(minHeight: 36),
            ),
            isExpanded: true,
            items: [
              for (final line in _order!.lines.where(
                (line) => line.skuId != null,
              ))
                DropdownMenuItem(
                  value: line,
                  child: Text(
                    '${line.styleCode} · ${line.color} / ${line.size}',
                  ),
                ),
            ],
            onChanged: (line) => setState(() => _orderLine = line),
          ),
        ),
      const SizedBox(height: 12),
      _text('跟单内容', _field('note'), limit: 240),
      _fieldPair(
        _text('整单备注', _field('notes'), required: false, limit: 1000),
        _text('明细备注', _field('line_notes'), required: false, limit: 500),
      ),
    ],
  };

  Widget _purchaseRow(_PurchaseRow row) => Padding(
    key: ObjectKey(row),
    padding: const EdgeInsets.only(bottom: 10),
    child: SalesPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('采购明细 ${_purchases.indexOf(row) + 1}')),
              if (_purchases.length > 1)
                IconButton(
                  tooltip: '移除该行',
                  onPressed: () {
                    setState(() => _purchases.remove(row));
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => row.dispose(),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          _fieldPair(
            _text('物料名称', row.item, limit: 120),
            _text('单位', row.unit, limit: 20),
          ),
          Row(
            children: [
              Expanded(
                child: _text(
                  '采购数量',
                  row.quantity,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  check: (text) =>
                      _decimal(text, digits: 9, scale: 3, positive: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _text(
                  '采购单价',
                  row.price,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  check: (text) => _decimal(text, digits: 8, scale: 2),
                ),
              ),
            ],
          ),
          _text('明细备注', row.notes, required: false, limit: 500),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: Material(
      color: salesCanvas,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width.clamp(0.0, 680.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              color: salesPaper,
              child: SalesTitle(
                widget.kind.title,
                action: IconButton(
                  tooltip: '关闭',
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            const Divider(height: 1, color: salesLine),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _form,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          if (_pending != null)
                            facts([('提交状态', '上次结果暂未确认，可继续重试同一请求。')])
                          else
                            ..._inputs(),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: salesPaper,
              child: Align(
                alignment: Alignment.centerRight,
                child: TabletAction(
                  _submitting
                      ? '提交中…'
                      : _pending != null
                      ? '重试提交'
                      : widget.kind == DocumentKind.returns
                      ? '确认退货'
                      : widget.kind == DocumentKind.receipt
                      ? '确认入库'
                      : '保存',
                  primary: true,
                  onPressed: _loading || _submitting ? null : _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
