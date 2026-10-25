import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../controllers/accept_invite_controller.dart';

class AcceptInviteView extends GetView<AcceptInviteController> {
  const AcceptInviteView({super.key});

  @override
  Widget build(BuildContext context) {
    form() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set your password', style: context.appText.sectionHeader),
        const SizedBox(height: 4),
        Text(
          'At least 10 characters with upper case, lower case and a digit. You set up your authenticator app at the first sign-in.',
          style: context.appText.timestamp,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.tokenCtrl,
          decoration: const InputDecoration(
            labelText: 'Invitation code',
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => TextField(
            controller: controller.passCtrl,
            obscureText: controller.obscure.value,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscure.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => controller.obscure.toggle(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.confirmCtrl,
          obscureText: true,
          onSubmitted: (_) => controller.submit(),
          decoration: const InputDecoration(
            labelText: 'Repeat password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        Obx(() => errorLine(controller.error.value)),
        const SizedBox(height: 18),
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: controller.busy.value ? null : controller.submit,
              child: const Text('Save password'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: controller.toLogin,
            child: const Text('Back to sign-in'),
          ),
        ),
      ],
    );

    success() => Column(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text('Password saved', style: context.appText.sectionHeader),
        const SizedBox(height: 6),
        Text(
          'Sign in with your email and the new password. You will be asked to set up your authenticator app.',
          textAlign: TextAlign.center,
          style: context.appText.timestamp,
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: controller.toLogin,
          child: const Text('Go to sign-in'),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nexora SuperAdmin',
                  style: context.appText.sectionHeader.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 24),
                cardBox(
                  padding: const EdgeInsets.all(24),
                  child: Obx(() => controller.done.value ? success() : form()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
