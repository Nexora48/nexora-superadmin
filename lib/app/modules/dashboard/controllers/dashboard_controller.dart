import 'package:get/get.dart';

import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/platform_repository.dart';

class DashboardController extends GetxController {
  final PlatformRepository _repo = PlatformRepository(ApiClient.to);

  final Rxn<PlatformStats> stats = Rxn<PlatformStats>();
  final RxList<AuditRow> recent = <AuditRow>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = stats.value == null;
    error.value = '';
    try {
      final r = await Future.wait([_repo.stats(), _repo.audit(pageSize: 8)]);
      stats.value = r[0] as PlatformStats;
      recent.assignAll((r[1] as dynamic).items as List<AuditRow>);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }
}
