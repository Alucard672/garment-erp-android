import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_update_panel.dart';
import 'sales_theme.dart';

class AppUpdateNotice extends StatefulWidget {
  const AppUpdateNotice({
    super.key,
    required this.visible,
    required this.onOpen,
    this.updateUrl,
  });

  final bool visible;
  final VoidCallback onOpen;
  final String? updateUrl;

  @override
  State<AppUpdateNotice> createState() => _AppUpdateNoticeState();
}

class _AppUpdateNoticeState extends State<AppUpdateNotice> {
  AppLifecycleListener? _lifecycle;
  Timer? _timer;
  DateTime? _lastProbe;
  bool _checking = false;
  Map<String, dynamic>? _available;
  int? _dismissed;

  String get _url => widget.updateUrl ?? AppUpdateSource.url;

  @override
  void initState() {
    super.initState();
    if (_url.isEmpty) return;
    _lifecycle = AppLifecycleListener(onResume: _check);
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _check();
      }
    });
    _check();
  }

  Future<void> _check() async {
    final previous = _lastProbe;
    if (_checking ||
        !widget.visible ||
        (previous != null &&
            DateTime.now().difference(previous) < const Duration(minutes: 1))) {
      return;
    }
    _checking = true;
    _lastProbe = DateTime.now();
    try {
      final available = await AppUpdateSource.channel
          .invokeMapMethod<String, dynamic>('probe', {'url': _url});
      if (mounted) setState(() => _available = available);
    } on PlatformException {
      // Checking in the background must not interrupt the workbench.
    } on MissingPluginException {
      // The updater is available on Android.
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = _available;
    if (!widget.visible ||
        available == null ||
        available['code'] == _dismissed) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: salesTint,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text('发现新版 ${available['name']}')),
            TextButton(onPressed: widget.onOpen, child: const Text('查看更新')),
            IconButton(
              tooltip: '稍后更新',
              onPressed: () =>
                  setState(() => _dismissed = available['code'] as int),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
