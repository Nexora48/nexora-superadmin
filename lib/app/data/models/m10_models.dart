int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
Map<String, dynamic> _m(dynamic v) =>
    ((v as Map?) ?? const {}).cast<String, dynamic>();
List<Map<String, dynamic>> _l(dynamic v) =>
    ((v as List?) ?? const []).map((e) => _m(e)).toList();

/// Plan limit keys in display order with their labels.
const planLimitLabels = <String, String>{
  'max_units': 'Flats',
  'max_residents': 'Residents',
  'max_guards': 'Guards',
  'max_admins': 'Office admins',
  'sms_per_month': 'SMS per month',
  'storage_mb': 'Storage (MB)',
  'visitors_per_month': 'Visitors per month',
};

/// Limits that stop creation (the others only warn).
const hardLimits = {
  'max_units',
  'max_residents',
  'max_guards',
  'max_admins',
  'sms_per_month',
};

class Plan {
  final String id;
  final String key;
  final String name;
  final int ratePerUnitPaise;
  final int flatFeePaise;
  final List<String> features;
  final Map<String, int> limits;
  final String status;
  final int societies;

  const Plan({
    required this.id,
    required this.key,
    required this.name,
    required this.ratePerUnitPaise,
    required this.flatFeePaise,
    required this.features,
    required this.limits,
    required this.status,
    required this.societies,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id: '${j['id']}',
    key: '${j['key']}',
    name: '${j['name']}',
    ratePerUnitPaise: _i(j['rate_per_unit_paise']),
    flatFeePaise: _i(j['flat_fee_paise']),
    features: ((j['features'] as List?) ?? const []).map((e) => '$e').toList(),
    limits: _m(j['limits']).map((k, v) => MapEntry(k, _i(v))),
    status: '${j['status']}',
    societies: _i(j['societies']),
  );

  bool get archived => status == 'archived';
  bool get unlimited => limits.isEmpty;
}

class MiniSociety {
  final String id;
  final String name;
  final String city;
  final int units;
  const MiniSociety({
    required this.id,
    required this.name,
    required this.city,
    required this.units,
  });
  factory MiniSociety.fromJson(Map<String, dynamic> j) => MiniSociety(
    id: '${j['id']}',
    name: '${j['name']}',
    city: '${j['city'] ?? ''}',
    units: _i(j['units']),
  );
}

class UsageRow {
  final String key;
  final String name;
  final int used;
  final int? max; // null = unlimited
  final bool hard;
  final bool exceeded;
  final bool atWarning;

  const UsageRow({
    required this.key,
    required this.name,
    required this.used,
    this.max,
    required this.hard,
    required this.exceeded,
    required this.atWarning,
  });

  factory UsageRow.fromJson(Map<String, dynamic> j) => UsageRow(
    key: '${j['key']}',
    name: '${j['name']}',
    used: _i(j['used']),
    max: j['max'] == null ? null : _i(j['max']),
    hard: j['hard'] == true,
    exceeded: j['exceeded'] == true,
    atWarning: j['at_warning'] == true,
  );

  /// 0..1+ share of the limit used (0 when unlimited).
  double get ratio => (max == null || max == 0) ? 0 : used / max!;
}

class AssignResult {
  final Plan plan;
  final List<UsageRow> exceeded;
  const AssignResult({required this.plan, required this.exceeded});
  factory AssignResult.fromJson(Map<String, dynamic> j) => AssignResult(
    plan: Plan.fromJson(_m(j['plan'])),
    exceeded: _l(j['exceeded']).map(UsageRow.fromJson).toList(),
  );
}

class Point {
  final String day; // YYYY-MM-DD
  final int value;
  const Point(this.day, this.value);
  factory Point.fromJson(Map<String, dynamic> j) =>
      Point('${j['day']}', _i(j['value']));
}

List<Point> _points(dynamic v) => _l(v).map(Point.fromJson).toList();

class SocietyUsage {
  final String planKey;
  final String planName;
  final List<UsageRow> usage;
  final String? planId;
  final List<String> differsFromPlan;
  final Map<String, int> monthTotals;
  final Map<String, List<Point>> series;

  const SocietyUsage({
    required this.planKey,
    required this.planName,
    required this.usage,
    this.planId,
    required this.differsFromPlan,
    required this.monthTotals,
    required this.series,
  });

  factory SocietyUsage.fromJson(Map<String, dynamic> j) {
    final p = _m(j['plan']);
    return SocietyUsage(
      planKey: '${p['plan_key'] ?? ''}',
      planName: '${p['plan_name'] ?? 'No plan'}',
      usage: _l(p['usage']).map(UsageRow.fromJson).toList(),
      planId: j['plan_id'] as String?,
      differsFromPlan: ((j['differs_from_plan'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
      monthTotals: _m(j['month_totals']).map((k, v) => MapEntry(k, _i(v))),
      series: _m(j['series']).map((k, v) => MapEntry(k, _points(v))),
    );
  }
}

class MetricInfo {
  final String key;
  final String name;
  final bool stock;
  final String service;
  const MetricInfo({
    required this.key,
    required this.name,
    required this.stock,
    required this.service,
  });
  factory MetricInfo.fromJson(Map<String, dynamic> j) => MetricInfo(
    key: '${j['key']}',
    name: '${j['name']}',
    stock: j['stock'] == true,
    service: '${j['service'] ?? ''}',
  );
}

class TopRow {
  final String societyId;
  final String name;
  final int value;
  const TopRow({
    required this.societyId,
    required this.name,
    required this.value,
  });
  factory TopRow.fromJson(Map<String, dynamic> j) => TopRow(
    societyId: '${j['society_id']}',
    name: '${j['name']}',
    value: _i(j['value']),
  );
}

class ServiceAdoption {
  final String key;
  final String name;
  final int enabled;
  final int used;
  final int adoptionPc;
  final List<MiniSociety> unused;
  const ServiceAdoption({
    required this.key,
    required this.name,
    required this.enabled,
    required this.used,
    required this.adoptionPc,
    required this.unused,
  });
  factory ServiceAdoption.fromJson(Map<String, dynamic> j) => ServiceAdoption(
    key: '${j['key']}',
    name: '${j['name']}',
    enabled: _i(j['enabled']),
    used: _i(j['used']),
    adoptionPc: _i(j['adoption_pc']),
    unused: _l(j['unused']).map(MiniSociety.fromJson).toList(),
  );
}

class PlatformAlert {
  final String kind; // limit | outbox | invoice
  final String message;
  final String? societyId;
  const PlatformAlert({
    required this.kind,
    required this.message,
    this.societyId,
  });
  factory PlatformAlert.fromJson(Map<String, dynamic> j) => PlatformAlert(
    kind: '${j['kind']}',
    message: '${j['message']}',
    societyId: j['society_id'] as String?,
  );
}

class Overview {
  final int societies;
  final int activeSocieties;
  final int dau;
  final int mau;
  final int mrrPaise;
  final int rangeDays;
  final Map<String, List<Point>> series;
  final List<TopRow> top;
  final List<ServiceAdoption> unused;
  final List<PlatformAlert> alerts;

  const Overview({
    required this.societies,
    required this.activeSocieties,
    required this.dau,
    required this.mau,
    required this.mrrPaise,
    required this.rangeDays,
    required this.series,
    required this.top,
    required this.unused,
    required this.alerts,
  });

  factory Overview.fromJson(Map<String, dynamic> j) => Overview(
    societies: _i(j['societies']),
    activeSocieties: _i(j['active_societies']),
    dau: _i(j['dau']),
    mau: _i(j['mau']),
    mrrPaise: _i(j['mrr_paise']),
    rangeDays: _i(j['range_days']),
    series: _m(j['series']).map((k, v) => MapEntry(k, _points(v))),
    top: _l(j['top']).map(TopRow.fromJson).toList(),
    unused: _l(j['unused']).map(ServiceAdoption.fromJson).toList(),
    alerts: _l(j['alerts']).map(PlatformAlert.fromJson).toList(),
  );
}

class StaffMember {
  final String id;
  final String email;
  final String fullName;
  final String role; // super_admin | platform_support
  final String status; // active | disabled
  final bool mfaEnabled;
  final DateTime? lastLoginAt;
  final bool invitePending;
  final DateTime? inviteExpiresAt;

  const StaffMember({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.mfaEnabled,
    this.lastLoginAt,
    required this.invitePending,
    this.inviteExpiresAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
    id: '${j['id']}',
    email: '${j['email']}',
    fullName: '${j['full_name']}',
    role: '${j['role']}',
    status: '${j['status']}',
    mfaEnabled: j['mfa_enabled'] == true,
    lastLoginAt: DateTime.tryParse('${j['last_login_at']}'),
    invitePending: j['invite_pending'] == true,
    inviteExpiresAt: DateTime.tryParse('${j['invite_expires_at']}'),
  );

  bool get isSuper => role == 'super_admin';
  bool get disabled => status == 'disabled';
  String get roleLabel => isSuper ? 'Super admin' : 'Support (read-only)';
}

class InviteResult {
  final StaffMember user;
  final String token;

  /// An invitation e-mail was handed to the mail server.
  final bool emailed;
  const InviteResult({
    required this.user,
    required this.token,
    this.emailed = false,
  });
  factory InviteResult.fromJson(Map<String, dynamic> j) => InviteResult(
    user: StaffMember.fromJson(_m(j['user'])),
    token: '${j['invite_token']}',
    emailed: j['emailed'] == true,
  );
}

class Broadcast {
  final String id;
  final String title;
  final String body;
  final String? link;
  final bool includeResidents;
  final String status; // queued | sending | sent | cancelled
  final int recipients;
  final int sentCount;
  final String? senderName;
  final DateTime createdAt;
  final String audienceLabel;

  const Broadcast({
    required this.id,
    required this.title,
    required this.body,
    this.link,
    required this.includeResidents,
    required this.status,
    required this.recipients,
    required this.sentCount,
    this.senderName,
    required this.createdAt,
    required this.audienceLabel,
  });

  factory Broadcast.fromJson(Map<String, dynamic> j) {
    final a = _m(j['audience']);
    final label = a['all'] == true
        ? 'All societies'
        : ((a['plan_ids'] as List?)?.isNotEmpty ?? false)
        ? '${(a['plan_ids'] as List).length} plan(s)'
        : '${(a['society_ids'] as List?)?.length ?? 0} society(ies)';
    return Broadcast(
      id: '${j['id']}',
      title: '${j['title']}',
      body: '${j['body']}',
      link: j['link'] as String?,
      includeResidents: j['include_residents'] == true,
      status: '${j['status']}',
      recipients: _i(j['recipients']),
      sentCount: _i(j['sent_count']),
      senderName: j['sender_name'] as String?,
      createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
      audienceLabel: label,
    );
  }

  bool get cancellable => status == 'queued';
}

class HealthCheck {
  final String name;
  final String status; // ok | warn | fail
  final String detail;
  const HealthCheck(this.name, this.status, this.detail);
  factory HealthCheck.fromJson(Map<String, dynamic> j) =>
      HealthCheck('${j['name']}', '${j['status']}', '${j['detail']}');
}

class HealthReport {
  final String version;
  final String commit;
  final int uptimeSeconds;
  final String status;
  final int migration;
  final List<HealthCheck> checks;
  final List<({String name, DateTime at})> sweepers;

  const HealthReport({
    required this.version,
    this.commit = '',
    required this.uptimeSeconds,
    required this.status,
    required this.migration,
    required this.checks,
    required this.sweepers,
  });

  factory HealthReport.fromJson(Map<String, dynamic> j) => HealthReport(
    version: '${j['version']}',
    commit: '${j['commit'] ?? ''}',
    uptimeSeconds: _i(j['uptime_seconds']),
    status: '${j['status']}',
    migration: _i(j['migration_version']),
    checks: _l(j['checks']).map(HealthCheck.fromJson).toList(),
    sweepers: _l(j['sweepers'])
        .map(
          (e) => (
            name: '${e['name']}',
            at: DateTime.tryParse('${e['last_run']}') ?? DateTime.now(),
          ),
        )
        .toList(),
  );
}

class AppVersion {
  final String app;
  final String minVersion;
  final String latestVersion;
  final String message;
  final String storeUrl;
  const AppVersion({
    required this.app,
    required this.minVersion,
    required this.latestVersion,
    required this.message,
    required this.storeUrl,
  });
  factory AppVersion.fromJson(Map<String, dynamic> j) => AppVersion(
    app: '${j['app']}',
    minVersion: '${j['min_version']}',
    latestVersion: '${j['latest_version']}',
    message: '${j['message'] ?? ''}',
    storeUrl: '${j['store_url'] ?? ''}',
  );

  String get label => switch (app) {
    'living' => 'Living (residents)',
    'admin' => 'Admin (society office)',
    'get' => 'Get (guards)',
    _ => app,
  };
}
