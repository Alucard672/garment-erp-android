import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'erp_environment.dart';
import 'generated/api_schema.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.status, this.message);
  final int status;
  final String message;
}

typedef RecordPageData<T> = ({List<T> items, int count, bool hasNext});
typedef RecordLoader<T> = Future<RecordPageData<T>> Function(String, int);

String newRequestKey() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

String requestFailure(Object error, String fallback) =>
    error is ApiFailure ? error.message : fallback;

class ErpApi {
  ErpApi({http.Client? client, this.baseUrl = configuredUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  // The direct endpoint and the old SSH tunnel reach the same test database.
  String get storageServerKey => baseUrl == ErpEnvironments.testServerUrl
      ? ErpEnvironments.testTunnelUrl
      : baseUrl;

  static const configuredUrl = String.fromEnvironment(
    'ERP_API_URL',
    defaultValue: 'http://10.0.2.2:8001',
  );

  Future<LoginResult> login(String username, String password) async {
    return LoginResult.fromJson(
      await _request(
        ApiPath.authLoginCreate,
        body: LoginRequest(username: username, password: password).toJson(),
      ),
    );
  }

  Future<void> changePassword(String token, String current, String next) async {
    await _request(
      ApiPath.authPasswordCreate,
      token: token,
      body: PasswordChange(
        currentPassword: current,
        newPassword: next,
      ).toJson(),
    );
  }

  Future<void> logout(String token) async {
    await _request(ApiPath.authLogoutCreate, token: token, body: const {});
  }

  Future<PaginatedCustomerList> customers(
    String token,
    String search,
    int page,
  ) async {
    return PaginatedCustomerList.fromJson(
      await _request(
        ApiPath.customersList,
        token: token,
        search: search,
        page: page,
      ),
    );
  }

  Future<PaginatedStyleList> styles(
    String token,
    String search,
    int page,
  ) async {
    return PaginatedStyleList.fromJson(
      await _request(
        ApiPath.stylesList,
        token: token,
        search: search,
        page: page,
      ),
    );
  }

  Future<CustomerReceivableDetail> customerReceivables(
    String token,
    int id,
  ) async => CustomerReceivableDetail.fromJson(
    await _request(ApiPath.customersReceivableDetail(id), token: token),
  );

  Future<CustomerReceiptRead> recordCustomerReceipt(
    String token,
    int id,
    CustomerReceiptWrite receipt,
  ) async => CustomerReceiptRead.fromJson(
    await _request(
      ApiPath.customersRecordReceipt(id),
      token: token,
      body: receipt.toJson(),
    ),
  );

  Future<StyleDetail> style(String token, int id) async {
    return StyleDetail.fromJson(
      await _request(ApiPath.stylesRetrieve(id), token: token),
    );
  }

  Future<Uint8List?> styleImage(
    String token,
    int id, {
    required String kind,
    bool thumbnail = false,
  }) async {
    final uri = _uri(ApiPath.stylesImagesRetrieve(id, kind), {
      if (thumbnail) 'thumbnail': 'true',
    });
    final result = await _client
        .get(
          uri,
          // DRF negotiates its renderer before the view returns a FileResponse.
          headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (result.statusCode == 404) return null;
    if (result.statusCode != 200) {
      throw ApiFailure(result.statusCode, '图片加载失败。');
    }
    return result.bodyBytes;
  }

  Future<RecordPageData<T>> list<T>({
    required String token,
    required String path,
    required T Function(Map<String, dynamic>) decode,
    String search = '',
    int page = 1,
    Map<String, String> query = const {},
  }) async {
    final data = await _request(
      path,
      token: token,
      search: search,
      page: page,
      query: query,
    );
    return (
      items: (data['results'] as List<dynamic>)
          .map((item) => decode(item as Map<String, dynamic>))
          .toList(growable: false),
      count: data['count'] as int,
      hasNext: data['next'] != null,
    );
  }

  Future<OrderRead> confirmOrder(String token, OrderWrite order) async =>
      OrderRead.fromJson(
        await _request(
          ApiPath.ordersCreate,
          token: token,
          body: order.toJson(),
        ),
      );

  Future<PaginatedStaffReadList> clerks(
    String token,
    String search,
    int page,
  ) async => PaginatedStaffReadList.fromJson(
    await _request(
      ApiPath.staffClerksList,
      token: token,
      search: search,
      page: page,
    ),
  );

  Future<ShipmentPosted> directShipment(
    String token,
    DirectShipmentWrite shipment,
  ) async => ShipmentPosted.fromJson(
    await _request(
      ApiPath.shipmentsDirectCreate,
      token: token,
      body: shipment.toJson(),
    ),
  );

  Future<OrderRead> order(String token, int id) async => OrderRead.fromJson(
    await _request(ApiPath.ordersRetrieve(id), token: token),
  );

  Future<ShipmentAvailability> availability(
    String token,
    int id,
    int warehouseId,
  ) async => ShipmentAvailability.fromJson(
    await _request(
      ApiPath.ordersAvailabilityRetrieve(id),
      token: token,
      query: {'warehouse_id': warehouseId.toString()},
    ),
  );

  Future<ShipmentPosted> ship(
    String token,
    int orderId,
    ShipmentWrite shipment,
  ) async => ShipmentPosted.fromJson(
    await _request(
      ApiPath.ordersShipCreate(orderId),
      token: token,
      body: shipment.toJson(),
    ),
  );

  Future<void> createDocument(
    String token,
    String path,
    Map<String, dynamic> request,
  ) async {
    await _request(path, token: token, body: request);
  }

  Future<SalesSummary> summary(String token) async => SalesSummary.fromJson(
    await _request(ApiPath.salesSummaryRetrieve, token: token),
  );

  Uri _uri(String path, Map<String, String> query) {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        base.host.isEmpty ||
        !(base.scheme == 'https' || (kDebugMode && base.scheme == 'http'))) {
      throw const ApiFailure(0, '请配置有效的 ERP 服务地址。');
    }

    return base.resolve(path).replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String? token,
    String? search,
    int? page,
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path, {
      ...query,
      if (search != null && search.isNotEmpty) 'search': search,
      if (page != null) 'page': page.toString(),
    });
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final result =
        await (body == null
                ? _client.get(uri, headers: headers)
                : _client.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 15));
    if (result.statusCode == 204) return {};
    Map<String, dynamic> payload = {};
    try {
      payload =
          jsonDecode(utf8.decode(result.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      // Infrastructure can return a non-JSON error page.
    } on TypeError {
      // Only JSON objects are valid API responses.
    }
    if (result.statusCode >= 400 || payload.isEmpty) {
      final detail = payload['detail'];
      final requestId = result.headers['x-request-id'];
      throw ApiFailure(
        result.statusCode,
        '${detail is String ? detail : '服务器暂时无法处理请求。'}'
        '${requestId == null ? '' : '（请求 ID $requestId）'}',
      );
    }
    return payload;
  }

  void close() => _client.close();
}
