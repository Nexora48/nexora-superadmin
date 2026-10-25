import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/money.dart';
import '../../../data/models/m10_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/m10_repository.dart';
import '../../../data/repositories/platform_repository.dart';

class PlansController extends GetxController {
  final M10Repository _repo = M10Repository(ApiClient.to);
  final PlatformRepository _platform = PlatformRepository(ApiClient.to);

  final RxList<Plan> plans = <Plan>[].obs;
  final RxList<CatalogueRow> catalogue = <CatalogueRow>[].obs;
  final RxBool showArchived = false.obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxString notice = ''.obs;

  // plan dialog
  final RxBool busy = false.obs;
  final RxString dialogError = ''.obs;
  final nameCtrl = TextEditingController();
  final keyCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final flatCtrl = TextEditingController();
  final Map<String, TextEditingController> limitCtrls = {
    for (final k in planLimitLabels.keys) k: TextEditingController(),
  };
  final RxList<String> selectedFeatures = <String>[].obs;
  final RxBool applyToSocieties = false.obs;

  List<Plan> get visible =>
      plans.where((p) => showArchived.value || !p.archived).toList();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    keyCtrl.dispose();
    rateCtrl.dispose();
    flatCtrl.dispose();
    for (final c in limitCtrls.values) {
      c.dispose();
    }
    super.onClose();
  }

  String featureName(String key) =>
      catalogue.firstWhereOrNull((c) => c.key == key)?.name ?? key;

  Future<void> load() async {
    isLoading.value = plans.isEmpty;
    error.value = '';
    try {
      final r = await Future.wait([_repo.plans(), _platform.catalogue()]);
      plans.assignAll(r[0] as List<Plan>);
      catalogue.assignAll(r[1] as List<CatalogueRow>);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void _flash(String text) {
    notice.value = text;
    Future.delayed(const Duration(seconds: 4), () {
      if (notice.value == text) notice.value = '';
    });
  }

  /// Fills the dialog fields from [p] (edit) or with blanks (create).
  void openForm(Plan? p) {
    dialogError.value = '';
    nameCtrl.text = p?.name ?? '';
    keyCtrl.text = p?.key ?? '';
    rateCtrl.text = p == null || p.ratePerUnitPaise == 0
        ? ''
        : (p.ratePerUnitPaise / 100).toString();
    flatCtrl.text = p == null || p.flatFeePaise == 0
        ? ''
        : (p.flatFeePaise / 100).toString();
    for (final e in limitCtrls.entries) {
      e.value.text = p?.limits[e.key]?.toString() ?? '';
    }
    selectedFeatures.assignAll(p?.features ?? catalogue.map((c) => c.key));
    applyToSocieties.value = false;
  }

  void toggleFeature(String key, bool on) {
    if (on) {
      if (!selectedFeatures.contains(key)) selectedFeatures.add(key);
    } else {
      selectedFeatures.remove(key);
    }
  }

  Future<bool> save(Plan? existing) async {
    final name = nameCtrl.text.trim();
    final key = keyCtrl.text.trim().toLowerCase();
    final rate = parseRupeesOrZero(rateCtrl.text);
    final flat = parseRupeesOrZero(flatCtrl.text);
    if (name.isEmpty ||
        (existing == null && !RegExp(r'^[a-z0-9_]{2,32}$').hasMatch(key))) {
      dialogError.value =
          'Give the plan a name and a key (2-32 letters, digits or underscores).';
      return false;
    }
    if (rate == null || flat == null) {
      dialogError.value = 'Enter the prices in rupees.';
      return false;
    }
    final limits = <String, int>{};
    for (final e in limitCtrls.entries) {
      final t = e.value.text.trim();
      if (t.isEmpty) continue; // empty = unlimited
      final n = int.tryParse(t);
      if (n == null || n < 0) {
        dialogError.value =
            '${planLimitLabels[e.key]} must be a whole number (leave empty for unlimited).';
        return false;
      }
      limits[e.key] = n;
    }
    if (busy.value) return false;
    busy.value = true;
    dialogError.value = '';
    try {
      await _repo.savePlan(
        existing?.id,
        key: key,
        name: name,
        ratePerUnitPaise: rate,
        flatFeePaise: flat,
        features: selectedFeatures.toList(),
        limits: limits,
        applyToSocieties: applyToSocieties.value,
      );
      _flash(existing == null ? 'Plan "$name" created' : 'Plan "$name" saved');
      await load();
      return true;
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<void> archive(Plan p) async {
    try {
      await _repo.archivePlan(p.id);
      _flash('Plan "${p.name}" archived');
      await load();
    } on ApiException catch (e) {
      error.value = '';
      _flash(e.message);
    }
  }

  Future<List<MiniSociety>> societiesOf(Plan p) => _repo.planSocieties(p.id);
}
