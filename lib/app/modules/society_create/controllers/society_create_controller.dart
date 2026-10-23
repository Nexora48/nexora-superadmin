import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/platform_repository.dart';

class SocietyCreateController extends GetxController {
  final PlatformRepository _repo = PlatformRepository(ApiClient.to);

  final nameCtrl = TextEditingController();
  final slugCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();
  final adminNameCtrl = TextEditingController();
  final adminEmailCtrl = TextEditingController();
  final adminPhoneCtrl = TextEditingController();
  final status = 'active'.obs;

  /// 0 Society, 1 Address, 2 First admin
  final step = 0.obs;
  final isLoading = false.obs;
  final error = ''.obs;

  @override
  void onClose() {
    for (final c in [nameCtrl, slugCtrl, addressCtrl, cityCtrl, stateCtrl, pincodeCtrl, adminNameCtrl, adminEmailCtrl, adminPhoneCtrl]) {
      c.dispose();
    }
    super.onClose();
  }

  String? _validate(int s) {
    switch (s) {
      case 0:
        if (nameCtrl.text.trim().length < 2) return 'Enter the society name';
        final slug = slugCtrl.text.trim();
        if (slug.isNotEmpty && !RegExp(r'^[a-z0-9-]{2,40}$').hasMatch(slug)) return 'Handle: lowercase letters, numbers and dashes only';
      case 2:
        if (adminNameCtrl.text.trim().isEmpty) return 'Enter the admin\'s full name';
        if (!GetUtils.isEmail(adminEmailCtrl.text.trim())) return 'Enter a valid admin email';
        if (adminPhoneCtrl.text.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter a 10-digit admin mobile number';
    }
    return null;
  }

  void next() {
    final e = _validate(step.value);
    error.value = e ?? '';
    if (e == null && step.value < 2) step.value++;
  }

  void back() {
    error.value = '';
    if (step.value > 0) step.value--;
  }

  /// Returns the created society and the one-time credentials, or null (error shown inline).
  Future<({SocietyDetail society, Credentials credentials})?> submit() async {
    final e = _validate(0) ?? _validate(2);
    if (e != null) {
      error.value = e;
      return null;
    }
    isLoading.value = true;
    error.value = '';
    try {
      return await _repo.createSociety({
        'name': nameCtrl.text.trim(),
        if (slugCtrl.text.trim().isNotEmpty) 'slug': slugCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'state': stateCtrl.text.trim(),
        'pincode': pincodeCtrl.text.trim(),
        'status': status.value,
        'admin': {
          'full_name': adminNameCtrl.text.trim(),
          'email': adminEmailCtrl.text.trim(),
          'phone': adminPhoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
        },
      });
    } on ApiException catch (ex) {
      error.value = ex.message;
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
