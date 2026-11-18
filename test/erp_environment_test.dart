import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/api.dart';
import 'package:garment_erp_android/draft.dart';
import 'package:garment_erp_android/erp_environment.dart';
import 'package:garment_erp_android/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('the known test server is available over HTTPS in all builds', () {
    const testServer = 'https://121.43.167.158';
    final debug = ErpEnvironments(
      debug: true,
      defaultUrl: 'http://10.0.2.2:8001',
    );
    expect(debug.urlFor(ErpEnvironment.test), testServer);

    final release = ErpEnvironments(debug: false, defaultUrl: testServer);
    expect(release.initial, ErpEnvironment.test);
    expect(release.urlFor(ErpEnvironment.test), testServer);
    expect(release.urlFor(ErpEnvironment.production), isNull);
  });

  test('the direct test server uses the existing tunnel storage keys', () {
    final api = ErpApi(baseUrl: 'https://121.43.167.158');
    addTearDown(api.close);
    expect(api.storageServerKey, 'http://127.0.0.1:8080');
  });

  test('build addresses distinguish the test tunnel from HTTPS production', () {
    final debug = ErpEnvironments(
      debug: true,
      defaultUrl: 'http://127.0.0.1:8080',
      productionUrl: 'http://production.invalid',
    );
    expect(debug.initial, ErpEnvironment.test);
    expect(debug.urlFor(ErpEnvironment.local), 'http://10.0.2.2:8001');
    expect(debug.urlFor(ErpEnvironment.test), 'http://127.0.0.1:8080');
    expect(debug.urlFor(ErpEnvironment.production), isNull);

    final release = ErpEnvironments(
      debug: false,
      defaultUrl: 'https://erp.example.com',
      testUrl: 'https://test.example.com',
    );
    expect(release.initial, ErpEnvironment.production);
    expect(release.urlFor(ErpEnvironment.local), isNull);
    expect(release.urlFor(ErpEnvironment.test), 'https://test.example.com');
    expect(
      release.urlFor(ErpEnvironment.production),
      'https://erp.example.com',
    );
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
  });

  test('API and drafts are scoped to the selected server', () async {
    const local = 'https://local.example.com';
    const test = 'https://test.example.com';
    final api = ErpApi(
      baseUrl: test,
      client: MockClient((request) async {
        expect(request.url.origin, test);
        expect(request.url.path, '/api/v1/auth/login/');
        return http.Response(
          '{"token":"test", "employee_id":3, "username":"staff", "expires_at":"2026-12-01"}',
          200,
        );
      }),
    );
    addTearDown(api.close);
    await api.login('staff', 'fixture');
    final localDraft = DraftStorage(3, serverUrl: local);
    final testDraft = DraftStorage(3, serverUrl: test);
    await localDraft.write(OrderDraft(notes: 'local'));
    await testDraft.write(OrderDraft(notes: 'test'));
    expect((await localDraft.read()).notes, 'local');
    expect((await testDraft.read()).notes, 'test');
  });

  testWidgets('eleventh logo tap unlocks and persists environment switching', (
    tester,
  ) async {
    await tester.pumpWidget(const ErpApp());
    await tester.pumpAndSettle();
    final scrollContext = tester.element(find.byType(SingleChildScrollView));
    const scrollChild = SizedBox.shrink();
    expect(
      ScrollConfiguration.of(scrollContext).buildOverscrollIndicator(
        scrollContext,
        scrollChild,
        const ScrollableDetails(direction: AxisDirection.down),
      ),
      same(scrollChild),
    );
    final logo = find.byKey(const ValueKey('login-logo'));
    expect(
      find.descendant(of: logo, matching: find.text('简上服饰')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: logo, matching: find.byType(Image)),
      findsOneWidget,
    );
    for (var i = 0; i < 10; i++) {
      await tester.tap(logo);
    }
    expect(find.text('切换环境'), findsNothing);
    await tester.tap(logo);
    await tester.pumpAndSettle();
    expect(find.text('切换环境'), findsOneWidget);
    expect(find.widgetWithText(ListTile, '正式环境'), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.widgetWithText(ListTile, '正式环境')).enabled,
      isFalse,
    );
    await tester.tap(find.widgetWithText(ListTile, '测试环境'));
    await tester.pumpAndSettle();
    expect(find.text('当前环境 · 测试环境'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ErpApp());
    await tester.pumpAndSettle();
    expect(find.text('当前环境 · 测试环境'), findsOneWidget);
  });
}
