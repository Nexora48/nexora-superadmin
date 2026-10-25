import 'package:get/get.dart';

import '../controllers/plans_controller.dart';

class PlansBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlansController>(() => PlansController());
  }
}
