import 'package:flutter/material.dart';
import 'tablet_filter_panel.dart';

import 'api.dart';
import 'sales_theme.dart';

class PasswordSettingsPanel extends StatefulWidget {
  const PasswordSettingsPanel({super.key, required this.onChange});

  final Future<void> Function(String current, String next) onChange;

  @override
  State<PasswordSettingsPanel> createState() => _PasswordSettingsPanelState();
}

class _PasswordSettingsPanelState extends State<PasswordSettingsPanel> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirmation = TextEditingController();
  bool saving = false;
  String? error;

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    if (current.text.isEmpty ||
        next.text.isEmpty ||
        confirmation.text.isEmpty) {
      setState(() => error = '请填写当前密码、新密码和确认新密码。');
      return;
    }
    if (next.text != confirmation.text) {
      setState(() => error = '两次输入的新密码不一致。');
      return;
    }
    setState(() {
      error = null;
      saving = true;
    });
    try {
      await widget.onChange(current.text, next.text);
      if (!mounted) return;
      current.clear();
      next.clear();
      confirmation.clear();
    } catch (failure) {
      if (mounted) {
        setState(() => error = requestFailure(failure, '修改密码失败，请检查网络后重试。'));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget passwordField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return TextField(
      controller: controller,
      enabled: !saving,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: [hint],
      textInputAction: controller == confirmation
          ? TextInputAction.done
          : TextInputAction.next,
      onSubmitted: controller == confirmation ? (_) => save() : null,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SalesPanel(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                passwordField('当前密码', current, AutofillHints.password),
                const SizedBox(height: 10),
                passwordField('新密码', next, AutofillHints.newPassword),
                const SizedBox(height: 10),
                passwordField('确认新密码', confirmation, AutofillHints.newPassword),
                const SizedBox(height: 12),
                const Text('保存后，所有设备都需使用新密码登录。'),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 12),
                TabletAction(
                  saving ? '正在保存…' : '修改密码',
                  primary: true,
                  onPressed: saving ? null : save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
