import 'package:get/get.dart';

import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/platform_repository.dart';

class ServicesController extends GetxController {
  final PlatformRepository _repo = PlatformRepository(ApiClient.to);

  final RxList<CatalogueRow> items = <CatalogueRow>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      items.assignAll(await _repo.catalogue());
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }
}
