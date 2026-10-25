import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/m10_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/m10_repository.dart';
import '../../../data/repositories/platform_repository.dart';

class SocietyDetailController extends GetxController {
  final PlatformRepository _repo = PlatformRepository(ApiClient.to);
  final M10Repository _m10 = M10Repository(ApiClient.to);

  late final String id;

  final Rxn<SocietyDetail> detail = Rxn<SocietyDetail>();
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxString notice = ''.obs;

  /// 0 Overview, 1 Services, 2 Admins, 3 Activity, 4 Usage
  final RxInt tab = 0.obs;
  final RxList<AuditRow> activity = <AuditRow>[].obs;
  final RxBool activityLoading = false.obs;

  // usage tab (M10)
  final Rxn<SocietyUsage> usage = Rxn<SocietyUsage>();
  final RxList<Plan> plans = <Plan>[].obs;
  final RxBool usageLoading = false.obs;
  final RxString usageError = ''.obs;
  final RxString pickedPlan = ''.obs;
  final RxBool keepPrice = false.obs;

  // ── Dialog state (shared by every dialog on this screen) ───────────────────
  final RxBool dialogBusy = false.obs;
  final RxString dialogError = ''.obs;
  final reasonCtrl = TextEditingController();

  // edit profile
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  // add admin
  final adminNameCtrl = TextEditingController();
  final adminEmailCtrl = TextEditingController();
  final adminPhoneCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    id = Get.arguments as String;
    load();
  }

  @override
  void onClose() {
    for (final c in [reasonCtrl, nameCtrl, addressCtrl, cityCtrl, stateCtrl, pincodeCtrl, adminNameCtrl, adminEmailCtrl, adminPhoneCtrl]) {
      c.dispose();
    }
    super.onClose();
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Future<void> load() async {
    isLoading.value = detail.value == null;
    error.value = '';
    try {
      detail.value = await _repo.society(id);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int i) {
    tab.value = i;
    if (i == 3) loadActivity();
    if (i == 4) loadUsage();
  }

  Future<void> loadActivity() async {
    activityLoading.value = true;
    try {
      activity.assignAll((await _repo.audit(societyId: id, pageSize: 30)).items);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      activityLoading.value = false;
    }
  }

  Future<void> loadUsage() async {
    usageLoading.value = usage.value == null;
    usageError.value = '';
    try {
      final r = await Future.wait([_m10.societyUsage(id), _m10.plans()]);
      usage.value = r[0] as SocietyUsage;
      plans.assignAll((r[1] as List<Plan>).where((p) => !p.archived));
    } on ApiException catch (e) {
      usageError.value = e.message;
    } finally {
      usageLoading.value = false;
    }
  }

  void openAssign() {
    dialogError.value = '';
    pickedPlan.value = usage.value?.planId ?? (plans.isNotEmpty ? plans.first.id : '');
    keepPrice.value = false;
  }

  /// Assigns the picked plan; returns the result (with limits already exceeded) or null on error.
  Future<AssignResult?> assignPlan() async {
    if (pickedPlan.value.isEmpty || dialogBusy.value) return null;
    dialogBusy.value = true;
    dialogError.value = '';
    try {
      final r = await _m10.assignPlan(id, pickedPlan.value, keepCustomPrice: keepPrice.value);
      showNotice('Plan changed to ${r.plan.name}: price and services updated');
      await Future.wait([loadUsage(), load()]);
      return r;
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return null;
    } finally {
      dialogBusy.value = false;
    }
  }

  void showNotice(String m) {
    notice.value = m;
    Future.delayed(const Duration(seconds: 5), () {
      if (notice.value == m) notice.value = '';
    });
  }

  void resetDialog() {
    dialogError.value = '';
    dialogBusy.value = false;
    reasonCtrl.clear();
  }

  /// Runs a mutation; on failure the message goes to [dialogError] and false is returned.
  Future<bool> _run(Future<void> Function() action, String success) async {
    dialogBusy.value = true;
    dialogError.value = '';
    try {
      await action();
      await load();
      if (tab.value == 3) loadActivity();
      showNotice(success);
      return true;
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return false;
    } finally {
      dialogBusy.value = false;
    }
  }

  String? _reason() {
    final r = reasonCtrl.text.trim();
    if (r.length < 3) {
      dialogError.value = 'Give a short reason (at least 3 characters). It is saved in the audit log.';
      return null;
    }
    return r;
  }

  // ── Society actions ────────────────────────────────────────────────────────
  Future<bool> suspend() async {
    final r = _reason();
    if (r == null) return false;
    return _run(() => _repo.suspend(id, r), 'Society suspended');
  }

  Future<bool> reactivate() => _run(() => _repo.reactivate(id), 'Society reactivated');

  void openEdit() {
    final d = detail.value!;
    nameCtrl.text = d.name;
    addressCtrl.text = d.address;
    cityCtrl.text = d.city;
    stateCtrl.text = d.state;
    pincodeCtrl.text = d.pincode;
    resetDialog();
  }

  Future<bool> saveEdit() async {
    if (nameCtrl.text.trim().length < 2) {
      dialogError.value = 'Enter the society name';
      return false;
    }
    return _run(() async {
      await _repo.updateSociety(id, {
        'name': nameCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'state': stateCtrl.text.trim(),
        'pincode': pincodeCtrl.text.trim(),
      });
    }, 'Society updated');
  }

  // ── Services ───────────────────────────────────────────────────────────────
  Future<bool> setFeature(FeatureRow f, bool enabled) {
    final r = _reason();
    if (r == null) return Future.value(false);
    return _run(() async {
      await _repo.setFeature(id, f.key, enabled, r);
    }, '${f.name} turned ${enabled ? 'on' : 'off'}');
  }

  Future<bool> setAllFeatures(bool enabled) {
    final r = _reason();
    if (r == null) return Future.value(false);
    final keys = detail.value!.features.map((f) => f.key);
    return _run(() async {
      await _repo.setFeaturesBulk(id, {for (final k in keys) k: enabled}, r);
    }, 'All services turned ${enabled ? 'on' : 'off'}');
  }

  // ── Admins ─────────────────────────────────────────────────────────────────
  void openAddAdmin() {
    adminNameCtrl.clear();
    adminEmailCtrl.clear();
    adminPhoneCtrl.clear();
    resetDialog();
  }

  /// Returns the one-time credentials, or null on failure.
  Future<Credentials?> addAdmin() async {
    final name = adminNameCtrl.text.trim();
    final email = adminEmailCtrl.text.trim();
    final phone = adminPhoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (name.isEmpty || !GetUtils.isEmail(email) || phone.length < 10) {
      dialogError.value = 'Enter a name, a valid email and a 10-digit mobile number';
      return null;
    }
    dialogBusy.value = true;
    dialogError.value = '';
    try {
      final c = await _repo.addAdmin(id, {'full_name': name, 'email': email, 'phone': phone});
      await load();
      showNotice('Admin added');
      return c;
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return null;
    } finally {
      dialogBusy.value = false;
    }
  }

  Future<Credentials?> resetPassword(AdminRow a) async {
    dialogBusy.value = true;
    dialogError.value = '';
    try {
      final c = await _repo.resetAdminPassword(id, a.id);
      await load();
      showNotice('Password reset for ${a.fullName}');
      return c;
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return null;
    } finally {
      dialogBusy.value = false;
    }
  }
}
