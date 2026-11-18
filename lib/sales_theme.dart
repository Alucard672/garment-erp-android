import 'package:flutter/material.dart';

const brandName = '简上服饰';

// TDesign brandColor7, shared by the Material shell and TDesign controls.
const salesPrimary = Color(0xff0052d9);
const salesCanvas = Color(0xfff4f6fb);
const salesPaper = Color(0xffffffff);
const salesSidebar = salesPaper;
const salesRail = Color(0xffedf1f8);
const salesRailText = Color(0xff4b5b77);
const salesRailSelection = Color(0xffd9e3f6);
const salesInk = Color(0xff202c43);
const salesMuted = Color(0xff526078);
const salesLine = Color(0xffd3dce9);
const salesTint = Color(0xffe7edf9);
const salesTableHeader = Color(0xfff3f4f6);
const salesTableAlternate = Color(0xfff7f9fd);
const salesWarningSurface = Color(0xfffbefd9);
const salesWarning = Color(0xff775016);

enum SalesDocumentStatus {
  waiting('待发货', Color(0xfffff4d9), salesWarning),
  partial('部分发货', Color(0xffe8effc), Color(0xff35538a)),
  fulfilled('已发齐', Color(0xffe8f4ed), Color(0xff276348)),
  posted('已过账', Color(0xffeff2f8), salesMuted);

  const SalesDocumentStatus(this.label, this.surface, this.ink);

  final String label;
  final Color surface;
  final Color ink;
}

class SalesPanel extends StatelessWidget {
  const SalesPanel({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: salesPaper,
      border: Border.all(color: salesLine),
      borderRadius: BorderRadius.circular(6),
    ),
    clipBehavior: Clip.antiAlias,
    child: padding == null ? child : Padding(padding: padding!, child: child),
  );
}

class SalesBrand extends StatelessWidget {
  const SalesBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset(
        'assets/branding/app-logo.png',
        width: compact ? 32 : 60,
        height: compact ? 32 : 60,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
      SizedBox(width: compact ? 4 : 12),
      Expanded(
        child: Text(
          brandName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: salesInk,
            fontSize: compact ? 13 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
