import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/m10_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/m10_repository.dart';

class SystemController extends GetxController {
  final M10Repository _repo = M10Repository(ApiClient.to);

  final Rxn<HealthReport> health = Rxn<HealthReport>();
  final RxList<AppVersion> versions = <AppVersion>[].obs;
  final RxInt retentionDays = 400.obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxString notice = ''.obs;
  final RxBool busy = false.obs;
  final RxString dialogError = ''.obs;

  final minCtrl = TextEditingController();
  final latestCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  final storeCtrl = TextEditingController();
  final retentionCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    for (final c in [
      minCtrl,
      latestCtrl,
      messageCtrl,
      storeCtrl,
      retentionCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = health.value == null;
    error.value = '';
    try {
      final r = await Future.wait([
        _repo.health(),
        _repo.appVersions(),
        _repo.retentionDays(),
      ]);
      health.value = r[0] as HealthReport;
      versions.assignAll(r[1] as List<AppVersion>);
      retentionDays.value = r[2] as int;
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

  void openVersion(AppVersion v) {
    dialogError.value = '';
    minCtrl.text = v.minVersion;
    latestCtrl.text = v.latestVersion;
    messageCtrl.text = v.message;
    storeCtrl.text = v.storeUrl;
  }

  Future<bool> saveVersion(AppVersion v) async {
    if (busy.value) return false;
    busy.value = true;
    dialogError.value = '';
    try {
      await _repo.saveAppVersion(
        AppVersion(
          app: v.app,
          minVersion: minCtrl.text.trim(),
          latestVersion: latestCtrl.text.trim(),
          message: messageCtrl.text.trim(),
          storeUrl: storeCtrl.text.trim(),
        ),
      );
      _flash('${v.label}: versions saved');
      await load();
      return true;
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> saveRetention() async {
    final n = int.tryParse(retentionCtrl.text.trim());
    if (n == null) {
      dialogError.value = 'Enter a number of days (30 to 3650).';
      return false;
    }
    try {
      retentionDays.value = await _repo.setRetentionDays(n);
      _flash('Audit retention set to ${retentionDays.value} days');
      return true;
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return false;
    }
  }

  String uptime(int s) {
    final d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60;
    return d > 0 ? '${d}d ${h}h' : (h > 0 ? '${h}h ${m}m' : '${m}m');
  }
}
