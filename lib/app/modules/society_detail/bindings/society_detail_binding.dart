import 'package:get/get.dart';

import '../controllers/society_detail_controller.dart';

class SocietyDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocietyDetailController>(() => SocietyDetailController());
  }
}
