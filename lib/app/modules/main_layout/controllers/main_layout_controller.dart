import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../services/platform_auth_service.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../audit_logs/controllers/audit_logs_controller.dart';
import '../../billing/controllers/billing_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../plans/controllers/plans_controller.dart';
import '../../societies/controllers/societies_controller.dart';
import '../../staff/controllers/staff_controller.dart';
import '../../system/controllers/system_controller.dart';

class MainLayoutController extends GetxController {
  final RxInt currentIndex = 0.obs;

  static const titles = ['Dashboard', 'Societies', 'Plans', 'Analytics', 'Services', 'Billing', 'Audit log', 'Staff', 'System'];

  /// The Staff page is for super admins only (the API refuses everyone else).
  bool visible(int i) => i != 7 || PlatformAuthService.to.canEdit;

  /// Switching tabs refreshes the data of the tab being shown.
  void select(int i) {
    currentIndex.value = i;
    switch (i) {
      case 0:
        Get.find<DashboardController>().load();
      case 1:
        Get.find<SocietiesController>().load();
      case 2:
        Get.find<PlansController>().load();
      case 3:
        Get.find<AnalyticsController>().load();
      case 5:
        Get.find<BillingController>().load();
      case 6:
        Get.find<AuditLogsController>().load();
      case 7:
        Get.find<StaffController>().load();
      case 8:
        Get.find<SystemController>().load();
    }
  }

  Future<void> logout() async {
    await PlatformAuthService.to.logout();
    Get.offAllNamed(Routes.login);
  }
}
