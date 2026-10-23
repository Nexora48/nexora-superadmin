import 'package:get/get.dart';

import '../controllers/societies_controller.dart';

class SocietiesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocietiesController>(() => SocietiesController());
  }
}
