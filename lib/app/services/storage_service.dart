import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  static StorageService get to => Get.find();

  final _storage = GetStorage();

  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyAdminEmail = 'admin_email';

  bool get isLoggedIn => _storage.read(_keyIsLoggedIn) == true;

  String get adminEmail => _storage.read(_keyAdminEmail) ?? '';

  void setLoggedIn({required String email}) {
    _storage.write(_keyIsLoggedIn, true);
    _storage.write(_keyAdminEmail, email);
  }

  void logout() {
    _storage.remove(_keyIsLoggedIn);
    _storage.remove(_keyAdminEmail);
  }
}
