import 'package:get/get.dart';

import '../controllers/mfa_controller.dart';

class MfaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MfaController>(() => MfaController());
  }
}
