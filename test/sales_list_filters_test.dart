import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/api.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:garment_erp_android/order_fulfillment.dart';
import 'package:garment_erp_android/sales_shell.dart';
import 'package:garment_erp_android/workspace_pages.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _employee = LoginResult(
  token: 'test',
  employeeId: 1,
  username: 'staff',
  expiresAt: '2026-12-01',
);

void main() {
  testWidgets('小横屏首屏完整显示十一列与至少八张订货单', (tester) async {
    final orders = [
      for (var id = 1; id <= 20; id++)
        OrderRead(
          id: id,
          code: 'SO-$id',
          customerName: '测试客户',
          dueDate: '2026-11-20',
          confirmedAt: '2026-11-18',
          lines: const [],
        ).toJson(),
    ];
    final api = ErpApi(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'count': orders.length, 'results': orders})),
          200,
        ),
      ),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(997, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SalesShell(
          section: SalesSection.orders,
          username: 'staff',
          onNavigate: (_) {},
          onScan: null,
          onLogout: null,
          child: WorkspacePages(
            section: SalesSection.orders,
            api: api,
            employee: _employee,
            onNewOrder: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final grid = tester.renderObject<RenderTable>(find.byType(Table));
    final footer = find.text('20 条记录');
    expect(grid.columns, 11);
    expect(
      grid.localToGlobal(grid.getRowBox(0).topRight).dx,
      lessThanOrEqualTo(997),
    );
    final footerY = tester.getTopLeft(footer).dy;
    expect(
      grid.localToGlobal(grid.getRowBox(8).bottomLeft).dy,
      lessThan(footerY),
    );
    expect(grid.getRowBox(1).height, lessThanOrEqualTo(33));
    expect(
      tester.getCenter(find.byKey(const ValueKey('list-keyword'))).dy,
      closeTo(tester.getCenter(find.widgetWithText(TextField, '全部客户')).dy, 1),
    );
    final inputs = find
        .byType(InputDecorator)
        .evaluate()
        .map((e) => e.size!)
        .toList();
    expect(inputs, hasLength(6));
    expect(inputs.map((s) => s.height).toSet(), {36.0});
    expect(inputs.map((s) => s.width).toSet(), hasLength(1));
    await tester.drag(find.text('SO-3'), const Offset(0, -230));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(footer).dy, footerY);
    expect(tester.takeException(), isNull);
  });

  testWidgets('订货筛选按客户、店员与状态查询，清除筛选保留关键字', (tester) async {
    final requests = <Uri>[];
    final api = ErpApi(
      client: MockClient((request) async {
        requests.add(request.url);
        final items = switch (request.url.path) {
          '/api/v1/customers/' => [
            {'id': 12, 'code': 'C-12', 'name': '样衣客户', 'active': true},
          ],
          '/api/v1/staff/clerks/' => [
            {'id': 15, 'username': 'clerk', 'name': '张店员', 'is_active': true},
          ],
          _ => [],
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode({'count': items.length, 'results': items})),
          200,
        );
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(1024, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspacePages(
            api: api,
            employee: _employee,
            section: SalesSection.orders,
            onNewOrder: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('list-keyword')), 'SO-');
    await tester.pumpAndSettle(const Duration(milliseconds: 360));
    final customerField = find.widgetWithText(TextField, '全部客户');
    await tester.tap(customerField);
    await tester.enterText(customerField, 'C-12');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(requests.last.queryParameters['search'], 'C-12');
    tester.view.viewInsets = FakeViewPadding(
      bottom: 400 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(customerField).controller!.text, 'C-12');
    expect(find.text('样衣客户').hitTestable(), findsOneWidget);
    await tester.tap(find.text('样衣客户'));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('展开店员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('张店员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部状态'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('部分发货').last);
    await tester.pumpAndSettle();
    expect(requests.last.path, '/api/v1/orders/');
    expect(requests.last.queryParameters, {
      'search': 'SO-',
      'customer_id': '12',
      'clerk_id': '15',
      'status': 'partial',
      'page': '1',
    });

    await tester.tap(find.text('清除筛选'));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters, {'search': 'SO-', 'page': '1'});
    expect(find.text('SO-'), findsOneWidget);
  });

  testWidgets('待发和全部订货切换保留搜索，销售单只有共有筛选', (tester) async {
    final requests = <Uri>[];
    final api = ErpApi(
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response('{"count":0,"results":[]}', 200);
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(800, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderFulfillment(
            api: api,
            employee: _employee,
            onNewCustomerOrder: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('list-keyword')), '客户名');
    await tester.pumpAndSettle(const Duration(milliseconds: 360));
    expect(requests.last.queryParameters, {
      'search': '客户名',
      'pending': 'false',
      'page': '1',
    });
    await tester.tap(find.byTooltip('订单范围'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('待发订单').last);
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters, {
      'search': '客户名',
      'pending': 'true',
      'page': '1',
    });
    expect(find.text('客户名'), findsOneWidget);

    await tester.tap(find.text('销售单'));
    await tester.pumpAndSettle();
    expect(requests.last.path, '/api/v1/shipments/');
    expect(find.text('全部状态'), findsNothing);
    expect(find.text('全部客户'), findsOneWidget);
    expect(find.text('全部店员'), findsOneWidget);
    await tester.tap(find.byTooltip('选择发货日期从'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('键盘输入'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('发货日期从')), '2026/11/17');
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters, {
      'date_from': '2026-11-17',
      'page': '1',
    });
    await tester.tap(find.byTooltip('选择发货日期至'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('键盘输入'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('发货日期至')), '2026-11-16');
    await tester.pumpAndSettle();
    expect(find.text('截止日期不能早于起始日期'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('发货日期至')), '2026-11-17');
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters, {
      'date_from': '2026-11-17',
      'date_to': '2026-11-17',
      'page': '1',
    });
  });
}
