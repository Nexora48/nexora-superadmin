import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/providers/api_exception.dart';
import '../../../routes/app_pages.dart';
import '../../../services/platform_auth_service.dart';

class LoginController extends GetxController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscure = true.obs;
  final RxString error = ''.obs;

  void toggleObscure() => obscure.value = !obscure.value;

  Future<void> login() async {
    if (isLoading.value) return;
    final email = emailCtrl.text.trim();
    final pw = passwordCtrl.text;
    if (!GetUtils.isEmail(email)) {
      error.value = 'Enter your work email address';
      return;
    }
    if (pw.isEmpty) {
      error.value = 'Enter your password';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final step = await PlatformAuthService.to.login(email, pw);
      passwordCtrl.clear();
      Get.toNamed(Routes.mfa, arguments: step);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
