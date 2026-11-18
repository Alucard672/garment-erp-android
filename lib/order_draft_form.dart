import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'draft.dart';
import 'generated/api_schema.dart';
import 'record_pages.dart';
import 'sales_fields.dart';
import 'sales_amount.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';
import 'shipment_settlement.dart';
import 'size_matrix.dart';

class OrderDraftForm extends StatelessWidget {
  const OrderDraftForm({
    super.key,
    required this.draft,
    this.stylePhoto,
    this.direct = false,
    this.onPickWarehouse,
    this.onPickClerk,
    this.onClearClerk,
    required this.onPickCustomer,
    required this.onPickDueDate,
    required this.onPickPaymentMethod,
    required this.onAddProduct,
    required this.onQuantityChanged,
    this.onRemoveSku,
    this.onRemoveStyle,
    this.onNotesChanged,
    this.onLineNotesChanged,
    this.onAddSpecial,
    this.onEditSpecial,
    this.onRemoveSpecial,
    this.onPaidChanged,
    this.onWriteOff,
  });

  final OrderDraft draft;
  final Widget Function(StyleDetail)? stylePhoto;
  final bool direct;
  final VoidCallback? onPickWarehouse;
  final VoidCallback? onPickClerk;
  final VoidCallback? onClearClerk;
  final VoidCallback? onPickCustomer;
  final ValueChanged<BuildContext>? onPickDueDate;
  final VoidCallback? onPickPaymentMethod;
  final VoidCallback? onAddProduct;
  final void Function(int, int) onQuantityChanged;
  final void Function(StyleDetail, Sku)? onRemoveSku;
  final ValueChanged<StyleDetail>? onRemoveStyle;
  final ValueChanged<String>? onNotesChanged;
  final void Function(int, String)? onLineNotesChanged;
  final VoidCallback? onAddSpecial;
  final ValueChanged<int>? onEditSpecial;
  final ValueChanged<int>? onRemoveSpecial;
  final ValueChanged<String>? onPaidChanged;
  final VoidCallback? onWriteOff;

  @override
  Widget build(BuildContext context) {
    final customer = draft.customer;
    final clerk = draft.clerk;
    final warehouse = draft.warehouse;
    final lines = direct
        ? draft.selectedLines.toList()
        : const <({StyleDetail style, Sku sku})>[];
    final count = direct ? lines.length : draft.styles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = TabletFilterPanel.gap;
            final width = constraints.maxWidth;
            final columns = width >= 800
                ? 5
                : width >= 650
                ? 3
                : width >= 420
                ? 2
                : 1;
            final fieldWidth = (width - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final field in [
                  SalesChoiceField(
                    compact: true,
                    label: '客户',
                    value: customer == null
                        ? '选择客户'
                        : '${customer.code}  ${customer.name}',
                    selected: customer != null,
                    icon: Icons.expand_more,
                    onTap: onPickCustomer,
                  ),
                  if (direct)
                    SalesChoiceField(
                      compact: true,
                      label: '发货仓库',
                      value: warehouse == null
                          ? '选择仓库'
                          : '${warehouse.code}  ${warehouse.name}',
                      selected: warehouse != null,
                      icon: Icons.expand_more,
                      onTap: onPickWarehouse,
                    )
                  else
                    Builder(
                      builder: (anchor) => SalesChoiceField(
                        compact: true,
                        label: '约定交期',
                        value: draft.dueDate ?? '选择日期',
                        selected: draft.dueDate != null,
                        icon: Icons.event_outlined,
                        onTap: onPickDueDate == null
                            ? null
                            : () => onPickDueDate!(anchor),
                      ),
                    ),
                  SalesChoiceField(
                    compact: true,
                    label: '付款方式',
                    value: draft.paymentMethod?.label ?? '未指定',
                    selected: draft.paymentMethod != null,
                    icon: Icons.expand_more,
                    onTap: onPickPaymentMethod,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SalesChoiceField(
                          compact: true,
                          label: direct ? '经手人' : '店员',
                          value: clerk == null
                              ? '未选择'
                              : clerk.name.isEmpty
                              ? clerk.username
                              : clerk.name,
                          selected: clerk != null,
                          icon: Icons.expand_more,
                          onTap: onPickClerk,
                        ),
                      ),
                      if (clerk != null && onClearClerk != null)
                        IconButton(
                          onPressed: onClearClerk,
                          tooltip: direct ? '清除经手人' : '清除店员',
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                  SalesNoteField(
                    key: ObjectKey(draft),
                    compact: true,
                    initialValue: draft.notes,
                    onChanged: onNotesChanged,
                  ),
                ])
                  SizedBox(width: fieldWidth, child: field),
              ],
            );
          },
        ),
        if (direct)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ShipmentSettlement(
              total: draft.estimatedAmount,
              paid: draft.pendingShipment?.paidAmount ?? draft.paidAmount,
              method: draft.paymentMethod,
              onPaidChanged: onPaidChanged,
              onWriteOff: onWriteOff,
            ),
          ),
        const SizedBox(height: 3),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          children: [
            Text.rich(
              TextSpan(
                text: '商品明细',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  if (count > 0)
                    TextSpan(
                      text: direct ? '  $count 条规格' : '  $count 款',
                      style: const TextStyle(
                        color: salesMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                if (!direct && onWriteOff != null)
                  TabletAction('核销客户账款', onPressed: onWriteOff),
                if (onAddSpecial != null)
                  TabletAction('特殊货品', onPressed: onAddSpecial),
                TabletAction(
                  direct ? '添加货品' : '添加款式',
                  icon: Icons.add,
                  onPressed: onAddProduct,
                ),
              ],
            ),
          ],
        ),
        if (count == 0 && draft.specialLines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              direct ? '请选择货品、颜色和尺码，逐条录入数量。' : '添加款式后，按颜色和尺码录入数量。',
              style: const TextStyle(color: salesMuted),
            ),
          )
        else if (direct && lines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: _skuTable(lines),
          )
        else
          for (final style in draft.styles)
            Padding(
              key: ValueKey(style.id),
              padding: const EdgeInsets.only(top: 3),
              child: _styleCard(style),
            ),
        if (draft.specialLines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: SalesPanel(
              child: SalesGrid(
                columns: const [
                  (title: '特殊货品', width: 235),
                  (title: '数量', width: 58),
                  (title: '销售价', width: 90),
                  (title: '小计', width: 90),
                  (title: '操作', width: 112),
                ],
                rows: [
                  for (final (index, line) in draft.specialLines.indexed)
                    [
                      Text(line.specialName ?? ''),
                      Text('${line.quantity}'),
                      Text('¥${line.unitPrice}'),
                      Text(
                        '¥${formatSalesDocumentAmount([(unitPrice: line.unitPrice, quantity: line.quantity)])}',
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: '编辑特殊货品',
                            onPressed: onEditSpecial == null
                                ? null
                                : () => onEditSpecial!(index),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton(
                            tooltip: '移除特殊货品',
                            onPressed: onRemoveSpecial == null
                                ? null
                                : () => onRemoveSpecial!(index),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _styleCard(StyleDetail style) {
    final subtotal = <String, int>{};
    var count = 0;
    for (final sku in style.skus) {
      final quantity = draft.quantities[sku.id] ?? 0;
      if (quantity == 0) continue;
      subtotal.update(
        sku.size,
        (value) => value + quantity,
        ifAbsent: () => quantity,
      );
      count += quantity;
    }
    final prices = style.skus.map((sku) => draft.unitPrice(style, sku)).toSet();
    final price = prices.length > 1 ? '按规格定价' : prices.firstOrNull ?? '未设置';
    return SalesPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            child: Row(
              children: [
                if (stylePhoto?.call(style) case final photo?) ...[
                  photo,
                  const SizedBox(width: 8),
                ],
                Container(
                  constraints: const BoxConstraints(maxWidth: 104),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: salesTint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    style.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: salesPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    style.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (onRemoveStyle != null)
                  IconButton(
                    onPressed: () => onRemoveStyle!(style),
                    tooltip: '移除 ${style.code}',
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
          ),
          SizeMatrix(
            style: style,
            quantities: draft.quantities,
            lineNotes: draft.lineNotes,
            editable: !draft.hasPending,
            onNoteChanged: onLineNotesChanged,
            onChanged: onQuantityChanged,
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: salesLine)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    draft.pending?.unitPrice == null
                        ? '销售价（元）  $price'
                        : '待确认销售价（元）  ${draft.pending!.unitPrice}',
                  ),
                  Semantics(
                    label: '尺码合计',
                    child: Wrap(
                      spacing: 9,
                      runSpacing: 3,
                      children: [
                        for (final entry in subtotal.entries)
                          Text('${entry.key} ${entry.value}'),
                        Text(
                          '共 $count 件',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skuTable(List<({StyleDetail style, Sku sku})> lines) {
    final shownPhotos = <int>{};
    return SalesPanel(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: SalesGrid(
          compact: true,
          columns: const [
            (title: '图片', width: 52),
            (title: '款号 / 商品', width: 192),
            (title: '颜色', width: 76),
            (title: '尺码', width: 60),
            (title: '数量', width: 96),
            (title: '销售价（元）', width: 100),
            (title: '小计（元）', width: 100),
            (title: '规格备注', width: 139),
            (title: '操作', width: 62),
          ],
          rowKeys: [for (final (:sku, style: _) in lines) ValueKey(sku.id)],
          rows: [
            for (final (index, (:style, :sku)) in lines.indexed)
              _skuCells(index, style, sku, shownPhotos.add(style.id)),
          ],
        ),
      ),
    );
  }

  List<Widget> _skuCells(
    int index,
    StyleDetail style,
    Sku sku,
    bool showPhoto,
  ) {
    final quantity = draft.quantities[sku.id] ?? 0;
    final label = '${style.code} ${sku.color} / ${sku.size}';
    return [
      if (showPhoto)
        stylePhoto?.call(style) ?? const SizedBox.shrink()
      else
        const SizedBox.shrink(),
      Tooltip(
        message: '${style.code} ${style.name}',
        child: Text(
          '${style.code}  ${style.name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      Text(sku.color),
      Text(sku.size),
      FocusTraversalOrder(
        order: NumericFocusOrder(index.toDouble()),
        child: Semantics(
          label: '$label 数量',
          child: TextFormField(
            key: ValueKey(('quantity', sku.id)),
            initialValue: quantity > 0 ? '$quantity' : '',
            enabled: !draft.hasPending,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.center,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '0',
              counterText: '',
              fillColor: quantity > 0 ? salesTint : salesPaper,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 6,
              ),
              constraints: const BoxConstraints(minHeight: 44),
            ),
            onChanged: (text) =>
                onQuantityChanged(sku.id, int.tryParse(text) ?? 0),
          ),
        ),
      ),
      Text(draft.unitPrice(style, sku) ?? '未设置'),
      Text(draft.lineAmount(style, sku) ?? '—'),
      Semantics(
        label: '$label 备注',
        child: TextFormField(
          key: ValueKey(('sku-note', sku.id)),
          initialValue: draft.lineNotes[sku.id] ?? '',
          enabled: onLineNotesChanged != null && !draft.hasPending,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: '选填',
            counterText: '',
            contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            constraints: BoxConstraints(minHeight: 44),
          ),
          onChanged: onLineNotesChanged == null
              ? null
              : (text) => onLineNotesChanged!(sku.id, text),
        ),
      ),
      IconButton(
        onPressed: onRemoveSku == null ? null : () => onRemoveSku!(style, sku),
        tooltip: '移除 $label',
        icon: const Icon(Icons.close, size: 18),
      ),
    ];
  }
}
