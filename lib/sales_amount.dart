final _pricePattern = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$');

BigInt? salesCents(String? value) {
  final match = value == null ? null : _pricePattern.firstMatch(value);
  if (match == null) return null;
  return BigInt.parse('${match[1]}${(match[2] ?? '').padRight(2, '0')}');
}

String salesCentsText(BigInt cents) {
  final amount = cents.toString().padLeft(3, '0');
  return '${amount.substring(0, amount.length - 2)}.${amount.substring(amount.length - 2)}';
}

String? formatSalesDocumentAmount(
  Iterable<({String? unitPrice, int quantity})> lines,
) {
  var total = BigInt.zero;
  for (final (:unitPrice, :quantity) in lines) {
    final cents = salesCents(unitPrice);
    if (cents == null) return null;
    total += cents * BigInt.from(quantity);
  }
  return salesCentsText(total);
}
