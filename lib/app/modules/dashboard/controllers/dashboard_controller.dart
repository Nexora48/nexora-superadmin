import 'package:get/get.dart';

import '../../../data/models/m10_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/m10_repository.dart';
import '../../../data/repositories/platform_repository.dart';

class DashboardController extends GetxController {
  final PlatformRepository _repo = PlatformRepository(ApiClient.to);
  final M10Repository _m10 = M10Repository(ApiClient.to);

  static const ranges = [7, 30, 90];

  final Rxn<PlatformStats> stats = Rxn<PlatformStats>();
  final Rxn<Overview> overview = Rxn<Overview>();
  final RxList<AuditRow> recent = <AuditRow>[].obs;
  final RxInt range = 30.obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ever(range, (_) => load());
    load();
  }

  Future<void> load() async {
    isLoading.value = stats.value == null;
    error.value = '';
    try {
      final r = await Future.wait([_repo.stats(), _repo.audit(pageSize: 8), _m10.overview(range.value)]);
      stats.value = r[0] as PlatformStats;
      recent.assignAll((r[1] as dynamic).items as List<AuditRow>);
      overview.value = r[2] as Overview;
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }
}
