import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';

abstract final class AppUpdateSource {
  static const channel = MethodChannel('garment_erp/app_updates');
  static const _configured = String.fromEnvironment('ERP_UPDATE_URL');
  static final url = _configured.isNotEmpty
      ? _configured
      : ErpApi.configuredUrl.startsWith('https://')
      ? Uri.parse(
          ErpApi.configuredUrl,
        ).resolve('/android-updates/latest.json').toString()
      : '';
}

class AppUpdatePanel extends StatefulWidget {
  const AppUpdatePanel({
    super.key,
    this.beforeInstall,
    this.updateUrl,
    this.checkOnOpen = false,
  });

  final Future<void> Function()? beforeInstall;
  final String? updateUrl;
  final bool checkOnOpen;

  @override
  State<AppUpdatePanel> createState() => _AppUpdatePanelState();
}

class _AppUpdatePanelState extends State<AppUpdatePanel> {
  static const _channel = AppUpdateSource.channel;
  String get _url => widget.updateUrl ?? AppUpdateSource.url;

  Map<String, dynamic>? _installed;
  Map<String, dynamic>? _available;
  String? _status;
  bool _busy = false;
  bool _downloaded = false;

  @override
  void initState() {
    super.initState();
    _loadVersionAndCheck();
  }

  Future<void> _loadVersionAndCheck() async {
    await _loadVersion();
    if (mounted && widget.checkOnOpen && _url.isNotEmpty) await _check();
  }

  Future<void> _loadVersion() async {
    try {
      final version = await _channel.invokeMapMethod<String, dynamic>(
        'version',
      );
      if (mounted) setState(() => _installed = version);
    } on PlatformException {
      if (mounted) setState(() => _status = '暂时无法读取当前版本。');
    } on MissingPluginException {
      if (mounted) setState(() => _status = '当前设备不支持此更新方式。');
    }
  }

  Future<void> _check() async {
    setState(() {
      _available = null;
      _downloaded = false;
    });
    await _run('正在检查更新…', () async {
      final latest = await _channel.invokeMapMethod<String, dynamic>('check', {
        'url': _url,
      });
      if (!mounted) return;
      setState(() {
        _available = latest;
        _status = latest == null ? '当前已是最新版本。' : null;
      });
    });
  }

  Future<void> _install() => _run('正在准备安装…', () async {
    if (!_downloaded) {
      setState(() => _status = '正在下载并校验新版 APK…');
      await _channel.invokeMethod<void>('download');
      if (!mounted) return;
      setState(() => _downloaded = true);
    }
    try {
      await widget.beforeInstall?.call();
    } catch (_) {
      if (mounted) setState(() => _status = '订单录入内容保留失败，请检查存储后重试。');
      return;
    }
    if (!mounted) return;
    final opened = await _channel.invokeMethod<bool>('install') == true;
    if (mounted) {
      setState(() {
        _status = opened ? '请在 Android 安装页面确认。' : '允许此来源安装应用后，返回点击「安装更新」。';
      });
    }
  });

  Future<void> _run(String status, Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = status;
    });
    try {
      await action();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          if (error.code == 'no_apk') _downloaded = false;
          _status = error.message ?? '更新失败，请稍后重试。';
        });
      }
    } on MissingPluginException {
      if (mounted) setState(() => _status = '当前设备不支持此更新方式。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = _installed;
    final available = _available;
    return SalesPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            installed == null
                ? '应用更新'
                : '当前版本 ${installed['name']}（${installed['code']}）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (available != null) ...[
            Text(
              '发现新版 ${available['name']}（${available['code']}）'
              ' · ${((available['bytes'] as int) / 1048576).toStringAsFixed(1)} MB',
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TabletAction(
                '检查更新',
                onPressed: _busy || _url.isEmpty ? null : _check,
              ),
              if (available != null)
                TabletAction(
                  _downloaded ? '安装更新' : '下载并安装',
                  primary: true,
                  onPressed: _busy ? null : _install,
                ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ],
          if (_status != null || _url.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _status ?? '当前构建未配置 HTTPS 更新地址。',
              style: const TextStyle(color: salesMuted),
            ),
          ],
        ],
      ),
    );
  }
}
