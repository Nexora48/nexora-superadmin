/// Formats paise as "₹1,23,456.50" (Indian digit grouping; paise shown only when not zero).
String rupees(int paise) {
  final neg = paise < 0;
  final p = paise.abs();
  final r = p ~/ 100;
  final c = p % 100;
  var s = '$r';
  if (s.length > 3) {
    var head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final parts = <String>[];
    while (head.length > 2) {
      parts.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) parts.insert(0, head);
    s = '${parts.join(',')},$tail';
  }
  final body = c == 0 ? '₹$s' : '₹$s.${c.toString().padLeft(2, '0')}';
  return neg ? '-$body' : body;
}

/// Parses "1500" / "1,500.50" into paise; null when empty or invalid. Zero is allowed ("0" -> 0).
int? parseRupeesOrZero(String text) {
  final t = text.replaceAll(',', '').replaceAll('₹', '').trim();
  if (t.isEmpty) return 0;
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(t)) return null;
  final parts = t.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}
