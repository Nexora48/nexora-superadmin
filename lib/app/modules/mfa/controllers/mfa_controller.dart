import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_exception.dart';
import '../../../routes/app_pages.dart';
import '../../../services/platform_auth_service.dart';

class MfaController extends GetxController {
  late final LoginStep step;

  final codeCtrl = TextEditingController();
  final recoveryCtrl = TextEditingController();

  final RxBool useRecovery = false.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool expired = false.obs;

  /// Shown once after first enrolment; the user must confirm they saved them.
  final RxList<String> recoveryCodes = <String>[].obs;
  final RxBool saved = false.obs;
  final RxBool copied = false.obs;

  @override
  void onInit() {
    super.onInit();
    step = Get.arguments as LoginStep;
  }

  @override
  void onClose() {
    codeCtrl.dispose();
    recoveryCtrl.dispose();
    super.onClose();
  }

  void toggleRecovery() {
    useRecovery.value = !useRecovery.value;
    error.value = '';
  }

  Future<void> verify() async {
    if (isLoading.value) return;
    final code = codeCtrl.text.trim();
    final rec = recoveryCtrl.text.trim();
    if (!useRecovery.value && !RegExp(r'^\d{6}$').hasMatch(code)) {
      error.value = 'Enter the 6-digit code';
      return;
    }
    if (useRecovery.value && rec.isEmpty) {
      error.value = 'Enter one of your recovery codes';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final session = await PlatformAuthService.to.verifyMfa(
        step.mfaToken,
        code: useRecovery.value ? null : code,
        recoveryCode: useRecovery.value ? rec : null,
      );
      if (session.recoveryCodes.isNotEmpty) {
        recoveryCodes.assignAll(session.recoveryCodes);
      } else {
        Get.offAllNamed(Routes.mainLayout);
      }
    } on ApiException catch (e) {
      if (e.code == 'MFA_EXPIRED') expired.value = true;
      error.value = e.message;
      codeCtrl.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyCodes() async {
    await Clipboard.setData(ClipboardData(text: recoveryCodes.join('\n')));
    copied.value = true;
  }

  void finish() => Get.offAllNamed(Routes.mainLayout);

  void backToLogin() => Get.offAllNamed(Routes.login);
}
