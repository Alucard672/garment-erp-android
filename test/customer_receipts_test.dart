import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/api.dart';
import 'package:garment_erp_android/customer_receipts.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('按发货单部分核销并重试原收款请求', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 750));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    const employee = LoginResult(
      token: 'test',
      employeeId: 1,
      username: 'admin',
      expiresAt: '',
    );
    final requests = <Map<String, dynamic>>[];
    final api = ErpApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/customers/42/receivables/');
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 42,
              'code': 'C42',
              'name': '测试客户',
              'receivable_amount': '70.00',
              'shipments': [
                for (final (id, amount) in [(10, '50.00'), (11, '20.00')])
                  {
                    'id': id,
                    'code': 'SH-$id',
                    'order_code': 'SO-$id',
                    'posted_at': '2026-11-17T05:00:00Z',
                    'receivable_amount': amount,
                    'settled_amount': '0.00',
                    'outstanding_amount': amount,
                  },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        requests.add(body);
        if (requests.length == 1) {
          throw http.ClientException('network interrupted');
        }
        return http.Response(
          jsonEncode({
            ...body,
            'id': 7,
            'code': 'RC-7',
            'customer_id': 42,
            'received_at': '2026-11-17T06:00:00Z',
            'recorded_by_name': 'admin',
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openCustomerReceipt(context, api, employee, 42),
              child: const Text('核销'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('核销'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '实收（元）'), '15');
    await tester.enterText(find.widgetWithText(TextFormField, '核销（元）'), '14');
    await tester.tap(find.text('收款方式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('现金').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认核销'));
    await tester.pumpAndSettle();
    expect(find.text('发货单核销金额合计须等于实际收款。'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, '核销（元）'), '15');
    await tester.tap(find.text('确认核销'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重试核销'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(2));
    expect(requests.first, requests.last);
    expect(requests.first['allocations'], [
      {'shipment_id': 10, 'amount': '15.00'},
    ]);
    expect(find.text('收款单 RC-7 已核销 ¥15.00。'), findsOneWidget);
  });
}
