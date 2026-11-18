import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/record_pages.dart';
import 'package:garment_erp_android/sales_shell.dart';

void main() {
  testWidgets('单据详情铺满工作区并保留左侧导航', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var section = SalesSection.orders;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, update) {
            return SalesShell(
              username: 'staff',
              section: section,
              onNavigate: (selected) => update(() => section = selected),
              onScan: null,
              onLogout: null,
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showRecordDetail(
                    context,
                    title: '订货单 SO-3',
                    expandInWorkspace: true,
                    child: const Text('单据明细'),
                  ),
                  child: const Text('展开单据'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('展开单据'));
    await tester.pumpAndSettle();
    expect(find.text('订货单 SO-3'), findsOneWidget);
    expect(find.text('单据明细'), findsOneWidget);
    expect(find.text('销售开单'), findsOneWidget);
    expect(find.text('展开单据'), findsNothing);
    expect(tester.getSize(find.byType(ListView).last).width, greaterThan(950));
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('单据明细'), findsNothing);
    expect(find.text('展开单据'), findsOneWidget);
    await tester.tap(find.text('展开单据'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    expect(find.text('单据明细'), findsNothing);
    expect(find.byTooltip('关闭'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
