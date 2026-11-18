import 'package:flutter/material.dart';

import 'generated/api_schema.dart';
import 'sales_amount.dart';

Future<OrderItemWrite?> openSpecialGoods(
  BuildContext context, [
  OrderItemWrite? line,
]) => showDialog<OrderItemWrite>(
  context: context,
  builder: (_) => _SpecialGoods(line),
);

class _SpecialGoods extends StatefulWidget {
  const _SpecialGoods(this.line);
  final OrderItemWrite? line;

  @override
  State<_SpecialGoods> createState() => _SpecialGoodsState();
}

class _SpecialGoodsState extends State<_SpecialGoods> {
  final _form = GlobalKey<FormState>();
  late var _name = widget.line?.specialName ?? '';
  late var _price = widget.line?.unitPrice ?? '';
  late var _quantity = '${widget.line?.quantity ?? 1}';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('特殊货品'),
    content: SizedBox(
      width: 400,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                autofocus: true,
                initialValue: _name,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: '品名',
                  counterText: '',
                ),
                onChanged: (value) => _name = value,
                validator: (value) => value!.trim().isEmpty ? '请输入品名' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _price,
                decoration: const InputDecoration(labelText: '销售价（元）'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => _price = value,
                validator: (value) =>
                    salesCents(value!.trim()) == null ? '请输入单价，最多两位小数' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _quantity,
                decoration: const InputDecoration(labelText: '数量'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _quantity = value,
                validator: (value) => (int.tryParse(value!.trim()) ?? 0) <= 0
                    ? '请输入大于 0 的整数'
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            OrderItemWrite(
              specialName: _name.trim(),
              unitPrice: _price.trim(),
              quantity: int.parse(_quantity.trim()),
              notes: widget.line?.notes,
            ),
          );
        },
        child: Text(widget.line == null ? '添加' : '完成'),
      ),
    ],
  );
}
