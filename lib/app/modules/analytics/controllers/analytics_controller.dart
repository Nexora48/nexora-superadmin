import 'package:get/get.dart';

import '../../../core/utils/download.dart';
import '../../../data/models/m10_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/m10_repository.dart';
import '../../../data/repositories/platform_repository.dart';

class AnalyticsController extends GetxController {
  final M10Repository _repo = M10Repository(ApiClient.to);
  final PlatformRepository _platform = PlatformRepository(ApiClient.to);

  static const ranges = [7, 30, 90];

  final RxInt range = 30.obs;
  final RxList<MetricInfo> metrics = <MetricInfo>[].obs;
  final RxString metric = 'active_users'.obs;
  final RxString societyId = ''.obs; // '' = whole platform
  final RxList<SocietyRow> societies = <SocietyRow>[].obs;
  final RxList<Point> series = <Point>[].obs;
  final RxList<TopRow> top = <TopRow>[].obs;
  final RxList<ServiceAdoption> adoption = <ServiceAdoption>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxString notice = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ever(range, (_) => load());
    ever(metric, (_) => loadSeries());
    ever(societyId, (_) => loadSeries());
    load(first: true);
  }

  String metricName(String key) =>
      metrics.firstWhereOrNull((m) => m.key == key)?.name ?? key;

  int get total => series.fold(0, (a, p) => a + p.value);

  Future<void> load({bool first = false}) async {
    isLoading.value = adoption.isEmpty;
    error.value = '';
    try {
      if (first) {
        final r = await Future.wait([
          _repo.metrics(),
          _platform.societies(pageSize: 100),
        ]);
        metrics.assignAll(r[0] as List<MetricInfo>);
        societies.assignAll((r[1] as dynamic).items as List<SocietyRow>);
      }
      final r = await Future.wait([
        _repo.adoption(range.value),
        _repo.series(
          metric.value,
          range.value,
          societyId: societyId.value.isEmpty ? null : societyId.value,
        ),
        _repo.top(metric.value, range.value),
      ]);
      adoption.assignAll(r[0] as List<ServiceAdoption>);
      series.assignAll(r[1] as List<Point>);
      top.assignAll(r[2] as List<TopRow>);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSeries() async {
    try {
      final r = await Future.wait([
        _repo.series(
          metric.value,
          range.value,
          societyId: societyId.value.isEmpty ? null : societyId.value,
        ),
        _repo.top(metric.value, range.value),
      ]);
      series.assignAll(r[0] as List<Point>);
      top.assignAll(r[1] as List<TopRow>);
    } on ApiException catch (e) {
      error.value = e.message;
    }
  }

  /// Saves the shown series as a CSV (or reports that this build cannot).
  Future<void> exportSeries() async {
    final name = metric.value;
    final csv = StringBuffer('day,$name\n');
    for (final p in series) {
      csv.writeln('${p.day},${p.value}');
    }
    final ok = await downloadText('$name-${range.value}d.csv', csv.toString());
    notice.value = ok
        ? 'Saved $name-${range.value}d.csv'
        : 'Downloads work in the web build only';
    Future.delayed(const Duration(seconds: 4), () => notice.value = '');
  }
}
