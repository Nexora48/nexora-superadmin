import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Brand ───────────────────────────────────────────────────────────────
    brandView() {
      return Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.lgAll),
            child: const Icon(Icons.shield_rounded, color: AppColors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Text('Nexora SuperAdmin', style: context.appText.sectionHeader.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text('Internal console · authorised staff only', style: context.appText.timestamp),
        ],
      );
    }

    // ── Form ────────────────────────────────────────────────────────────────
    formView() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(labelText: 'Work email', prefixIcon: Icon(Icons.mail_outline_rounded)),
          ),
          const SizedBox(height: 14),
          Obx(() => TextField(
                controller: controller.passwordCtrl,
                obscureText: controller.obscure.value,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => controller.login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(controller.obscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: controller.toggleObscure,
                  ),
                ),
              )),
          Obx(() => errorLine(controller.error.value)),
          const SizedBox(height: 20),
          Obx(() => SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: controller.isLoading.value ? null : controller.login,
                  child: controller.isLoading.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Text('Continue'),
                ),
              )),
          const SizedBox(height: 14),
          Text('You will be asked for a 6-digit code from your authenticator app next.', style: context.appText.timestamp),
        ],
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                brandView(),
                const SizedBox(height: 28),
                cardBox(padding: const EdgeInsets.all(24), child: formView()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
