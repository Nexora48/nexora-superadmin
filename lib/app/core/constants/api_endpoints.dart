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
}
