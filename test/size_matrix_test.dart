import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:garment_erp_android/size_matrix.dart';

void main() {
  testWidgets('only existing color and size combinations accept quantity', (
    tester,
  ) async {
    final changes = <int, int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizeMatrix(
            style: const StyleDetail(
              id: 2,
              code: 'S02',
              name: '测试款',
              skus: [
                Sku(id: 4, color: '雾松绿', size: 'M'),
                Sku(id: 8, color: '米白', size: 'L'),
              ],
            ),
            quantities: const {},
            onChanged: (sku, value) => changes[sku] = value,
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '18');
    await tester.enterText(fields.at(1), '3');
    expect(changes, {4: 18, 8: 3});
  });
}
