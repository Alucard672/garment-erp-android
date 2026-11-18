import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/api.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:garment_erp_android/sales_shell.dart';
import 'package:garment_erp_android/record_pages.dart';
import 'package:garment_erp_android/workspace_pages.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('基础信息在同一行切换档案与账款', (tester) async {
    final requests = <String>[];
    final api = ErpApi(
      client: MockClient((request) async {
        requests.add(request.url.path);
        if (request.url.path == '/api/v1/customers/receivables/') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'count': 2,
                'results': [
                  {
                    'id': 1,
                    'code': 'C01',
                    'name': '测试客户',
                    'receivable_amount': '25.00',
                  },
                  {
                    'id': 2,
                    'code': 'C02',
                    'name': '结余客户',
                    'receivable_amount': '-7.00',
                  },
                ],
              }),
            ),
            200,
          );
        }
        final (code, name) = switch (request.url.path) {
          '/api/v1/customers/' => ('C01', '测试客户'),
          '/api/v1/suppliers/' => ('S01', '测试厂家'),
          _ => throw StateError('Unexpected request ${request.url.path}'),
        };
        return http.Response(
          jsonEncode({
            'count': 1,
            'results': [
              {'id': 1, 'code': code, 'name': name},
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(1280, 752));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var section = SalesSection.customers;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            void navigate(SalesSection next) => setState(() => section = next);
            return SalesShell(
              username: 'staff',
              section: section,
              onNavigate: navigate,
              onScan: null,
              onLogout: null,
              child: WorkspacePages(
                section: section,
                api: api,
                employee: const LoginResult(
                  token: 'test',
                  employeeId: 1,
                  username: 'staff',
                  expiresAt: '2026-12-01',
                ),
                onNewOrder: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SalesTabs), findsOneWidget);
    expect(find.text('客户账款'), findsOneWidget);
    expect(find.text('测试客户'), findsOneWidget);
    expect(find.text('新增客户'), findsOneWidget);
    expect(
      tester.getCenter(find.text('新增客户')).dy,
      tester.getCenter(find.byType(TextField)).dy,
    );

    await tester.tap(find.text('客户账款'));
    await tester.pumpAndSettle();
    expect(section, SalesSection.customerReceivables);
    expect(find.text('应收 / 结余（元）'), findsOneWidget);
    expect(find.text('25.00'), findsOneWidget);
    expect(find.text('客户结余 7.00'), findsOneWidget);
    expect(find.text('新增客户'), findsNothing);

    await tester.tap(find.text('供应商档案'));
    await tester.pumpAndSettle();
    expect(section, SalesSection.suppliers);
    expect(find.text('测试厂家'), findsOneWidget);
    expect(find.text('S01'), findsOneWidget);

    await tester.tap(find.text('厂家账款'));
    await tester.pumpAndSettle();
    expect(section, SalesSection.supplierPayables);
    expect(find.byType(SalesTabs), findsOneWidget);
    expect(find.textContaining('厂家应付'), findsOneWidget);
    expect(requests, [
      '/api/v1/customers/',
      '/api/v1/customers/receivables/',
      '/api/v1/suppliers/',
    ]);
  });
}
