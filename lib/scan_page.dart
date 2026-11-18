import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _finished = false;
  bool _unsupportedCode = false;

  void _detect(BarcodeCapture capture) {
    if (_finished || !mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) continue;
      if (code.length > 48 || code.contains(RegExp(r'[\r\n\t]'))) {
        if (!_unsupportedCode) setState(() => _unsupportedCode = true);
        continue;
      }
      _finished = true;
      Navigator.of(context).pop(code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const CloseButton(), title: const Text('扫码')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _detect,
              errorBuilder: (context, error) => Center(
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? '请在系统设置中允许相机权限，也可返回扫码查询手动输入。'
                      : '无法打开相机，请关闭后重试。',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _unsupportedCode ? '无法使用此码查询，请扫描款号或订货单号。' : '将款号或订货单号的条码对准相机。',
            ),
          ),
        ],
      ),
    ),
  );
}
