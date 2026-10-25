import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/download.dart';
import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/m10_repository.dart';
import '../../../data/repositories/platform_repository.dart';

class AuditLogsController extends GetxController {
  final M10Repository _repo = M10Repository(ApiClient.to);
  final PlatformRepository _platform = PlatformRepository(ApiClient.to);

  static const int perPage = 15;
  static const filters = {
    'All activity': '',
    'Societies': 'society.*',
    'Services': 'feature.*',
    'Plans': 'plan.*',
    'Staff': 'staff.*',
    'Broadcasts': 'broadcast.*',
    'Admins': 'admin.*',
    'Sign-ins': 'platform.*',
  };
  static const actorTypes = {'Anyone': '', 'Staff': 'platform', 'Society users': 'user', 'System': 'system'};

  final selected = 'All activity'.obs;
  final actorType = 'Anyone'.obs;
  final RxString societyId = ''.obs;
  final RxString from = ''.obs; // YYYY-MM-DD
  final RxString to = ''.obs;
  final textCtrl = TextEditingController();
  final RxList<SocietyRow> societies = <SocietyRow>[].obs;
  final currentPage = 1.obs;
  final total = 0.obs;
  final RxList<AuditRow> items = <AuditRow>[].obs;
  final isLoading = true.obs;
  final error = ''.obs;
  final RxString notice = ''.obs;
  final RxBool exporting = false.obs;
  final Rxn<AuditRow> detail = Rxn<AuditRow>();

  int get totalPages => (total.value / perPage).ceil().clamp(1, 1 << 30);

  bool get hasFilters => selected.value != 'All activity' || actorType.value != 'Anyone' || societyId.value.isNotEmpty || from.value.isNotEmpty || to.value.isNotEmpty || textCtrl.text.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    for (final r in [selected, actorType, societyId, from, to]) {
      ever(r, (_) => apply());
    }
    _platform.societies(pageSize: 100).then((p) => societies.assignAll(p.items)).catchError((_) {});
    load();
  }

  @override
  void onClose() {
    textCtrl.dispose();
    super.onClose();
  }

  void apply() {
    currentPage.value = 1;
    load();
  }

  void clearFilters() {
    textCtrl.clear();
    selected.value = 'All activity';
    actorType.value = 'Anyone';
    societyId.value = '';
    from.value = '';
    to.value = '';
  }

  String? get _soc => societyId.value.isEmpty ? null : societyId.value;

  Future<void> load() async {
    isLoading.value = items.isEmpty;
    error.value = '';
    try {
      final p = await _repo.audit(
        societyId: _soc,
        actorType: actorTypes[actorType.value],
        action: filters[selected.value],
        text: textCtrl.text.trim(),
        from: from.value,
        to: to.value,
        page: currentPage.value,
        pageSize: perPage,
      );
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

  Future<void> open(AuditRow r) async {
    detail.value = r;
    try {
      detail.value = await _repo.auditEntry(r.id); // full actor details
    } on ApiException {
      // the row we already have is enough
    }
  }

  Future<void> export() async {
    if (exporting.value) return;
    exporting.value = true;
    try {
      final csv = await _repo.auditCsv(
        societyId: _soc,
        actorType: actorTypes[actorType.value],
        action: filters[selected.value],
        text: textCtrl.text.trim(),
        from: from.value,
        to: to.value,
      );
      final rows = '\n'.allMatches(csv).length - 1;
      final ok = await downloadText('audit-log.csv', csv);
      notice.value = ok ? 'Exported $rows rows (the export is recorded in the audit log)' : 'Downloads work in the web build only';
      load();
    } on ApiException catch (e) {
      notice.value = e.message;
    } finally {
      exporting.value = false;
      Future.delayed(const Duration(seconds: 5), () => notice.value = '');
    }
  }
}
