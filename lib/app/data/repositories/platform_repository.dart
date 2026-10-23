import '../../core/constants/api_endpoints.dart';
import '../models/paged.dart';
import '../models/platform_models.dart';
import '../providers/api_client.dart';

class PlatformRepository {
  final ApiClient _api;
  PlatformRepository(this._api);

  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<LoginStep> login(String email, String password) async {
    final d = await _api.post(ApiEndpoints.login, body: {'email': email, 'password': password});
    return LoginStep.fromJson((d as Map).cast());
  }

  Future<PlatformSession> verifyMfa(String mfaToken, {String? code, String? recoveryCode}) async {
    final d = await _api.post(ApiEndpoints.mfaVerify, body: {
      'mfa_token': mfaToken,
      'code': ?code,
      'recovery_code': ?recoveryCode,
    });
    return PlatformSession.fromJson((d as Map).cast());
  }

  Future<PlatformSession> refresh(String refreshToken) async {
    final d = await _api.post(ApiEndpoints.refresh, body: {'refresh_token': refreshToken});
    return PlatformSession.fromJson((d as Map).cast());
  }

  Future<void> logout(String refreshToken) => _api.post(ApiEndpoints.logout, body: {'refresh_token': refreshToken});

  Future<StaffUser> me() async => StaffUser.fromJson(((await _api.get(ApiEndpoints.me)) as Map).cast());

  // ── Societies ──────────────────────────────────────────────────────────────
  Future<Paged<SocietyRow>> societies({String? q, String? status, int page = 1, int pageSize = 10}) async {
    final r = await _api.getPaged(ApiEndpoints.societies, query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
      'page_size': pageSize,
    });
    return Paged(
      items: (r.data as List).map((e) => SocietyRow.fromJson((e as Map).cast())).toList(),
      page: (r.meta['page'] as num?)?.toInt() ?? page,
      pageSize: (r.meta['page_size'] as num?)?.toInt() ?? pageSize,
      total: (r.meta['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<SocietyDetail> society(String id) async =>
      SocietyDetail.fromJson(((await _api.get(ApiEndpoints.society(id))) as Map).cast());

  Future<({SocietyDetail society, Credentials credentials})> createSociety(Map<String, dynamic> body) async {
    final d = (await _api.post(ApiEndpoints.societies, body: body)) as Map;
    return (
      society: SocietyDetail.fromJson((d['society'] as Map).cast()),
      credentials: Credentials.fromJson((d['admin_credentials'] as Map).cast()),
    );
  }

  Future<SocietyDetail> updateSociety(String id, Map<String, dynamic> body) async =>
      SocietyDetail.fromJson(((await _api.put(ApiEndpoints.society(id), body: body)) as Map).cast());

  Future<void> suspend(String id, String reason) => _api.post(ApiEndpoints.suspend(id), body: {'reason': reason});
  Future<void> reactivate(String id) => _api.post(ApiEndpoints.reactivate(id));

  Future<Credentials> addAdmin(String id, Map<String, dynamic> body) async =>
      Credentials.fromJson(((await _api.post(ApiEndpoints.admins(id), body: body)) as Map).cast());

  Future<Credentials> resetAdminPassword(String id, String userId) async =>
      Credentials.fromJson(((await _api.post(ApiEndpoints.resetPassword(id, userId))) as Map).cast());

  // ── Services ───────────────────────────────────────────────────────────────
  Future<List<FeatureRow>> setFeature(String id, String key, bool enabled, String reason) async {
    final d = await _api.put(ApiEndpoints.feature(id, key), body: {'enabled': enabled, 'reason': reason});
    return (d as List).map((e) => FeatureRow.fromJson((e as Map).cast())).toList();
  }

  Future<List<FeatureRow>> setFeaturesBulk(String id, Map<String, bool> features, String reason) async {
    final d = await _api.post(ApiEndpoints.featuresBulk(id), body: {'features': features, 'reason': reason});
    return (d as List).map((e) => FeatureRow.fromJson((e as Map).cast())).toList();
  }

  Future<List<CatalogueRow>> catalogue() async =>
      ((await _api.get(ApiEndpoints.catalogue)) as List).map((e) => CatalogueRow.fromJson((e as Map).cast())).toList();

  // ── Audit & stats ──────────────────────────────────────────────────────────
  Future<Paged<AuditRow>> audit({String? societyId, String? action, int page = 1, int pageSize = 15}) async {
    final r = await _api.getPaged(ApiEndpoints.audit, query: {
      'society_id': ?societyId,
      if (action != null && action.isNotEmpty) 'action': action,
      'page': page,
      'page_size': pageSize,
    });
    return Paged(
      items: (r.data as List).map((e) => AuditRow.fromJson((e as Map).cast())).toList(),
      page: (r.meta['page'] as num?)?.toInt() ?? page,
      pageSize: (r.meta['page_size'] as num?)?.toInt() ?? pageSize,
      total: (r.meta['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<PlatformStats> stats() async => PlatformStats.fromJson(((await _api.get(ApiEndpoints.stats)) as Map).cast());
}
