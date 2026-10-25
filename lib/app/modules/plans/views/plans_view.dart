import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/m10_models.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/plans_controller.dart';

class PlansView extends GetView<PlansController> {
  const PlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final canEdit = PlatformAuthService.to.canEdit;

    // ── Plan form dialog ────────────────────────────────────────────────────
    formDialog(Plan? p) {
      controller.openForm(p);
      Get.dialog(
        dialogShell(
          context,
          title: p == null ? 'New plan' : 'Edit plan · ${p.name}',
          maxWidth: 640,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              TextField(
                controller: controller.nameCtrl,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  counterText: '',
                  isDense: true,
                ),
              ),
              if (p == null)
                TextField(
                  controller: controller.keyCtrl,
                  maxLength: 32,
                  decoration: const InputDecoration(
                    labelText: 'Key (cannot be changed later)',
                    hintText: 'e.g. premium_plus',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Per flat per month',
                        prefixText: '₹ ',
                        isDense: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller.flatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Flat fee per month',
                        prefixText: '₹ ',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Included services',
                style: context.appText.sectionHeader.copyWith(fontSize: 14),
              ),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final c in controller.catalogue)
                      FilterChip(
                        label: Text(c.name),
                        selected: controller.selectedFeatures.contains(c.key),
                        onSelected: (v) => controller.toggleFeature(c.key, v),
                      ),
                  ],
                ),
              ),
              Text(
                'Limits (leave empty for unlimited)',
                style: context.appText.sectionHeader.copyWith(fontSize: 14),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final e in planLimitLabels.entries)
                    SizedBox(
                      width: 190,
                      child: TextField(
                        controller: controller.limitCtrls[e.key],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: e.value,
                          helperText: hardLimits.contains(e.key)
                              ? 'blocks at the limit'
                              : 'warns only',
                          isDense: true,
                        ),
                      ),
                    ),
                ],
              ),
              if (p != null && p.societies > 0)
                Obx(
                  () => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: controller.applyToSocieties.value,
                    onChanged: (v) =>
                        controller.applyToSocieties.value = v ?? false,
                    title: Text(
                      'Also change the price for the ${p.societies} societies on this plan',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Otherwise only new assignments get the new price. Limits and services of existing societies follow the plan at their next change.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        if (await controller.save(p)) Get.back();
                      },
                child: Text(controller.busy.value ? 'Saving…' : 'Save plan'),
              ),
            ),
          ],
        ),
      );
    }

    // ── Societies on a plan ─────────────────────────────────────────────────
    societiesDialog(Plan p) {
      Get.dialog(
        dialogShell(
          context,
          title: 'Societies on ${p.name}',
          body: FutureBuilder(
            future: controller.societiesOf(p),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return Text(
                  'No society is on this plan.',
                  style: context.appText.timestamp,
                );
              }
              return Column(
                children: [
                  for (final s in list)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${s.city} · ${s.units} flats'),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Close')),
          ],
        ),
      );
    }

    // ── Plan card ───────────────────────────────────────────────────────────
    planCard(Plan p) {
      return cardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.name, style: context.appText.sectionHeader),
                ),
                if (p.archived)
                  pill(
                    'Archived',
                    AppColors.textSecondaryLight,
                    AppColors.backgroundLight,
                  ),
                if (p.key == 'legacy')
                  pill(
                    'No limits',
                    AppColors.primary,
                    AppColors.primaryLighter,
                  ),
              ],
            ),
            Text(p.key, style: context.appText.timestamp),
            const SizedBox(height: 10),
            Text(
              p.ratePerUnitPaise == 0 && p.flatFeePaise == 0
                  ? 'Free'
                  : '${rupees(p.ratePerUnitPaise)} per flat${p.flatFeePaise > 0 ? ' + ${rupees(p.flatFeePaise)}' : ''} / month',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in p.features)
                  pill(
                    controller.featureName(f),
                    AppColors.primary,
                    AppColors.primaryLighter,
                  ),
                if (p.features.isEmpty)
                  Text('No services', style: context.appText.timestamp),
              ],
            ),
            const SizedBox(height: 10),
            if (p.unlimited)
              Text('Unlimited', style: context.appText.timestamp)
            else
              for (final e in planLimitLabels.entries)
                if (p.limits.containsKey(e.key))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${p.limits[e.key]}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
            const Divider(height: 22),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => societiesDialog(p),
                  icon: const Icon(Icons.apartment_rounded, size: 16),
                  label: Text(
                    p.societies == 1 ? '1 society' : '${p.societies} societies',
                  ),
                ),
                const Spacer(),
                if (canEdit && !p.archived) ...[
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => formDialog(p),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  if (p.societies == 0 && p.key != 'legacy')
                    IconButton(
                      tooltip: 'Archive',
                      onPressed: () => controller.archive(p),
                      icon: const Icon(Icons.archive_outlined, size: 18),
                    ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return stateMessage(
          context,
          icon: Icons.cloud_off_rounded,
          title: 'Could not load plans',
          subtitle: controller.error.value,
          actionLabel: 'Retry',
          onAction: controller.load,
        );
      }
      final list = controller.visible;
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Plans',
                    style: context.appText.sectionHeader.copyWith(fontSize: 20),
                  ),
                ),
                Row(
                  children: [
                    const Text('Show archived', style: TextStyle(fontSize: 13)),
                    Switch(
                      value: controller.showArchived.value,
                      onChanged: (v) => controller.showArchived.value = v,
                    ),
                  ],
                ),
                if (canEdit)
                  FilledButton.icon(
                    onPressed: () => formDialog(null),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New plan'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'A plan sets the price, the services a society gets and its limits. Assign it from a society\'s page.',
              style: context.appText.timestamp,
            ),
            const SizedBox(height: 14),
            noticeBar(controller.notice),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1100
                    ? 3
                    : (c.maxWidth >= 700 ? 2 : 1);
                final w = (c.maxWidth - (cols - 1) * 14) / cols;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final p in list)
                      SizedBox(width: w, child: planCard(p)),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
