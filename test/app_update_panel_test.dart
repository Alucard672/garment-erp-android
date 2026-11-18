import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/app_update_notice.dart';
import 'package:garment_erp_android/app_update_panel.dart';

void main() {
  testWidgets('shows new release in the workbench and opens the update page', (
    tester,
  ) async {
    const channel = MethodChannel('garment_erp/app_updates');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'probe');
      return {'name': '0.1.2', 'code': 3, 'bytes': 1200};
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppUpdateNotice(
            visible: true,
            updateUrl: 'https://updates.example.com/latest.json',
            onOpen: () => opened++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('发现新版 0.1.2'), findsOneWidget);
    await tester.tap(find.text('查看更新'));
    expect(opened, 1);
    await tester.tap(find.byTooltip('稍后更新'));
    await tester.pumpAndSettle();
    expect(find.text('发现新版 0.1.2'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('downloads once and opens installer after saving the draft', (
    tester,
  ) async {
    const channel = MethodChannel('garment_erp/app_updates');
    const url = 'https://updates.example.com/erp/latest.json';
    final calls = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    var installAttempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'version':
          return {'name': '0.1.0', 'code': 1};
        case 'check':
          expect(call.arguments, {'url': url});
          return {'name': '0.1.1', 'code': 2, 'bytes': 12 * 1048576};
        case 'download':
          return null;
        case 'install':
          return ++installAttempts > 1;
        default:
          throw MissingPluginException();
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppUpdatePanel(
            updateUrl: url,
            beforeInstall: () async => calls.add('save-draft'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('当前版本 0.1.0（1）'), findsOneWidget);
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下载并安装'));
    await tester.pumpAndSettle();
    expect(find.textContaining('允许此来源'), findsOneWidget);
    await tester.tap(find.text('安装更新'));
    await tester.pumpAndSettle();
    expect(find.text('请在 Android 安装页面确认。'), findsOneWidget);
    expect(calls, [
      'version',
      'check',
      'download',
      'save-draft',
      'install',
      'save-draft',
      'install',
    ]);
  });
}
