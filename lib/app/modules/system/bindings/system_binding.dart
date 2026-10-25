import 'package:get/get.dart';

import '../controllers/system_controller.dart';

class SystemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SystemController>(() => SystemController());
  }
}
