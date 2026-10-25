int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String periodLabel(String period) {
  final p = period.split('-');
  return p.length == 2 ? '${_months[int.parse(p[1]) - 1]} ${p[0]}' : period;
}

class Subscription {
  final String societyId;
  final int ratePerUnitPaise;
  final int flatFeePaise;
  final int billingDay;
  final String status; // active | paused
  final String startsOn;
  final int units;
  final int nextAmountPaise;

  const Subscription({
    required this.societyId,
    required this.ratePerUnitPaise,
    required this.flatFeePaise,
    required this.billingDay,
    required this.status,
    required this.startsOn,
    required this.units,
    required this.nextAmountPaise,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    societyId: '${j['society_id']}',
    ratePerUnitPaise: _i(j['rate_per_unit_paise']),
    flatFeePaise: _i(j['flat_fee_paise']),
    billingDay: _i(j['billing_day']),
    status: '${j['status']}',
    startsOn: '${j['starts_on']}',
    units: _i(j['units']),
    nextAmountPaise: _i(j['next_amount_paise']),
  );

  bool get active => status == 'active';
}

class PlatformInvoice {
  final String id;
  final String societyId;
  final String society;
  final String period;
  final String number;
  final int units;
  final int amountPaise;
  final String status; // issued | paid
  final String dueDate;
  final String? paidOn;
  final String? reference;
  final bool overdue;

  const PlatformInvoice({
    required this.id,
    required this.societyId,
    required this.society,
    required this.period,
    required this.number,
    required this.units,
    required this.amountPaise,
    required this.status,
    required this.dueDate,
    this.paidOn,
    this.reference,
    required this.overdue,
  });

  factory PlatformInvoice.fromJson(Map<String, dynamic> j) => PlatformInvoice(
    id: '${j['id']}',
    societyId: '${j['society_id']}',
    society: '${j['society']}',
    period: '${j['period']}',
    number: '${j['number']}',
    units: _i(j['units']),
    amountPaise: _i(j['amount_paise']),
    status: '${j['status']}',
    dueDate: '${j['due_date']}',
    paidOn: j['paid_on'] as String?,
    reference: j['reference'] as String?,
    overdue: j['overdue'] == true,
  );

  bool get paid => status == 'paid';
}
