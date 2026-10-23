import 'package:get/get.dart';

import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/platform_repository.dart';

class AuditLogsController extends GetxController {
  final PlatformRepository _repo = PlatformRepository(ApiClient.to);

  static const int perPage = 15;
  static const filters = {
    'All activity': '',
    'Societies': 'society.*',
    'Services': 'feature.*',
    'Admins': 'admin.*',
    'Staff sign-ins': 'platform.*',
  };

  final selected = 'All activity'.obs;
  final currentPage = 1.obs;
  final total = 0.obs;
  final RxList<AuditRow> items = <AuditRow>[].obs;
  final isLoading = true.obs;
  final error = ''.obs;

  int get totalPages => (total.value / perPage).ceil().clamp(1, 1 << 30);

  @override
  void onInit() {
    super.onInit();
    ever(selected, (_) {
      currentPage.value = 1;
      load();
    });
    load();
  }

  Future<void> load() async {
    isLoading.value = items.isEmpty;
    error.value = '';
    try {
      final p = await _repo.audit(action: filters[selected.value], page: currentPage.value, pageSize: perPage);
      total.value = p.total;
      items.assignAll(p.items);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void goToPage(int p) {
    if (p >= 1 && p <= totalPages) {
      currentPage.value = p;
      load();
    }
  }
}
