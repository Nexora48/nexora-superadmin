import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../routes/app_pages.dart';

class AcceptInviteController extends GetxController {
  final tokenCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final RxBool busy = false.obs;
  final RxString error = ''.obs;
  final RxBool done = false.obs;
  final RxBool obscure = true.obs;

  @override
  void onInit() {
    super.onInit();
    // the invitation link carries the token: /#/accept-invite?token=...
    final fromRoute =
        Get.parameters['token'] ?? Uri.base.queryParameters['token'];
    final frag = Uri.base.fragment;
    final fromFragment = frag.contains('token=')
        ? Uri.splitQueryString(frag.substring(frag.indexOf('?') + 1))['token']
        : null;
    tokenCtrl.text = fromRoute ?? fromFragment ?? '';
  }

  @override
  void onClose() {
    tokenCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    error.value = '';
    if (tokenCtrl.text.trim().isEmpty) {
      error.value = 'Paste the invitation code from your link.';
      return;
    }
    if (passCtrl.text != confirmCtrl.text) {
      error.value = 'The two passwords do not match.';
      return;
    }
    busy.value = true;
    try {
      await ApiClient.to.post(
        ApiEndpoints.acceptInvite,
        body: {'token': tokenCtrl.text.trim(), 'password': passCtrl.text},
      );
      done.value = true;
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      busy.value = false;
    }
  }

  void toLogin() => Get.offAllNamed(Routes.login);
}
