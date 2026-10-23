import 'package:get/get.dart';

import '../controllers/audit_logs_controller.dart';

class AuditLogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuditLogsController>(() => AuditLogsController());
  }
}
