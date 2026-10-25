import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_superadmin/app/core/utils/money.dart';
import 'package:nexora_superadmin/app/data/models/billing_models.dart';

void main() {
  test('money formatting and parsing', () {
    expect(rupees(12000000), '₹1,20,000');
    expect(rupees(150), '₹1.50');
    expect(parseRupeesOrZero(''), 0);
    expect(parseRupeesOrZero('50'), 5000);
    expect(parseRupeesOrZero('1,000.5'), 100050);
    expect(parseRupeesOrZero('x'), isNull);
    expect(parseRupeesOrZero('1.234'), isNull);
    expect(periodLabel('2026-10'), 'Oct 2026');
  });

  test('Subscription parses and knows when it bills', () {
    final s = Subscription.fromJson({
      'society_id': 's',
      'rate_per_unit_paise': 5000,
      'flat_fee_paise': 100000,
      'billing_day': 1,
      'status': 'active',
      'starts_on': '2026-01-01',
      'units': 4,
      'next_amount_paise': 120000,
    });
    expect(s.active, isTrue);
    expect(s.nextAmountPaise, 120000);
    expect(
      Subscription.fromJson({
        'society_id': 's',
        'billing_day': 1,
        'status': 'paused',
        'starts_on': '2026-01-01',
      }).active,
      isFalse,
    );
  });

  test('PlatformInvoice parses paid and overdue states', () {
    final open = PlatformInvoice.fromJson({
      'id': 'i',
      'society_id': 's',
      'society': 'Sunrise',
      'period': '2026-10',
      'number': 'PI-2610-0001',
      'units': 4,
      'amount_paise': 120000,
      'status': 'issued',
      'due_date': '2026-10-15',
      'overdue': true,
    });
    expect(open.paid, isFalse);
    expect(open.overdue, isTrue);
    final paid = PlatformInvoice.fromJson({
      'id': 'i',
      'society_id': 's',
      'society': 'Sunrise',
      'period': '2026-10',
      'number': 'PI-2610-0001',
      'units': 4,
      'amount_paise': 120000,
      'status': 'paid',
      'due_date': '2026-10-15',
      'paid_on': '2026-10-20',
      'reference': 'NEFT-1',
    });
    expect(paid.paid, isTrue);
    expect(paid.reference, 'NEFT-1');
  });
}
