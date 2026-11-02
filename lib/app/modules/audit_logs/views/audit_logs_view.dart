import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/models/platform_models.dart';
import '../controllers/audit_logs_controller.dart';

class AuditLogsView extends GetView<AuditLogsController> {
  const AuditLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    // who did it decides the colour and icon of a row
    Color actorColor(String t) => switch (t) {
          'platform' => AppColors.primary,
          'system' => AppColors.textSecondaryLight,
          _ => AppColors.purple,
        };
    IconData actorIcon(String t) => switch (t) {
          'platform' => Icons.shield_outlined,
          'system' => Icons.settings_suggest_outlined,
          _ => Icons.person_outline_rounded,
        };
    String actorLabel(String t) => switch (t) {
          'platform' => 'Staff',
          'system' => 'System',
          _ => 'Society user',
        };

    // a code block for before / after / raw json
    jsonBox(String title, IconData icon, Color color, {dynamic value, String? raw}) {
      final text = raw ?? (value == null ? '—' : const JsonEncoder.withIndent('  ').convert(value));
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: color.withAlpha(16), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withAlpha(50))),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(spacing: 6, children: [
              Icon(icon, size: 15, color: color),
              Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: color)),
            ]),
            SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.45)),
          ],
        ),
      );
    }

    // ── Detail ──────────────────────────────────────────────────────────────
    detailDialog(AuditRow r) {
      detail(IconData icon, String k, String? v) => (v == null || v.isEmpty)
          ? const SizedBox.shrink()
          : SizedBox(
              width: 270,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                IconTile(icon, AppColors.primary, size: 32),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(k, style: context.appText.timestamp),
                    SelectableText(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            );
      final pretty = const JsonEncoder.withIndent('  ').convert(r.meta);
      final before = r.meta['before'];
      final after = r.meta['after'];
      Get.dialog(
        dialogShell(
          context,
          title: r.summary,
          subtitle: formatDateTime(r.createdAt),
          icon: actorIcon(r.actorType),
          color: actorColor(r.actorType),
          maxWidth: 680,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Wrap(spacing: 8, children: [PillTag(actorLabel(r.actorType), actorColor(r.actorType)), PillTag(r.action, AppColors.teal)]),
              Wrap(spacing: 16, runSpacing: 14, children: [
                detail(Icons.person_outline_rounded, 'Who', [r.actorName ?? r.actorType, if (r.actorRole != null) '(${r.actorRole})'].join(' ')),
                detail(Icons.mail_outline_rounded, 'Email', r.actorEmail),
                detail(Icons.apartment_rounded, 'Society', r.societyName),
                detail(Icons.category_outlined, 'Entity', [r.entity, r.entityId].where((e) => e.isNotEmpty).join(' · ')),
                detail(Icons.language_rounded, 'IP address', r.ip),
              ]),
              if (before != null || after != null)
                Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
                  Expanded(child: jsonBox('Before', Icons.history_rounded, AppColors.error, value: before)),
                  Expanded(child: jsonBox('After', Icons.check_circle_outline_rounded, AppColors.success, value: after)),
                ]),
              jsonBox('Full details', Icons.data_object_rounded, AppColors.textSecondaryLight, raw: pretty),
            ],
          ),
          actions: [FilledButton(onPressed: Get.back, child: const Text('Close'))],
        ),
      );
    }

    // ── Row ─────────────────────────────────────────────────────────────────
    auditRow(AuditRow row) {
      final color = actorColor(row.actorType);
      return SoftCard(
        accent: color,
        margin: const EdgeInsets.only(bottom: 10),
        onTap: () async {
          await controller.open(row);
          detailDialog(controller.detail.value ?? row);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            spacing: 14,
            children: [
              IconTile(actorIcon(row.actorType), color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(row.summary, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Wrap(spacing: 14, runSpacing: 4, children: [
                      MetaItem(Icons.person_outline_rounded, row.actorName ?? actorLabel(row.actorType)),
                      if (row.societyName != null) MetaItem(Icons.apartment_rounded, row.societyName!),
                      if (row.ip.isNotEmpty) MetaItem(Icons.language_rounded, row.ip),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 4,
                children: [
                  Text(formatDateTime(row.createdAt), style: context.appText.timestamp),
                  PillTag(actorLabel(row.actorType), color),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      );
    }

    pagination() {
      return Obx(() {
        final page = controller.currentPage.value;
        return Row(
          children: [
            Text('${controller.total.value} events', style: context.appText.timestamp),
            const Spacer(),
            IconButton(onPressed: page > 1 ? () => controller.goToPage(page - 1) : null, icon: const Icon(Icons.chevron_left_rounded)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(22), borderRadius: BorderRadius.circular(10)),
              child: Text('$page / ${controller.totalPages}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
            IconButton(onPressed: page < controller.totalPages ? () => controller.goToPage(page + 1) : null, icon: const Icon(Icons.chevron_right_rounded)),
          ],
        );
      });
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
                Text(value, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: color, height: 1.1)),
                Text(label, style: context.appText.timestamp, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );
    }

    summaryRow() {
      return Obx(() {
        final items = controller.items.toList();
        int n(String t) => items.where((r) => r.actorType == t).length;
        final tiles = [
          summaryTile(Icons.history_rounded, AppColors.primary, '${controller.total.value}', 'Events matching'),
          summaryTile(Icons.shield_outlined, AppColors.teal, '${n('platform')}', 'By staff · this page'),
          summaryTile(Icons.person_outline_rounded, AppColors.purple, '${items.length - n('platform') - n('system')}', 'By society users'),
          summaryTile(Icons.settings_suggest_outlined, AppColors.textSecondaryLight, '${n('system')}', 'By the system'),
        ];
        return LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 700) {
            return Column(spacing: 10, children: [Row(spacing: 10, children: [tiles[0], tiles[1]]), Row(spacing: 10, children: [tiles[2], tiles[3]])]);
          }
          return Row(spacing: 12, children: tiles);
        });
      });
    }

    // ── Filters ─────────────────────────────────────────────────────────────
    pickDate(RxString target) async {
      final now = DateTime.now();
      final d = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 3), lastDate: now);
      if (d != null) target.value = d.toIso8601String().substring(0, 10);
    }

    dateButton(String label, RxString v) => Obx(
      () => OutlinedButton.icon(
        onPressed: () => pickDate(v),
        icon: const Icon(Icons.event_outlined, size: 16),
        label: Text(v.value.isEmpty ? label : '$label ${v.value}'),
      ),
    );

    filterBar() => cardBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Obx(() {
            final keys = AuditLogsController.filters.keys.toList();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Segmented(items: keys, selected: keys.indexOf(controller.selected.value), onTap: (i) => controller.selected.value = keys[i]),
            );
          }),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: controller.textCtrl,
                  onSubmitted: (_) => controller.apply(),
                  decoration: InputDecoration(
                    labelText: 'Search action, entity or id',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: IconButton(onPressed: controller.apply, icon: const Icon(Icons.arrow_forward_rounded, size: 18)),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: Obx(
                  () => AppDropdown<String>(
                    initialValue: controller.actorType.value,
                    decoration: const InputDecoration(labelText: 'Who', isDense: true, prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                    items: [for (final k in AuditLogsController.actorTypes.keys) DropdownMenuItem(value: k, child: Text(k))],
                    onChanged: (v) => controller.actorType.value = v ?? 'Anyone',
                  ),
                ),
              ),
              SizedBox(
                width: 230,
                child: Obx(
                  () => AppDropdown<String>(
                    initialValue: controller.societyId.value,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Society', isDense: true, prefixIcon: Icon(Icons.apartment_rounded, size: 20)),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All societies')),
                      for (final s in controller.societies) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => controller.societyId.value = v ?? '',
                  ),
                ),
              ),
              dateButton('From', controller.from),
              dateButton('To', controller.to),
              Obx(() => controller.hasFilters
                  ? TextButton.icon(onPressed: controller.clearFilters, icon: const Icon(Icons.filter_alt_off_outlined, size: 17), label: const Text('Clear filters'))
                  : const SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Audit log', style: context.appText.sectionHeader.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Who changed what, and when', style: context.appText.timestamp),
                ]),
              ),
              Obx(
                () => FilledButton.tonalIcon(
                  onPressed: controller.exporting.value ? null : controller.export,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          noticeBar(controller.notice),
          summaryRow(),
          const SizedBox(height: 12),
          filterBar(),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              if (controller.error.value.isNotEmpty) {
                return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load the audit log', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
              }
              if (controller.items.isEmpty) {
                return stateMessage(context, icon: Icons.history_rounded, title: 'No events', subtitle: 'Nothing matches these filters.');
              }
              return ListView.builder(
                itemCount: controller.items.length,
                itemBuilder: (_, i) => auditRow(controller.items[i]),
              );
            }),
          ),
          const SizedBox(height: 8),
          pagination(),
        ],
      ),
    );
  }
}
