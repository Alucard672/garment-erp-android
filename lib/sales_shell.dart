import 'package:flutter/material.dart';

import 'record_pages.dart';
import 'sales_theme.dart';

enum SalesSection {
  home('首页'),
  products('款号'),
  customers('客户档案'),
  customerReceivables('客户账款'),
  suppliers('供应商档案'),
  supplierPayables('厂家账款'),
  orders('客户订单'),
  fulfillment('销售开单'),
  purchase('采购单'),
  returns('退货管理'),
  inventory('库存管理'),
  production('生产跟单'),
  staff('配货职工'),
  styleLookup('款号查询'),
  orderLookup('原订货单查询'),
  settings('系统设置');

  const SalesSection(this.label);
  final String label;

  static final _orderCode = RegExp(r'^SO-[0-9A-F]{14}$', caseSensitive: false);

  static SalesSection forScannedCode(String code) =>
      _orderCode.hasMatch(code) ? orderLookup : styleLookup;
}

enum _SalesMenu {
  products('商品中心', Icons.checkroom_outlined, [SalesSection.products]),
  production('生产', Icons.factory_outlined, [
    SalesSection.production,
    SalesSection.purchase,
  ]),
  orders('客户订单', Icons.assignment_outlined, [SalesSection.orders]),
  sales('销售开单', Icons.receipt_long_outlined, [SalesSection.fulfillment]),
  returns('退货管理', Icons.assignment_return_outlined, [SalesSection.returns]),
  inventory('入库与发货', Icons.warehouse_outlined, [SalesSection.inventory]),
  masterData('基础信息', Icons.people_outline, [
    SalesSection.customers,
    SalesSection.suppliers,
    SalesSection.customerReceivables,
    SalesSection.supplierPayables,
    SalesSection.staff,
  ]),
  workspace('工作台', Icons.dashboard_outlined, [
    SalesSection.styleLookup,
    SalesSection.orderLookup,
    SalesSection.settings,
  ]);

  const _SalesMenu(this.label, this.icon, this.sections);
  final String label;
  final IconData icon;
  final List<SalesSection> sections;

  static _SalesMenu? of(SalesSection section) => section == SalesSection.home
      ? null
      : values.firstWhere((menu) => menu.sections.contains(section));
}

class SalesShell extends StatelessWidget {
  const SalesShell({
    super.key,
    required this.username,
    required this.section,
    required this.onNavigate,
    required this.onScan,
    required this.onLogout,
    required this.child,
    this.updateNotice,
    this.orderHeader,
  });

  final String username;
  final SalesSection section;
  final ValueChanged<SalesSection> onNavigate;
  final VoidCallback? onScan;
  final VoidCallback? onLogout;
  final Widget child;
  final Widget? updateNotice;
  final ({String title, String backLabel, VoidCallback? onBack})? orderHeader;

  @override
  Widget build(BuildContext context) {
    final menu = _SalesMenu.of(section);
    final header = orderHeader;
    return Scaffold(
      backgroundColor: salesPaper,
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 128,
              child: ColoredBox(
                color: salesRail,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: const SalesBrand(compact: true),
                    ),
                    const Divider(height: 1, color: salesRailDivider),
                    Expanded(
                      child: _SalesNavigation(
                        section: section,
                        onNavigate: onNavigate,
                      ),
                    ),
                    const Divider(height: 1, color: salesRailDivider),
                    _account(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (menu != null && menu.sections.length > 1)
                    SalesTabs(
                      labels: [for (final item in menu.sections) item.label],
                      selected: menu.sections.indexOf(section),
                      onSelect: (index) => onNavigate(menu.sections[index]),
                    ),
                  Expanded(
                    child: WorkspaceDetails(
                      section: section,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (header != null || menu == null)
                            Container(
                              constraints: const BoxConstraints(minHeight: 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: salesLine),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (header != null)
                                    TextButton(
                                      onPressed: header.onBack,
                                      child: Text(header.backLabel),
                                    ),
                                  Expanded(
                                    child: Text(
                                      header?.title ?? '销售工作台',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (menu == null)
                                    OutlinedButton.icon(
                                      onPressed: onScan,
                                      icon: const Icon(
                                        Icons.qr_code_scanner,
                                        size: 16,
                                      ),
                                      label: const Text('扫码'),
                                    ),
                                ],
                              ),
                            ),
                          ?updateNotice,
                          Expanded(
                            child: ColoredBox(color: salesCanvas, child: child),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _account() => PopupMenuButton<bool>(
    tooltip: '员工账号菜单',
    enabled: onLogout != null,
    onSelected: (_) => onLogout?.call(),
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: true,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.logout, size: 18),
          title: Text('退出登录'),
        ),
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 11,
            backgroundColor: salesPrimary,
            foregroundColor: salesPaper,
            child: Icon(Icons.person_outline, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: salesInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  '员工账号',
                  style: TextStyle(color: salesRailText, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.expand_more, color: salesRailText, size: 16),
        ],
      ),
    ),
  );
}

class _SalesNavigation extends StatelessWidget {
  const _SalesNavigation({required this.section, required this.onNavigate});

  final SalesSection section;
  final ValueChanged<SalesSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final active = _SalesMenu.of(section);
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          _row(
            SalesSection.home.label,
            Icons.home_outlined,
            active == null,
            () => onNavigate(SalesSection.home),
          ),
          for (final menu in _SalesMenu.values) ...[
            const SizedBox(height: 4),
            _row(menu.label, menu.icon, active == menu, () {
              if (active != menu) onNavigate(menu.sections.first);
            }),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, IconData icon, bool selected, VoidCallback onTap) {
    final foreground = selected ? salesPrimary : salesRailText;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? salesRailSelection : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const salesRailDivider = salesLine;
