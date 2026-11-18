import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'generated/api_schema.dart';
import 'sales_amount.dart';

class OrderDraft {
  OrderDraft({
    this.customer,
    List<StyleDetail>? styles,
    this.dueDate,
    this.warehouse,
    this.clerk,
    this.paymentMethod,
    this.paidAmount = '',
    List<OrderItemWrite>? specialLines,
    this.notes = '',
    Map<int, String>? lineNotes,
    this.pending,
    this.pendingShipment,
    Map<int, int>? quantities,
  }) : styles = [...?styles],
       specialLines = [...?specialLines],
       quantities = quantities ?? {},
       lineNotes = lineNotes ?? {};

  Customer? customer;
  final List<StyleDetail> styles;
  String? dueDate;
  WarehouseRead? warehouse;
  StaffRead? clerk;
  PaymentMethod? paymentMethod;
  String paidAmount;
  final List<OrderItemWrite> specialLines;
  String notes;
  final Map<int, String> lineNotes;
  OrderWrite? pending;
  DirectShipmentWrite? pendingShipment;
  final Map<int, int> quantities;

  bool get hasPending => pending != null || pendingShipment != null;
  bool get hasLines => styles.isNotEmpty || specialLines.isNotEmpty;
  int get total =>
      quantities.values.fold(0, (sum, quantity) => sum + quantity) +
      specialLines.fold(0, (sum, line) => sum + line.quantity);

  Iterable<({StyleDetail style, Sku sku})> get selectedLines sync* {
    final selected = {...quantities.keys, ...lineNotes.keys};
    for (final style in styles) {
      for (final sku in style.skus) {
        if (selected.contains(sku.id)) yield (style: style, sku: sku);
      }
    }
  }

  String? unitPrice(StyleDetail style, Sku sku) =>
      pending?.unitPrice ?? style.salePrice ?? sku.wholesalePrice;

  String? lineAmount(StyleDetail style, Sku sku) => formatSalesDocumentAmount([
    (unitPrice: unitPrice(style, sku), quantity: quantities[sku.id] ?? 0),
  ]);

  String? get estimatedAmount => formatSalesDocumentAmount([
    for (final (:style, :sku) in selectedLines)
      if ((quantities[sku.id] ?? 0) > 0)
        (unitPrice: unitPrice(style, sku), quantity: quantities[sku.id]!),
    for (final line in specialLines)
      (unitPrice: line.unitPrice, quantity: line.quantity),
  ]);

  factory OrderDraft.decode(String input) {
    final json = jsonDecode(input) as Map<String, dynamic>;
    return OrderDraft(
      customer: json['customer'] == null
          ? null
          : Customer.fromJson(json['customer'] as Map<String, dynamic>),
      styles: switch (json['styles']) {
        final List<dynamic> stored => [
          for (final item in stored)
            StyleDetail.fromJson(item as Map<String, dynamic>),
        ],
        _ => [
          if (json['style'] case final Map<String, dynamic> legacy)
            StyleDetail.fromJson(legacy),
        ],
      },
      dueDate: json['due_date'] as String?,
      warehouse: json['warehouse'] == null
          ? null
          : WarehouseRead.fromJson(json['warehouse'] as Map<String, dynamic>),
      clerk: json['clerk'] == null
          ? null
          : StaffRead.fromJson(json['clerk'] as Map<String, dynamic>),
      paymentMethod: PaymentMethod.fromCode(json['payment_method'] as String?),
      paidAmount: json['paid_amount'] as String? ?? '',
      specialLines: [
        for (final item in json['special_lines'] as List<dynamic>? ?? const [])
          OrderItemWrite.fromJson(item as Map<String, dynamic>),
      ],
      notes: json['notes'] as String? ?? '',
      lineNotes: (json['line_notes'] as Map<String, dynamic>? ?? {}).map(
        (id, notes) => MapEntry(int.parse(id), notes as String),
      ),
      pending: json['pending'] == null
          ? null
          : OrderWrite.fromJson(json['pending'] as Map<String, dynamic>),
      pendingShipment: json['pending_shipment'] == null
          ? null
          : DirectShipmentWrite.fromJson(
              json['pending_shipment'] as Map<String, dynamic>,
            ),
      quantities: (json['quantities'] as Map<String, dynamic>).map(
        (id, quantity) => MapEntry(int.parse(id), quantity as int),
      ),
    );
  }

  String encode() => jsonEncode({
    'customer': customer?.toJson(),
    'styles': styles.map((style) => style.toJson()).toList(),
    'due_date': dueDate,
    'warehouse': warehouse?.toJson(),
    'clerk': clerk?.toJson(),
    'payment_method': paymentMethod?.code,
    'paid_amount': paidAmount,
    'special_lines': specialLines.map((item) => item.toJson()).toList(),
    'notes': notes,
    'line_notes': lineNotes.map((id, notes) => MapEntry(id.toString(), notes)),
    'pending': pending?.toJson(),
    'pending_shipment': pendingShipment?.toJson(),
    'quantities': quantities.map(
      (id, quantity) => MapEntry(id.toString(), quantity),
    ),
  });
}

class DraftStorage {
  DraftStorage(int employeeId, {required String serverUrl, bool direct = false})
    : _key = direct
          ? 'erp.draft.direct.v1.$serverUrl.$employeeId'
          : 'erp.draft.v1.$serverUrl.$employeeId';
  final String _key;
  final _preferences = SharedPreferencesAsync();

  Future<OrderDraft> read() async {
    final existing = await _preferences.getString(_key);
    return existing == null ? OrderDraft() : OrderDraft.decode(existing);
  }

  Future<void> write(OrderDraft draft) =>
      _preferences.setString(_key, draft.encode());
}
