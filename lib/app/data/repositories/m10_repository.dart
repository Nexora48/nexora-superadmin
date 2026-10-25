import '../../core/constants/api_endpoints.dart';
import '../models/m10_models.dart';
import '../models/paged.dart';
import '../models/platform_models.dart';
import '../providers/api_client.dart';

class M10Repository {
  final ApiClient _api;
  M10Repository(this._api);

  Map<String, dynamic> _map(dynamic d) => (d as Map).cast<String, dynamic>();
  List<Map<String, dynamic>> _list(dynamic d) =>
      (d as List).map((e) => _map(e)).toList();

  // ── Plans ──────────────────────────────────────────────────────────────────
  Future<List<Plan>> plans() async =>
      _list(await _api.get(ApiEndpoints.plans)).map(Plan.fromJson).toList();

  Future<Plan> savePlan(
    String? id, {
    required String key,
    required String name,
    required int ratePerUnitPaise,
    required int flatFeePaise,
    required List<String> features,
    required Map<String, int> limits,
    bool applyToSocieties = false,
  }) async {
    final body = {
      if (id == null) 'key': key,
      'name': name,
      'rate_per_unit_paise': ratePerUnitPaise,
      'flat_fee_paise': flatFeePaise,
      'features': features,
      'limits': limits,
      if (id != null) 'apply_to_societies': applyToSocieties,
    };
    final d = id == null
        ? await _api.post(ApiEndpoints.plans, body: body)
        : await _api.put(ApiEndpoints.plan(id), body: body);
    return Plan.fromJson(_map(d));
  }

  Future<Plan> archivePlan(String id) async =>
      Plan.fromJson(_map(await _api.post(ApiEndpoints.planArchive(id))));

  Future<List<MiniSociety>> planSocieties(String id) async => _list(
    await _api.get(ApiEndpoints.planSocieties(id)),
  ).map(MiniSociety.fromJson).toList();

  Future<AssignResult> assignPlan(
    String societyId,
    String planId, {
    bool keepCustomPrice = false,
  }) async => AssignResult.fromJson(
    _map(
      await _api.put(
        ApiEndpoints.societyPlan(societyId),
        body: {'plan_id': planId, 'keep_custom_price': keepCustomPrice},
      ),
    ),
  );

  Future<SocietyUsage> societyUsage(String id) async => SocietyUsage.fromJson(
    _map(await _api.get(ApiEndpoints.societyUsage(id))),
  );

  // ── Analytics ──────────────────────────────────────────────────────────────
  Future<List<MetricInfo>> metrics() async => _list(
    await _api.get(ApiEndpoints.analyticsMetrics),
  ).map(MetricInfo.fromJson).toList();

  Future<Overview> overview(int range) async => Overview.fromJson(
    _map(
      await _api.get(ApiEndpoints.analyticsOverview, query: {'range': range}),
    ),
  );

  Future<List<ServiceAdoption>> adoption(int range) async => _list(
    await _api.get(ApiEndpoints.analyticsServices, query: {'range': range}),
  ).map(ServiceAdoption.fromJson).toList();

  Future<List<Point>> series(
    String metric,
    int range, {
    String? societyId,
  }) async => _list(
    await _api.get(
      ApiEndpoints.analyticsSeries,
      query: {'metric': metric, 'range': range, 'society_id': ?societyId},
    ),
  ).map(Point.fromJson).toList();

  Future<List<TopRow>> top(String metric, int range) async => _list(
    await _api.get(
      ApiEndpoints.analyticsTop,
      query: {'metric': metric, 'range': range},
    ),
  ).map(TopRow.fromJson).toList();

  // ── Audit v2 ───────────────────────────────────────────────────────────────
  Map<String, dynamic> _auditQuery({
    String? societyId,
    String? actorType,
    String? action,
    String? entity,
    String? text,
    String? from,
    String? to,
  }) => {
    'society_id': ?societyId,
    if (actorType != null && actorType.isNotEmpty) 'actor_type': actorType,
    if (action != null && action.isNotEmpty) 'action': action,
    if (entity != null && entity.isNotEmpty) 'entity': entity,
    if (text != null && text.isNotEmpty) 'q': text,
    if (from != null && from.isNotEmpty) 'from': from,
    if (to != null && to.isNotEmpty) 'to': to,
  };

  Future<Paged<AuditRow>> audit({
    String? societyId,
    String? actorType,
    String? action,
    String? entity,
    String? text,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 15,
  }) async {
    final r = await _api.getPaged(
      ApiEndpoints.audit,
      query: {
        ..._auditQuery(
          societyId: societyId,
          actorType: actorType,
          action: action,
          entity: entity,
          text: text,
          from: from,
          to: to,
        ),
        'page': page,
        'page_size': pageSize,
      },
    );
    return Paged(
      items: (r.data as List).map((e) => AuditRow.fromJson(_map(e))).toList(),
      page: (r.meta['page'] as num?)?.toInt() ?? page,
      pageSize: (r.meta['page_size'] as num?)?.toInt() ?? pageSize,
      total: (r.meta['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<AuditRow> auditEntry(int id) async =>
      AuditRow.fromJson(_map(await _api.get(ApiEndpoints.auditEntry(id))));

  /// The filtered log as CSV text (the server audits the export).
  Future<String> auditCsv({
    String? societyId,
    String? actorType,
    String? action,
    String? entity,
    String? text,
    String? from,
    String? to,
  }) => _api.getText(
    ApiEndpoints.auditExport,
    query: _auditQuery(
      societyId: societyId,
      actorType: actorType,
      action: action,
      entity: entity,
      text: text,
      from: from,
      to: to,
    ),
  );

  Future<int> retentionDays() async =>
      (_map(await _api.get(ApiEndpoints.auditSettings))['retention_days']
              as num)
          .toInt();

  Future<int> setRetentionDays(int days) async =>
      (_map(
                await _api.put(
                  ApiEndpoints.auditSettings,
                  body: {'retention_days': days},
                ),
              )['retention_days']
              as num)
          .toInt();

  // ── Staff ──────────────────────────────────────────────────────────────────
  Future<List<StaffMember>> staff() async => _list(
    await _api.get(ApiEndpoints.staff),
  ).map(StaffMember.fromJson).toList();

  Future<InviteResult> invite(String email, String name, String role) async =>
      InviteResult.fromJson(
        _map(
          await _api.post(
            ApiEndpoints.staff,
            body: {'email': email, 'full_name': name, 'role': role},
          ),
        ),
      );

  Future<InviteResult> reinvite(String id) async => InviteResult.fromJson(
    _map(await _api.post(ApiEndpoints.staffReinvite(id))),
  );

  Future<StaffMember> updateStaff(
    String id, {
    String? role,
    String? status,
  }) async => StaffMember.fromJson(
    _map(
      await _api.put(
        ApiEndpoints.staffMember(id),
        body: {'role': ?role, 'status': ?status},
      ),
    ),
  );

  Future<StaffMember> resetMfa(String id) async => StaffMember.fromJson(
    _map(await _api.post(ApiEndpoints.staffResetMfa(id))),
  );

  // ── Broadcast ──────────────────────────────────────────────────────────────
  Future<List<Broadcast>> broadcasts() async => _list(
    await _api.get(ApiEndpoints.broadcasts),
  ).map(Broadcast.fromJson).toList();

  Map<String, dynamic> _broadcastBody({
    required String title,
    required String body,
    required String link,
    required bool all,
    required List<String> planIds,
    required List<String> societyIds,
    required bool includeResidents,
    bool preview = false,
  }) => {
    'title': title,
    'body': body,
    if (link.isNotEmpty) 'link': link,
    'audience': {
      'all': all,
      if (planIds.isNotEmpty) 'plan_ids': planIds,
      if (societyIds.isNotEmpty) 'society_ids': societyIds,
    },
    'include_residents': includeResidents,
    if (preview) 'preview': true,
  };

  Future<int> broadcastPreview({
    required bool all,
    required List<String> planIds,
    required List<String> societyIds,
    required bool includeResidents,
  }) async =>
      (_map(
                await _api.post(
                  ApiEndpoints.broadcasts,
                  body: _broadcastBody(
                    title: 'preview',
                    body: 'preview',
                    link: '',
                    all: all,
                    planIds: planIds,
                    societyIds: societyIds,
                    includeResidents: includeResidents,
                    preview: true,
                  ),
                ),
              )['recipients']
              as num)
          .toInt();

  Future<Broadcast> sendBroadcast({
    required String title,
    required String body,
    required String link,
    required bool all,
    required List<String> planIds,
    required List<String> societyIds,
    required bool includeResidents,
  }) async => Broadcast.fromJson(
    _map(
      await _api.post(
        ApiEndpoints.broadcasts,
        body: _broadcastBody(
          title: title,
          body: body,
          link: link,
          all: all,
          planIds: planIds,
          societyIds: societyIds,
          includeResidents: includeResidents,
        ),
      ),
    ),
  );

  Future<Broadcast> cancelBroadcast(String id) async => Broadcast.fromJson(
    _map(await _api.post(ApiEndpoints.broadcastCancel(id))),
  );

  // ── System ─────────────────────────────────────────────────────────────────
  Future<HealthReport> health() async =>
      HealthReport.fromJson(_map(await _api.get(ApiEndpoints.systemHealth)));

  Future<List<AppVersion>> appVersions() async => _list(
    await _api.get(ApiEndpoints.appVersions),
  ).map(AppVersion.fromJson).toList();

  Future<AppVersion> saveAppVersion(AppVersion v) async => AppVersion.fromJson(
    _map(
      await _api.put(
        ApiEndpoints.appVersion(v.app),
        body: {
          'min_version': v.minVersion,
          'latest_version': v.latestVersion,
          'message': v.message,
          'store_url': v.storeUrl,
        },
      ),
    ),
  );
}
