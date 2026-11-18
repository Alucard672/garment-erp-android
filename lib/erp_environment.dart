import 'package:flutter/foundation.dart';

enum ErpEnvironment {
  local('本地开发'),
  test('测试环境'),
  production('正式环境');

  const ErpEnvironment(this.label);
  final String label;

  static ErpEnvironment? fromName(String? name) {
    for (final environment in values) {
      if (environment.name == name) return environment;
    }
    return null;
  }
}

class ErpEnvironments {
  static const testServerUrl = 'https://121.43.167.158';
  static const testTunnelUrl = 'http://127.0.0.1:8080';

  ErpEnvironments({
    required bool debug,
    required String defaultUrl,
    String defaultEnvironment = '',
    String localUrl = '',
    String testUrl = '',
    String productionUrl = '',
  }) {
    const emulatorLocal = 'http://10.0.2.2:8001';
    final legacy = defaultUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final declared = {
      ErpEnvironment.production: productionUrl.trim(),
      ErpEnvironment.test: testUrl.trim(),
      ErpEnvironment.local: localUrl.trim(),
    };
    final requested = ErpEnvironment.fromName(defaultEnvironment);
    final matching = declared.keys
        .where(
          (environment) => legacy.isNotEmpty && declared[environment] == legacy,
        )
        .firstOrNull;
    final inferred =
        legacy == testServerUrl || (debug && legacy == testTunnelUrl)
        ? ErpEnvironment.test
        : !debug
        ? ErpEnvironment.production
        : legacy.startsWith('https://')
        ? ErpEnvironment.test
        : ErpEnvironment.local;
    final preferred = requested ?? matching ?? inferred;

    void add(ErpEnvironment environment, String explicit, String fallback) {
      final raw = explicit.trim();
      final value = raw.isNotEmpty
          ? raw
          : preferred == environment && legacy.isNotEmpty
          ? legacy
          : fallback;
      final uri = Uri.tryParse(value);
      final valid =
          uri != null &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty &&
          !uri.hasQuery &&
          !uri.hasFragment &&
          (uri.path.isEmpty || uri.path == '/') &&
          (uri.scheme == 'https' ||
              (debug &&
                  environment != ErpEnvironment.production &&
                  uri.scheme == 'http'));
      if (valid) _urls[environment] = value.replaceFirst(RegExp(r'/+$'), '');
    }

    add(ErpEnvironment.local, localUrl, emulatorLocal);
    add(ErpEnvironment.test, testUrl, testServerUrl);
    add(ErpEnvironment.production, productionUrl, '');
    initial = _urls.containsKey(preferred)
        ? preferred
        : _urls.keys.firstOrNull ?? preferred;
  }

  static final build = ErpEnvironments(
    debug: kDebugMode,
    defaultUrl: const String.fromEnvironment('ERP_API_URL'),
    defaultEnvironment: const String.fromEnvironment('ERP_DEFAULT_ENV'),
    localUrl: const String.fromEnvironment('ERP_LOCAL_API_URL'),
    testUrl: const String.fromEnvironment('ERP_TEST_API_URL'),
    productionUrl: const String.fromEnvironment('ERP_PRODUCTION_API_URL'),
  );

  final _urls = <ErpEnvironment, String>{};
  late final ErpEnvironment initial;

  String? urlFor(ErpEnvironment environment) => _urls[environment];
}
