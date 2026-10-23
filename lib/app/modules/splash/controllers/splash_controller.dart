import 'package:get/get.dart';

import 'package:nexora_superadmin/app/data/models/health_status.dart';
import 'package:nexora_superadmin/app/data/providers/api_client.dart';
import 'package:nexora_superadmin/app/data/providers/api_exception.dart';
import 'package:nexora_superadmin/app/data/repositories/health_repository.dart';

class SplashController extends GetxController {
  final HealthRepository _repo = HealthRepository(ApiClient.to);

  final RxBool isLoading = true.obs;
  final Rxn<HealthStatus> health = Rxn<HealthStatus>();
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    checkServer();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────
  Future<void> checkServer() async {
    isLoading.value = true;
    error.value = null;
    try {
      health.value = await _repo.check();
      // M1: navigate to login / home based on TokenService.hasSession
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }
}
