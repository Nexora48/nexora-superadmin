import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../controllers/audit_logs_controller.dart';

class AuditLogsView extends GetView<AuditLogsController> {
  const AuditLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Row ─────────────────────────────────────────────────────────────────
    auditRow(row) {
      return cardBox(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(row.actorType == 'platform' ? Icons.shield_outlined : Icons.person_outline_rounded, size: 18, color: AppColors.primary),
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
          ],
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audit log', style: context.appText.sectionHeader.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in AuditLogsController.filters.keys)
                    ChoiceChip(label: Text(f), selected: controller.selected.value == f, onSelected: (_) => controller.selected.value = f),
                ],
              )),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              if (controller.error.value.isNotEmpty) {
                return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load the audit log', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
              }
              if (controller.items.isEmpty) {
                return stateMessage(context, icon: Icons.history_rounded, title: 'No events', subtitle: 'Nothing matches this filter yet.');
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
