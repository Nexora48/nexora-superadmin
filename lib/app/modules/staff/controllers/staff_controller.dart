import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/m10_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/m10_repository.dart';
import '../../../data/repositories/platform_repository.dart';
import '../../../services/platform_auth_service.dart';

class StaffController extends GetxController {
  final M10Repository _repo = M10Repository(ApiClient.to);
  final PlatformRepository _platform = PlatformRepository(ApiClient.to);

  final RxInt tab = 0.obs; // 0 team, 1 broadcast
  final RxList<StaffMember> staff = <StaffMember>[].obs;
  final RxList<Broadcast> broadcasts = <Broadcast>[].obs;
  final RxList<SocietyRow> societies = <SocietyRow>[].obs;
  final RxList<Plan> plans = <Plan>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxString notice = ''.obs;
  final RxBool busy = false.obs;
  final RxString dialogError = ''.obs;

  // invite dialog
  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final RxString inviteRole = 'platform_support'.obs;

  // broadcast composer
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final linkCtrl = TextEditingController();
  final RxString audienceMode = 'all'.obs; // all | plans | societies
  final RxList<String> pickedPlans = <String>[].obs;
  final RxList<String> pickedSocieties = <String>[].obs;
  final RxBool includeResidents = false.obs;
  final RxInt previewCount = (-1).obs;

  String get myId => PlatformAuthService.to.user.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    ever(
      tab,
      (_) => load(),
    ); // delivery counts move on their own, so refresh when the tab changes
    load();
  }

  @override
  void onClose() {
    for (final c in [emailCtrl, nameCtrl, titleCtrl, bodyCtrl, linkCtrl]) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = staff.isEmpty;
    error.value = '';
    try {
      final r = await Future.wait([
        _repo.staff(),
        _repo.broadcasts(),
        _platform.societies(pageSize: 100),
        _repo.plans(),
      ]);
      staff.assignAll(r[0] as List<StaffMember>);
      broadcasts.assignAll(r[1] as List<Broadcast>);
      societies.assignAll((r[2] as dynamic).items as List<SocietyRow>);
      plans.assignAll((r[3] as List<Plan>).where((p) => !p.archived));
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void flash(String text) {
    notice.value = text;
    Future.delayed(const Duration(seconds: 5), () {
      if (notice.value == text) notice.value = '';
    });
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (busy.value) return null;
    busy.value = true;
    dialogError.value = '';
    try {
      return await action();
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return null;
    } finally {
      busy.value = false;
    }
  }

  // ── Team ──────────────────────────────────────────────────────────────────
  void openInvite() {
    dialogError.value = '';
    emailCtrl.clear();
    nameCtrl.clear();
    inviteRole.value = 'platform_support';
  }

  Future<InviteResult?> invite() async {
    final email = emailCtrl.text.trim();
    final name = nameCtrl.text.trim();
    if (name.isEmpty || !email.contains('@')) {
      dialogError.value = 'Enter a name and a valid email.';
      return null;
    }
    final r = await _run(() => _repo.invite(email, name, inviteRole.value));
    if (r != null) await load();
    return r;
  }

  Future<InviteResult?> reinvite(StaffMember m) async {
    final r = await _run(() => _repo.reinvite(m.id));
    if (r != null) await load();
    return r;
  }

  /// Role / status change; returns an error text or null.
  Future<String?> change(StaffMember m, {String? role, String? status}) async {
    try {
      await _repo.updateStaff(m.id, role: role, status: status);
      await load();
      flash('${m.fullName} updated');
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> resetMfa(StaffMember m) async {
    try {
      await _repo.resetMfa(m.id);
      await load();
      flash(
        '${m.fullName} will set up the authenticator again at the next sign-in',
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // ── Broadcast ─────────────────────────────────────────────────────────────
  void openCompose() {
    dialogError.value = '';
    titleCtrl.clear();
    bodyCtrl.clear();
    linkCtrl.clear();
    audienceMode.value = 'all';
    pickedPlans.clear();
    pickedSocieties.clear();
    includeResidents.value = false;
    previewCount.value = -1;
  }

  bool get _audienceReady =>
      audienceMode.value == 'all' ||
      (audienceMode.value == 'plans'
          ? pickedPlans.isNotEmpty
          : pickedSocieties.isNotEmpty);

  Future<void> preview() async {
    previewCount.value = -1;
    if (!_audienceReady) return;
    final n = await _run(
      () => _repo.broadcastPreview(
        all: audienceMode.value == 'all',
        planIds: audienceMode.value == 'plans' ? pickedPlans.toList() : [],
        societyIds: audienceMode.value == 'societies'
            ? pickedSocieties.toList()
            : [],
        includeResidents: includeResidents.value,
      ),
    );
    if (n != null) previewCount.value = n;
  }

  Future<bool> send() async {
    if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
      dialogError.value = 'A title and a message are required.';
      return false;
    }
    if (!_audienceReady) {
      dialogError.value = 'Choose who receives it.';
      return false;
    }
    final b = await _run(
      () => _repo.sendBroadcast(
        title: titleCtrl.text.trim(),
        body: bodyCtrl.text.trim(),
        link: linkCtrl.text.trim(),
        all: audienceMode.value == 'all',
        planIds: audienceMode.value == 'plans' ? pickedPlans.toList() : [],
        societyIds: audienceMode.value == 'societies'
            ? pickedSocieties.toList()
            : [],
        includeResidents: includeResidents.value,
      ),
    );
    if (b == null) return false;
    flash('Broadcast queued for ${b.recipients} people');
    await load();
    return true;
  }

  Future<void> cancel(Broadcast b) async {
    try {
      await _repo.cancelBroadcast(b.id);
      flash('Broadcast cancelled');
    } on ApiException catch (e) {
      flash(e.message);
    }
    await load();
  }
}
