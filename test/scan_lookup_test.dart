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
  testWidgets('顶栏扫码，退出登录从左下角账号打开', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 752));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var scans = 0;
    var logouts = 0;
    SalesSection? visited;
    await tester.pumpWidget(
      MaterialApp(
        home: SalesShell(
          username: 'staff',
          section: SalesSection.home,
          onNavigate: (section) => visited = section,
          onScan: () => scans++,
          onLogout: () => logouts++,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('销售开单'), findsOneWidget);
    expect(find.text('工作台'), findsOneWidget);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    await tester.tap(find.text('入库与发货'));
    await tester.pumpAndSettle();
    expect(visited, SalesSection.inventory);
    await tester.tap(find.widgetWithText(OutlinedButton, '扫码'));
    expect(scans, 1);
    expect(find.text('退出登录'), findsNothing);
    await tester.tap(find.text('staff'));
    await tester.pumpAndSettle();
    expect(logouts, 0);
    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    expect(logouts, 1);
  });

  for (final (code, path, tab) in [
    ('A01', '/api/v1/styles/', '款号查询'),
    ('SO-0123456789ABCD', '/api/v1/orders/', '原订货单查询'),
  ]) {
    testWidgets('扫码后直接查询 $code', (tester) async {
      final requests = <Uri>[];
      final api = ErpApi(
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response('{"count":0,"results":[]}', 200);
        }),
      );
      addTearDown(api.close);
      await tester.binding.setSurfaceSize(const Size(1280, 752));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: SalesShell(
            username: 'staff',
            section: SalesSection.forScannedCode(code),
            onNavigate: (_) {},
            onScan: null,
            onLogout: null,
            child: WorkspacePages(
              section: SalesSection.forScannedCode(code),
              api: api,
              employee: const LoginResult(
                token: 'test',
                employeeId: 1,
                username: 'staff',
                expiresAt: '2026-12-01',
              ),
              onNewOrder: () {},
              scannedCode: code,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabs = tester.widget<SalesTabs>(find.byType(SalesTabs));
      expect(tabs.labels[tabs.selected], tab);
      expect(tabs.labels, ['款号查询', '原订货单查询', '系统设置']);
      expect(find.text(code), findsOneWidget);
      expect(requests.single.path, path);
      expect(requests.single.queryParameters['search'], code);
    });
  }
}
