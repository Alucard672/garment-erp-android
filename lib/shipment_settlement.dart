import 'package:flutter/material.dart';

import 'generated/api_schema.dart';
import 'sales_amount.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';

BigInt? shipmentPaidCents(String input, String? total, PaymentMethod? method) =>
    input.trim().isNotEmpty
    ? salesCents(input.trim())
    : method == null || method == PaymentMethod.unpaid
    ? BigInt.zero
    : salesCents(total);

String? shipmentPaymentError(
  String input,
  String? total,
  PaymentMethod? method,
) {
  final cents = shipmentPaidCents(input, total, method);
  if (cents == null) return '请输入有效金额，最多两位小数。';
  if (cents > (salesCents(total) ?? BigInt.zero)) return '实收不能超过本单应收。';
  if (cents > BigInt.zero &&
      (method == null || method == PaymentMethod.unpaid)) {
    return '请为本次实收选择付款方式。';
  }
  return null;
}

class ShipmentSettlement extends StatelessWidget {
  const ShipmentSettlement({
    super.key,
    required this.total,
    required this.paid,
    required this.method,
    this.onPaidChanged,
    this.onMethodChanged,
    this.onWriteOff,
  });

  final String? total;
  final String paid;
  final PaymentMethod? method;
  final ValueChanged<String>? onPaidChanged;
  final ValueChanged<PaymentMethod?>? onMethodChanged;
  final VoidCallback? onWriteOff;

  @override
  Widget build(BuildContext context) {
    final gross = salesCents(total);
    final actual = shipmentPaidCents(paid, total, method);
    final remainder = gross != null && actual != null && actual <= gross
        ? '¥${salesCentsText(gross - actual)}'
        : '—';
    final error = shipmentPaymentError(paid, total, method);
    return SalesPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        spacing: 16,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (onMethodChanged != null)
            SizedBox(
              width: 125,
              child: DropdownButtonFormField<PaymentMethod>(
                initialValue: method,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: '付款方式',
                ),
                items: [
                  for (final item in PaymentMethod.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: onMethodChanged,
              ),
            ),
          Text('本单应收  ${total == null ? '—' : '¥$total'}'),
          SizedBox(
            width: 140,
            child: TextFormField(
              initialValue: paid,
              enabled: onPaidChanged != null,
              onChanged: onPaidChanged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '实收（元）',
                hintText: actual == null ? null : salesCentsText(actual),
                isDense: true,
              ),
            ),
          ),
          Text(
            '本单欠款  $remainder',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (onWriteOff != null) TabletAction('核销客户账款', onPressed: onWriteOff),
          if (error != null && paid.isNotEmpty)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
