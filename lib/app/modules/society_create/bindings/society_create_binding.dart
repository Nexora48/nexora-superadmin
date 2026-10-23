import 'package:get/get.dart';

import '../controllers/society_create_controller.dart';

class SocietyCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocietyCreateController>(() => SocietyCreateController());
  }
}
