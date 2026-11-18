import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:garment_erp_android/tablet_filter_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/api.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:garment_erp_android/order_fulfillment.dart';
import 'package:garment_erp_android/style_details.dart';
import 'package:garment_erp_android/workspace_pages.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _employee = LoginResult(
  token: 'test',
  employeeId: 1,
  username: 'staff',
  expiresAt: '2026-12-01',
);

http.Response _records(List<Map<String, dynamic>> items) => http.Response.bytes(
  utf8.encode(jsonEncode({'count': items.length, 'results': items})),
  200,
);

const _shippingOrder = OrderRead(
  id: 3,
  code: 'SO-3',
  customerName: '测试客户',
  dueDate: '2026-12-01',
  confirmedAt: '2026-11-17T08:00:00Z',
  lines: [
    OrderLineRead(
      id: 5,
      skuId: 1,
      styleCode: 'A0001',
      styleName: '毛衣',
      color: '红色',
      size: 'S',
      quantity: 5,
      sent: 2,
      unitPrice: '22.00',
    ),
  ],
);

void main() {
  testWidgets('订货与发货行按实际履约状态区分，付款方式不改变底色', (tester) async {
    final order = _shippingOrder.toJson();
    final line = _shippingOrder.lines.single.toJson();
    final api = ErpApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/shipments/') {
          return _records([
            for (final (id, payment) in [(1, 'unpaid'), (2, 'cash')])
              ShipmentRead(
                id: id,
                code: 'SH-$id',
                orderCode: 'SO-$id',
                customer: '客户 $id',
                warehouseName: '发货仓',
                quantity: 2,
                postedAt: '2026-11-17T08:00:00Z',
                paymentMethod: PaymentMethod.fromCode(payment),
                lines: const [],
              ).toJson(),
          ]);
        }
        return _records([
          for (final (id, sent, payment) in [
            (1, 0, 'unpaid'),
            (2, 2, 'unpaid'),
            (3, 5, 'unpaid'),
          ])
            {
              ...order,
              'id': id,
              'code': 'SO-$id',
              'payment_method': payment,
              'lines': [
                {...line, 'sent': sent},
              ],
            },
        ]);
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(1024, 640));
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
    await tester.tap(find.byTooltip('订单范围'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部订单').last);
    await tester.pumpAndSettle();

    Table grid() => tester.widget<Table>(find.byType(Table));
    Color? color(TableRow row) => (row.decoration! as BoxDecoration).color;
    Finder labelInGrid(String label) =>
        find.descendant(of: find.byType(Table), matching: find.text(label));

    expect(labelInGrid('待发货'), findsOneWidget);
    expect(labelInGrid('部分发货'), findsOneWidget);
    expect(labelInGrid('已发齐'), findsOneWidget);
    expect(labelInGrid('¥110.00'), findsNWidgets(3));
    expect(labelInGrid('未付'), findsNWidgets(3));
    final orderColors = grid().children.skip(1).map(color).toSet();
    expect(orderColors, hasLength(3));
    expect(
      tester.getTopLeft(find.text('SO-2')).dy -
          tester.getTopLeft(find.text('SO-1')).dy,
      lessThan(60),
    );

    await tester.tap(find.text('销售单'));
    await tester.pumpAndSettle();

    expect(labelInGrid('已过账'), findsNWidgets(2));
    expect(labelInGrid('现金'), findsOneWidget);
    expect(labelInGrid('未付'), findsOneWidget);
    final shipmentColors = grid().children.skip(1).map(color).toSet();
    expect(shipmentColors, hasLength(1));
    expect(orderColors.intersection(shipmentColors), isEmpty);

    await tester.binding.setSurfaceSize(const Size(720, 640));
    await tester.pumpAndSettle();
    final firstDetail = find.text('详情').first;
    expect(firstDetail.hitTestable(), findsNothing);
    await tester.dragFrom(
      tester.getCenter(find.byType(Table)),
      const Offset(-420, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(firstDetail);
    await tester.pumpAndSettle();
    expect(find.text('发货单 SH-1'), findsOneWidget);
  });

  testWidgets('订货单详情按款号分表，尺码横排且保留每格明细', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const order = OrderRead(
      id: 3,
      code: 'SO-3',
      customerName: '测试客户',
      dueDate: '2026-12-01',
      confirmedAt: '2026-11-17T08:00:00Z',
      lines: [
        OrderLineRead(
          id: 1,
          skuId: 1,
          styleCode: 'A0001',
          styleName: '毛衣',
          color: '红色',
          size: 'S',
          quantity: 5,
          sent: 2,
          unitPrice: '22.00',
          notes: '单独装箱',
        ),
        OrderLineRead(
          id: 2,
          skuId: 2,
          styleCode: 'A0001',
          styleName: '毛衣',
          color: '红色',
          size: 'M',
          quantity: 2,
          sent: 0,
          unitPrice: '23.00',
        ),
        OrderLineRead(
          id: 3,
          skuId: 3,
          styleCode: 'A0001',
          styleName: '毛衣',
          color: '白色',
          size: 'S',
          quantity: 4,
          sent: 0,
          unitPrice: '22.00',
        ),
        OrderLineRead(
          id: 4,
          skuId: 4,
          styleCode: 'A0002',
          styleName: '针织衫',
          color: '蓝色',
          size: 'L',
          quantity: 6,
          sent: 0,
          unitPrice: '30.00',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showOrderDetails(context, order),
              child: const Text('打开订货单'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开订货单'));
    await tester.pumpAndSettle();
    final small = find.text('S');
    final medium = find.text('M');
    expect(tester.getTopLeft(small).dy, tester.getTopLeft(medium).dy);
    expect(tester.getTopLeft(small).dx, lessThan(tester.getTopLeft(medium).dx));
    expect(find.text('红色'), findsOneWidget);
    expect(find.text('白色'), findsOneWidget);
    expect(find.text('订货 5 · 待发 3'), findsOneWidget);
    expect(find.text('¥23.00'), findsOneWidget);
    expect(find.text('单独装箱'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
    expect(find.text('A0002  针织衫'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
  });

  testWidgets('loads confirmed orders from the API with an empty database', (
    tester,
  ) async {
    final requested = <Uri>[];
    final api = ErpApi(
      client: MockClient((request) async {
        requested.add(request.url);
        expect(request.headers['Authorization'], 'Bearer test');
        return http.Response(
          '{"count":0,"next":null,"previous":null,"results":[]}',
          200,
        );
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(1280, 752));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderFulfillment(
            api: api,
            employee: const LoginResult(
              token: 'test',
              employeeId: 1,
              username: 'staff',
              expiresAt: '2026-12-01',
            ),
            onNewCustomerOrder: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requested.single.path, '/api/v1/orders/');
    expect(requested.single.queryParameters['pending'], 'false');
    expect(find.text('自由开单'), findsNothing);
    expect(find.text('开单发货'), findsNothing);
    expect(find.textContaining('暂无已确认订货单'), findsOneWidget);

    await tester.tap(find.byTooltip('订单范围'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('待发订单').last);
    await tester.pumpAndSettle();
    expect(requested.last.queryParameters['pending'], 'true');

    expect(find.text('订货单'), findsOneWidget);
    expect(find.text('开单'), findsOneWidget);
    await tester.tap(find.text('销售单'));
    await tester.pumpAndSettle();
    expect(requested.last.path, '/api/v1/shipments/');
    expect(find.text('暂无已过账发货单。'), findsOneWidget);
  });

  testWidgets('新增发货可选现货或订货单，允许负库存并保留店员和重试请求', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
    final requested = <http.Request>[];
    final shipments = <Map<String, dynamic>>[];
    var direct = false;
    var stock = 0;
    var warehouseExists = false;
    final api = ErpApi(
      client: MockClient((request) async {
        requested.add(request);
        if (request.url.path == '/api/v1/staff/clerks/') {
          return _records([
            {'id': 7, 'username': 'clerk', 'name': '李制单'},
          ]);
        }
        return switch (request.url.path) {
          '/api/v1/shipments/' => _records([
            if (shipments.length > 1)
              {
                'id': 9,
                'code': 'SH-9',
                'order_code': _shippingOrder.code,
                'customer': _shippingOrder.customerName,
                'warehouse_name': '卡美澜',
                'quantity': 3,
                'posted_at': '2026-11-17T08:00:00Z',
                'lines': [
                  {
                    'id': 10,
                    'style_id': 12,
                    'style_code': 'A0001',
                    'style_name': '毛衣',
                    'color': '红色',
                    'size': 'S',
                    'quantity': 3,
                    'returnable': 3,
                    'unit_price': '22.00',
                  },
                ],
                'clerk_name': '李制单',
                'receivable_amount': '66.00',
              },
          ]),
          '/api/v1/orders/' => _records([_shippingOrder.toJson()]),
          '/api/v1/warehouses/' => _records([
            if (warehouseExists) {'id': 4, 'code': 'A', 'name': '卡美澜'},
          ]),
          '/api/v1/orders/3/availability/' => http.Response(
            '{"lines":[{"order_line_id":5,"available":$stock}]}',
            200,
          ),
          '/api/v1/orders/3/ship/' => () {
            shipments.add(jsonDecode(request.body) as Map<String, dynamic>);
            if (shipments.length == 1) {
              throw http.ClientException('lost response');
            }
            return http.Response('{"id":9,"code":"SH-9"}', 201);
          }(),
          '/api/v1/styles/12/images/style_image/' => http.Response('', 404),
          _ => throw StateError('Unexpected request: ${request.url}'),
        };
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(1280, 752));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderFulfillment(
            api: api,
            employee: _employee,
            onNewCustomerOrder: () {},
            onOpenDirectShipment: () => direct = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('销售单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('现货直接发货'));
    await tester.pumpAndSettle();
    expect(direct, isTrue);
    await tester.tap(find.text('开单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按订货单发货'));
    await tester.pumpAndSettle();
    expect(requested.last.url.queryParameters['pending'], 'true');
    await tester.tap(find.text('SO-3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择出库仓库'));
    await tester.pumpAndSettle();
    expect(find.textContaining('暂无启用的仓库'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    warehouseExists = true;
    await tester.tap(find.text('选择出库仓库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('卡美澜'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TabletAction>(find.widgetWithText(TabletAction, '按待发数量填满'))
          .onPressed,
      isNotNull,
    );
    final submit = find.widgetWithText(TabletAction, '确认发货');
    expect(tester.widget<TabletAction>(submit).onPressed, isNull);
    expect(requested.any((request) => request.method == 'POST'), isFalse);

    await tester.tap(find.text('默认当前操作员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('李制单'));
    await tester.pumpAndSettle();
    expect(find.text('李制单'), findsOneWidget);
    await tester.tap(find.byTooltip('恢复默认店员'));
    await tester.pumpAndSettle();
    expect(find.text('默认当前操作员'), findsOneWidget);
    await tester.tap(find.text('默认当前操作员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('李制单'));
    await tester.pumpAndSettle();

    stock = -2;
    await tester.tap(find.text('卡美澜'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('卡美澜').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('按待发数量填满'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('付款方式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('微信').last);
    await tester.pumpAndSettle();
    final paidField = find.widgetWithText(TextFormField, '实收（元）');
    await tester.enterText(paidField, '12.50');
    await tester.pumpAndSettle();
    expect(find.text('本单欠款  ¥53.50'), findsOneWidget);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('确认发货'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('重试确认发货'));
    await tester.pumpAndSettle();
    expect(shipments, hasLength(2));
    expect(shipments.last, shipments.first);
    expect(shipments.last['clerk_id'], 7);
    expect(shipments.last['warehouse_id'], 4);
    expect(shipments.last['paid_amount'], '12.50');
    expect(shipments.last['payment_method'], 'wechat');
    expect(shipments.last['lines'], contains(containsPair('quantity', 3)));
    expect(find.text('SH-9'), findsOneWidget);
    expect(find.text('李制单'), findsOneWidget);
    expect(find.text('¥66.00'), findsOneWidget);

    await tester.tap(find.text('详情'));
    await tester.pumpAndSettle();
    final facts = find
        .ancestor(of: find.text('发货时欠款'), matching: find.byType(Wrap))
        .first;
    expect(
      find.descendant(of: facts, matching: find.text('李制单')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: facts, matching: find.text('¥66.00')),
      findsOneWidget,
    );
    expect(find.byType(StylePhoto), findsOneWidget);
  });
}
