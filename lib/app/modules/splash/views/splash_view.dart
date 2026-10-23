import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nexora_superadmin/app/core/theme/app_colors.dart';
import 'package:nexora_superadmin/app/core/theme/app_spacing.dart';
import 'package:nexora_superadmin/app/core/theme/app_text_theme.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Brand header ────────────────────────────────────────────────────────
    brandView() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apartment_rounded, size: 72, color: AppColors.primary),
          SizedBox(height: AppSpacing.lg),
          Text('Nexora SuperAdmin', style: context.appText.sectionHeader),
        ],
      );
    }

    // ── Server status ───────────────────────────────────────────────────────
    statusView() {
      return Obx(() {
        if (controller.isLoading.value) {
          return const CircularProgressIndicator();
        }
        final err = controller.error.value;
        if (err != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(err, style: TextStyle(color: context.colors.textSecondary)),
              SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: controller.checkServer,
                child: const Text('Retry'),
              ),
            ],
          );
        }
        return Text(
          'Connected to ${controller.health.value?.service}',
          style: TextStyle(color: context.colors.textSecondary),
        );
      });
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [brandView(), SizedBox(height: AppSpacing.xl), statusView()],
        ),
      ),
    );
  }
}
