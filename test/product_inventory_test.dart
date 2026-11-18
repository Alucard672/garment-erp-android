import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/api.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:garment_erp_android/sales_shell.dart';
import 'package:garment_erp_android/workspace_pages.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('款式档案支持图片放大并显示颜色尺码、其他字段和尺寸表', (tester) async {
    final images = <bool>[];
    const item = {
      'id': 1,
      'code': 'A0001',
      'name': '毛衣',
      'has_style_image': true,
    };
    final api = ErpApi(
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/images/style_image/')) {
          expect(request.headers['authorization'], 'Bearer test');
          if (request.headers['accept'] == 'image/jpeg') {
            return http.Response('Not Acceptable', 406);
          }
          images.add(request.url.queryParameters['thumbnail'] == 'true');
          return http.Response.bytes(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
            ),
            200,
            headers: {'content-type': 'image/png'},
          );
        }
        final result = path == '/api/v1/styles/catalog/'
            ? {
                'count': 2,
                'results': [
                  {...item, 'active': true},
                  {
                    'id': 2,
                    'code': 'A0002',
                    'name': '无图款',
                    'has_style_image': false,
                    'active': true,
                  },
                ],
              }
            : {
                ...item,
                'skus': [
                  {
                    'id': 3,
                    'color': '红色',
                    'size': 'S',
                    'wholesale_price': '98.00',
                  },
                ],
                'specification': {
                  'bom': [
                    {
                      'material_id': 4,
                      'material_code': 'Y01',
                      'material_name': '生产用纱线',
                      'unit': 'kg',
                      'quantity': '0.5',
                    },
                  ],
                  'measurements': [],
                  'care_label': {},
                  'profile': {
                    'design_code': 'DS01',
                    'year': 2027,
                    'attributes': [
                      {'attribute': 'season', 'entry_id': 1, 'label': '春'},
                    ],
                  },
                  'has_style_image': true,
                  'size_table': [
                    {
                      'point_id': 1,
                      'point': '衣长',
                      'values': [
                        {
                          'size_id': 1,
                          'size': 'S',
                          'before_wash': '60.00',
                          'after_wash': '59.00',
                        },
                      ],
                    },
                  ],
                },
              };
        return http.Response(
          jsonEncode(result),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspacePages(
            section: SalesSection.products,
            api: api,
            employee: const LoginResult(
              token: 'test',
              employeeId: 1,
              username: 'staff',
              expiresAt: '2026-12-01',
            ),
            onNewOrder: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(images, [true]);
    await tester.tap(find.byTooltip('放大 A0001 款式图'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(images, [true, false]);
    await tester.tap(find.byTooltip('关闭大图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('图片').first);
    await tester.pumpAndSettle();
    expect(images, [true, false, true]);
    await tester.tap(find.byTooltip('放大 A0001 款式图'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(images.last, false);
    await tester.tap(find.byTooltip('关闭大图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('毛衣'));
    await tester.pumpAndSettle();
    expect(find.text('基础资料'), findsOneWidget);
    expect(find.text('DS01'), findsNothing);
    expect(find.text('春'), findsOneWidget);
    expect(find.text('2027'), findsOneWidget);
    for (final label in [
      '设计款号',
      '供应商款号',
      '性别',
      '单位',
      '样衣',
      '来源',
      '包装袋',
      '起订量',
      '生产周期（天）',
    ]) {
      expect(find.text(label), findsNothing);
    }
    expect(find.text('生产用纱线'), findsNothing);
    await tester.tap(find.text('颜色尺码'));
    await tester.pumpAndSettle();
    expect(find.text('红色'), findsOneWidget);
    expect(find.text('¥98.00'), findsOneWidget);
    await tester.tap(find.text('尺寸表'));
    await tester.pumpAndSettle();
    expect(find.text('尺寸表（cm）'), findsOneWidget);
    expect(find.text('衣长'), findsOneWidget);
    expect(find.text('60.00'), findsOneWidget);
    expect(find.text('59.00'), findsOneWidget);
  });

  testWidgets('商品管理可切换到分仓库存并按颜色查询', (tester) async {
    final requests = <Uri>[];
    Completer<void>? stockRefresh;
    final api = ErpApi(
      client: MockClient((request) async {
        requests.add(request.url);
        if (request.url.path == '/api/v1/stock/' && stockRefresh != null) {
          await stockRefresh.future;
        }
        final results = request.url.path == '/api/v1/stock/'
            ? [
                {
                  'warehouse': '门店仓',
                  'style_code': 'A01',
                  'style_name': '圆领',
                  'color': '米白',
                  'size': 'M',
                  'quantity': 27,
                },
              ]
            : request.url.path == '/api/v1/style-dictionary/'
            ? [
                {'id': 9, 'kind': 'color', 'active': true, 'label': '蓝'},
              ]
            : [];
        return http.Response(
          jsonEncode({'count': results.length, 'results': results}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(1280, 752));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspacePages(
            section: SalesSection.products,
            api: api,
            employee: const LoginResult(
              token: 'test',
              employeeId: 1,
              username: 'staff',
              expiresAt: '2026-12-01',
            ),
            onNewOrder: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requests.single.path, '/api/v1/styles/catalog/');
    expect(find.text('货品查询'), findsOneWidget);
    expect(find.text('商品管理'), findsNothing);
    expect(find.text('0 条记录'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('search'))).height, 36);
    expect(
      tester.getTopLeft(find.widgetWithText(InkWell, '货品查询')).dx,
      tester.getTopLeft(find.byKey(const ValueKey('search'))).dx,
    );
    await tester.tap(find.text('库存管理'));
    await tester.pumpAndSettle();
    expect(find.text('商品管理'), findsNothing);
    expect(requests.last.path, '/api/v1/stock/');
    expect(find.text('门店仓'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('list-keyword')), '米白');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['search'], '米白');
    final inputs = find
        .byType(InputDecorator)
        .evaluate()
        .map((element) => element.size!)
        .toList();
    expect(inputs, hasLength(12));
    expect(inputs.map((size) => size.height).toSet(), {36.0});
    final paintedFields = find
        .byType(EditableText)
        .evaluate()
        .map((element) => InputDecorator.containerOf(element)!.size.height);
    expect(paintedFields.toSet(), {36.0});

    expect(inputs.map((size) => size.width).toSet(), hasLength(1));
    await tester.tap(find.byTooltip('展开颜色'));
    await tester.pumpAndSettle();
    expect(requests.last.path, '/api/v1/style-dictionary/');
    expect(requests.last.queryParameters['kind'], 'color');
    await tester.tap(find.text('蓝'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('style_code')), 'A01');
    expect(requests.last.queryParameters.containsKey('color'), isFalse);
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters, {
      'search': '米白',
      'color': '蓝',
      'style_code': 'A01',
      'status': 'active',
      'page': '1',
    });
    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters, {'page': '1'});

    await tester.tap(find.text('货品查询'));
    await tester.pumpAndSettle();
    expect(requests.last.path, '/api/v1/styles/catalog/');
    expect(find.text('门店仓'), findsNothing);
    stockRefresh = Completer<void>();
    await tester.tap(find.text('库存管理'));
    await tester.pump();
    expect(requests.last.path, '/api/v1/stock/');
    expect(find.text('门店仓'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    stockRefresh.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.binding.setSurfaceSize(const Size(870, 420));
    await tester.pumpAndSettle();
    final compact = find.byType(InputDecorator).evaluate().map((e) => e.size!);
    expect(compact.map((s) => s.width).toSet(), hasLength(1));
    expect(compact.map((s) => s.height).toSet(), {36.0});
    expect(find.text('查询').hitTestable(), findsOneWidget);
  });
}
