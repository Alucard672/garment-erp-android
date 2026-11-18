import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'app_update_notice.dart';
import 'customer_receipts.dart';
import 'draft.dart';
import 'erp_environment.dart';
import 'generated/api_schema.dart';
import 'order_draft_form.dart';
import 'order_fulfillment.dart';
import 'record_pages.dart';
import 'sales_shell.dart';
import 'sales_theme.dart';
import 'tablet_filter_panel.dart';
import 'scan_page.dart';
import 'search_picker.dart';
import 'sales_amount.dart';
import 'shipment_settlement.dart';
import 'special_goods.dart';
import 'style_details.dart';
import 'workspace_pages.dart';
import 'wheel_date.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ErpApp());
}

class ErpApp extends StatelessWidget {
  const ErpApp({super.key});

  static const _chineseText = TextStyle(
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: brandName,
    debugShowCheckedModeBanner: false,
    scrollBehavior: const MaterialScrollBehavior().copyWith(overscroll: false),
    builder: (_, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
      ),
      child: child!,
    ),
    theme: ThemeData(
      visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
      fontFamily: 'Roboto',
      fontFamilyFallback: const [
        'PingFang SC',
        'Microsoft YaHei',
        'Noto Sans CJK SC',
      ],
      textTheme: TextTheme(
        bodyLarge: _chineseText.copyWith(fontSize: 14),
        bodyMedium: _chineseText.copyWith(fontSize: 12, height: 1.3),
        bodySmall: _chineseText,
        labelLarge: _chineseText.copyWith(fontSize: 12),
        labelMedium: _chineseText,
        labelSmall: _chineseText,
        titleLarge: _chineseText.copyWith(fontSize: 16),
        titleMedium: _chineseText.copyWith(fontSize: 15),
        titleSmall: _chineseText,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: salesPrimary,
        primary: salesPrimary,
        surface: salesPaper,
        onSurface: salesInk,
      ),
      scaffoldBackgroundColor: salesCanvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: salesPaper,
        foregroundColor: salesInk,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: salesInk,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: salesPaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        titleTextStyle: TextStyle(
          color: salesInk,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: salesPaper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: salesLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: salesLine),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(color: salesLine),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: salesPrimary,
          backgroundColor: salesPaper,
          side: const BorderSide(color: salesLine),
          minimumSize: const Size(64, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    ),
    home: const _SessionScreen(),
  );
}

class _SessionScreen extends StatefulWidget {
  const _SessionScreen();
  @override
  State<_SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<_SessionScreen> {
  static const _environmentKey = 'erp.login.environment';
  final _environments = ErpEnvironments.build;
  final _preferences = SharedPreferencesAsync();
  late ErpEnvironment _environment = _environments.initial;
  late ErpApi _api;
  final _username = TextEditingController();
  final _password = TextEditingController();
  LoginResult? _employee;
  bool _loading = false;
  bool _restoringEnvironment = true;
  bool _changingEnvironment = false;
  String? _error;
  int _logoTaps = 0;
  Timer? _tapTimeout;

  String? get _serverUrl => _environments.urlFor(_environment);
  bool get _loginBusy =>
      _loading || _restoringEnvironment || _changingEnvironment;

  @override
  void initState() {
    super.initState();
    _api = ErpApi(baseUrl: _serverUrl ?? '');
    _restoreEnvironment();
  }

  Future<void> _restoreEnvironment() async {
    try {
      final saved = ErpEnvironment.fromName(
        await _preferences.getString(_environmentKey),
      );
      if (mounted && saved != null && _environments.urlFor(saved) != null) {
        setState(() => _useEnvironment(saved));
      }
    } catch (_) {
      // The build default is usable when preferences cannot be read.
    } finally {
      if (mounted) setState(() => _restoringEnvironment = false);
    }
  }

  void _useEnvironment(ErpEnvironment environment) {
    _environment = environment;
    _api.close();
    _api = ErpApi(baseUrl: _serverUrl ?? '');
  }

  void _onLogoTap() {
    if (_loginBusy) return;
    _tapTimeout?.cancel();
    if (++_logoTaps == 11) {
      _logoTaps = 0;
      _chooseEnvironment();
    } else {
      _tapTimeout = Timer(const Duration(seconds: 4), () => _logoTaps = 0);
    }
  }

  Future<void> _chooseEnvironment() async {
    FocusScope.of(context).unfocus();
    final choice = await showDialog<ErpEnvironment>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('切换环境'),
        children: [
          for (final environment in ErpEnvironment.values)
            ListTile(
              enabled: _environments.urlFor(environment) != null,
              title: Text(environment.label),
              subtitle: Text(_environments.urlFor(environment) ?? '此构建未配置地址'),
              trailing: environment == _environment
                  ? const Icon(Icons.check)
                  : null,
              onTap: _environments.urlFor(environment) == null
                  ? null
                  : () => Navigator.pop(context, environment),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
        ],
      ),
    );
    if (!mounted || choice == null || choice == _environment || _loginBusy) {
      return;
    }
    setState(() => _changingEnvironment = true);
    try {
      await _preferences.setString(_environmentKey, choice.name);
      if (!mounted) return;
      _username.clear();
      _password.clear();
      setState(() {
        _useEnvironment(choice);
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = '无法保存环境选择，请重试。');
    } finally {
      if (mounted) setState(() => _changingEnvironment = false);
    }
  }

  @override
  void dispose() {
    _tapTimeout?.cancel();
    _api.close();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginBusy ||
        _serverUrl == null ||
        _username.text.trim().isEmpty ||
        _password.text.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final employee = await _api.login(_username.text.trim(), _password.text);
      if (mounted) setState(() => _employee = employee);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiFailure ? error.message : '连接失败，请检查网络后重试。',
        );
      }
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    final employee = _employee;
    if (employee == null) return;
    try {
      await _api.logout(employee.token);
    } on ApiFailure catch (error) {
      if (error.status != 401) rethrow;
    }
    if (mounted) setState(() => _employee = null);
  }

  @override
  Widget build(BuildContext context) {
    final employee = _employee;
    if (employee != null) {
      return _OrderWorkspace(
        api: _api,
        employee: employee,
        onLogout: _logout,
        onPasswordChanged: () {
          if (!mounted) return;
          setState(() => _employee = null);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('密码已修改，请使用新密码重新登录。')));
        },
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 340,
              child: SalesPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      key: const ValueKey('login-logo'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _onLogoTap,
                      child: const SalesBrand(),
                    ),
                    const SizedBox(height: 6),
                    const Text('平板销售工作台 · 员工登录'),
                    const SizedBox(height: 4),
                    Text(
                      '当前环境 · ${_environment.label}',
                      style: const TextStyle(color: salesMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '账号',
                        constraints: BoxConstraints(minHeight: 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        constraints: BoxConstraints(minHeight: 40),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 16),
                    TabletAction(
                      _loading ? '正在登录…' : '登录',
                      primary: true,
                      onPressed: _loginBusy || _serverUrl == null
                          ? null
                          : _login,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderWorkspace extends StatefulWidget {
  const _OrderWorkspace({
    required this.api,
    required this.employee,
    required this.onLogout,
    required this.onPasswordChanged,
  });
  final VoidCallback onPasswordChanged;
  final ErpApi api;
  final LoginResult employee;
  final Future<void> Function() onLogout;

  @override
  State<_OrderWorkspace> createState() => _OrderWorkspaceState();
}

class _OrderInput {
  _OrderInput(this.storage);

  final DraftStorage storage;
  OrderDraft draft = OrderDraft();
  bool ready = false;
  bool restoring = false;
  bool dirty = false;
  String? saveError;
}

class _OrderWorkspaceState extends State<_OrderWorkspace> {
  final _fulfillmentKey = GlobalKey<OrderFulfillmentState>();
  late final _OrderInput _orderInput;
  late final _OrderInput _shipmentInput;
  bool _busy = false;
  SalesSection _section = SalesSection.home;
  bool _showOrderForm = false;
  bool _showDirectForm = false;
  bool _showPostedShipments = false;
  bool _leavingForm = false;
  String _scannedCode = '';
  int _scanRevision = 0;
  bool _checkForUpdateOnOpen = false;

  bool get _direct => _section == SalesSection.fulfillment;
  bool get _isOrderFormOpen => switch (_section) {
    SalesSection.fulfillment => _showDirectForm,
    SalesSection.orders => _showOrderForm,
    _ => false,
  };
  _OrderInput get _input => _direct ? _shipmentInput : _orderInput;
  OrderDraft get _draft => _input.draft;

  void _changeDraft(VoidCallback change) => setState(() {
    change();
    _input.dirty = true;
  });

  Future<void> _navigate(SalesSection section) async {
    if (_busy || _section == section) return;
    if (_fulfillmentKey.currentState case final sales?) {
      if (!await sales.leaveActiveEntry()) return;
    }
    if (_isOrderFormOpen && !await _openOrderForm(false)) return;
    if (mounted) {
      FocusScope.of(context).unfocus();
      setState(() {
        _section = section;
        _scannedCode = '';
        _checkForUpdateOnOpen = false;
      });
    }
  }

  void _openAppUpdate() {
    FocusScope.of(context).unfocus();
    setState(() {
      _checkForUpdateOnOpen = true;
      _section = SalesSection.settings;
    });
  }

  Future<void> _openScanner() async {
    FocusScope.of(context).unfocus();
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScanPage()));
    if (!mounted || code == null) return;
    setState(() {
      _section = SalesSection.forScannedCode(code);
      _scannedCode = code;
      _scanRevision++;
    });
  }

  Future<bool> _openOrderForm(bool show) async {
    if (_busy || _leavingForm) return false;
    final direct = _direct;
    final input = _input;
    if (!show && input.draft.hasLines && !input.draft.hasPending) {
      _leavingForm = true;
      try {
        final clear = await confirmClearDocument(context);
        if (!mounted || clear == null) return false;
        final retained = clear ? OrderDraft() : input.draft;
        await input.storage.write(retained);
        if (!mounted) return false;
        input.draft = retained;
        input.dirty = false;
        if (clear) input.saveError = null;
      } catch (_) {
        if (mounted) _message('无法处理单据录入内容，请重试。');
        return false;
      } finally {
        _leavingForm = false;
      }
    }
    FocusScope.of(context).unfocus();
    setState(() {
      if (direct) {
        _showDirectForm = show;
        if (show) _showPostedShipments = true;
      } else {
        _showOrderForm = show;
      }
    });
    return true;
  }

  Future<void> _editSpecialGoods([int? index]) async {
    final draft = _draft;
    final line = await openSpecialGoods(
      context,
      index == null ? null : draft.specialLines[index],
    );
    if (!mounted || line == null || _draft != draft) return;
    _changeDraft(() {
      if (index == null) {
        draft.specialLines.add(line);
      } else {
        draft.specialLines[index] = line;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _orderInput = _OrderInput(
      DraftStorage(
        widget.employee.employeeId,
        serverUrl: widget.api.storageServerKey,
      ),
    );
    _shipmentInput = _OrderInput(
      DraftStorage(
        widget.employee.employeeId,
        serverUrl: widget.api.storageServerKey,
        direct: true,
      ),
    );
    _restore(_orderInput);
    _restore(_shipmentInput);
  }

  Future<void> _restore(_OrderInput input) async {
    if (input.restoring) return;
    setState(() => input.restoring = true);
    try {
      final draft = await input.storage.read();
      if (mounted) {
        setState(() {
          input.draft = draft;
          input.ready = true;
        });
      }
    } catch (_) {
      if (mounted && input == _input) _message('单据录入内容读取失败，请重试。');
    } finally {
      if (mounted) setState(() => input.restoring = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickCustomer() async {
    final chosen = await showDialog<Customer>(
      context: context,
      builder: (_) => SearchPicker<Customer>(
        title: '选择客户',
        hint: '搜索客户名称或编号',
        label: (item) => item.name,
        code: (item) => item.code,
        load: (query, page) async {
          final list = await widget.api.customers(
            widget.employee.token,
            query,
            page,
          );
          return (items: list.results, hasNext: list.next != null);
        },
      ),
    );
    if (mounted && chosen != null) {
      _changeDraft(() => _draft.customer = chosen);
    }
  }

  Future<void> _pickWarehouse() async {
    final chosen = await showDialog<WarehouseRead>(
      context: context,
      builder: (_) => SearchPicker<WarehouseRead>(
        title: '选择发货仓库',
        hint: '搜索仓库名称或编号',
        label: (item) => item.name,
        code: (item) => item.code,
        load: (query, page) async {
          final list = await widget.api.list(
            token: widget.employee.token,
            path: ApiPath.warehousesList,
            decode: WarehouseRead.fromJson,
            search: query,
            page: page,
          );
          return (items: list.items, hasNext: list.hasNext);
        },
      ),
    );
    if (mounted && chosen != null) {
      _changeDraft(() => _draft.warehouse = chosen);
    }
  }

  Future<void> _pickClerk() async {
    final chosen = await showDialog<StaffRead>(
      context: context,
      builder: (_) => SearchPicker<StaffRead>(
        title: _direct ? '选择经手人' : '选择店员',
        hint: '搜索员工姓名或账号',
        label: (item) => item.name.isEmpty ? item.username : item.name,
        code: (item) => item.username,
        load: (query, page) async {
          final list = await widget.api.clerks(
            widget.employee.token,
            query,
            page,
          );
          return (items: list.results, hasNext: list.next != null);
        },
      ),
    );
    if (mounted && chosen != null) {
      _changeDraft(() => _draft.clerk = chosen);
    }
  }

  Future<void> _pickOrderProduct() async {
    final direct = _direct;
    final chosen = await showDialog<Style>(
      context: context,
      builder: (_) => SearchPicker<Style>(
        title: direct ? '选择货品' : '选择款号',
        hint: '搜索款号或款式名称',
        label: (item) => item.name,
        code: (item) => item.code,
        thumbnail: (item) => StylePhoto(
          key: ValueKey(item.id),
          api: widget.api,
          token: widget.employee.token,
          id: item.id,
          available: item.hasStyleImage,
          label: '${item.code} 款式图',
          expandable: false,
        ),
        load: (query, page) async {
          final list = await widget.api.styles(
            widget.employee.token,
            query,
            page,
          );
          return (items: list.results, hasNext: list.next != null);
        },
      ),
    );
    if (!mounted || chosen == null) return;
    setState(() => _busy = true);
    try {
      final cached = _draft.styles
          .where((style) => style.id == chosen.id)
          .firstOrNull;
      final style =
          cached ?? await widget.api.style(widget.employee.token, chosen.id);
      if (!mounted) return;
      if (!direct) {
        if (cached == null) {
          _changeDraft(() => _draft.styles.add(style));
        } else {
          _message('已添加 ${style.code}。');
        }
        return;
      }
      setState(() => _busy = false);
      final sku = await showDialog<Sku>(
        context: context,
        builder: (_) => SearchPicker<Sku>(
          title: '${style.code} · 选择颜色和尺码',
          hint: '搜索颜色或尺码',
          empty: '这个款号暂无可选规格。',
          label: (sku) => '${sku.color} / ${sku.size}',
          code: (sku) =>
              _draft.quantities.containsKey(sku.id) ||
                  _draft.lineNotes.containsKey(sku.id)
              ? '已添加'
              : style.name,
          load: (query, _) async {
            final terms = query.toLowerCase().split(RegExp(r'\s+'));
            return (
              items: style.skus.where((sku) {
                final label = '${sku.color} ${sku.size}'.toLowerCase();
                return terms.every(label.contains);
              }).toList(),
              hasNext: false,
            );
          },
        ),
      );
      if (!mounted || sku == null) return;
      if (_draft.quantities.containsKey(sku.id) ||
          _draft.lineNotes.containsKey(sku.id)) {
        _message('已添加 ${style.code} ${sku.color} / ${sku.size}。');
        return;
      }
      _changeDraft(() {
        if (cached == null) _draft.styles.add(style);
        _draft.quantities[sku.id] = 0;
      });
    } catch (error) {
      if (mounted) {
        _message(error is ApiFailure ? error.message : '款号规格加载失败，请重试。');
      }
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _removeOrderProduct(StyleDetail style, [Sku? sku]) async {
    final ids = sku == null
        ? style.skus.map((item) => item.id).toSet()
        : {sku.id};
    if (ids.any(
      (id) =>
          (_draft.quantities[id] ?? 0) > 0 ||
          (_draft.lineNotes[id]?.isNotEmpty ?? false),
    )) {
      final remove = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            sku == null
                ? '移除 ${style.code}'
                : '移除 ${style.code} ${sku.color} / ${sku.size}',
          ),
          content: Text(sku == null ? '此款的数量和规格备注会一并清除。' : '该规格的数量和备注会一并清除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('移除'),
            ),
          ],
        ),
      );
      if (!mounted || remove != true) return;
    }
    _changeDraft(() {
      _draft.quantities.removeWhere((id, _) => ids.contains(id));
      _draft.lineNotes.removeWhere((id, _) => ids.contains(id));
      if (sku == null ||
          !style.skus.any(
            (item) =>
                _draft.quantities.containsKey(item.id) ||
                _draft.lineNotes.containsKey(item.id),
          )) {
        _draft.styles.remove(style);
      }
    });
  }

  Future<void> _logout() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await _storeOrderInput();
      if (!mounted) return;
      await widget.onLogout();
    } catch (error) {
      if (mounted) {
        _message(error is ApiFailure ? error.message : '操作失败，请检查存储或网络后重试。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _storeOrderInput() async {
    for (final input in [_orderInput, _shipmentInput]) {
      if (input.dirty) {
        await input.storage.write(input.draft);
        input.dirty = false;
      }
    }
  }

  Future<void> _pickDueDate(BuildContext anchor) async {
    final date = await showWheelDatePicker(
      anchor,
      initial: DateTime.tryParse(_draft.dueDate ?? ''),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (mounted && date != null) {
      _changeDraft(
        () => _draft.dueDate = date.toIso8601String().split('T').first,
      );
    }
  }

  Future<void> _pickPaymentMethod() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('付款方式'),
        children: [
          for (final method in PaymentMethod.values)
            ListTile(
              title: Text(method.label),
              selected: method == _draft.paymentMethod,
              trailing: method == _draft.paymentMethod
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, method.code),
            ),
          ListTile(
            title: const Text('未指定'),
            onTap: () => Navigator.pop(context, ''),
          ),
        ],
      ),
    );
    if (!mounted || code == null) return;
    _changeDraft(() => _draft.paymentMethod = PaymentMethod.fromCode(code));
  }

  Future<void> _submitOrder() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final input = _input;
    final draft = input.draft;
    final direct = _direct;
    final documentType = direct ? '发货单' : '订单';
    final button = direct ? '确认发货' : '保存订单';
    setState(() {
      _busy = true;
      input.saveError = null;
    });
    String? confirmedCode;
    try {
      if (!draft.hasPending) {
        final lines = [
          for (final entry in draft.quantities.entries)
            if (entry.value > 0)
              OrderItemWrite(
                skuId: entry.key,
                quantity: entry.value,
                notes: draft.lineNotes[entry.key],
              ),
          ...draft.specialLines,
        ];
        if (direct) {
          draft.pendingShipment = DirectShipmentWrite(
            customerId: draft.customer!.id,
            warehouseId: draft.warehouse!.id,
            paymentMethod: draft.paymentMethod,
            paidAmount: salesCentsText(
              shipmentPaidCents(
                draft.paidAmount,
                draft.estimatedAmount,
                draft.paymentMethod,
              )!,
            ),
            clerkId: draft.clerk?.id,
            notes: draft.notes.trim(),
            requestKey: newRequestKey(),
            lines: lines,
          );
        } else {
          draft.pending = OrderWrite(
            customerId: draft.customer!.id,
            dueDate: draft.dueDate!,
            paymentMethod: draft.paymentMethod,
            clerkId: draft.clerk?.id,
            notes: draft.notes.trim(),
            requestKey: newRequestKey(),
            lines: lines,
          );
        }
      }
      await input.storage.write(draft);
      confirmedCode = direct
          ? (await widget.api.directShipment(
              widget.employee.token,
              draft.pendingShipment!,
            )).code
          : (await widget.api.confirmOrder(
              widget.employee.token,
              draft.pending!,
            )).code;
      final clean = OrderDraft();
      await input.storage.write(clean);
      if (!mounted) return;
      setState(() {
        input.draft = clean;
        input.dirty = false;
        if (direct) {
          _showDirectForm = false;
        } else {
          _showOrderForm = false;
        }
      });
      _message('$documentType $confirmedCode 已保存。');
    } catch (error) {
      if (error is ApiFailure && error.status == 400) {
        draft.pending = null;
        draft.pendingShipment = null;
        try {
          await input.storage.write(draft);
        } catch (_) {
          input.dirty = true;
          if (mounted) _message('设备无法保留单据录入内容。');
        }
      }
      if (mounted) {
        final message = confirmedCode == null
            ? requestFailure(error, '保存结果暂未确认，请重试$button。')
            : '$documentType $confirmedCode 已保存，请重试以完成本机记录清理。';
        setState(() => input.saveError = message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isOrderFormOpen,
    onPopInvokedWithResult: (popped, _) {
      if (!popped && _isOrderFormOpen) unawaited(_openOrderForm(false));
    },
    child: SalesShell(
      username: widget.employee.username,
      section: _section,
      onNavigate: _navigate,
      onScan: _busy ? null : _openScanner,
      onLogout: _busy ? null : _logout,
      orderHeader: _isOrderFormOpen
          ? (
              title: _direct ? '现货发货' : '新增客户订货',
              backLabel: _direct ? '返回销售开单' : '返回订单',
              onBack: _busy ? null : () => _openOrderForm(false),
            )
          : null,
      updateNotice: AppUpdateNotice(
        visible: !_busy && _section != SalesSection.settings,
        onOpen: _openAppUpdate,
      ),
      child: switch (_section) {
        SalesSection.fulfillment when _showDirectForm => _buildCustomerOrder(),
        SalesSection.fulfillment => OrderFulfillment(
          key: _fulfillmentKey,
          api: widget.api,
          employee: widget.employee,
          onNewCustomerOrder: () async {
            await _navigate(SalesSection.orders);
            if (mounted && _section == SalesSection.orders) {
              await _openOrderForm(true);
            }
          },
          onOpenDirectShipment: () => _openOrderForm(true),
          initialShipments: _showPostedShipments,
        ),
        SalesSection.orders when _showOrderForm => _buildCustomerOrder(),
        _ => WorkspacePages(
          key: ValueKey((_section, _scanRevision)),
          section: _section,
          api: widget.api,
          employee: widget.employee,
          onNewOrder: () => _openOrderForm(true),
          scannedCode: _scannedCode,
          onChangePassword: (current, next) async {
            await _storeOrderInput();
            await widget.api.changePassword(
              widget.employee.token,
              current,
              next,
            );
            if (mounted) widget.onPasswordChanged();
          },
          beforeAppUpdate: _storeOrderInput,
          checkForUpdateOnOpen: _checkForUpdateOnOpen,
        ),
      },
    ),
  );

  Widget _buildCustomerOrder() {
    final input = _input;
    final direct = _direct;
    final editing = !_draft.hasPending;
    final estimatedAmount = _draft.estimatedAmount;
    final canSave =
        input.ready &&
        (!editing ||
            (_draft.customer != null &&
                (direct ? _draft.warehouse != null : _draft.dueDate != null) &&
                (!direct ||
                    shipmentPaymentError(
                          _draft.paidAmount,
                          estimatedAmount,
                          _draft.paymentMethod,
                        ) ==
                        null) &&
                _draft.total > 0));
    return Column(
      key: ValueKey(direct),
      children: [
        Expanded(
          child: AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
              children: [
                if (!editing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      '上次保存结果待确认',
                      style: TextStyle(color: salesMuted, fontSize: 12),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (!input.ready)
                  Center(
                    child: input.restoring
                        ? const CircularProgressIndicator()
                        : OutlinedButton(
                            onPressed: () => _restore(input),
                            child: const Text('重试读取单据录入内容'),
                          ),
                  ),
                if (input.ready)
                  OrderDraftForm(
                    draft: _draft,
                    direct: direct,
                    stylePhoto: (style) => StylePhoto(
                      api: widget.api,
                      token: widget.employee.token,
                      id: style.id,
                      label: '${style.code} 款式图',
                      size: 40,
                      available:
                          style.specification?.hasStyleImage ??
                          style.hasStyleImage,
                    ),
                    onPickCustomer: editing ? _pickCustomer : null,
                    onWriteOff: editing && _draft.customer != null
                        ? () => openCustomerReceipt(
                            context,
                            widget.api,
                            widget.employee,
                            _draft.customer!.id,
                          )
                        : null,
                    onPickDueDate: editing ? _pickDueDate : null,
                    onPickPaymentMethod: editing ? _pickPaymentMethod : null,
                    onPickWarehouse: editing ? _pickWarehouse : null,
                    onPickClerk: editing ? _pickClerk : null,
                    onClearClerk: editing
                        ? () => _changeDraft(() => _draft.clerk = null)
                        : null,
                    onAddProduct: editing ? _pickOrderProduct : null,
                    onAddSpecial: editing ? _editSpecialGoods : null,
                    onEditSpecial: editing ? _editSpecialGoods : null,
                    onRemoveSpecial: editing
                        ? (index) => _changeDraft(
                            () => _draft.specialLines.removeAt(index),
                          )
                        : null,
                    onPaidChanged: editing
                        ? (value) =>
                              _changeDraft(() => _draft.paidAmount = value)
                        : null,
                    onRemoveSku: editing ? _removeOrderProduct : null,
                    onRemoveStyle: editing ? _removeOrderProduct : null,
                    onNotesChanged: editing
                        ? (value) => _changeDraft(() => _draft.notes = value)
                        : null,
                    onLineNotesChanged: editing
                        ? (sku, value) =>
                              _changeDraft(() => _draft.lineNotes[sku] = value)
                        : null,
                    onQuantityChanged: (sku, value) =>
                        _changeDraft(() => _draft.quantities[sku] = value),
                  ),
              ],
            ),
          ),
        ),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        if (input.saveError case final message?)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        Container(
          decoration: const BoxDecoration(
            color: salesSidebar,
            border: Border(top: BorderSide(color: salesLine)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${_draft.total} 件',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: salesPrimary,
                      ),
                    ),
                    if (estimatedAmount != null && _draft.total > 0)
                      Text(
                        '预计金额 ¥$estimatedAmount',
                        style: const TextStyle(color: salesMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              TabletAction(
                direct
                    ? editing
                          ? '确认发货'
                          : '重试确认发货'
                    : editing
                    ? '保存订单'
                    : '重试保存订单',
                primary: true,
                onPressed: _busy || !canSave ? null : _submitOrder,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
