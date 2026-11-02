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

    // numbers only (digits and one decimal point) for money fields
    money() => [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    // icon for a service tile
    IconData serviceIcon(String key) {
      final k = key.toLowerCase();
      if (k.contains('daily') || k.contains('staff_help')) return Icons.cleaning_services_outlined;
      if (k.contains('visitor')) return Icons.badge_outlined;
      if (k.contains('pay') || k.contains('bill')) return Icons.account_balance_wallet_outlined;
      if (k.contains('complaint') || k.contains('help')) return Icons.support_agent_rounded;
      if (k.contains('communit') || k.contains('notice')) return Icons.campaign_outlined;
      if (k.contains('amenit')) return Icons.pool_rounded;
      if (k.contains('deliver')) return Icons.local_shipping_outlined;
      if (k.contains('sos') || k.contains('emerg')) return Icons.emergency_outlined;
      if (k.contains('park')) return Icons.local_parking_rounded;
      if (k.contains('poll')) return Icons.poll_outlined;
      if (k.contains('attend')) return Icons.how_to_reg_outlined;
      return Icons.extension_outlined;
    }

    // a white section card with an icon title and an optional trailing widget
    section(IconData icon, Color color, String title, {String? hint, Widget? trailing, required Widget child}) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.dividerLight),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Row(spacing: 10, children: [
              IconTile(icon, color, size: 34),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  if (hint != null) Text(hint, style: context.appText.timestamp),
                ]),
              ),
              if (trailing != null) trailing,
            ]),
            child,
          ],
        ),
      );
    }

    // ── Plan form dialog ────────────────────────────────────────────────────
    formDialog(Plan? p) {
      controller.openForm(p);
      final color = p == null ? AppColors.primary : planColor(p);
      Get.dialog(
        Dialog(
          backgroundColor: AppColors.backgroundLight,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720, maxHeight: MediaQuery.of(context).size.height * 0.92),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gradient header ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.28)!]),
                  ),
                  child: Row(
                    spacing: 16,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withAlpha(70))),
                        child: Icon(p == null ? Icons.add_card_rounded : Icons.workspace_premium_rounded, color: AppColors.white, size: 28),
                      ),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p == null ? 'Create a plan' : 'Edit ${p.name}', style: const TextStyle(color: AppColors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                          Text('Set the price, the services and the limits a society gets', style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 13)),
                        ]),
                      ),
                      IconButton(onPressed: Get.back, icon: const Icon(Icons.close_rounded, color: AppColors.white)),
                    ],
                  ),
                ),
                // ── Sections ─────────────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        section(
                          Icons.badge_outlined,
                          AppColors.primary,
                          'Plan details',
                          child: Column(spacing: 14, children: [
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
                          ]),
                        ),
                        section(
                          Icons.sell_outlined,
                          AppColors.success,
                          'Pricing',
                          hint: 'Billed monthly: rate × flats + the flat fee',
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
                            Row(spacing: 12, children: [
                              Expanded(
                                child: TextField(
                                  controller: controller.rateCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: money(),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                  decoration: const InputDecoration(labelText: 'Per flat per month', prefixText: '₹ ', prefixIcon: Icon(Icons.home_work_outlined, size: 20)),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: controller.flatCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: money(),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                  decoration: const InputDecoration(labelText: 'Flat fee per month', prefixText: '₹ ', prefixIcon: Icon(Icons.payments_outlined, size: 20)),
                                ),
                              ),
                            ]),
                            // live preview of what a 100-flat society pays
                            AnimatedBuilder(
                              animation: Listenable.merge([controller.rateCtrl, controller.flatCtrl]),
                              builder: (_, _) {
                                final rate = ((double.tryParse(controller.rateCtrl.text) ?? 0) * 100).round();
                                final fee = ((double.tryParse(controller.flatCtrl.text) ?? 0) * 100).round();
                                final example = rate * 100 + fee;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                                  child: Row(spacing: 10, children: [
                                    const Icon(Icons.calculate_outlined, size: 18, color: AppColors.success),
                                    Expanded(
                                      child: Text.rich(TextSpan(children: [
                                        const TextSpan(text: 'A 100-flat society pays '),
                                        TextSpan(text: '${rupees(example)} / month', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success)),
                                      ]), style: const TextStyle(fontSize: 13)),
                                    ),
                                  ]),
                                );
                              },
                            ),
                          ]),
                        ),
                        section(
                          Icons.extension_outlined,
                          AppColors.purple,
                          'Included services',
                          hint: 'Tap to include or remove a service',
                          trailing: Obx(() => Row(mainAxisSize: MainAxisSize.min, children: [
                                PillTag('${controller.selectedFeatures.length} of ${controller.catalogue.length}', AppColors.purple),
                                TextButton(
                                  onPressed: () => controller.selectedFeatures.assignAll(controller.catalogue.map((c) => c.key)),
                                  child: const Text('All'),
                                ),
                                TextButton(onPressed: controller.selectedFeatures.clear, child: const Text('None')),
                              ])),
                          child: LayoutBuilder(builder: (context, c) {
                            final cols = c.maxWidth >= 560 ? 3 : 2;
                            final w = (c.maxWidth - (cols - 1) * 10) / cols;
                            return Obx(() {
                              // read the selection here, inside the Obx, so every tile redraws when it changes
                              final selected = controller.selectedFeatures.toList();
                              return Wrap(spacing: 10, runSpacing: 10, children: [
                                  for (final f in controller.catalogue)
                                    Builder(builder: (_) {
                                      final on = selected.contains(f.key);
                                      return SizedBox(
                                        width: w,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: () => controller.toggleFeature(f.key, !on),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: on ? AppColors.purple.withAlpha(18) : AppColors.backgroundLight,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: on ? AppColors.purple.withAlpha(140) : Colors.transparent, width: 1.3),
                                            ),
                                            child: Row(spacing: 10, children: [
                                              Icon(serviceIcon(f.key), size: 20, color: on ? AppColors.purple : AppColors.textSecondaryLight),
                                              Expanded(child: Text(f.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: on ? FontWeight.w800 : FontWeight.w600, height: 1.2))),
                                              Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined, size: 19, color: on ? AppColors.purple : AppColors.textDisabledLight),
                                            ]),
                                          ),
                                        ),
                                      );
                                    }),
                                ]);
                            });
                          }),
                        ),
                        section(
                          Icons.speed_rounded,
                          AppColors.orange,
                          'Limits',
                          hint: 'Leave a field empty for unlimited · a lock means the limit blocks new records',
                          child: LayoutBuilder(builder: (context, c) {
                            final cols = c.maxWidth >= 560 ? 3 : 2;
                            final w = (c.maxWidth - (cols - 1) * 12) / cols;
                            return Wrap(spacing: 12, runSpacing: 12, children: [
                              for (final e in planLimitLabels.entries)
                                SizedBox(
                                  width: w,
                                  child: TextField(
                                    controller: controller.limitCtrls[e.key],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: e.value,
                                      hintText: 'Unlimited',
                                      prefixIcon: Icon(limitIcon(e.key), size: 19),
                                      suffixIcon: hardLimits.contains(e.key)
                                          ? const Tooltip(message: 'Blocks at the limit', child: Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.orange))
                                          : const Tooltip(message: 'Only warns', child: Icon(Icons.notifications_none_rounded, size: 17, color: AppColors.textSecondaryLight)),
                                    ),
                                  ),
                                ),
                            ]);
                          }),
                        ),
                        if (p != null && p.societies > 0)
                          Obx(
                            () => Container(
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.warning.withAlpha(120)),
                              ),
                              child: CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                value: controller.applyToSocieties.value,
                                onChanged: (v) => controller.applyToSocieties.value = v ?? false,
                                title: Text('Also change the price for the ${p.societies} ${p.societies == 1 ? 'society' : 'societies'} on this plan', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                subtitle: const Text('Otherwise only new assignments get the new price. Limits and services of existing societies follow the plan at their next change.', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ),
                        dialogErrorText(controller.dialogError),
                      ],
                    ),
                  ),
                ),
                // ── Footer ───────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  decoration: const BoxDecoration(color: AppColors.surfaceLight, border: Border(top: BorderSide(color: AppColors.dividerLight))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 10,
                    children: [
                      TextButton(onPressed: Get.back, child: const Text('Cancel')),
                      Obx(
                        () => FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
                          onPressed: controller.busy.value
                              ? null
                              : () async {
                                  if (await controller.save(p)) Get.back();
                                },
                          icon: controller.busy.value
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(p == null ? 'Create plan' : 'Save plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
