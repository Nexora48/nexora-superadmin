import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/platform_models.dart';
import '../controllers/audit_logs_controller.dart';

class AuditLogsView extends GetView<AuditLogsController> {
  const AuditLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Detail ──────────────────────────────────────────────────────────────
    detailDialog(AuditRow r) {
      line(String k, String? v) => (v == null || v.isEmpty)
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 96, child: Text(k, style: context.appText.timestamp)),
                Expanded(child: SelectableText(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
            );
      final pretty = const JsonEncoder.withIndent('  ').convert(r.meta);
      final before = r.meta['before'];
      final after = r.meta['after'];
      Get.dialog(
        dialogShell(
          context,
          title: r.summary,
          maxWidth: 640,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line('When', formatDateTime(r.createdAt)),
              line('Action', r.action),
              line('Who', [r.actorName ?? r.actorType, if (r.actorRole != null) '(${r.actorRole})'].join(' ')),
              line('Email', r.actorEmail),
              line('Society', r.societyName),
              line('Entity', [r.entity, r.entityId].where((e) => e.isNotEmpty).join(' · ')),
              line('IP address', r.ip),
              const SizedBox(height: 12),
              if (before != null || after != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _jsonBox('Before', before, AppColors.errorLight)),
                    const SizedBox(width: 10),
                    Expanded(child: _jsonBox('After', after, AppColors.successLight)),
                  ],
                ),
              if (before != null || after != null) const SizedBox(height: 10),
              _jsonBox('Full details', null, AppColors.backgroundLight, raw: pretty),
            ],
          ),
          actions: [TextButton(onPressed: Get.back, child: const Text('Close'))],
        ),
      );
    }

    // ── Row ─────────────────────────────────────────────────────────────────
    auditRow(AuditRow row) {
      return InkWell(
        onTap: () async {
          await controller.open(row);
          detailDialog(controller.detail.value ?? row);
        },
        child: cardBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(row.actorType == 'platform' ? Icons.shield_outlined : (row.actorType == 'system' ? Icons.settings_suggest_outlined : Icons.person_outline_rounded), size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.summary, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      [row.actorName ?? row.actorType, if (row.societyName != null) row.societyName, if (row.ip.isNotEmpty) row.ip].join(' · '),
                      style: context.appText.timestamp,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(formatDateTime(row.createdAt), style: context.appText.timestamp),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondaryLight),
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
            Text('$page / ${controller.totalPages}', style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(onPressed: page < controller.totalPages ? () => controller.goToPage(page + 1) : null, icon: const Icon(Icons.chevron_right_rounded)),
          ],
        );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in AuditLogsController.filters.keys) ChoiceChip(label: Text(f), selected: controller.selected.value == f, onSelected: (_) => controller.selected.value = f),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  controller: controller.textCtrl,
                  onSubmitted: (_) => controller.apply(),
                  decoration: InputDecoration(
                    labelText: 'Search action, entity or id',
                    isDense: true,
                    suffixIcon: IconButton(onPressed: controller.apply, icon: const Icon(Icons.search_rounded, size: 18)),
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: controller.actorType.value,
                    decoration: const InputDecoration(labelText: 'Who', isDense: true),
                    items: [for (final k in AuditLogsController.actorTypes.keys) DropdownMenuItem(value: k, child: Text(k))],
                    onChanged: (v) => controller.actorType.value = v ?? 'Anyone',
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: controller.societyId.value,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Society', isDense: true),
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
              Obx(() => controller.hasFilters ? TextButton(onPressed: controller.clearFilters, child: const Text('Clear filters')) : const SizedBox.shrink()),
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
              Expanded(child: Text('Audit log', style: context.appText.sectionHeader.copyWith(fontSize: 20))),
              Obx(
                () => OutlinedButton.icon(
                  onPressed: controller.exporting.value ? null : controller.export,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          noticeBar(controller.notice),
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
              return ListView.separated(
                itemCount: controller.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
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

Widget _jsonBox(String title, dynamic value, Color bg, {String? raw}) {
  final text = raw ?? (value == null ? '—' : const JsonEncoder.withIndent('  ').convert(value));
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5)),
      ],
    ),
  );
}
