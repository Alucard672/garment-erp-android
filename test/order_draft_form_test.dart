import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:garment_erp_android/tablet_filter_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/draft.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:garment_erp_android/main.dart';
import 'package:garment_erp_android/order_draft_form.dart';
import 'package:garment_erp_android/sales_fields.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('横屏显示两款商品的颜色尺码矩阵与合计', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 610));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL'];
    final styles = [
      for (final (index, colors) in [
        ['红色', '白色', '墨绿'],
        ['浅灰', '米白'],
      ].indexed)
        StyleDetail(
          id: index + 1,
          code: 'A000${index + 1}',
          name: index == 0 ? '圆领毛衣' : '针织开衫',
          salePrice: '22.00',
          skus: [
            for (final (row, color) in colors.indexed)
              for (final (column, size) in sizes.indexed)
                Sku(
                  id: index * 100 + row * sizes.length + column + 1,
                  color: color,
                  size: size,
                ),
          ],
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              OrderDraftForm(
                draft: OrderDraft(
                  styles: styles,
                  quantities: {
                    for (final style in styles)
                      for (final sku in style.skus.take(4)) sku.id: 1,
                  },
                ),
                stylePhoto: (_) => const SizedBox.square(dimension: 40),
                onPickCustomer: () {},
                onPickDueDate: (_) {},
                onPickPaymentMethod: () {},
                onAddProduct: () {},
                onRemoveStyle: (_) {},
                onQuantityChanged: (_, _) {},
              ),
            ],
          ),
        ),
      ),
    );
    final matrices = tester.widgetList<DataTable>(find.byType(DataTable));
    expect(matrices, hasLength(2));
    expect(matrices.every((table) => table.columns.length == 9), isTrue);
    expect(matrices.every((table) => table.dataRowMinHeight! >= 44), isTrue);
    expect(tester.getBottomLeft(find.text('共 4 件').last).dy, lessThan(610));
    expect(tester.takeException(), isNull);
  });

  testWidgets('现货发货独立保存并重试，成功后返回销售单列表', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
    const serverUrl = 'http://10.0.2.2:8001';
    final orderStorage = DraftStorage(1, serverUrl: serverUrl);
    final directStorage = DraftStorage(1, serverUrl: serverUrl, direct: true);
    await orderStorage.write(
      OrderDraft(
        notes: '另一个订货草稿',
        styles: const [
          StyleDetail(
            id: 3,
            code: 'S03',
            name: '测试短袖',
            hasStyleImage: false,
            skus: [Sku(id: 6, color: '白', size: 'L')],
          ),
        ],
        quantities: {6: 1},
      ),
    );
    await directStorage.write(
      OrderDraft(
        customer: const Customer(id: 1, code: 'C01', name: '测试客户'),
        styles: const [
          StyleDetail(
            id: 2,
            code: 'S02',
            name: '测试圆领',
            salePrice: '68.50',
            skus: [Sku(id: 4, color: '米白', size: 'M')],
          ),
        ],
        quantities: {4: 2},
        lineNotes: {4: '门店自提'},
      ),
    );
    final requests = <String>[];
    http.Response jsonResponse(Object data, int status) =>
        http.Response.bytes(utf8.encode(jsonEncode(data)), status);
    final client = MockClient((request) async {
      switch (request.url.path) {
        case ApiPath.authLoginCreate:
          return jsonResponse({
            'token': 'test',
            'employee_id': 1,
            'username': 'tester',
            'expires_at': '2026-12-01',
          }, 200);
        case ApiPath.ordersList:
        case ApiPath.shipmentsList:
          return jsonResponse({'count': 0, 'results': []}, 200);
        case ApiPath.salesSummaryRetrieve:
          return jsonResponse({
            'order_count': 3,
            'shipment_count': 2,
            'ordered': 90,
            'sent': 30,
          }, 200);
        case ApiPath.warehousesList:
          return jsonResponse({
            'count': 1,
            'results': [
              {'id': 3, 'code': 'W03', 'name': '成品仓'},
            ],
          }, 200);
        case ApiPath.staffClerksList:
          return jsonResponse({
            'count': 1,
            'results': [
              {'id': 5, 'username': 'clerk', 'name': '李店员'},
            ],
          }, 200);
        case ApiPath.shipmentsDirectCreate:
          expect(request.method, 'POST');
          requests.add(request.body);
          if (requests.length == 1) throw http.ClientException('lost response');
          return jsonResponse({'id': 8, 'code': 'XS-8'}, 201);
        default:
          throw StateError('Unexpected request ${request.url}');
      }
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const ErpApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'tester');
      await tester.enterText(find.byType(TextField).at(1), 'test-password');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
      expect(find.text('经营情况'), findsOneWidget);
      expect(find.text('已发 30 件　待发 60 件'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '扫码'), findsOneWidget);
      await tester.tap(find.text('销售开单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('销售单'));
      await tester.pumpAndSettle();
      expect(find.textContaining('销售工作台  /'), findsNothing);
      expect(find.byTooltip('扫码'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '扫码'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('list-keyword'))).width,
        lessThanOrEqualTo(390),
      );
      await tester.tap(find.text('开单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('现货直接发货'));
      await tester.pumpAndSettle();

      expect(find.text('约定交期'), findsNothing);
      expect(find.byKey(const ValueKey(('quantity', 4))), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
      final submit = find.widgetWithText(TabletAction, '确认发货');
      expect(tester.widget<TabletAction>(submit).onPressed, isNull);
      await tester.tap(find.text('选择仓库'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('成品仓'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('返回销售开单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保留并返回'));
      await tester.pumpAndSettle();
      expect(find.text('销售单'), findsOneWidget);
      await tester.tap(find.text('开单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('现货直接发货'));
      await tester.pumpAndSettle();
      expect(find.text('W03  成品仓'), findsOneWidget);
      final clerk = find.widgetWithText(SalesFieldSurface, '经手人');
      await tester.tap(clerk);
      await tester.pumpAndSettle();
      await tester.tap(find.text('李店员'));
      await tester.pumpAndSettle();
      expect(find.text('李店员'), findsOneWidget);
      await tester.tap(find.byTooltip('清除经手人'));
      await tester.pumpAndSettle();
      expect(find.text('未选择'), findsOneWidget);
      await tester.tap(clerk);
      await tester.pumpAndSettle();
      await tester.tap(find.text('李店员'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('未指定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PaymentMethod.unpaid.label));
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(requests, hasLength(1));
      final payload = jsonDecode(requests.single) as Map<String, dynamic>;
      expect(payload['warehouse_id'], 3);
      expect(payload['clerk_id'], 5);
      expect(payload['payment_method'], PaymentMethod.unpaid.code);
      expect(payload.containsKey('due_date'), isFalse);
      expect(payload['lines'], [
        {'sku_id': 4, 'quantity': 2, 'notes': '门店自提'},
      ]);
      expect(
        (await directStorage.read()).pendingShipment?.requestKey,
        payload['request_key'],
      );
      await tester.tap(find.text('重试确认发货'));
      await tester.pumpAndSettle();
      expect(requests, [requests.first, requests.first]);
      expect(find.text('发货单 XS-8 已保存。'), findsOneWidget);
      expect(find.text('销售单'), findsOneWidget);
      expect((await directStorage.read()).customer, isNull);
      expect((await orderStorage.read()).notes, '另一个订货草稿');

      await tester.tap(find.text('客户订单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增客户订货'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('返回订单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('清空并返回'));
      await tester.pumpAndSettle();
      expect(find.text('新增客户订货'), findsOneWidget);
      expect((await orderStorage.read()).hasLines, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });

  testWidgets('保存订单直接提交，失败时保留录入并可重试同一次请求', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
    final storage = DraftStorage(1, serverUrl: 'http://10.0.2.2:8001');
    await storage.write(
      OrderDraft(
        customer: const Customer(id: 1, code: 'C01', name: '测试客户'),
        dueDate: '2026-12-01',
        styles: const [
          StyleDetail(
            id: 2,
            code: 'S02',
            name: '测试圆领',
            salePrice: '68.50',
            hasStyleImage: true,
            skus: [Sku(id: 4, color: '米白', size: 'M')],
          ),
        ],
        quantities: {4: 6},
      ),
    );
    final requests = <String>[];
    final imageRequests = <Uri>[];
    const saved = {
      'id': 3,
      'code': 'SO-3',
      'customer_name': '测试客户',
      'due_date': '2026-12-01',
      'confirmed_at': '2026-11-17T08:00:00Z',
      'lines': [],
    };
    http.Response jsonResponse(Object data, int status) =>
        http.Response.bytes(utf8.encode(jsonEncode(data)), status);
    final client = MockClient((request) async {
      if (request.url.path == ApiPath.stylesList) {
        return jsonResponse({
          'count': 2,
          'results': [
            {'id': 2, 'code': 'S02', 'name': '测试圆领'},
            {'id': 5, 'code': 'S05', 'name': '测试翻领'},
          ],
        }, 200);
      }
      if (request.url.path == ApiPath.stylesRetrieve(5)) {
        return jsonResponse({
          'id': 5,
          'code': 'S05',
          'name': '测试翻领',
          'sale_price': '76.00',
          'skus': [
            {'id': 11, 'color': '黑色', 'size': 'M'},
            {'id': 10, 'color': '黑色', 'size': 'L'},
          ],
        }, 200);
      }
      if (request.url.path == '/api/v1/styles/2/images/style_image/') {
        expect(request.headers['authorization'], 'Bearer test');
        imageRequests.add(request.url);
        return http.Response.bytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
          ),
          200,
          headers: {'content-type': 'image/png'},
        );
      }
      if (request.url.path == ApiPath.authLoginCreate) {
        return http.Response(
          '{"token":"test","employee_id":1,"username":"tester","expires_at":"2026-12-01"}',
          200,
        );
      }
      if (request.url.path == ApiPath.salesSummaryRetrieve) {
        return jsonResponse({
          'order_count': 0,
          'shipment_count': 0,
          'ordered': 0,
          'sent': 0,
        }, 200);
      }
      expect(request.url.path, ApiPath.ordersList);
      if (request.method == 'GET') {
        return jsonResponse({
          'count': requests.length == 3 ? 1 : 0,
          'results': requests.length == 3 ? [saved] : [],
        }, 200);
      }
      requests.add(request.body);
      if (requests.length == 1) {
        return jsonResponse({'detail': '款式售价尚未设置，请联系商品管理员。'}, 400);
      }
      if (requests.length == 2) throw http.ClientException('lost response');
      return jsonResponse(saved, 201);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const ErpApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'tester');
      await tester.enterText(find.byType(TextField).at(1), 'test-password');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('销售开单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('开单'));
      await tester.pumpAndSettle();

      expect(find.text('保存草稿'), findsNothing);
      final price = find.text('销售价（元）  68.50');
      expect(price, findsOneWidget);
      expect(
        tester.getTopLeft(price).dy,
        greaterThan(tester.getBottomLeft(find.text('颜色 / 尺码')).dy),
      );
      expect(find.byTooltip('放大 S02 款式图'), findsOneWidget);
      expect(imageRequests.single.queryParameters['thumbnail'], 'true');

      await tester.tap(find.text('添加款式'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('测试翻领'));
      await tester.pumpAndSettle();
      Finder quantityField(int id) => find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(TextFormField),
      );
      final quantity = quantityField(10);
      await tester.ensureVisible(quantity);
      await tester.enterText(quantity, '2');
      await tester.pumpAndSettle();
      expect(find.text('销售价（元）  76.00'), findsOneWidget);
      expect(find.text('8 件'), findsOneWidget);
      expect(find.text('预计金额 ¥563.00'), findsOneWidget);

      await tester.enterText(quantityField(11), '1');
      await tester.pumpAndSettle();
      expect(find.text('9 件'), findsOneWidget);
      await tester.enterText(quantityField(11), '');
      await tester.pumpAndSettle();
      expect(find.text('8 件'), findsOneWidget);

      final remove = find.byTooltip('移除 S05');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('8 件'), findsOneWidget);

      await tester.tap(find.text('保存订单'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('款式售价尚未设置，请联系商品管理员。'), findsOneWidget);
      expect(find.text('8 件'), findsOneWidget);

      final payload = jsonDecode(requests.first) as Map<String, dynamic>;
      expect(payload['unit_price'], isNull);
      expect(payload['clerk_id'], isNull);
      expect(
        (payload['lines'] as List).map(
          (line) => [line['sku_id'], line['quantity']],
        ),
        [
          [4, 6],
          [10, 2],
        ],
      );
      await tester.tap(find.text('保存订单'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(2));
      expect((await storage.read()).pending?.lines.length, 2);
      await tester.tap(find.text('重试保存订单'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(3));
      expect(requests[2], requests[1]);
      expect(
        imageRequests.map((uri) => uri.queryParameters['thumbnail']),
        everyElement('true'),
      );
      expect(find.text('订单 SO-3 已保存。'), findsOneWidget);
      expect(find.text('SO-3'), findsOneWidget);
      expect((await storage.read()).customer, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });

  testWidgets('单头字段并排，数量和备注绑定各自的规格行', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1040, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selected = <String>[];
    final changes = <int, int>{};
    final lineNotes = <int, String>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              OrderDraftForm(
                draft: OrderDraft(
                  customer: const Customer(id: 1, code: 'C01', name: '测试客户'),
                  dueDate: '2026-12-01',
                  paymentMethod: PaymentMethod.wechat,
                  styles: const [
                    StyleDetail(
                      id: 2,
                      code: 'S02',
                      name: '测试圆领',
                      skus: [
                        Sku(id: 4, color: '米白', size: 'M'),
                        Sku(id: 5, color: '米白', size: 'L'),
                      ],
                    ),
                  ],
                  quantities: {4: 6, 5: 0},
                ),
                onPickCustomer: () => selected.add('customer'),
                onPickDueDate: (_) => selected.add('date'),
                onPickPaymentMethod: () => selected.add('payment'),
                onAddProduct: () => selected.add('style'),
                onQuantityChanged: (sku, quantity) => changes[sku] = quantity,
                onLineNotesChanged: (sku, notes) => lineNotes[sku] = notes,
              ),
            ],
          ),
        ),
      ),
    );

    final customer = find.text('C01  测试客户');
    final date = find.text('2026-12-01');
    final payment = find.text('微信');
    final product = find.text('测试圆领');
    final quantity = find.byWidgetPredicate(
      (widget) => widget is TextFormField && widget.initialValue == '6',
    );
    expect(tester.getTopLeft(customer).dy, tester.getTopLeft(date).dy);
    expect(tester.getTopLeft(customer).dy, tester.getTopLeft(payment).dy);
    expect(
      tester.getTopLeft(find.text('客户')).dy,
      tester.getTopLeft(find.text('整单备注')).dy,
    );
    expect(
      tester.getSize(find.widgetWithText(SalesFieldSurface, '整单备注')).height,
      tester.getSize(find.widgetWithText(SalesFieldSurface, '客户')).height,
    );
    expect(
      tester.getTopLeft(product).dy,
      greaterThan(tester.getBottomLeft(customer).dy),
    );
    await tester.tap(customer);
    await tester.tap(date);
    await tester.tap(payment);
    await tester.tap(find.text('添加款式'));
    expect(selected, ['customer', 'date', 'payment', 'style']);
    await tester.enterText(quantity, '12');
    expect(changes, {4: 12});

    await tester.tap(find.byTooltip('米白 明细备注'));
    await tester.pumpAndSettle();
    final noteField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(noteField, '单独装箱');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('L').last);
    await tester.pumpAndSettle();
    await tester.enterText(noteField, '另加吊牌');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(lineNotes, {4: '单独装箱', 5: '另加吊牌'});

    await tester.binding.setSurfaceSize(const Size(390, 620));
    await tester.pump();
    expect(find.text('明细备注'), findsOneWidget);
    expect(
      tester.getTopLeft(date).dy,
      greaterThan(tester.getBottomLeft(customer).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
