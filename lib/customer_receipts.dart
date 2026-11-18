import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'generated/api_schema.dart';
import 'record_pages.dart';
import 'sales_amount.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';

Future<bool?> openCustomerReceipt(
  BuildContext context,
  ErpApi api,
  LoginResult employee,
  int customerId,
) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _CustomerReceipt(api, employee, customerId),
);

class _CustomerReceipt extends StatefulWidget {
  const _CustomerReceipt(this.api, this.employee, this.customerId);
  final ErpApi api;
  final LoginResult employee;
  final int customerId;

  @override
  State<_CustomerReceipt> createState() => _CustomerReceiptState();
}

class _CustomerReceiptState extends State<_CustomerReceipt> {
  final _preferences = SharedPreferencesAsync();
  final _actual = TextEditingController();
  final _notes = TextEditingController();
  final _allocations = <int, String>{};
  late Future<CustomerReceivableDetail> _detail;
  CustomerReceiptWrite? _pending;
  PaymentMethod? _method;
  bool _sending = false;
  String? _error;

  String get _key =>
      'erp.receipt.${widget.api.storageServerKey}.${widget.employee.employeeId}.${widget.customerId}';

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<CustomerReceivableDetail> _load() async {
    final existing = await _preferences.getString(_key);
    if (existing != null && mounted) {
      _pending = CustomerReceiptWrite.fromJson(
        jsonDecode(existing) as Map<String, dynamic>,
      );
      _actual.text = _pending!.amount;
      _notes.text = _pending!.notes ?? '';
      _method = PaymentMethod.fromCode(_pending!.paymentMethod);
    }
    return widget.api.customerReceivables(
      widget.employee.token,
      widget.customerId,
    );
  }

  @override
  void dispose() {
    _actual.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save(CustomerReceivableDetail? data) async {
    var request = _pending;
    if (request == null) {
      final paid = salesCents(_actual.text.trim());
      final amounts = <ReceiptAllocation>[];
      var total = BigInt.zero;
      String? invalid;
      for (final entry in _allocations.entries) {
        final shipment = data!.shipments.firstWhere(
          (item) => item.id == entry.key,
        );
        final amount = salesCents(entry.value.trim());
        if (amount == null ||
            amount <= BigInt.zero ||
            amount > salesCents(shipment.outstandingAmount)!) {
          invalid = '${shipment.code} 的核销金额须大于零，且不超过待收金额。';
          break;
        }
        total += amount;
        amounts.add(
          ReceiptAllocation(
            shipmentId: entry.key,
            amount: salesCentsText(amount),
          ),
        );
      }
      invalid ??= switch ((paid, _method)) {
        (null, _) => '请输入有效的实收金额。',
        (_, null) => '请选择收款方式。',
        _ when paid! <= BigInt.zero => '实收金额须大于零。',
        _ when amounts.isEmpty => '请选择要核销的发货单。',
        _
            when data != null &&
                paid > (salesCents(data.receivableAmount) ?? BigInt.zero) =>
          '收款不能超过扣除退货后的净欠款。',
        _ when paid != total => '发货单核销金额合计须等于实际收款。',
        _ => null,
      };
      if (invalid != null) {
        setState(() => _error = invalid);
        return;
      }
      request = CustomerReceiptWrite(
        requestKey: newRequestKey(),
        amount: salesCentsText(paid!),
        paymentMethod: _method!.code,
        notes: _notes.text.trim(),
        allocations: amounts,
      );
    }

    setState(() {
      _sending = true;
      _error = null;
      _pending = request;
    });
    try {
      await _preferences.setString(_key, jsonEncode(request.toJson()));
      final receipt = await widget.api.recordCustomerReceipt(
        widget.employee.token,
        widget.customerId,
        request,
      );
      await _preferences.remove(_key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('收款单 ${receipt.code} 已核销 ¥${receipt.amount}。')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (error is ApiFailure && [400, 403, 404, 409].contains(error.status)) {
        await _preferences.remove(_key);
        if (mounted) {
          setState(() {
            _pending = null;
            _allocations.clear();
            _detail = _load();
          });
        }
      }
      if (mounted) {
        setState(() => _error = requestFailure(error, '收款结果暂未确认，请重试同一笔核销。'));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: FutureBuilder(
      future: _detail,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final pending = _pending;
        final editing = pending == null && !_sending;
        return AlertDialog(
          title: const Text('核销客户账款'),
          content: SizedBox(
            width: 620,
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data != null &&
                    data.returnAmount != null &&
                    data.returnAmount != '0.00')
                  Text(
                    '累计退货 ¥${data.returnAmount} · ${data.receivableAmount.startsWith('-') ? '客户结余 ¥${data.receivableAmount.substring(1)}' : '净欠款 ¥${data.receivableAmount}'}',
                  ),
                if (pending != null)
                  Text('上次收款 ¥${pending.amount} 结果待确认，请重试原笔核销。'),
                if (pending == null &&
                    snapshot.connectionState == ConnectionState.waiting)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (pending == null && snapshot.hasError)
                  Expanded(
                    child: Center(
                      child: Text(
                        requestFailure(snapshot.error!, '客户欠款加载失败，请重试。'),
                      ),
                    ),
                  )
                else if (pending == null &&
                    ((data?.shipments.isEmpty ?? true) ||
                        (salesCents(data?.receivableAmount) ?? BigInt.zero) ==
                            BigInt.zero))
                  const Expanded(child: Center(child: Text('该客户暂无待核销的发货单。')))
                else ...[
                  if (data != null)
                    Text('${data.name} · 客户欠款 ¥${data.receivableAmount}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          enabled: editing,
                          controller: _actual,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '实收（元）',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<PaymentMethod>(
                          key: ValueKey(pending?.requestKey),
                          initialValue: _method,
                          decoration: const InputDecoration(
                            labelText: '收款方式',
                            isDense: true,
                          ),
                          items: [
                            for (final method in PaymentMethod.values)
                              if (method != PaymentMethod.unpaid)
                                DropdownMenuItem(
                                  value: method,
                                  child: Text(method.label),
                                ),
                          ],
                          onChanged: editing
                              ? (value) => setState(() => _method = value)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (editing && data != null)
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: data.shipments.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: salesLine),
                        itemBuilder: (context, index) {
                          final item = data.shipments[index];
                          final selected = _allocations.containsKey(item.id);
                          return Row(
                            children: [
                              Checkbox(
                                value: selected,
                                onChanged: (checked) => setState(() {
                                  if (checked == true) {
                                    _allocations[item.id] =
                                        item.outstandingAmount;
                                  } else {
                                    _allocations.remove(item.id);
                                  }
                                }),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.code),
                                      Text(
                                        '${displayDate(item.postedAt)} · 待收 ¥${item.outstandingAmount}',
                                        style: const TextStyle(
                                          color: salesMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (selected)
                                SizedBox(
                                  width: 140,
                                  child: TextFormField(
                                    key: ValueKey(item.id),
                                    initialValue: _allocations[item.id],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (value) =>
                                        _allocations[item.id] = value,
                                    decoration: const InputDecoration(
                                      labelText: '核销（元）',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    )
                  else
                    const Spacer(),
                  TextField(
                    enabled: editing,
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: '收款备注',
                      isDense: true,
                    ),
                  ),
                ],
                if (_sending) const LinearProgressIndicator(),
                if (_error case final error?)
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _sending ? null : () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            if (snapshot.hasError && pending == null)
              TabletAction(
                '重新查询',
                onPressed: () => setState(() => _detail = _load()),
              ),
            TabletAction(
              pending == null ? '确认核销' : '重试核销',
              primary: true,
              onPressed:
                  _sending ||
                      (pending == null &&
                          (snapshot.connectionState != ConnectionState.done ||
                              (data?.shipments.isEmpty ?? true) ||
                              (salesCents(data?.receivableAmount) ??
                                      BigInt.zero) ==
                                  BigInt.zero))
                  ? null
                  : () => _save(data),
            ),
          ],
        );
      },
    ),
  );
}
