import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/password_settings.dart';
import 'package:garment_erp_android/tablet_filter_panel.dart';

void main() {
  testWidgets('validates confirmation and submits once while saving', (
    tester,
  ) async {
    final pending = Completer<void>();
    final submissions = <List<String>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PasswordSettingsPanel(
              onChange: (current, next) {
                submissions.add([current, next]);
                return pending.future;
              },
            ),
          ),
        ),
      ),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'old password');
    await tester.enterText(fields.at(1), 'new password');
    await tester.enterText(fields.at(2), 'other password');
    await tester.tap(find.byType(TabletAction));
    await tester.pump();
    expect(find.text('两次输入的新密码不一致。'), findsOneWidget);
    expect(submissions, isEmpty);
    await tester.enterText(fields.at(2), 'new password');
    await tester.tap(find.byType(TabletAction));
    await tester.pump();
    expect(
      tester.widget<TabletAction>(find.byType(TabletAction)).onPressed,
      isNull,
    );
    expect(
      submissions,
      equals([
        ['old password', 'new password'],
      ]),
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(fields.first).controller!.text, isEmpty);
  });
}
