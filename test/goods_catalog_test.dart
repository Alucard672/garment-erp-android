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
  testWidgets('货品查询在两种视图复用筛选和分页，清除恢复全部状态', (tester) async {
    const dictionaries = {
      'color': ('颜色', '藏青'),
      'season': ('季节', '冬季'),
      'brand': ('品牌', '青禾'),
      'category': ('类别', '针织'),
    };
    final queries = <Map<String, String>>[];
    final api = ErpApi(
      client: MockClient((request) async {
        final params = request.url.queryParameters;
        var payload = <String, dynamic>{};
        if (request.url.path == ApiPath.styleDictionaryList) {
          final kind = params['kind']!;
          payload = {
            'count': 1,
            'results': [
              {
                'id': 1,
                'kind': kind,
                'label': dictionaries[kind]!.$2,
                'active': true,
              },
            ],
          };
        } else {
          expect(request.url.path, ApiPath.stylesCatalogList);
          queries.add(params);
          final page = params['page'];
          payload = {
            'count': 2,
            'next': page == '1' ? '/api/v1/styles/catalog/?page=2' : null,
            'results': [
              {
                'id': int.parse(page!),
                'code': 'A-$page',
                'name': '冬衣$page',
                'active': false,
                'has_style_image': false,
                'sale_price': '83.00',
                'launch_date': '2026-11-01',
                'total_stock': page == '1' ? null : -3,
              },
            ],
          };
        }
        return http.Response(
          jsonEncode(payload),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    await tester.binding.setSurfaceSize(const Size(1000, 420));
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
              expiresAt: '2027-01-01',
            ),
            onNewOrder: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(queries.single, {'status': 'active', 'page': '1'});
    await tester.enterText(find.byKey(const ValueKey('search')), '冬衣');
    await tester.enterText(find.byKey(const ValueKey('operator')), '员工');
    for (final (label, text) in dictionaries.values) {
      await tester.tap(find.byTooltip('展开$label'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, text));
      await tester.pumpAndSettle();
    }

    Future<void> date(String key, String value) async {
      final label = key == 'launch_from' ? '上架日期从' : '上架日期至';
      final clear = find.byTooltip('清空$label');
      if (clear.evaluate().isNotEmpty) {
        await tester.tap(clear);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('选择$label'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('键盘输入'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(TextFormField),
        ),
        value,
      );
    }

    await date('launch_from', '2026-11-01');
    await date('launch_to', '2026-10-30');
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    expect(find.text('截止日期不能早于起始日期'), findsOneWidget);
    expect(queries, hasLength(1));
    await date('launch_to', '2026-11-18');
    for (final (label, text) in [('商品状态', '停用'), ('是否有图', '无图')]) {
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, text));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    final applied = {
      'search': '冬衣',
      'operator': '员工',
      'status': 'disabled',
      'has_image': 'false',
      'launch_from': '2026-11-01',
      'launch_to': '2026-11-18',
      for (final e in dictionaries.entries) e.key: e.value.$2,
    };
    expect(queries.last, {...applied, 'page': '1'});
    final tally = queries.length;
    await tester.tap(find.text('图片').first);
    await tester.pumpAndSettle();
    expect(queries.length, tally);
    expect(find.text('总库存 —'), findsOneWidget);
    await tester.tap(find.text('下一页'));
    await tester.pumpAndSettle();
    expect(queries.last, {...applied, 'page': '2'});
    expect(find.text('总库存 -3'), findsOneWidget);
    expect(find.text('售价 ¥83.00'), findsOneWidget);
    expect(find.text('上架 2026-11-01'), findsOneWidget);
    await tester.tap(find.text('列表'));
    await tester.pumpAndSettle();
    expect(find.text('A-2'), findsOneWidget);
    expect(find.text('第 2 页'), findsOneWidget);
    expect(queries.length, tally + 1);
    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();
    expect(queries.last, {'status': 'all', 'page': '1'});
    expect(find.text('A-1'), findsOneWidget);
  });
}
