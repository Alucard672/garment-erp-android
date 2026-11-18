import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/wheel_date.dart';

void main() {
  testWidgets('日期弹窗在屏幕内，滚轮关闭后回填，点外部取消，支持清空', (tester) async {
    final controller = TextEditingController(text: '2024-02-28');
    final changes = <String>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 130,
              child: WheelDateInput(
                label: '日期',
                controller: controller,
                decoration: const InputDecoration(),
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final picker = find.byType(CupertinoDatePicker);
    expect(
      tester.getBottomRight(picker).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
    final days = find
        .descendant(of: picker, matching: find.byType(ListWheelScrollView))
        .last;
    await tester.drag(days, const Offset(0, -32));
    await tester.pumpAndSettle();
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(changes, ['2024-02-29']);
    expect(controller.text, '2024-02-29');

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.drag(days, const Offset(0, 32));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(controller.text, '2024-02-29');
    await tester.tap(find.byTooltip('清空日期'));
    await tester.pumpAndSettle();
    expect(changes, ['2024-02-29', '']);
  });
}
