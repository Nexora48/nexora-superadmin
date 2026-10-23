import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../services/platform_auth_service.dart';
import '../../audit_logs/controllers/audit_logs_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../societies/controllers/societies_controller.dart';

class MainLayoutController extends GetxController {
  final RxInt currentIndex = 0.obs;

  static const titles = ['Dashboard', 'Societies', 'Services', 'Audit log'];

  /// Switching tabs refreshes the data of the tab being shown.
  void select(int i) {
    currentIndex.value = i;
    switch (i) {
      case 0:
        Get.find<DashboardController>().load();
      case 1:
        Get.find<SocietiesController>().load();
      case 3:
        Get.find<AuditLogsController>().load();
    }
  }

  Future<void> logout() async {
    await PlatformAuthService.to.logout();
    Get.offAllNamed(Routes.login);
  }
}
