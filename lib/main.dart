import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/core/theme/app_theme.dart';
import 'app/data/providers/api_client.dart';
import 'app/routes/app_pages.dart';
import 'app/services/platform_auth_service.dart';
import 'app/services/storage_service.dart';
import 'app/services/token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  await Get.putAsync(() async => StorageService());
  await Get.putAsync(() => TokenService().init());
  Get.put(ApiClient(), permanent: true);
  final auth = await Get.putAsync(() => PlatformAuthService().init());

  // The session died (refresh failed / revoked / role removed) -> back to sign-in.
  auth.onSessionExpired = () => Get.offAllNamed(Routes.login);

  final initialRoute = await auth.restoreSession() ? Routes.mainLayout : Routes.login;

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexora SuperAdmin',
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    ),
  );
}
