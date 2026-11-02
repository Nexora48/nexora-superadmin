import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/models/m10_models.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/plans_controller.dart';

class PlansView extends GetView<PlansController> {
  const PlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final canEdit = PlatformAuthService.to.canEdit;

    // each plan gets its own accent so the cards are easy to tell apart
    const palette = [AppColors.primary, AppColors.teal, AppColors.purple, AppColors.orange, AppColors.success];
    Color planColor(Plan p) {
      if (p.key == 'legacy') return AppColors.textSecondaryLight;
      final i = controller.plans.indexWhere((x) => x.id == p.id);
      return palette[(i < 0 ? 0 : i) % palette.length];
    }

    IconData limitIcon(String key) => switch (key) {
          'max_units' => Icons.meeting_room_outlined,
          'max_residents' => Icons.people_outline_rounded,
          'max_guards' => Icons.local_police_outlined,
          'max_admins' => Icons.admin_panel_settings_outlined,
          'sms_per_month' => Icons.sms_outlined,
          'storage_mb' => Icons.cloud_outlined,
          'visitors_per_month' => Icons.directions_walk_rounded,
          _ => Icons.speed_rounded,
        };

    // a small section title inside a dialog
    formTitle(IconData icon, String text) => Row(spacing: 8, children: [
          Icon(icon, size: 18, color: AppColors.primary),
          Text(text, style: context.appText.sectionHeader.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
        ]);

    // numbers only (digits and one decimal point) for money fields
    money() => [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    // ── Plan form dialog ────────────────────────────────────────────────────
    formDialog(Plan? p) {
      controller.openForm(p);
      Get.dialog(
        dialogShell(
          context,
          title: p == null ? 'New plan' : 'Edit plan · ${p.name}',
          subtitle: 'Price, services and limits a society gets',
          icon: p == null ? Icons.add_card_rounded : Icons.edit_rounded,
          color: p == null ? AppColors.primary : planColor(p),
          maxWidth: 660,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              TextField(
                controller: controller.nameCtrl,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name', counterText: '', prefixIcon: Icon(Icons.workspace_premium_outlined, size: 20)),
              ),
              if (p == null)
                TextField(
                  controller: controller.keyCtrl,
                  maxLength: 32,
                  decoration: const InputDecoration(
                    labelText: 'Key (cannot be changed later)',
                    hintText: 'e.g. premium_plus',
                    counterText: '',
                    prefixIcon: Icon(Icons.key_rounded, size: 20),
                  ),
                ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: money(),
                      decoration: const InputDecoration(labelText: 'Per flat per month', prefixText: '₹ ', prefixIcon: Icon(Icons.home_work_outlined, size: 20)),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller.flatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: money(),
                      decoration: const InputDecoration(labelText: 'Flat fee per month', prefixText: '₹ ', prefixIcon: Icon(Icons.payments_outlined, size: 20)),
                    ),
                  ),
                ],
              ),
              formTitle(Icons.extension_outlined, 'Included services'),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in controller.catalogue)
                      FilterChip(
                        label: Text(c.name),
                        selected: controller.selectedFeatures.contains(c.key),
                        showCheckmark: true,
                        onSelected: (v) => controller.toggleFeature(c.key, v),
                      ),
                  ],
                ),
              ),
              formTitle(Icons.speed_rounded, 'Limits (leave empty for unlimited)'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final e in planLimitLabels.entries)
                    SizedBox(
                      width: 190,
                      child: TextField(
                        controller: controller.limitCtrls[e.key],
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: e.value,
                          prefixIcon: Icon(limitIcon(e.key), size: 19),
                          helperText: hardLimits.contains(e.key) ? 'blocks at the limit' : 'warns only',
                        ),
                      ),
                    ),
                ],
              ),
              if (p != null && p.societies > 0)
                Obx(
                  () => Container(
                    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(14)),
                    child: CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      value: controller.applyToSocieties.value,
                      onChanged: (v) => controller.applyToSocieties.value = v ?? false,
                      title: Text('Also change the price for the ${p.societies} societies on this plan', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: const Text(
                        'Otherwise only new assignments get the new price. Limits and services of existing societies follow the plan at their next change.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              dialogErrorText(controller.dialogError),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton.icon(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        if (await controller.save(p)) Get.back();
                      },
                icon: controller.busy.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save plan'),
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
          subtitle: p.societies == 1 ? '1 society' : '${p.societies} societies',
          icon: Icons.apartment_rounded,
          color: planColor(p),
          maxWidth: 460,
          body: FutureBuilder(
            future: controller.societiesOf(p),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return stateMessage(context, icon: Icons.apartment_outlined, title: 'No society is on this plan', subtitle: 'Assign it from a society\'s page.');
              }
              return Column(
                children: [
                  for (final s in list)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(14)),
                      child: Row(spacing: 12, children: [
                        IconTile(Icons.apartment_rounded, planColor(p), size: 38),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Wrap(spacing: 12, children: [
                              if (s.city.isNotEmpty) MetaItem(Icons.place_outlined, s.city),
                              MetaItem(Icons.meeting_room_outlined, '${s.units} flats'),
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                ],
              );
            },
          ),
          actions: [FilledButton(onPressed: Get.back, child: const Text('Close'))],
        ),
      );
    }

    // ── Plan card ───────────────────────────────────────────────────────────
    planCard(Plan p, {required bool popular}) {
      final color = planColor(p);
      final free = p.ratePerUnitPaise == 0 && p.flatFeePaise == 0;
      final limits = [for (final e in planLimitLabels.entries) if (p.limits.containsKey(e.key)) e];
      const shown = 7;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: popular ? color.withAlpha(150) : AppColors.dividerLight, width: popular ? 1.5 : 1),
          boxShadow: [BoxShadow(color: popular ? color.withAlpha(40) : Colors.black.withAlpha(10), blurRadius: popular ? 22 : 14, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Coloured header: name, tags and the price ────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withAlpha(46), color.withAlpha(10)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Row(spacing: 12, children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13), boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: const Icon(Icons.workspace_premium_rounded, color: AppColors.white, size: 22),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: context.appText.sectionHeader.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text(p.key, style: context.appText.timestamp),
                      ]),
                    ),
                    if (p.archived) const PillTag('Archived', AppColors.textSecondaryLight),
                    if (popular && !p.archived) PillTag('Most used', color),
                    if (p.key == 'legacy') const PillTag('No limits', AppColors.primary),
                  ]),
                  if (free)
                    Text('Free', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color, height: 1))
                  else
                    Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 6, children: [
                      Text(rupees(p.ratePerUnitPaise), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color, height: 1)),
                      Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('per flat / month', style: context.appText.timestamp)),
                      if (p.flatFeePaise > 0)
                        Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('+ ${rupees(p.flatFeePaise)} flat fee', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                    ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  // ── Services ───────────────────────────────────────────────
                  Text('SERVICES', style: context.appText.timestamp.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  if (p.features.isEmpty)
                    Text('No services', style: context.appText.timestamp)
                  else
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final f in p.features.take(shown))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
                            Icon(Icons.check_rounded, size: 13, color: color),
                            Text(controller.featureName(f), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
                          ]),
                        ),
                      if (p.features.length > shown)
                        Tooltip(
                          message: p.features.skip(shown).map(controller.featureName).join(', '),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(20)),
                            child: Text('+${p.features.length - shown} more', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ]),
                  // ── Limits ─────────────────────────────────────────────────
                  Text('LIMITS', style: context.appText.timestamp.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  if (p.unlimited)
                    Row(spacing: 8, children: [
                      Icon(Icons.all_inclusive_rounded, size: 18, color: color),
                      Text('Unlimited', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ])
                  else
                    Column(spacing: 8, children: [
                      for (final e in limits)
                        Row(spacing: 10, children: [
                          Icon(limitIcon(e.key), size: 17, color: AppColors.textSecondaryLight),
                          Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13))),
                          Text('${p.limits[e.key]}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                        ]),
                    ]),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => societiesDialog(p),
                    icon: const Icon(Icons.apartment_rounded, size: 17),
                    label: Text(p.societies == 1 ? '1 society' : '${p.societies} societies'),
                  ),
                  const Spacer(),
                  if (canEdit && !p.archived) ...[
                    IconButton(tooltip: 'Edit', onPressed: () => formDialog(p), icon: const Icon(Icons.edit_outlined, size: 19)),
                    if (p.societies == 0 && p.key != 'legacy')
                      IconButton(tooltip: 'Archive', onPressed: () => controller.archive(p), icon: const Icon(Icons.archive_outlined, size: 19, color: AppColors.error)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Summary tiles ───────────────────────────────────────────────────────
    summaryTile(IconData icon, Color color, String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerLight),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(spacing: 12, children: [
            IconTile(icon, color),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: color, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: context.appText.timestamp, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );
    }

    summaryRow() {
      final all = controller.plans.toList();
      final active = all.where((p) => !p.archived).toList();
      final assigned = active.fold<int>(0, (s, p) => s + p.societies);
      final top = active.isEmpty ? 0 : active.map((p) => p.ratePerUnitPaise).reduce((a, b) => a > b ? a : b);
      return LayoutBuilder(builder: (context, c) {
        final tiles = [
          summaryTile(Icons.workspace_premium_rounded, AppColors.primary, '${active.length}', 'Active plans'),
          summaryTile(Icons.apartment_rounded, AppColors.teal, '$assigned', 'Societies on a plan'),
          summaryTile(Icons.archive_outlined, AppColors.orange, '${all.length - active.length}', 'Archived plans'),
          summaryTile(Icons.sell_outlined, AppColors.purple, '${rupees(top)}', 'Highest rate per flat'),
        ];
        if (c.maxWidth < 700) {
          return Column(spacing: 10, children: [Row(spacing: 10, children: [tiles[0], tiles[1]]), Row(spacing: 10, children: [tiles[2], tiles[3]])]);
        }
        return Row(spacing: 12, children: tiles);
      });
    }

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value.isNotEmpty) {
        return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load plans', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
      }
      final list = controller.visible;
      final maxSocieties = list.where((p) => !p.archived).fold<int>(0, (m, p) => p.societies > m ? p.societies : m);
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Plans', style: context.appText.sectionHeader.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('A plan sets the price, the services a society gets and its limits. Assign it from a society\'s page.', style: context.appText.timestamp),
                  ],
                ),
                Row(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.dividerLight)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Show archived', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Switch(value: controller.showArchived.value, onChanged: (v) => controller.showArchived.value = v),
                    ]),
                  ),
                  if (canEdit)
                    FilledButton.icon(onPressed: () => formDialog(null), icon: const Icon(Icons.add_rounded), label: const Text('New plan')),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            summaryRow(),
            const SizedBox(height: 14),
            noticeBar(controller.notice),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1100 ? 3 : (c.maxWidth >= 700 ? 2 : 1);
                final w = (c.maxWidth - (cols - 1) * 16) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final p in list) SizedBox(width: w, child: planCard(p, popular: maxSocieties > 0 && p.societies == maxSocieties)),
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
