import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/api.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:garment_erp_android/sales_shell.dart';
import 'package:garment_erp_android/workspace_pages.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _orderCode = 'SO-0123456789ABCD';

void main() {
  for (final section in [SalesSection.orders, SalesSection.orderLookup]) {
    testWidgets('订单详情加载并放大款式图（${section.name}）', (tester) async {
      final requests = await _openOrder(
        tester,
        section: section,
        styleId: 17,
        clerk: '张三',
      );

      expect(find.text('A0001  毛衣'), findsOneWidget);
      final facts = find
          .ancestor(of: find.text('整单备注'), matching: find.byType(Wrap))
          .first;
      Finder fact(String text) =>
          find.descendant(of: facts, matching: find.text(text));
      final customerLabel = fact('客户');
      final clerkLabel = fact('店员');
      final dueDateLabel = fact('交货日期');
      expect(clerkLabel, findsOneWidget);
      expect(fact('张三'), findsOneWidget);
      final customer = tester.getTopLeft(customerLabel);
      final clerk = tester.getTopLeft(clerkLabel);
      final dueDate = tester.getTopLeft(dueDateLabel);
      expect([clerk.dy, dueDate.dy], everyElement(customer.dy));
      expect(clerk.dx, greaterThan(customer.dx));
      expect(dueDate.dx, greaterThan(clerk.dx));
      expect(
        tester.getTopLeft(find.text('整单备注')).dy,
        greaterThan(tester.getTopLeft(find.text('订货 / 已发')).dy),
      );
      expect(find.text('订货 5 · 待发 3'), findsOneWidget);
      expect(find.text('¥22.00'), findsOneWidget);
      expect(find.text('单独装箱'), findsOneWidget);
      expect(requests.map((uri) => uri.path), [
        '/api/v1/orders/',
        '/api/v1/styles/17/images/style_image/',
      ]);
      expect(requests.last.queryParameters['thumbnail'], 'true');

      if (section == SalesSection.orders) {
        await tester.binding.setSurfaceSize(const Size(480, 900));
        await tester.pump();
        expect(
          tester.getTopLeft(clerkLabel).dy,
          tester.getTopLeft(customerLabel).dy,
        );
        expect(
          tester.getTopLeft(dueDateLabel).dy,
          greaterThan(tester.getTopLeft(customerLabel).dy),
        );
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        await tester.pump();
      }

      await tester.tap(find.byTooltip('放大 A0001 款式图'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(requests.last.path, '/api/v1/styles/17/images/style_image/');
      expect(requests.last.queryParameters, isEmpty);
    });
  }

  testWidgets('旧接口订单仍可查看颜色尺码明细', (tester) async {
    final requests = await _openOrder(tester, section: SalesSection.orders);

    expect(find.text('A0001  毛衣'), findsOneWidget);
    expect(find.text('红色'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('订货 5 · 待发 3'), findsOneWidget);
    expect(find.text('¥22.00'), findsOneWidget);
    expect(find.text('单独装箱'), findsOneWidget);
    expect(requests.single.path, '/api/v1/orders/');
  });
}

Future<List<Uri>> _openOrder(
  WidgetTester tester, {
  required SalesSection section,
  int? styleId,
  String? clerk,
}) async {
  final requests = <Uri>[];
  final api = ErpApi(
    client: MockClient((request) async {
      requests.add(request.url);
      expect(request.headers['authorization'], 'Bearer test');
      if (request.url.path == '/api/v1/styles/17/images/style_image/') {
        return http.Response.bytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
          ),
          200,
          headers: {'content-type': 'image/png'},
        );
      }
      expect(request.url.path, '/api/v1/orders/');
      return http.Response(
        jsonEncode({
          'count': 1,
          'results': [
            {
              'id': 3,
              'code': _orderCode,
              'customer_name': '测试客户',
              'due_date': '2026-12-01',
              'confirmed_at': '2026-11-17T08:00:00Z',
              'clerk_name': ?clerk,
              'lines': [
                {
                  'id': 1,
                  'sku_id': 101,
                  'style_id': ?styleId,
                  'style_code': 'A0001',
                  'style_name': '毛衣',
                  'color': '红色',
                  'size': 'S',
                  'quantity': 5,
                  'sent': 2,
                  'unit_price': '22.00',
                  'notes': '单独装箱',
                },
              ],
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
  addTearDown(api.close);
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WorkspacePages(
          section: section,
          api: api,
          employee: const LoginResult(
            token: 'test',
            employeeId: 1,
            username: 'staff',
            expiresAt: '2026-12-01',
          ),
          onNewOrder: () {},
          scannedCode: section == SalesSection.orderLookup ? _orderCode : '',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('详情'));
  await tester.pumpAndSettle();
  expect(find.text('订货单 $_orderCode'), findsOneWidget);
  return requests;
}
