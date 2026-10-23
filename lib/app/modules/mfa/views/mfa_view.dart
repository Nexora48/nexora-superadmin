import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../controllers/mfa_controller.dart';

class MfaView extends GetView<MfaController> {
  const MfaView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── First-time setup: QR + manual key ───────────────────────────────────
    setupView() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set up two-factor authentication', style: context.appText.sectionHeader),
          const SizedBox(height: 6),
          Text(
            'Scan this QR code with Google Authenticator, Microsoft Authenticator or 1Password, then enter the 6-digit code it shows.',
            style: context.appText.timestamp,
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.dividerLight), borderRadius: AppRadius.mdAll),
              child: QrImageView(data: controller.step.otpauthUrl ?? '', size: 180),
            ),
          ),
          const SizedBox(height: 12),
          Text("Can't scan? Enter this key manually:", style: context.appText.timestamp),
          const SizedBox(height: 4),
          SelectableText(
            controller.step.secret ?? '',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    // ── Code entry ──────────────────────────────────────────────────────────
    codeView() {
      return Obx(() {
        final recovery = controller.useRecovery.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!controller.step.setupRequired) ...[
              Text('Two-factor authentication', style: context.appText.sectionHeader),
              const SizedBox(height: 6),
              Text(
                recovery ? 'Enter one of the recovery codes you saved. Each works once.' : 'Enter the 6-digit code from your authenticator app.',
                style: context.appText.timestamp,
              ),
              const SizedBox(height: 16),
            ],
            if (!recovery)
              TextField(
                controller: controller.codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w700),
                onSubmitted: (_) => controller.verify(),
                decoration: const InputDecoration(counterText: '', hintText: '••••••'),
              )
            else
              TextField(
                controller: controller.recoveryCtrl,
                autofocus: true,
                onSubmitted: (_) => controller.verify(),
                decoration: const InputDecoration(labelText: 'Recovery code', hintText: 'abcde-fghij'),
              ),
            errorLine(controller.error.value),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: controller.isLoading.value ? null : controller.verify,
                child: controller.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(controller.step.setupRequired ? 'Confirm and sign in' : 'Verify'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: controller.backToLogin, child: const Text('Back to sign in')),
                if (!controller.step.setupRequired)
                  TextButton(
                    onPressed: controller.toggleRecovery,
                    child: Text(recovery ? 'Use authenticator code' : 'Use a recovery code'),
                  ),
              ],
            ),
          ],
        );
      });
    }

    // ── Recovery codes (shown once after enrolment) ─────────────────────────
    recoveryView() {
      return Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Save your recovery codes', style: context.appText.sectionHeader),
              const SizedBox(height: 6),
              Text(
                'If you lose your phone, each code lets you sign in once. They are shown only now. Store them somewhere safe.',
                style: context.appText.timestamp,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: AppRadius.mdAll),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    for (final c in controller.recoveryCodes)
                      SelectableText(c, style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.copyCodes,
                icon: Icon(controller.copied.value ? Icons.check_rounded : Icons.copy_rounded, size: 18),
                label: Text(controller.copied.value ? 'Copied' : 'Copy all'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: controller.saved.value,
                onChanged: (v) => controller.saved.value = v ?? false,
                title: const Text('I have saved these codes'),
              ),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: controller.saved.value ? controller.finish : null,
                  child: const Text('Continue to the console'),
                ),
              ),
            ],
          ));
    }

    expiredView() {
      return stateMessage(
        context,
        icon: Icons.timer_off_outlined,
        title: 'Sign-in expired',
        subtitle: 'Please start again.',
        actionLabel: 'Back to sign in',
        onAction: controller.backToLogin,
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: cardBox(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                if (controller.expired.value) return expiredView();
                if (controller.recoveryCodes.isNotEmpty) return recoveryView();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [if (controller.step.setupRequired) setupView(), codeView()],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
