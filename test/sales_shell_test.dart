import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/sales_shell.dart';

void main() {
  testWidgets('menu labels fit the compact landscape sidebar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 460));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SalesShell(
          username: 'staff',
          section: SalesSection.home,
          onNavigate: (_) {},
          onScan: null,
          onLogout: null,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    final inventory = tester.renderObject<RenderParagraph>(find.text('入库与发货'));
    expect(inventory.didExceedMaxLines, isFalse);
  });

  testWidgets('pages outside the home screen have no scan button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SalesShell(
          username: 'staff',
          section: SalesSection.orders,
          onNavigate: (_) {},
          onScan: () {},
          onLogout: null,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.widgetWithText(OutlinedButton, '扫码'), findsNothing);
  });

  testWidgets('secondary destinations share a row above the workspace', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(997, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var section = SalesSection.purchase;
    late StateSetter changeSection;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            changeSection = setState;
            return SalesShell(
              username: 'staff',
              section: section,
              onNavigate: (next) => setState(() => section = next),
              onScan: null,
              onLogout: null,
              child: const SizedBox.shrink(),
            );
          },
        ),
      ),
    );

    final salesMenu = find.text('生产');
    final sales = find.text('采购单');
    expect(salesMenu, findsOneWidget);
    expect(sales, findsOneWidget);

    await tester.tap(salesMenu);
    await tester.pumpAndSettle();
    expect(sales, findsOneWidget);
    expect(tester.getCenter(sales).dy, tester.getCenter(find.text('生产跟单')).dy);
    expect(
      tester.getTopLeft(sales).dx,
      greaterThan(tester.getTopRight(salesMenu).dx),
    );
    expect(section, SalesSection.purchase);

    await tester.tap(find.text('商品中心'));
    await tester.pumpAndSettle();
    expect(sales, findsNothing);
    expect(find.text('商品中心'), findsOneWidget);
    expect(section, SalesSection.products);

    await tester.tap(salesMenu);
    await tester.pumpAndSettle();
    expect(section, SalesSection.production);
    await tester.tap(find.text('退货管理'));
    await tester.pumpAndSettle();
    expect(section, SalesSection.returns);

    changeSection(() => section = SalesSection.purchase);
    await tester.pumpAndSettle();
    expect(sales, findsOneWidget);
    expect(
      find.ancestor(
        of: sales,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.selected == true,
        ),
      ),
      findsOneWidget,
    );
  });
}
