import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// Holds auth tokens in secure storage (never in GetStorage).
class TokenService extends GetxService {
  static TokenService get to => Get.find();

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  final _secure = const FlutterSecureStorage();

  String? accessToken;
  String? refreshToken;

  Future<TokenService> init() async {
    accessToken = await _secure.read(key: _kAccess);
    refreshToken = await _secure.read(key: _kRefresh);
    return this;
  }

  bool get hasSession => refreshToken != null;

  Future<void> save({required String access, required String refresh}) async {
    accessToken = access;
    refreshToken = refresh;
    await _secure.write(key: _kAccess, value: access);
    await _secure.write(key: _kRefresh, value: refresh);
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    await _secure.delete(key: _kAccess);
    await _secure.delete(key: _kRefresh);
  }
}
