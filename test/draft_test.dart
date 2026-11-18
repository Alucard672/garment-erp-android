import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/draft.dart';
import 'package:garment_erp_android/generated/api_schema.dart';

void main() {
  test('restores a legacy style and preserves the pending order price', () {
    final draft = OrderDraft.decode('''{
      "style": {"id": 2, "code": "S02", "name": "款式", "skus": []},
      "unit_price": "45.50",
      "quantities": {"4": 8},
      "line_notes": {"4": "单独装箱"},
      "pending": {
        "customer_id": 1, "due_date": "2026-12-01", "unit_price": "45.50",
        "request_key": "pending", "lines": [{"sku_id": 4, "quantity": 8}]
      }
    }''');

    expect(draft.styles.single.id, 2);
    expect(draft.quantities, {4: 8});
    expect(draft.lineNotes, {4: '单独装箱'});
    final pending = OrderDraft.decode(draft.encode()).pending!;
    expect(pending.requestKey, 'pending');
    expect(pending.unitPrice, '45.50');
    expect(pending.lines.single.quantity, 8);
  });

  test('restores independent quantities and selected customer and SKU', () {
    final draft = OrderDraft(
      customer: const Customer(id: 1, code: 'C01', name: '本地测试客户'),
      paymentMethod: PaymentMethod.card,
      clerk: const StaffRead(id: 3, username: 'staff', name: '经手人'),
      styles: const [
        StyleDetail(
          id: 2,
          code: 'S02',
          name: '本地测试款',
          skus: [
            Sku(id: 4, color: '雾松绿', size: 'M'),
            Sku(id: 8, color: '米白', size: 'M'),
          ],
        ),
        StyleDetail(
          id: 3,
          code: 'S03',
          name: '本地第二款',
          skus: [Sku(id: 9, color: '米白', size: 'M')],
        ),
      ],
      quantities: {4: 8, 8: 2, 9: 6},
      notes: '分批发货',
      lineNotes: {8: '单独装箱'},
    );

    final restored = OrderDraft.decode(draft.encode());
    expect(restored.customer?.code, 'C01');
    expect(restored.paymentMethod, PaymentMethod.card);
    expect(restored.clerk?.username, 'staff');
    expect(restored.styles.map((style) => style.id), [2, 3]);
    expect(restored.styles.first.skus.length, 2);
    expect(restored.quantities, {4: 8, 8: 2, 9: 6});
    expect(restored.notes, '分批发货');
    expect(restored.lineNotes, {8: '单独装箱'});
    expect(restored.total, 16);
    expect(OrderDraft.decode('{"quantities":{}}').paymentMethod, isNull);
  });
}
