abstract class ApiEndpoints {
  static const String health = '/health';
  static const String ready = '/ready';

  // ── Console auth ───────────────────────────────────────────────────────────
  static const String login = '/superadmin/auth/login';
  static const String mfaVerify = '/superadmin/auth/mfa/verify';
  static const String refresh = '/superadmin/auth/refresh';
  static const String logout = '/superadmin/auth/logout';
  static const String me = '/superadmin/me';

  // ── Console data ───────────────────────────────────────────────────────────
  static const String societies = '/superadmin/societies';
  static String society(String id) => '/superadmin/societies/$id';
  static String suspend(String id) => '/superadmin/societies/$id/suspend';
  static String reactivate(String id) => '/superadmin/societies/$id/reactivate';
  static String admins(String id) => '/superadmin/societies/$id/admins';
  static String resetPassword(String id, String userId) => '/superadmin/societies/$id/admins/$userId/reset-password';
  static String feature(String id, String key) => '/superadmin/societies/$id/features/$key';
  static String featuresBulk(String id) => '/superadmin/societies/$id/features/bulk';
  static const String catalogue = '/superadmin/features';
  static const String audit = '/superadmin/audit';
  static const String stats = '/superadmin/stats';

  // ── Billing (M9) ───────────────────────────────────────────────────────────
  static String subscription(String societyId) => '/superadmin/societies/$societyId/subscription';
  static const String platformInvoices = '/superadmin/billing/invoices';
  static const String platformInvoicesGenerate = '/superadmin/billing/invoices/generate';
  static String platformInvoicePaid(String id) => '/superadmin/billing/invoices/$id/paid';

  // ── Plans, analytics, audit v2, staff, broadcast, system (M10) ─────────────
  static const String acceptInvite = '/superadmin/auth/accept-invite';
  static const String plans = '/superadmin/plans';
  static String plan(String id) => '/superadmin/plans/$id';
  static String planArchive(String id) => '/superadmin/plans/$id/archive';
  static String planSocieties(String id) => '/superadmin/plans/$id/societies';
  static String societyPlan(String id) => '/superadmin/societies/$id/plan';
  static String societyUsage(String id) => '/superadmin/societies/$id/usage';
  static const String analyticsMetrics = '/superadmin/analytics/metrics';
  static const String analyticsOverview = '/superadmin/analytics/overview';
  static const String analyticsServices = '/superadmin/analytics/services';
  static const String analyticsSeries = '/superadmin/analytics/timeseries';
  static const String analyticsTop = '/superadmin/analytics/top';
  static String auditEntry(int id) => '/superadmin/audit/$id';
  static const String auditExport = '/superadmin/audit/export.csv';
  static const String auditSettings = '/superadmin/audit/settings';
  static const String staff = '/superadmin/staff';
  static String staffMember(String id) => '/superadmin/staff/$id';
  static String staffReinvite(String id) => '/superadmin/staff/$id/reinvite';
  static String staffResetMfa(String id) => '/superadmin/staff/$id/reset-mfa';
  static const String broadcasts = '/superadmin/broadcasts';
  static String broadcastCancel(String id) => '/superadmin/broadcasts/$id/cancel';
  static const String systemHealth = '/superadmin/health';
  static const String appVersions = '/superadmin/app-versions';
  static String appVersion(String app) => '/superadmin/app-versions/$app';
}
