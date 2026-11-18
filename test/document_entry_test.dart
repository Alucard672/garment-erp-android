import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garment_erp_android/api.dart';
import 'package:garment_erp_android/document_entry.dart';
import 'package:garment_erp_android/generated/api_schema.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets(
    'customer creation retries the same request after a lost response',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
      final requests = <Map<String, dynamic>>[];
      final api = ErpApi(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, ApiPath.customersCreate);
          requests.add(jsonDecode(request.body) as Map<String, dynamic>);
          if (requests.length == 1) throw http.ClientException('lost response');
          return http.Response('{"id":5,"code":"C01","name":"Sample"}', 201);
        }),
      );
      addTearDown(api.close);
      bool? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => saved = await openDocumentEntry(
                  context,
                  kind: DocumentKind.customer,
                  api: api,
                  employee: const LoginResult(
                    token: 'test',
                    employeeId: 1,
                    username: 'tester',
                    expiresAt: '2026-11-17',
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'C01');
      await tester.enterText(find.byType(TextFormField).at(1), 'Sample');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('重试提交'), findsOneWidget);
      await tester.tap(find.text('重试提交'));
      await tester.pumpAndSettle();
      expect(requests.length, 2);
      expect(requests[1], requests[0]);
      expect(saved, isTrue);
    },
  );
  testWidgets(
    'return entry submits customer and SKU without a source shipment',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final attempts = <Map<String, dynamic>>[];
      final api = ErpApi(
        client: MockClient((request) async {
          Object result;
          if (request.url.path == ApiPath.salesReturnsCreate &&
              request.method == 'POST') {
            attempts.add(jsonDecode(request.body) as Map<String, dynamic>);
            if (attempts.length == 1) {
              throw http.ClientException('lost response');
            }
            result = {'code': 'XT-5'};
          } else if (request.url.path == ApiPath.stylesRetrieve(7)) {
            result = {
              'id': 7,
              'name': 'Top',
              'code': 'TOP',
              'skus': [
                {
                  'id': 9,
                  'color': 'Red',
                  'size': 'M',
                  'wholesale_price': '12.50',
                },
              ],
            };
          } else {
            final item = switch (request.url.path) {
              ApiPath.customersList => {
                'id': 3,
                'name': 'Customer A',
                'code': 'A',
              },
              ApiPath.warehousesList => {
                'id': 4,
                'name': 'Warehouse B',
                'code': 'B',
              },
              ApiPath.stylesList => {'id': 7, 'name': 'Top', 'code': 'TOP'},
              _ => throw StateError('Unexpected request ${request.url}'),
            };
            result = {
              'count': 1,
              'next': null,
              'previous': null,
              'results': [item],
            };
          }
          return http.Response(jsonEncode(result), 200);
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openDocumentEntry(
                  context,
                  kind: DocumentKind.returns,
                  api: api,
                  employee: const LoginResult(
                    token: 'demo',
                    employeeId: 1,
                    username: 'seller',
                    expiresAt: '2099-12-01',
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      Future<void> tap(String label) async {
        final finder = find.text(label);
        await tester.ensureVisible(finder.first);
        await tester.tap(finder.first);
        await tester.pumpAndSettle();
      }

      await tap('open');
      await tap('未选择');
      await tap('Customer A');
      await tap('未选择');
      await tap('Warehouse B');
      await tap('添加退货款号');
      await tap('Top');
      await tap('Red / M');
      await tester.enterText(find.byType(TextFormField).at(1), '3');
      await tap('确认退货');
      await tap('重试提交');
      expect(attempts, hasLength(2));
      expect(attempts.first, attempts.last);
      expect(attempts.first['customer_id'], 3);
      expect(attempts.first['warehouse_id'], 4);
      expect(attempts.first['lines'], [containsPair('sku_id', 9)]);
      expect(attempts.first['lines'][0]['quantity'], 3);
      expect(attempts.first.containsKey('shipment_line_id'), isFalse);
    },
  );
}
