import 'package:get/get.dart' hide Response;

import '../data/models/platform_models.dart';
import '../data/providers/api_client.dart';
import '../data/providers/api_exception.dart';
import '../data/repositories/platform_repository.dart';
import 'token_service.dart';

/// Owns the staff session: two-step sign-in, tokens, refresh and sign-out.
class PlatformAuthService extends GetxService {
  static PlatformAuthService get to => Get.find();

  late final PlatformRepository _repo = PlatformRepository(ApiClient.to);
  final TokenService _tokens = TokenService.to;

  final Rxn<StaffUser> user = Rxn<StaffUser>();

  /// Set by main.dart: called when the session dies (refresh failed / revoked).
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  bool get isLoggedIn => _tokens.hasSession;
  bool get canEdit => user.value?.isSuper ?? false;

  Future<PlatformAuthService> init() async {
    final api = ApiClient.to;
    api.onRefresh = refresh;
    api.onSessionExpired = () async {
      await _clear();
      onSessionExpired?.call();
    };
    return this;
  }

  // ── Sign-in ────────────────────────────────────────────────────────────────
  Future<LoginStep> login(String email, String password) => _repo.login(email, password);

  /// Step 2. Returns the session (with recovery codes after first enrolment).
  Future<PlatformSession> verifyMfa(String mfaToken, {String? code, String? recoveryCode}) async {
    final s = await _repo.verifyMfa(mfaToken, code: code, recoveryCode: recoveryCode);
    await _tokens.save(access: s.accessToken, refresh: s.refreshToken);
    user.value = s.user;
    return s;
  }

  // ── Session ────────────────────────────────────────────────────────────────
  /// Startup check; a network failure keeps the session so the console can retry.
  Future<bool> restoreSession() async {
    if (!isLoggedIn) return false;
    try {
      user.value = await _repo.me();
      return true;
    } on ApiException catch (e) {
      if (e.isNetwork) return true;
      await _clear();
      return false;
    }
  }

  Future<bool> refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final rt = _tokens.refreshToken;
    if (rt == null) return false;
    try {
      final s = await _repo.refresh(rt);
      await _tokens.save(access: s.accessToken, refresh: s.refreshToken);
      user.value = s.user;
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> logout() async {
    final rt = _tokens.refreshToken;
    if (rt != null) {
      try {
        await _repo.logout(rt);
      } catch (_) {
        // sign-out must always succeed locally
      }
    }
    await _clear();
  }

  Future<void> _clear() async {
    await _tokens.clear();
    user.value = null;
  }
}
