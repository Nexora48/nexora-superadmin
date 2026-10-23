import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/platform_models.dart';
import '../../../routes/app_pages.dart';
import '../controllers/society_create_controller.dart';

class SocietyCreateView extends GetView<SocietyCreateController> {
  const SocietyCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Step indicator ──────────────────────────────────────────────────────
    stepper() {
      const labels = ['Society', 'Address', 'First admin'];
      return Obx(() => Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                CircleAvatar(
                  radius: 13,
                  backgroundColor: i <= controller.step.value ? AppColors.primary : AppColors.dividerLight,
                  child: i < controller.step.value
                      ? const Icon(Icons.check_rounded, size: 15, color: AppColors.white)
                      : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: i <= controller.step.value ? AppColors.white : AppColors.textSecondaryLight)),
                ),
                const SizedBox(width: 8),
                Text(labels[i], style: TextStyle(fontSize: 13, fontWeight: i == controller.step.value ? FontWeight.w700 : FontWeight.w500)),
                if (i < labels.length - 1) const Expanded(child: Divider(indent: 10, endIndent: 10)),
              ],
            ],
          ));
    }

    // ── Steps ───────────────────────────────────────────────────────────────
    societyStep() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: controller.nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Society name *', hintText: 'Lakeview Towers')),
          const SizedBox(height: 14),
          TextField(
            controller: controller.slugCtrl,
            decoration: const InputDecoration(labelText: 'Handle (optional)', helperText: 'Short unique id, e.g. lakeview-towers. Generated from the name when empty.'),
          ),
          const SizedBox(height: 14),
          Text('Starting status', style: context.appText.timestamp),
          const SizedBox(height: 6),
          Obx(() => SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'active', label: Text('Active')),
                  ButtonSegment(value: 'trial', label: Text('Trial')),
                ],
                selected: {controller.status.value},
                onSelectionChanged: (s) => controller.status.value = s.first,
              )),
        ],
      );
    }

    addressStep() {
      return Column(
        children: [
          TextField(controller: controller.addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(controller: controller.cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: controller.stateCtrl, decoration: const InputDecoration(labelText: 'State'))),
          ]),
          const SizedBox(height: 14),
          TextField(controller: controller.pincodeCtrl, decoration: const InputDecoration(labelText: 'Pincode')),
        ],
      );
    }

    adminStep() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This person manages the society in the Admin app. A temporary password is generated and shown once at the end.', style: context.appText.timestamp),
          const SizedBox(height: 14),
          TextField(controller: controller.adminNameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Full name *')),
          const SizedBox(height: 14),
          TextField(controller: controller.adminEmailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email * (used to sign in)')),
          const SizedBox(height: 14),
          TextField(controller: controller.adminPhoneCtrl, keyboardType: TextInputType.phone, maxLength: 10, decoration: const InputDecoration(labelText: 'Mobile number *', counterText: '')),
        ],
      );
    }

    // ── Credentials dialog (one-time) ───────────────────────────────────────
    credentialsDialog(SocietyDetail s, Credentials c) {
      Get.dialog(
        AlertDialog(
          title: const Text('Society created'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.name} is ready. Share these sign-in details with the admin:', style: context.appText.timestamp),
                const SizedBox(height: 12),
                SelectableText('Email: ${c.email}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (c.temporaryPassword != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: AppRadius.mdAll),
                    child: Row(children: [
                      Expanded(
                        child: SelectableText(c.temporaryPassword!,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                      IconButton(
                        tooltip: 'Copy',
                        onPressed: () => Clipboard.setData(ClipboardData(text: c.temporaryPassword!)),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                      ),
                    ]),
                  )
                else
                  Text('This person already has an account and signs in with their existing password.', style: context.appText.timestamp),
                if (c.temporaryPassword != null) ...[
                  const SizedBox(height: 10),
                  Text('Shown only once. They must set a new password at first sign-in.', style: context.appText.timestamp),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Get.back();
                Get.offNamed(Routes.societyDetail, arguments: s.id);
              },
              child: const Text('Open society'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: const Text('Onboard a society')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: cardBox(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                final s = controller.step.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stepper(),
                    const SizedBox(height: 22),
                    switch (s) { 0 => societyStep(), 1 => addressStep(), _ => adminStep() },
                    errorLine(controller.error.value),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        if (s > 0) OutlinedButton(onPressed: controller.back, child: const Text('Back')),
                        const Spacer(),
                        if (s < 2)
                          FilledButton(onPressed: controller.next, child: const Text('Next'))
                        else
                          FilledButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () async {
                                    final r = await controller.submit();
                                    if (r != null) credentialsDialog(r.society, r.credentials);
                                  },
                            child: controller.isLoading.value
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                : const Text('Create society'),
                          ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
