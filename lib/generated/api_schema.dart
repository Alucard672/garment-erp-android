// Generated from openapi/schema.yaml. Do not edit.

abstract final class ApiPath {
  static const authLoginCreate = '/api/v1/auth/login/';
  static const authLogoutCreate = '/api/v1/auth/logout/';
  static const authPasswordCreate = '/api/v1/auth/password/';
  static const changeLogsList = '/api/v1/change-logs/';
  static const customersList = '/api/v1/customers/';
  static const customersCreate = '/api/v1/customers/';
  static String customersPartialUpdate(int id) => '/api/v1/customers/$id/';
  static String customersAvailabilityPartialUpdate(int id) =>
      '/api/v1/customers/$id/availability/';
  static String customersReceivableDetail(int id) =>
      '/api/v1/customers/$id/receivables/';
  static String customersRecordReceipt(int id) =>
      '/api/v1/customers/$id/receivables/';
  static const customersReceivablesList = '/api/v1/customers/receivables/';
  static const inventoryCountsList = '/api/v1/inventory-counts/';
  static const inventoryCountsCreate = '/api/v1/inventory-counts/';
  static String inventoryCountsRetrieve(int id) =>
      '/api/v1/inventory-counts/$id/';
  static const inventoryTransfersList = '/api/v1/inventory-transfers/';
  static const inventoryTransfersCreate = '/api/v1/inventory-transfers/';
  static String inventoryTransfersRetrieve(int id) =>
      '/api/v1/inventory-transfers/$id/';
  static const materialBalancesList = '/api/v1/material-balances/';
  static const materialMovementsList = '/api/v1/material-movements/';
  static String materialMovementsRetrieve(int id) =>
      '/api/v1/material-movements/$id/';
  static const materialMovementsIssueCreate =
      '/api/v1/material-movements/issue/';
  static const materialMovementsReceiveCreate =
      '/api/v1/material-movements/receive/';
  static const materialMovementsReturnCreate =
      '/api/v1/material-movements/return/';
  static const materialsList = '/api/v1/materials/';
  static const materialsCreate = '/api/v1/materials/';
  static String materialsRetrieve(int id) => '/api/v1/materials/$id/';
  static String materialsAccessoryOptionsUpdate(int id) =>
      '/api/v1/materials/$id/accessory-options/';
  static String materialsColorImagesRetrieve(int id, String imageId) =>
      '/api/v1/materials/$id/color-images/$imageId/';
  static String materialsColorsUpdate(int id) =>
      '/api/v1/materials/$id/colors/';
  static String materialsEditUpdate(int id) => '/api/v1/materials/$id/edit/';
  static String materialsImageRetrieve(int id) =>
      '/api/v1/materials/$id/image/';
  static const operationLogsList = '/api/v1/operation-logs/';
  static const ordersList = '/api/v1/orders/';
  static const ordersCreate = '/api/v1/orders/';
  static String ordersRetrieve(int id) => '/api/v1/orders/$id/';
  static String ordersAvailabilityRetrieve(int id) =>
      '/api/v1/orders/$id/availability/';
  static String ordersShipCreate(int id) => '/api/v1/orders/$id/ship/';
  static const positionsList = '/api/v1/positions/';
  static const positionsCreate = '/api/v1/positions/';
  static String positionsRetrieve(int id) => '/api/v1/positions/$id/';
  static String positionsPartialUpdate(int id) => '/api/v1/positions/$id/';
  static String positionsEmployeesList(int id) =>
      '/api/v1/positions/$id/employees/';
  static const positionsOptionsRetrieve = '/api/v1/positions/options/';
  static const processDispatchesList = '/api/v1/process-dispatches/';
  static const processDispatchesCreate = '/api/v1/process-dispatches/';
  static String processDispatchesRetrieve(int id) =>
      '/api/v1/process-dispatches/$id/';
  static const processReceiptsList = '/api/v1/process-receipts/';
  static const processReceiptsCreate = '/api/v1/process-receipts/';
  static String processReceiptsRetrieve(int id) =>
      '/api/v1/process-receipts/$id/';
  static const processingFactoriesList = '/api/v1/processing-factories/';
  static const processingFactoriesCreate = '/api/v1/processing-factories/';
  static String processingFactoriesRetrieve(int id) =>
      '/api/v1/processing-factories/$id/';
  static const productionDemandList = '/api/v1/production-demand/';
  static String productionDemandRetrieve(int id) =>
      '/api/v1/production-demand/$id/';
  static const productionNotesList = '/api/v1/production-notes/';
  static const productionNotesCreate = '/api/v1/production-notes/';
  static String productionNotesRetrieve(int id) =>
      '/api/v1/production-notes/$id/';
  static const productionOrdersList = '/api/v1/production-orders/';
  static const productionOrdersCreate = '/api/v1/production-orders/';
  static String productionOrdersRetrieve(int id) =>
      '/api/v1/production-orders/$id/';
  static const productionProcessesList = '/api/v1/production-processes/';
  static const productionProcessesCreate = '/api/v1/production-processes/';
  static String productionProcessesRetrieve(int id) =>
      '/api/v1/production-processes/$id/';
  static const purchasesList = '/api/v1/purchases/';
  static const purchasesCreate = '/api/v1/purchases/';
  static String purchasesRetrieve(int id) => '/api/v1/purchases/$id/';
  static const receiptsList = '/api/v1/receipts/';
  static const receiptsCreate = '/api/v1/receipts/';
  static String receiptsRetrieve(int id) => '/api/v1/receipts/$id/';
  static const returnsList = '/api/v1/returns/';
  static const returnsCreate = '/api/v1/returns/';
  static String returnsRetrieve(int id) => '/api/v1/returns/$id/';
  static const salesReturnsList = '/api/v1/sales-returns/';
  static const salesReturnsCreate = '/api/v1/sales-returns/';
  static String salesReturnsRetrieve(int id) => '/api/v1/sales-returns/$id/';
  static const salesSummaryRetrieve = '/api/v1/sales-summary/';
  static const shipmentsList = '/api/v1/shipments/';
  static String shipmentsRetrieve(int id) => '/api/v1/shipments/$id/';
  static const shipmentsDirectCreate = '/api/v1/shipments/direct/';
  static const staffList = '/api/v1/staff/';
  static String staffRetrieve(int id) => '/api/v1/staff/$id/';
  static String staffPositionsRetrieve(int id) =>
      '/api/v1/staff/$id/positions/';
  static String staffPositionsPartialUpdate(int id) =>
      '/api/v1/staff/$id/positions/';
  static const staffClerksList = '/api/v1/staff/clerks/';
  static const stockList = '/api/v1/stock/';
  static const stockMovementsList = '/api/v1/stock-movements/';
  static String stockMovementsRetrieve(int id) =>
      '/api/v1/stock-movements/$id/';
  static const stockSnapshotsList = '/api/v1/stock-snapshots/';
  static const storesList = '/api/v1/stores/';
  static const storesCreate = '/api/v1/stores/';
  static String storesRetrieve(int id) => '/api/v1/stores/$id/';
  static String storesPartialUpdate(int id) => '/api/v1/stores/$id/';
  static String storesAvailabilityPartialUpdate(int id) =>
      '/api/v1/stores/$id/availability/';
  static const styleDictionaryList = '/api/v1/style-dictionary/';
  static const styleDictionaryCreate = '/api/v1/style-dictionary/';
  static String styleDictionaryRetrieve(int id) =>
      '/api/v1/style-dictionary/$id/';
  static String styleDictionaryPartialUpdate(int id) =>
      '/api/v1/style-dictionary/$id/';
  static String styleDictionaryAvailabilityPartialUpdate(int id) =>
      '/api/v1/style-dictionary/$id/availability/';
  static const stylesList = '/api/v1/styles/';
  static const stylesCreate = '/api/v1/styles/';
  static String stylesRetrieve(int id) => '/api/v1/styles/$id/';
  static String stylesEditUpdate(int id) => '/api/v1/styles/$id/edit/';
  static String stylesImagesRetrieve(int id, String kind) =>
      '/api/v1/styles/$id/images/$kind/';
  static String stylesStyleImagesRetrieve(int id, String imageId) =>
      '/api/v1/styles/$id/style-images/$imageId/';
  static const stylesCatalogList = '/api/v1/styles/catalog/';
  static const suppliersList = '/api/v1/suppliers/';
  static const suppliersCreate = '/api/v1/suppliers/';
  static String suppliersRetrieve(int id) => '/api/v1/suppliers/$id/';
  static String suppliersPartialUpdate(int id) => '/api/v1/suppliers/$id/';
  static String suppliersAvailabilityPartialUpdate(int id) =>
      '/api/v1/suppliers/$id/availability/';
  static const warehousesList = '/api/v1/warehouses/';
  static const warehousesCreate = '/api/v1/warehouses/';
  static String warehousesRetrieve(int id) => '/api/v1/warehouses/$id/';
  static String warehousesPartialUpdate(int id) => '/api/v1/warehouses/$id/';
  static String warehousesAvailabilityPartialUpdate(int id) =>
      '/api/v1/warehouses/$id/availability/';
}

enum PaymentMethod {
  cash('cash', '现金'),
  wechat('wechat', '微信'),
  alipay('alipay', '支付宝'),
  card('card', '刷卡'),
  bankTransfer('bank_transfer', '汇款'),
  unpaid('unpaid', '未付');

  const PaymentMethod(this.code, this.label);
  final String code;
  final String label;

  static PaymentMethod? fromCode(String? code) {
    for (final method in values) {
      if (method.code == code) return method;
    }
    return null;
  }
}

class ApiError {
  const ApiError({
    required this.code,
    required this.detail,
    required this.requestId,
  });

  final String code;
  final String detail;
  final String requestId;

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
    code: json['code'] as String,
    detail: json['detail'] as String,
    requestId: json['request_id'] as String,
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'detail': detail,
    'request_id': requestId,
  };
}

class LoginRequest {
  const LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
    username: json['username'] as String,
    password: json['password'] as String,
  );

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class PasswordChange {
  const PasswordChange({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  factory PasswordChange.fromJson(Map<String, dynamic> json) => PasswordChange(
    currentPassword: json['current_password'] as String,
    newPassword: json['new_password'] as String,
  );

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };
}

class LoginResult {
  const LoginResult({
    required this.token,
    required this.employeeId,
    required this.username,
    required this.expiresAt,
  });

  final String token;
  final int employeeId;
  final String username;
  final String expiresAt;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    token: json['token'] as String,
    employeeId: json['employee_id'] as int,
    username: json['username'] as String,
    expiresAt: json['expires_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'employee_id': employeeId,
    'username': username,
    'expires_at': expiresAt,
  };
}

class Customer {
  const Customer({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.address,
    this.active,
  });

  final int id;
  final String code;
  final String name;
  final String? phone;
  final String? address;
  final bool? active;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    phone: json['phone'] == null ? null : json['phone'] as String,
    address: json['address'] == null ? null : json['address'] as String,
    active: json['active'] == null ? null : json['active'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'phone': phone,
    'address': address,
    'active': active,
  };
}

class CustomerReceivable {
  const CustomerReceivable({
    required this.id,
    required this.code,
    required this.name,
    required this.receivableAmount,
  });

  final int id;
  final String code;
  final String name;
  final String receivableAmount;

  factory CustomerReceivable.fromJson(Map<String, dynamic> json) =>
      CustomerReceivable(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        receivableAmount: json['receivable_amount'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'receivable_amount': receivableAmount,
  };
}

class Sku {
  const Sku({
    required this.id,
    required this.color,
    required this.size,
    this.wholesalePrice,
  });

  final int id;
  final String color;
  final String size;
  final String? wholesalePrice;

  factory Sku.fromJson(Map<String, dynamic> json) => Sku(
    id: json['id'] as int,
    color: json['color'] as String,
    size: json['size'] as String,
    wholesalePrice: json['wholesale_price'] == null
        ? null
        : json['wholesale_price'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'color': color,
    'size': size,
    'wholesale_price': wholesalePrice,
  };
}

class CustomerReceivableDetail {
  const CustomerReceivableDetail({
    required this.id,
    required this.code,
    required this.name,
    required this.receivableAmount,
    this.returnAmount,
    required this.shipments,
  });

  final int id;
  final String code;
  final String name;
  final String receivableAmount;
  final String? returnAmount;
  final List<ShipmentReceivable> shipments;

  factory CustomerReceivableDetail.fromJson(Map<String, dynamic> json) =>
      CustomerReceivableDetail(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        receivableAmount: json['receivable_amount'] as String,
        returnAmount: json['return_amount'] == null
            ? null
            : json['return_amount'] as String,
        shipments: (json['shipments'] as List<dynamic>)
            .map(
              (item) =>
                  ShipmentReceivable.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'receivable_amount': receivableAmount,
    'return_amount': returnAmount,
    'shipments': shipments.map((item) => item.toJson()).toList(),
  };
}

class ShipmentReceivable {
  const ShipmentReceivable({
    required this.id,
    required this.code,
    required this.orderCode,
    required this.postedAt,
    required this.receivableAmount,
    required this.settledAmount,
    required this.outstandingAmount,
  });

  final int id;
  final String code;
  final String orderCode;
  final String postedAt;
  final String receivableAmount;
  final String settledAmount;
  final String outstandingAmount;

  factory ShipmentReceivable.fromJson(Map<String, dynamic> json) =>
      ShipmentReceivable(
        id: json['id'] as int,
        code: json['code'] as String,
        orderCode: json['order_code'] as String,
        postedAt: json['posted_at'] as String,
        receivableAmount: json['receivable_amount'] as String,
        settledAmount: json['settled_amount'] as String,
        outstandingAmount: json['outstanding_amount'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'order_code': orderCode,
    'posted_at': postedAt,
    'receivable_amount': receivableAmount,
    'settled_amount': settledAmount,
    'outstanding_amount': outstandingAmount,
  };
}

class CustomerReceiptRead {
  const CustomerReceiptRead({
    required this.id,
    required this.code,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.receivedAt,
    required this.recordedByName,
    required this.allocations,
  });

  final int id;
  final String code;
  final int customerId;
  final String amount;
  final String paymentMethod;
  final String? notes;
  final String receivedAt;
  final String recordedByName;
  final List<ReceiptAllocation> allocations;

  factory CustomerReceiptRead.fromJson(Map<String, dynamic> json) =>
      CustomerReceiptRead(
        id: json['id'] as int,
        code: json['code'] as String,
        customerId: json['customer_id'] as int,
        amount: json['amount'] as String,
        paymentMethod: json['payment_method'] as String,
        notes: json['notes'] == null ? null : json['notes'] as String,
        receivedAt: json['received_at'] as String,
        recordedByName: json['recorded_by_name'] as String,
        allocations: (json['allocations'] as List<dynamic>)
            .map(
              (item) =>
                  ReceiptAllocation.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'customer_id': customerId,
    'amount': amount,
    'payment_method': paymentMethod,
    'notes': notes,
    'received_at': receivedAt,
    'recorded_by_name': recordedByName,
    'allocations': allocations.map((item) => item.toJson()).toList(),
  };
}

class CustomerReceiptWrite {
  const CustomerReceiptWrite({
    required this.requestKey,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.allocations,
  });

  final String requestKey;
  final String amount;
  final String paymentMethod;
  final String? notes;
  final List<ReceiptAllocation> allocations;

  factory CustomerReceiptWrite.fromJson(Map<String, dynamic> json) =>
      CustomerReceiptWrite(
        requestKey: json['request_key'] as String,
        amount: json['amount'] as String,
        paymentMethod: json['payment_method'] as String,
        notes: json['notes'] == null ? null : json['notes'] as String,
        allocations: (json['allocations'] as List<dynamic>)
            .map(
              (item) =>
                  ReceiptAllocation.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'request_key': requestKey,
    'amount': amount,
    'payment_method': paymentMethod,
    'notes': notes,
    'allocations': allocations.map((item) => item.toJson()).toList(),
  };
}

class ReceiptAllocation {
  const ReceiptAllocation({required this.shipmentId, required this.amount});

  final int shipmentId;
  final String amount;

  factory ReceiptAllocation.fromJson(Map<String, dynamic> json) =>
      ReceiptAllocation(
        shipmentId: json['shipment_id'] as int,
        amount: json['amount'] as String,
      );

  Map<String, dynamic> toJson() => {
    'shipment_id': shipmentId,
    'amount': amount,
  };
}

class Style {
  const Style({
    required this.id,
    required this.code,
    required this.name,
    this.category,
    this.composition,
    this.salePrice,
    this.hasStyleImage,
  });

  final int id;
  final String code;
  final String name;
  final String? category;
  final String? composition;
  final String? salePrice;
  final bool? hasStyleImage;

  factory Style.fromJson(Map<String, dynamic> json) => Style(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    category: json['category'] == null ? null : json['category'] as String,
    composition: json['composition'] == null
        ? null
        : json['composition'] as String,
    salePrice: json['sale_price'] == null ? null : json['sale_price'] as String,
    hasStyleImage: json['has_style_image'] == null
        ? null
        : json['has_style_image'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'category': category,
    'composition': composition,
    'sale_price': salePrice,
    'has_style_image': hasStyleImage,
  };
}

class StyleDetail {
  const StyleDetail({
    required this.id,
    required this.code,
    required this.name,
    this.category,
    this.composition,
    this.salePrice,
    this.hasStyleImage,
    this.active,
    required this.skus,
    this.specification,
  });

  final int id;
  final String code;
  final String name;
  final String? category;
  final String? composition;
  final String? salePrice;
  final bool? hasStyleImage;
  final bool? active;
  final List<Sku> skus;
  final StyleSpecificationRead? specification;

  factory StyleDetail.fromJson(Map<String, dynamic> json) => StyleDetail(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    category: json['category'] == null ? null : json['category'] as String,
    composition: json['composition'] == null
        ? null
        : json['composition'] as String,
    salePrice: json['sale_price'] == null ? null : json['sale_price'] as String,
    hasStyleImage: json['has_style_image'] == null
        ? null
        : json['has_style_image'] as bool,
    active: json['active'] == null ? null : json['active'] as bool,
    skus: (json['skus'] as List<dynamic>)
        .map((item) => Sku.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    specification: json['specification'] == null
        ? null
        : StyleSpecificationRead.fromJson(
            json['specification'] as Map<String, dynamic>,
          ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'category': category,
    'composition': composition,
    'sale_price': salePrice,
    'has_style_image': hasStyleImage,
    'active': active,
    'skus': skus.map((item) => item.toJson()).toList(),
    'specification': specification?.toJson(),
  };
}

class StyleSpecificationRead {
  const StyleSpecificationRead({
    this.revision,
    required this.bom,
    required this.measurements,
    required this.careLabel,
    this.profile,
    this.sizeTable,
    this.hasStyleImage,
    this.hasCareImage,
    this.styleImageIds,
  });

  final int? revision;
  final List<BomLineRead> bom;
  final List<Measurement> measurements;
  final CareLabel careLabel;
  final ProfileRead? profile;
  final List<SizeRowRead>? sizeTable;
  final bool? hasStyleImage;
  final bool? hasCareImage;
  final List<String>? styleImageIds;

  factory StyleSpecificationRead.fromJson(
    Map<String, dynamic> json,
  ) => StyleSpecificationRead(
    revision: json['revision'] == null ? null : json['revision'] as int,
    bom: (json['bom'] as List<dynamic>)
        .map((item) => BomLineRead.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    measurements: (json['measurements'] as List<dynamic>)
        .map((item) => Measurement.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    careLabel: CareLabel.fromJson(json['care_label'] as Map<String, dynamic>),
    profile: json['profile'] == null
        ? null
        : ProfileRead.fromJson(json['profile'] as Map<String, dynamic>),
    sizeTable: json['size_table'] == null
        ? null
        : (json['size_table'] as List<dynamic>)
              .map((item) => SizeRowRead.fromJson(item as Map<String, dynamic>))
              .toList(growable: false),
    hasStyleImage: json['has_style_image'] == null
        ? null
        : json['has_style_image'] as bool,
    hasCareImage: json['has_care_image'] == null
        ? null
        : json['has_care_image'] as bool,
    styleImageIds: json['style_image_ids'] == null
        ? null
        : (json['style_image_ids'] as List<dynamic>)
              .map((item) => item as String)
              .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'revision': revision,
    'bom': bom.map((item) => item.toJson()).toList(),
    'measurements': measurements.map((item) => item.toJson()).toList(),
    'care_label': careLabel.toJson(),
    'profile': profile?.toJson(),
    'size_table': sizeTable?.map((item) => item.toJson()).toList(),
    'has_style_image': hasStyleImage,
    'has_care_image': hasCareImage,
    'style_image_ids': styleImageIds,
  };
}

class BomLineRead {
  const BomLineRead({
    this.id,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    this.materialType,
    this.materialBaseUnit,
    this.supplierName,
    required this.unit,
    required this.quantity,
    this.lossRate,
    this.grossQuantity,
    this.remark,
    this.usagePart,
    this.usageCategory,
    this.garmentColor,
    this.materialColorCode,
  });

  final int? id;
  final int materialId;
  final String materialCode;
  final String materialName;
  final String? materialType;
  final String? materialBaseUnit;
  final String? supplierName;
  final String unit;
  final String quantity;
  final String? lossRate;
  final String? grossQuantity;
  final String? remark;
  final String? usagePart;
  final String? usageCategory;
  final String? garmentColor;
  final String? materialColorCode;

  factory BomLineRead.fromJson(Map<String, dynamic> json) => BomLineRead(
    id: json['id'] == null ? null : json['id'] as int,
    materialId: json['material_id'] as int,
    materialCode: json['material_code'] as String,
    materialName: json['material_name'] as String,
    materialType: json['material_type'] == null
        ? null
        : json['material_type'] as String,
    materialBaseUnit: json['material_base_unit'] == null
        ? null
        : json['material_base_unit'] as String,
    supplierName: json['supplier_name'] == null
        ? null
        : json['supplier_name'] as String,
    unit: json['unit'] as String,
    quantity: json['quantity'] as String,
    lossRate: json['loss_rate'] == null ? null : json['loss_rate'] as String,
    grossQuantity: json['gross_quantity'] == null
        ? null
        : json['gross_quantity'] as String,
    remark: json['remark'] == null ? null : json['remark'] as String,
    usagePart: json['usage_part'] == null ? null : json['usage_part'] as String,
    usageCategory: json['usage_category'] == null
        ? null
        : json['usage_category'] as String,
    garmentColor: json['garment_color'] == null
        ? null
        : json['garment_color'] as String,
    materialColorCode: json['material_color_code'] == null
        ? null
        : json['material_color_code'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'material_id': materialId,
    'material_code': materialCode,
    'material_name': materialName,
    'material_type': materialType,
    'material_base_unit': materialBaseUnit,
    'supplier_name': supplierName,
    'unit': unit,
    'quantity': quantity,
    'loss_rate': lossRate,
    'gross_quantity': grossQuantity,
    'remark': remark,
    'usage_part': usagePart,
    'usage_category': usageCategory,
    'garment_color': garmentColor,
    'material_color_code': materialColorCode,
  };
}

class Measurement {
  const Measurement({
    required this.size,
    required this.point,
    required this.value,
    this.tolerance,
  });

  final String size;
  final String point;
  final String value;
  final String? tolerance;

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
    size: json['size'] as String,
    point: json['point'] as String,
    value: json['value'] as String,
    tolerance: json['tolerance'] == null ? null : json['tolerance'] as String,
  );

  Map<String, dynamic> toJson() => {
    'size': size,
    'point': point,
    'value': value,
    'tolerance': tolerance,
  };
}

class CareLabel {
  const CareLabel({this.composition, this.care, this.remark});

  final String? composition;
  final String? care;
  final String? remark;

  factory CareLabel.fromJson(Map<String, dynamic> json) => CareLabel(
    composition: json['composition'] == null
        ? null
        : json['composition'] as String,
    care: json['care'] == null ? null : json['care'] as String,
    remark: json['remark'] == null ? null : json['remark'] as String,
  );

  Map<String, dynamic> toJson() => {
    'composition': composition,
    'care': care,
    'remark': remark,
  };
}

class ProfileRead {
  const ProfileRead({
    this.pieceWeightGrams,
    this.weightGradeGrams,
    this.weightBaseSize,
    this.weightSizeOrder,
    this.sizeWeights,
    this.weightAutoSizes,
    this.year,
    this.launchDate,
    this.remark,
    this.processInstructions,
    this.washProcess,
    this.precautions,
    this.attributes,
    this.personnel,
  });

  final String? pieceWeightGrams;
  final String? weightGradeGrams;
  final String? weightBaseSize;
  final List<String>? weightSizeOrder;
  final List<SizeWeight>? sizeWeights;
  final List<String>? weightAutoSizes;
  final int? year;
  final String? launchDate;
  final String? remark;
  final String? processInstructions;
  final String? washProcess;
  final String? precautions;
  final List<AttributeRead>? attributes;
  final List<PersonnelRead>? personnel;

  factory ProfileRead.fromJson(Map<String, dynamic> json) => ProfileRead(
    pieceWeightGrams: json['piece_weight_grams'] == null
        ? null
        : json['piece_weight_grams'] as String,
    weightGradeGrams: json['weight_grade_grams'] == null
        ? null
        : json['weight_grade_grams'] as String,
    weightBaseSize: json['weight_base_size'] == null
        ? null
        : json['weight_base_size'] as String,
    weightSizeOrder: json['weight_size_order'] == null
        ? null
        : (json['weight_size_order'] as List<dynamic>)
              .map((item) => item as String)
              .toList(growable: false),
    sizeWeights: json['size_weights'] == null
        ? null
        : (json['size_weights'] as List<dynamic>)
              .map((item) => SizeWeight.fromJson(item as Map<String, dynamic>))
              .toList(growable: false),
    weightAutoSizes: json['weight_auto_sizes'] == null
        ? null
        : (json['weight_auto_sizes'] as List<dynamic>)
              .map((item) => item as String)
              .toList(growable: false),
    year: json['year'] == null ? null : json['year'] as int,
    launchDate: json['launch_date'] == null
        ? null
        : json['launch_date'] as String,
    remark: json['remark'] == null ? null : json['remark'] as String,
    processInstructions: json['process_instructions'] == null
        ? null
        : json['process_instructions'] as String,
    washProcess: json['wash_process'] == null
        ? null
        : json['wash_process'] as String,
    precautions: json['precautions'] == null
        ? null
        : json['precautions'] as String,
    attributes: json['attributes'] == null
        ? null
        : (json['attributes'] as List<dynamic>)
              .map(
                (item) => AttributeRead.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
    personnel: json['personnel'] == null
        ? null
        : (json['personnel'] as List<dynamic>)
              .map(
                (item) => PersonnelRead.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'piece_weight_grams': pieceWeightGrams,
    'weight_grade_grams': weightGradeGrams,
    'weight_base_size': weightBaseSize,
    'weight_size_order': weightSizeOrder,
    'size_weights': sizeWeights?.map((item) => item.toJson()).toList(),
    'weight_auto_sizes': weightAutoSizes,
    'year': year,
    'launch_date': launchDate,
    'remark': remark,
    'process_instructions': processInstructions,
    'wash_process': washProcess,
    'precautions': precautions,
    'attributes': attributes?.map((item) => item.toJson()).toList(),
    'personnel': personnel?.map((item) => item.toJson()).toList(),
  };
}

class AttributeRead {
  const AttributeRead({
    required this.attribute,
    required this.entryId,
    required this.label,
  });

  final String attribute;
  final int entryId;
  final String label;

  factory AttributeRead.fromJson(Map<String, dynamic> json) => AttributeRead(
    attribute: json['attribute'] as String,
    entryId: json['entry_id'] as int,
    label: json['label'] as String,
  );

  Map<String, dynamic> toJson() => {
    'attribute': attribute,
    'entry_id': entryId,
    'label': label,
  };
}

class PersonnelRead {
  const PersonnelRead({
    required this.role,
    required this.employeeId,
    required this.name,
  });

  final String role;
  final int employeeId;
  final String name;

  factory PersonnelRead.fromJson(Map<String, dynamic> json) => PersonnelRead(
    role: json['role'] as String,
    employeeId: json['employee_id'] as int,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'role': role,
    'employee_id': employeeId,
    'name': name,
  };
}

class SizeRowRead {
  const SizeRowRead({
    required this.pointId,
    this.method,
    this.tolerance,
    this.gradeDelta,
    this.patternSize,
    this.sampleSize,
    required this.point,
    required this.values,
  });

  final int pointId;
  final String? method;
  final String? tolerance;
  final String? gradeDelta;
  final String? patternSize;
  final String? sampleSize;
  final String point;
  final List<SizeCellRead> values;

  factory SizeRowRead.fromJson(Map<String, dynamic> json) => SizeRowRead(
    pointId: json['point_id'] as int,
    method: json['method'] == null ? null : json['method'] as String,
    tolerance: json['tolerance'] == null ? null : json['tolerance'] as String,
    gradeDelta: json['grade_delta'] == null
        ? null
        : json['grade_delta'] as String,
    patternSize: json['pattern_size'] == null
        ? null
        : json['pattern_size'] as String,
    sampleSize: json['sample_size'] == null
        ? null
        : json['sample_size'] as String,
    point: json['point'] as String,
    values: (json['values'] as List<dynamic>)
        .map((item) => SizeCellRead.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'point_id': pointId,
    'method': method,
    'tolerance': tolerance,
    'grade_delta': gradeDelta,
    'pattern_size': patternSize,
    'sample_size': sampleSize,
    'point': point,
    'values': values.map((item) => item.toJson()).toList(),
  };
}

class SizeCellRead {
  const SizeCellRead({
    this.beforeWash,
    this.afterWash,
    required this.sizeId,
    required this.size,
  });

  final String? beforeWash;
  final String? afterWash;
  final int sizeId;
  final String size;

  factory SizeCellRead.fromJson(Map<String, dynamic> json) => SizeCellRead(
    beforeWash: json['before_wash'] == null
        ? null
        : json['before_wash'] as String,
    afterWash: json['after_wash'] == null ? null : json['after_wash'] as String,
    sizeId: json['size_id'] as int,
    size: json['size'] as String,
  );

  Map<String, dynamic> toJson() => {
    'before_wash': beforeWash,
    'after_wash': afterWash,
    'size_id': sizeId,
    'size': size,
  };
}

class SizeWeight {
  const SizeWeight({required this.size, required this.grams});

  final String size;
  final String grams;

  factory SizeWeight.fromJson(Map<String, dynamic> json) =>
      SizeWeight(size: json['size'] as String, grams: json['grams'] as String);

  Map<String, dynamic> toJson() => {'size': size, 'grams': grams};
}

class PaginatedCustomerList {
  const PaginatedCustomerList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<Customer> results;

  factory PaginatedCustomerList.fromJson(Map<String, dynamic> json) =>
      PaginatedCustomerList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map((item) => Customer.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class PaginatedStyleList {
  const PaginatedStyleList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<Style> results;

  factory PaginatedStyleList.fromJson(Map<String, dynamic> json) =>
      PaginatedStyleList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map((item) => Style.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class StyleCatalogRead {
  const StyleCatalogRead({
    required this.id,
    required this.code,
    required this.name,
    this.category,
    this.composition,
    this.salePrice,
    required this.hasStyleImage,
    required this.active,
    this.launchDate,
    this.totalStock,
  });

  final int id;
  final String code;
  final String name;
  final String? category;
  final String? composition;
  final String? salePrice;
  final bool hasStyleImage;
  final bool active;
  final String? launchDate;
  final int? totalStock;

  factory StyleCatalogRead.fromJson(
    Map<String, dynamic> json,
  ) => StyleCatalogRead(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    category: json['category'] == null ? null : json['category'] as String,
    composition: json['composition'] == null
        ? null
        : json['composition'] as String,
    salePrice: json['sale_price'] == null ? null : json['sale_price'] as String,
    hasStyleImage: json['has_style_image'] as bool,
    active: json['active'] as bool,
    launchDate: json['launch_date'] == null
        ? null
        : json['launch_date'] as String,
    totalStock: json['total_stock'] == null ? null : json['total_stock'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'category': category,
    'composition': composition,
    'sale_price': salePrice,
    'has_style_image': hasStyleImage,
    'active': active,
    'launch_date': launchDate,
    'total_stock': totalStock,
  };
}

class OrderRead {
  const OrderRead({
    required this.id,
    required this.code,
    this.customerId,
    required this.customerName,
    required this.dueDate,
    this.paymentMethod,
    this.clerkId,
    this.clerkName,
    this.status,
    required this.confirmedAt,
    required this.lines,
    this.notes,
  });

  final int id;
  final String code;
  final int? customerId;
  final String customerName;
  final String dueDate;
  final PaymentMethod? paymentMethod;
  final int? clerkId;
  final String? clerkName;
  final String? status;
  final String confirmedAt;
  final List<OrderLineRead> lines;
  final String? notes;

  factory OrderRead.fromJson(Map<String, dynamic> json) => OrderRead(
    id: json['id'] as int,
    code: json['code'] as String,
    customerId: json['customer_id'] == null ? null : json['customer_id'] as int,
    customerName: json['customer_name'] as String,
    dueDate: json['due_date'] as String,
    paymentMethod: json['payment_method'] == null
        ? null
        : PaymentMethod.fromCode(json['payment_method'] as String?),
    clerkId: json['clerk_id'] == null ? null : json['clerk_id'] as int,
    clerkName: json['clerk_name'] == null ? null : json['clerk_name'] as String,
    status: json['status'] == null ? null : json['status'] as String,
    confirmedAt: json['confirmed_at'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((item) => OrderLineRead.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    notes: json['notes'] == null ? null : json['notes'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'customer_id': customerId,
    'customer_name': customerName,
    'due_date': dueDate,
    'payment_method': paymentMethod?.code,
    'clerk_id': clerkId,
    'clerk_name': clerkName,
    'status': status,
    'confirmed_at': confirmedAt,
    'lines': lines.map((item) => item.toJson()).toList(),
    'notes': notes,
  };
}

class OrderLineRead {
  const OrderLineRead({
    required this.id,
    this.skuId,
    this.styleId,
    required this.styleCode,
    required this.styleName,
    this.specialName,
    required this.color,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.sent,
    this.notes,
  });

  final int id;
  final int? skuId;
  final int? styleId;
  final String styleCode;
  final String styleName;
  final String? specialName;
  final String color;
  final String size;
  final int quantity;
  final String unitPrice;
  final int sent;
  final String? notes;

  factory OrderLineRead.fromJson(Map<String, dynamic> json) => OrderLineRead(
    id: json['id'] as int,
    skuId: json['sku_id'] == null ? null : json['sku_id'] as int,
    styleId: json['style_id'] == null ? null : json['style_id'] as int,
    styleCode: json['style_code'] as String,
    styleName: json['style_name'] as String,
    specialName: json['special_name'] == null
        ? null
        : json['special_name'] as String,
    color: json['color'] as String,
    size: json['size'] as String,
    quantity: json['quantity'] as int,
    unitPrice: json['unit_price'] as String,
    sent: json['sent'] as int,
    notes: json['notes'] == null ? null : json['notes'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sku_id': skuId,
    'style_id': styleId,
    'style_code': styleCode,
    'style_name': styleName,
    'special_name': specialName,
    'color': color,
    'size': size,
    'quantity': quantity,
    'unit_price': unitPrice,
    'sent': sent,
    'notes': notes,
  };
}

class PaginatedOrderReadList {
  const PaginatedOrderReadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<OrderRead> results;

  factory PaginatedOrderReadList.fromJson(Map<String, dynamic> json) =>
      PaginatedOrderReadList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map((item) => OrderRead.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class OrderItemWrite {
  const OrderItemWrite({
    this.notes,
    this.skuId,
    this.specialName,
    this.unitPrice,
    required this.quantity,
  });

  final String? notes;
  final int? skuId;
  final String? specialName;
  final String? unitPrice;
  final int quantity;

  factory OrderItemWrite.fromJson(Map<String, dynamic> json) => OrderItemWrite(
    notes: json['notes'] == null ? null : json['notes'] as String,
    skuId: json['sku_id'] == null ? null : json['sku_id'] as int,
    specialName: json['special_name'] == null
        ? null
        : json['special_name'] as String,
    unitPrice: json['unit_price'] == null ? null : json['unit_price'] as String,
    quantity: json['quantity'] as int,
  );

  Map<String, dynamic> toJson() => {
    'notes': notes,
    if (skuId != null) 'sku_id': skuId,
    if (specialName != null) 'special_name': specialName,
    if (unitPrice != null) 'unit_price': unitPrice,
    'quantity': quantity,
  };
}

class OrderWrite {
  const OrderWrite({
    this.notes,
    required this.customerId,
    required this.dueDate,
    this.paymentMethod,
    this.clerkId,
    this.unitPrice,
    required this.requestKey,
    required this.lines,
  });

  final String? notes;
  final int customerId;
  final String dueDate;
  final PaymentMethod? paymentMethod;
  final int? clerkId;
  final String? unitPrice;
  final String requestKey;
  final List<OrderItemWrite> lines;

  factory OrderWrite.fromJson(Map<String, dynamic> json) => OrderWrite(
    notes: json['notes'] == null ? null : json['notes'] as String,
    customerId: json['customer_id'] as int,
    dueDate: json['due_date'] as String,
    paymentMethod: json['payment_method'] == null
        ? null
        : PaymentMethod.fromCode(json['payment_method'] as String?),
    clerkId: json['clerk_id'] == null ? null : json['clerk_id'] as int,
    unitPrice: json['unit_price'] == null ? null : json['unit_price'] as String,
    requestKey: json['request_key'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((item) => OrderItemWrite.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'notes': notes,
    'customer_id': customerId,
    'due_date': dueDate,
    'payment_method': paymentMethod?.code,
    'clerk_id': clerkId,
    'unit_price': unitPrice,
    'request_key': requestKey,
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.kind,
    required this.label,
    required this.active,
  });

  final int id;
  final String kind;
  final String label;
  final bool active;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) =>
      DictionaryEntry(
        id: json['id'] as int,
        kind: json['kind'] as String,
        label: json['label'] as String,
        active: json['active'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'label': label,
    'active': active,
  };
}

class WarehouseRead {
  const WarehouseRead({
    required this.id,
    required this.code,
    required this.name,
    this.active,
  });

  final int id;
  final String code;
  final String name;
  final bool? active;

  factory WarehouseRead.fromJson(Map<String, dynamic> json) => WarehouseRead(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    active: json['active'] == null ? null : json['active'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'active': active,
  };
}

class PaginatedWarehouseReadList {
  const PaginatedWarehouseReadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<WarehouseRead> results;

  factory PaginatedWarehouseReadList.fromJson(Map<String, dynamic> json) =>
      PaginatedWarehouseReadList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map((item) => WarehouseRead.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class AvailabilityLine {
  const AvailabilityLine({required this.orderLineId, required this.available});

  final int orderLineId;
  final int available;

  factory AvailabilityLine.fromJson(Map<String, dynamic> json) =>
      AvailabilityLine(
        orderLineId: json['order_line_id'] as int,
        available: json['available'] as int,
      );

  Map<String, dynamic> toJson() => {
    'order_line_id': orderLineId,
    'available': available,
  };
}

class ShipmentAvailability {
  const ShipmentAvailability({required this.lines});

  final List<AvailabilityLine> lines;

  factory ShipmentAvailability.fromJson(Map<String, dynamic> json) =>
      ShipmentAvailability(
        lines: (json['lines'] as List<dynamic>)
            .map(
              (item) => AvailabilityLine.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class ShipmentWrite {
  const ShipmentWrite({
    this.paymentMethod,
    this.paidAmount,
    this.notes,
    required this.warehouseId,
    this.clerkId,
    required this.requestKey,
    required this.lines,
  });

  final PaymentMethod? paymentMethod;
  final String? paidAmount;
  final String? notes;
  final int warehouseId;
  final int? clerkId;
  final String requestKey;
  final List<ShipmentItemWrite> lines;

  factory ShipmentWrite.fromJson(Map<String, dynamic> json) => ShipmentWrite(
    paymentMethod: json['payment_method'] == null
        ? null
        : PaymentMethod.fromCode(json['payment_method'] as String?),
    paidAmount: json['paid_amount'] == null
        ? null
        : json['paid_amount'] as String,
    notes: json['notes'] == null ? null : json['notes'] as String,
    warehouseId: json['warehouse_id'] as int,
    clerkId: json['clerk_id'] == null ? null : json['clerk_id'] as int,
    requestKey: json['request_key'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((item) => ShipmentItemWrite.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'payment_method': paymentMethod?.code,
    'paid_amount': paidAmount,
    'notes': notes,
    'warehouse_id': warehouseId,
    'clerk_id': clerkId,
    'request_key': requestKey,
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class ShipmentItemWrite {
  const ShipmentItemWrite({
    this.notes,
    required this.orderLineId,
    required this.quantity,
  });

  final String? notes;
  final int orderLineId;
  final int quantity;

  factory ShipmentItemWrite.fromJson(Map<String, dynamic> json) =>
      ShipmentItemWrite(
        notes: json['notes'] == null ? null : json['notes'] as String,
        orderLineId: json['order_line_id'] as int,
        quantity: json['quantity'] as int,
      );

  Map<String, dynamic> toJson() => {
    'notes': notes,
    'order_line_id': orderLineId,
    'quantity': quantity,
  };
}

class ShipmentPosted {
  const ShipmentPosted({required this.id, required this.code});

  final int id;
  final String code;

  factory ShipmentPosted.fromJson(Map<String, dynamic> json) =>
      ShipmentPosted(id: json['id'] as int, code: json['code'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'code': code};
}

class ShipmentRead {
  const ShipmentRead({
    required this.id,
    required this.code,
    required this.orderCode,
    this.customerId,
    required this.customer,
    required this.warehouseName,
    required this.quantity,
    required this.postedAt,
    required this.lines,
    this.notes,
    this.isDirect,
    this.clerkId,
    this.clerkName,
    this.paymentMethod,
    this.paidAmount,
    this.grossAmount,
    this.receivableAmount,
    this.settledAmount,
    this.outstandingAmount,
  });

  final int id;
  final String code;
  final String orderCode;
  final int? customerId;
  final String customer;
  final String warehouseName;
  final int quantity;
  final String postedAt;
  final List<ShipmentLineRead> lines;
  final String? notes;
  final bool? isDirect;
  final int? clerkId;
  final String? clerkName;
  final PaymentMethod? paymentMethod;
  final String? paidAmount;
  final String? grossAmount;
  final String? receivableAmount;
  final String? settledAmount;
  final String? outstandingAmount;

  factory ShipmentRead.fromJson(Map<String, dynamic> json) => ShipmentRead(
    id: json['id'] as int,
    code: json['code'] as String,
    orderCode: json['order_code'] as String,
    customerId: json['customer_id'] == null ? null : json['customer_id'] as int,
    customer: json['customer'] as String,
    warehouseName: json['warehouse_name'] as String,
    quantity: json['quantity'] as int,
    postedAt: json['posted_at'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((item) => ShipmentLineRead.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    notes: json['notes'] == null ? null : json['notes'] as String,
    isDirect: json['is_direct'] == null ? null : json['is_direct'] as bool,
    clerkId: json['clerk_id'] == null ? null : json['clerk_id'] as int,
    clerkName: json['clerk_name'] == null ? null : json['clerk_name'] as String,
    paymentMethod: json['payment_method'] == null
        ? null
        : PaymentMethod.fromCode(json['payment_method'] as String?),
    paidAmount: json['paid_amount'] == null
        ? null
        : json['paid_amount'] as String,
    grossAmount: json['gross_amount'] == null
        ? null
        : json['gross_amount'] as String,
    receivableAmount: json['receivable_amount'] == null
        ? null
        : json['receivable_amount'] as String,
    settledAmount: json['settled_amount'] == null
        ? null
        : json['settled_amount'] as String,
    outstandingAmount: json['outstanding_amount'] == null
        ? null
        : json['outstanding_amount'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'order_code': orderCode,
    'customer_id': customerId,
    'customer': customer,
    'warehouse_name': warehouseName,
    'quantity': quantity,
    'posted_at': postedAt,
    'lines': lines.map((item) => item.toJson()).toList(),
    'notes': notes,
    'is_direct': isDirect,
    'clerk_id': clerkId,
    'clerk_name': clerkName,
    'payment_method': paymentMethod?.code,
    'paid_amount': paidAmount,
    'gross_amount': grossAmount,
    'receivable_amount': receivableAmount,
    'settled_amount': settledAmount,
    'outstanding_amount': outstandingAmount,
  };
}

class DirectShipmentWrite {
  const DirectShipmentWrite({
    required this.requestKey,
    this.paymentMethod,
    this.paidAmount,
    required this.customerId,
    required this.warehouseId,
    this.clerkId,
    this.notes,
    required this.lines,
  });

  final String requestKey;
  final PaymentMethod? paymentMethod;
  final String? paidAmount;
  final int customerId;
  final int warehouseId;
  final int? clerkId;
  final String? notes;
  final List<OrderItemWrite> lines;

  factory DirectShipmentWrite.fromJson(Map<String, dynamic> json) =>
      DirectShipmentWrite(
        requestKey: json['request_key'] as String,
        paymentMethod: json['payment_method'] == null
            ? null
            : PaymentMethod.fromCode(json['payment_method'] as String?),
        paidAmount: json['paid_amount'] == null
            ? null
            : json['paid_amount'] as String,
        customerId: json['customer_id'] as int,
        warehouseId: json['warehouse_id'] as int,
        clerkId: json['clerk_id'] == null ? null : json['clerk_id'] as int,
        notes: json['notes'] == null ? null : json['notes'] as String,
        lines: (json['lines'] as List<dynamic>)
            .map(
              (item) => OrderItemWrite.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'request_key': requestKey,
    'payment_method': paymentMethod?.code,
    'paid_amount': paidAmount,
    'customer_id': customerId,
    'warehouse_id': warehouseId,
    'clerk_id': clerkId,
    'notes': notes,
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class PaginatedShipmentReadList {
  const PaginatedShipmentReadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<ShipmentRead> results;

  factory PaginatedShipmentReadList.fromJson(Map<String, dynamic> json) =>
      PaginatedShipmentReadList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map((item) => ShipmentRead.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class PurchaseOrderRead {
  const PurchaseOrderRead({
    required this.id,
    required this.code,
    required this.supplierName,
    required this.orderedOn,
    required this.dueOn,
    this.notes,
    required this.lines,
  });

  final int id;
  final String code;
  final String supplierName;
  final String orderedOn;
  final String dueOn;
  final String? notes;
  final List<PurchaseLineRead> lines;

  factory PurchaseOrderRead.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderRead(
        id: json['id'] as int,
        code: json['code'] as String,
        supplierName: json['supplier_name'] as String,
        orderedOn: json['ordered_on'] as String,
        dueOn: json['due_on'] as String,
        notes: json['notes'] == null ? null : json['notes'] as String,
        lines: (json['lines'] as List<dynamic>)
            .map(
              (item) => PurchaseLineRead.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'supplier_name': supplierName,
    'ordered_on': orderedOn,
    'due_on': dueOn,
    'notes': notes,
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class PurchaseLineRead {
  const PurchaseLineRead({
    required this.id,
    required this.item,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.notes,
    this.materialId,
    this.colorCode,
    required this.receivedQuantity,
  });

  final int id;
  final String item;
  final String unit;
  final String quantity;
  final String unitPrice;
  final String? notes;
  final int? materialId;
  final String? colorCode;
  final String receivedQuantity;

  factory PurchaseLineRead.fromJson(
    Map<String, dynamic> json,
  ) => PurchaseLineRead(
    id: json['id'] as int,
    item: json['item'] as String,
    unit: json['unit'] as String,
    quantity: json['quantity'] as String,
    unitPrice: json['unit_price'] as String,
    notes: json['notes'] == null ? null : json['notes'] as String,
    materialId: json['material_id'] == null ? null : json['material_id'] as int,
    colorCode: json['color_code'] == null ? null : json['color_code'] as String,
    receivedQuantity: json['received_quantity'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'item': item,
    'unit': unit,
    'quantity': quantity,
    'unit_price': unitPrice,
    'notes': notes,
    'material_id': materialId,
    'color_code': colorCode,
    'received_quantity': receivedQuantity,
  };
}

class PaginatedPurchaseOrderReadList {
  const PaginatedPurchaseOrderReadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<PurchaseOrderRead> results;

  factory PaginatedPurchaseOrderReadList.fromJson(Map<String, dynamic> json) =>
      PaginatedPurchaseOrderReadList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map(
              (item) =>
                  PurchaseOrderRead.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class ReturnRequestRead {
  const ReturnRequestRead({
    required this.id,
    required this.code,
    required this.shipmentCode,
    required this.customer,
    required this.styleCode,
    this.specialName,
    required this.quantity,
    required this.reason,
    required this.createdAt,
    this.notes,
    this.lineNotes,
  });

  final int id;
  final String code;
  final String shipmentCode;
  final String customer;
  final String styleCode;
  final String? specialName;
  final int quantity;
  final String reason;
  final String createdAt;
  final String? notes;
  final String? lineNotes;

  factory ReturnRequestRead.fromJson(Map<String, dynamic> json) =>
      ReturnRequestRead(
        id: json['id'] as int,
        code: json['code'] as String,
        shipmentCode: json['shipment_code'] as String,
        customer: json['customer'] as String,
        styleCode: json['style_code'] as String,
        specialName: json['special_name'] == null
            ? null
            : json['special_name'] as String,
        quantity: json['quantity'] as int,
        reason: json['reason'] as String,
        createdAt: json['created_at'] as String,
        notes: json['notes'] == null ? null : json['notes'] as String,
        lineNotes: json['line_notes'] == null
            ? null
            : json['line_notes'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'shipment_code': shipmentCode,
    'customer': customer,
    'style_code': styleCode,
    'special_name': specialName,
    'quantity': quantity,
    'reason': reason,
    'created_at': createdAt,
    'notes': notes,
    'line_notes': lineNotes,
  };
}

class PaginatedReturnRequestReadList {
  const PaginatedReturnRequestReadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<ReturnRequestRead> results;

  factory PaginatedReturnRequestReadList.fromJson(Map<String, dynamic> json) =>
      PaginatedReturnRequestReadList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map(
              (item) =>
                  ReturnRequestRead.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class StockRead {
  const StockRead({
    required this.warehouse,
    required this.styleCode,
    required this.styleName,
    required this.color,
    required this.size,
    required this.quantity,
  });

  final String warehouse;
  final String styleCode;
  final String styleName;
  final String color;
  final String size;
  final int quantity;

  factory StockRead.fromJson(Map<String, dynamic> json) => StockRead(
    warehouse: json['warehouse'] as String,
    styleCode: json['style_code'] as String,
    styleName: json['style_name'] as String,
    color: json['color'] as String,
    size: json['size'] as String,
    quantity: json['quantity'] as int,
  );

  Map<String, dynamic> toJson() => {
    'warehouse': warehouse,
    'style_code': styleCode,
    'style_name': styleName,
    'color': color,
    'size': size,
    'quantity': quantity,
  };
}

class PaginatedStockReadList {
  const PaginatedStockReadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<StockRead> results;

  factory PaginatedStockReadList.fromJson(Map<String, dynamic> json) =>
      PaginatedStockReadList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map((item) => StockRead.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class ProgressNoteRead {
  const ProgressNoteRead({
    required this.id,
    required this.orderCode,
    required this.styleCode,
    required this.color,
    required this.size,
    required this.note,
    required this.author,
    required this.recordedAt,
    this.notes,
    this.lineNotes,
  });

  final int id;
  final String orderCode;
  final String styleCode;
  final String color;
  final String size;
  final String note;
  final String author;
  final String recordedAt;
  final String? notes;
  final String? lineNotes;

  factory ProgressNoteRead.fromJson(Map<String, dynamic> json) =>
      ProgressNoteRead(
        id: json['id'] as int,
        orderCode: json['order_code'] as String,
        styleCode: json['style_code'] as String,
        color: json['color'] as String,
        size: json['size'] as String,
        note: json['note'] as String,
        author: json['author'] as String,
        recordedAt: json['recorded_at'] as String,
        notes: json['notes'] == null ? null : json['notes'] as String,
        lineNotes: json['line_notes'] == null
            ? null
            : json['line_notes'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_code': orderCode,
    'style_code': styleCode,
    'color': color,
    'size': size,
    'note': note,
    'author': author,
    'recorded_at': recordedAt,
    'notes': notes,
    'line_notes': lineNotes,
  };
}

class PaginatedProgressNoteReadList {
  const PaginatedProgressNoteReadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<ProgressNoteRead> results;

  factory PaginatedProgressNoteReadList.fromJson(Map<String, dynamic> json) =>
      PaginatedProgressNoteReadList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map(
              (item) => ProgressNoteRead.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class StaffRead {
  const StaffRead({
    required this.id,
    required this.username,
    required this.name,
    this.isActive,
  });

  final int id;
  final String username;
  final String name;
  final bool? isActive;

  factory StaffRead.fromJson(Map<String, dynamic> json) => StaffRead(
    id: json['id'] as int,
    username: json['username'] as String,
    name: json['name'] as String,
    isActive: json['is_active'] == null ? null : json['is_active'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'is_active': isActive,
  };
}

class PaginatedStaffReadList {
  const PaginatedStaffReadList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<StaffRead> results;

  factory PaginatedStaffReadList.fromJson(Map<String, dynamic> json) =>
      PaginatedStaffReadList(
        count: json['count'] as int,
        next: json['next'] == null ? null : json['next'] as String,
        previous: json['previous'] == null ? null : json['previous'] as String,
        results: (json['results'] as List<dynamic>)
            .map((item) => StaffRead.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((item) => item.toJson()).toList(),
  };
}

class SalesSummary {
  const SalesSummary({
    required this.orderCount,
    required this.shipmentCount,
    required this.ordered,
    required this.sent,
  });

  final int orderCount;
  final int shipmentCount;
  final int ordered;
  final int sent;

  factory SalesSummary.fromJson(Map<String, dynamic> json) => SalesSummary(
    orderCount: json['order_count'] as int,
    shipmentCount: json['shipment_count'] as int,
    ordered: json['ordered'] as int,
    sent: json['sent'] as int,
  );

  Map<String, dynamic> toJson() => {
    'order_count': orderCount,
    'shipment_count': shipmentCount,
    'ordered': ordered,
    'sent': sent,
  };
}

class ShipmentLineRead {
  const ShipmentLineRead({
    required this.id,
    this.styleId,
    required this.styleCode,
    required this.styleName,
    this.specialName,
    required this.color,
    required this.size,
    required this.unitPrice,
    required this.quantity,
    required this.returnable,
    this.notes,
  });

  final int id;
  final int? styleId;
  final String styleCode;
  final String styleName;
  final String? specialName;
  final String color;
  final String size;
  final String unitPrice;
  final int quantity;
  final int returnable;
  final String? notes;

  factory ShipmentLineRead.fromJson(Map<String, dynamic> json) =>
      ShipmentLineRead(
        id: json['id'] as int,
        styleId: json['style_id'] == null ? null : json['style_id'] as int,
        styleCode: json['style_code'] as String,
        styleName: json['style_name'] as String,
        specialName: json['special_name'] == null
            ? null
            : json['special_name'] as String,
        color: json['color'] as String,
        size: json['size'] as String,
        unitPrice: json['unit_price'] as String,
        quantity: json['quantity'] as int,
        returnable: json['returnable'] as int,
        notes: json['notes'] == null ? null : json['notes'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'style_id': styleId,
    'style_code': styleCode,
    'style_name': styleName,
    'special_name': specialName,
    'color': color,
    'size': size,
    'unit_price': unitPrice,
    'quantity': quantity,
    'returnable': returnable,
    'notes': notes,
  };
}

class StockMovementRead {
  const StockMovementRead({
    required this.id,
    required this.warehouseName,
    required this.styleCode,
    required this.color,
    required this.size,
    required this.quantity,
    required this.movementType,
    required this.sourceRef,
    required this.recordedAt,
  });

  final int id;
  final String warehouseName;
  final String styleCode;
  final String color;
  final String size;
  final int quantity;
  final String movementType;
  final String sourceRef;
  final String recordedAt;

  factory StockMovementRead.fromJson(Map<String, dynamic> json) =>
      StockMovementRead(
        id: json['id'] as int,
        warehouseName: json['warehouse_name'] as String,
        styleCode: json['style_code'] as String,
        color: json['color'] as String,
        size: json['size'] as String,
        quantity: json['quantity'] as int,
        movementType: json['movement_type'] as String,
        sourceRef: json['source_ref'] as String,
        recordedAt: json['recorded_at'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'warehouse_name': warehouseName,
    'style_code': styleCode,
    'color': color,
    'size': size,
    'quantity': quantity,
    'movement_type': movementType,
    'source_ref': sourceRef,
    'recorded_at': recordedAt,
  };
}

class CustomerWrite {
  const CustomerWrite({
    required this.requestKey,
    this.code,
    required this.name,
    this.phone,
    this.address,
  });

  final String requestKey;
  final String? code;
  final String name;
  final String? phone;
  final String? address;

  factory CustomerWrite.fromJson(Map<String, dynamic> json) => CustomerWrite(
    requestKey: json['request_key'] as String,
    code: json['code'] == null ? null : json['code'] as String,
    name: json['name'] as String,
    phone: json['phone'] == null ? null : json['phone'] as String,
    address: json['address'] == null ? null : json['address'] as String,
  );

  Map<String, dynamic> toJson() => {
    'request_key': requestKey,
    'code': code,
    'name': name,
    'phone': phone,
    'address': address,
  };
}

class PurchaseWrite {
  const PurchaseWrite({
    required this.requestKey,
    required this.supplierId,
    required this.orderedOn,
    required this.dueOn,
    this.notes,
    required this.lines,
  });

  final String requestKey;
  final int supplierId;
  final String orderedOn;
  final String dueOn;
  final String? notes;
  final List<PurchaseItemWrite> lines;

  factory PurchaseWrite.fromJson(Map<String, dynamic> json) => PurchaseWrite(
    requestKey: json['request_key'] as String,
    supplierId: json['supplier_id'] as int,
    orderedOn: json['ordered_on'] as String,
    dueOn: json['due_on'] as String,
    notes: json['notes'] == null ? null : json['notes'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((item) => PurchaseItemWrite.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'request_key': requestKey,
    'supplier_id': supplierId,
    'ordered_on': orderedOn,
    'due_on': dueOn,
    'notes': notes,
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class PurchaseItemWrite {
  const PurchaseItemWrite({
    this.notes,
    this.item,
    this.unit,
    this.materialId,
    this.colorCode,
    required this.quantity,
    required this.unitPrice,
  });

  final String? notes;
  final String? item;
  final String? unit;
  final int? materialId;
  final String? colorCode;
  final String quantity;
  final String unitPrice;

  factory PurchaseItemWrite.fromJson(
    Map<String, dynamic> json,
  ) => PurchaseItemWrite(
    notes: json['notes'] == null ? null : json['notes'] as String,
    item: json['item'] == null ? null : json['item'] as String,
    unit: json['unit'] == null ? null : json['unit'] as String,
    materialId: json['material_id'] == null ? null : json['material_id'] as int,
    colorCode: json['color_code'] == null ? null : json['color_code'] as String,
    quantity: json['quantity'] as String,
    unitPrice: json['unit_price'] as String,
  );

  Map<String, dynamic> toJson() => {
    'notes': notes,
    'item': item,
    'unit': unit,
    'material_id': materialId,
    'color_code': colorCode,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}

class SupplierRead {
  const SupplierRead({
    required this.id,
    required this.code,
    required this.name,
    this.active,
  });

  final int id;
  final String code;
  final String name;
  final bool? active;

  factory SupplierRead.fromJson(Map<String, dynamic> json) => SupplierRead(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    active: json['active'] == null ? null : json['active'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'active': active,
  };
}

class SalesReturnRead {
  const SalesReturnRead({
    required this.id,
    required this.code,
    required this.customerId,
    required this.customerName,
    required this.warehouseName,
    required this.postedByName,
    required this.postedAt,
    required this.amount,
    this.notes,
    required this.lines,
  });

  final int id;
  final String code;
  final int customerId;
  final String customerName;
  final String warehouseName;
  final String postedByName;
  final String postedAt;
  final String amount;
  final String? notes;
  final List<SalesReturnLineRead> lines;

  factory SalesReturnRead.fromJson(Map<String, dynamic> json) =>
      SalesReturnRead(
        id: json['id'] as int,
        code: json['code'] as String,
        customerId: json['customer_id'] as int,
        customerName: json['customer_name'] as String,
        warehouseName: json['warehouse_name'] as String,
        postedByName: json['posted_by_name'] as String,
        postedAt: json['posted_at'] as String,
        amount: json['amount'] as String,
        notes: json['notes'] == null ? null : json['notes'] as String,
        lines: (json['lines'] as List<dynamic>)
            .map(
              (item) =>
                  SalesReturnLineRead.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'customer_id': customerId,
    'customer_name': customerName,
    'warehouse_name': warehouseName,
    'posted_by_name': postedByName,
    'posted_at': postedAt,
    'amount': amount,
    'notes': notes,
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class SalesReturnWrite {
  const SalesReturnWrite({
    required this.requestKey,
    required this.customerId,
    required this.warehouseId,
    this.notes,
    required this.lines,
  });

  final String requestKey;
  final int customerId;
  final int warehouseId;
  final String? notes;
  final List<OrderItemWrite> lines;

  factory SalesReturnWrite.fromJson(Map<String, dynamic> json) =>
      SalesReturnWrite(
        requestKey: json['request_key'] as String,
        customerId: json['customer_id'] as int,
        warehouseId: json['warehouse_id'] as int,
        notes: json['notes'] == null ? null : json['notes'] as String,
        lines: (json['lines'] as List<dynamic>)
            .map(
              (item) => OrderItemWrite.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'request_key': requestKey,
    'customer_id': customerId,
    'warehouse_id': warehouseId,
    'notes': notes,
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class SalesReturnLineRead {
  const SalesReturnLineRead({
    this.skuId,
    this.styleCode,
    required this.styleName,
    this.color,
    this.size,
    required this.unitPrice,
    required this.quantity,
    this.notes,
  });

  final int? skuId;
  final String? styleCode;
  final String styleName;
  final String? color;
  final String? size;
  final String unitPrice;
  final int quantity;
  final String? notes;

  factory SalesReturnLineRead.fromJson(Map<String, dynamic> json) =>
      SalesReturnLineRead(
        skuId: json['sku_id'] == null ? null : json['sku_id'] as int,
        styleCode: json['style_code'] == null
            ? null
            : json['style_code'] as String,
        styleName: json['style_name'] as String,
        color: json['color'] == null ? null : json['color'] as String,
        size: json['size'] == null ? null : json['size'] as String,
        unitPrice: json['unit_price'] as String,
        quantity: json['quantity'] as int,
        notes: json['notes'] == null ? null : json['notes'] as String,
      );

  Map<String, dynamic> toJson() => {
    'sku_id': skuId,
    'style_code': styleCode,
    'style_name': styleName,
    'color': color,
    'size': size,
    'unit_price': unitPrice,
    'quantity': quantity,
    'notes': notes,
  };
}

class ReturnWrite {
  const ReturnWrite({
    required this.requestKey,
    this.notes,
    this.lineNotes,
    required this.shipmentLineId,
    required this.quantity,
    required this.reason,
  });

  final String requestKey;
  final String? notes;
  final String? lineNotes;
  final int shipmentLineId;
  final int quantity;
  final String reason;

  factory ReturnWrite.fromJson(Map<String, dynamic> json) => ReturnWrite(
    requestKey: json['request_key'] as String,
    notes: json['notes'] == null ? null : json['notes'] as String,
    lineNotes: json['line_notes'] == null ? null : json['line_notes'] as String,
    shipmentLineId: json['shipment_line_id'] as int,
    quantity: json['quantity'] as int,
    reason: json['reason'] as String,
  );

  Map<String, dynamic> toJson() => {
    'request_key': requestKey,
    'notes': notes,
    'line_notes': lineNotes,
    'shipment_line_id': shipmentLineId,
    'quantity': quantity,
    'reason': reason,
  };
}

class ProgressWrite {
  const ProgressWrite({
    required this.requestKey,
    this.notes,
    this.lineNotes,
    required this.orderLineId,
    required this.note,
  });

  final String requestKey;
  final String? notes;
  final String? lineNotes;
  final int orderLineId;
  final String note;

  factory ProgressWrite.fromJson(Map<String, dynamic> json) => ProgressWrite(
    requestKey: json['request_key'] as String,
    notes: json['notes'] == null ? null : json['notes'] as String,
    lineNotes: json['line_notes'] == null ? null : json['line_notes'] as String,
    orderLineId: json['order_line_id'] as int,
    note: json['note'] as String,
  );

  Map<String, dynamic> toJson() => {
    'request_key': requestKey,
    'notes': notes,
    'line_notes': lineNotes,
    'order_line_id': orderLineId,
    'note': note,
  };
}

class ReceiptRead {
  const ReceiptRead({
    required this.id,
    required this.code,
    required this.warehouseName,
    required this.sourceRef,
    required this.receivedAt,
    required this.lines,
    this.notes,
  });

  final int id;
  final String code;
  final String warehouseName;
  final String sourceRef;
  final String receivedAt;
  final List<ReceiptLineRead> lines;
  final String? notes;

  factory ReceiptRead.fromJson(Map<String, dynamic> json) => ReceiptRead(
    id: json['id'] as int,
    code: json['code'] as String,
    warehouseName: json['warehouse_name'] as String,
    sourceRef: json['source_ref'] as String,
    receivedAt: json['received_at'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((item) => ReceiptLineRead.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    notes: json['notes'] == null ? null : json['notes'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'warehouse_name': warehouseName,
    'source_ref': sourceRef,
    'received_at': receivedAt,
    'lines': lines.map((item) => item.toJson()).toList(),
    'notes': notes,
  };
}

class ReceiptLineRead {
  const ReceiptLineRead({
    required this.id,
    required this.styleCode,
    required this.styleName,
    required this.color,
    required this.size,
    required this.quantity,
    this.notes,
  });

  final int id;
  final String styleCode;
  final String styleName;
  final String color;
  final String size;
  final int quantity;
  final String? notes;

  factory ReceiptLineRead.fromJson(Map<String, dynamic> json) =>
      ReceiptLineRead(
        id: json['id'] as int,
        styleCode: json['style_code'] as String,
        styleName: json['style_name'] as String,
        color: json['color'] as String,
        size: json['size'] as String,
        quantity: json['quantity'] as int,
        notes: json['notes'] == null ? null : json['notes'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'style_code': styleCode,
    'style_name': styleName,
    'color': color,
    'size': size,
    'quantity': quantity,
    'notes': notes,
  };
}

class ReceiptWrite {
  const ReceiptWrite({
    required this.requestKey,
    this.notes,
    required this.warehouseId,
    required this.sourceRef,
    required this.lines,
  });

  final String requestKey;
  final String? notes;
  final int warehouseId;
  final String sourceRef;
  final List<ReceiptLineWrite> lines;

  factory ReceiptWrite.fromJson(Map<String, dynamic> json) => ReceiptWrite(
    requestKey: json['request_key'] as String,
    notes: json['notes'] == null ? null : json['notes'] as String,
    warehouseId: json['warehouse_id'] as int,
    sourceRef: json['source_ref'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((item) => ReceiptLineWrite.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'request_key': requestKey,
    'notes': notes,
    'warehouse_id': warehouseId,
    'source_ref': sourceRef,
    'lines': lines.map((item) => item.toJson()).toList(),
  };
}

class ReceiptLineWrite {
  const ReceiptLineWrite({
    this.notes,
    required this.skuId,
    required this.quantity,
  });

  final String? notes;
  final int skuId;
  final int quantity;

  factory ReceiptLineWrite.fromJson(Map<String, dynamic> json) =>
      ReceiptLineWrite(
        notes: json['notes'] == null ? null : json['notes'] as String,
        skuId: json['sku_id'] as int,
        quantity: json['quantity'] as int,
      );

  Map<String, dynamic> toJson() => {
    'notes': notes,
    'sku_id': skuId,
    'quantity': quantity,
  };
}
