import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/ui_kit.dart';
import '../controllers/services_controller.dart';

class ServicesView extends GetView<ServicesController> {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    // each service gets a stable accent so the grid reads as a catalogue
    const palette = [AppColors.primary, AppColors.teal, AppColors.purple, AppColors.orange, AppColors.success, AppColors.error];

    // ── One service card ────────────────────────────────────────────────────
    serviceCard(row, int index) {
      final color = palette[index % palette.length];
      final on = row.defaultEnabled;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.dividerLight),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.25)!]),
                    boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: Icon(serviceIconFor(row.key), color: AppColors.white, size: 26),
                ),
                const Spacer(),
                PillTag(on ? 'On by default' : 'Off by default', on ? AppColors.success : AppColors.textSecondaryLight),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(row.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(row.description.isEmpty ? 'No description' : row.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.appText.timestamp.copyWith(height: 1.4)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
                const Icon(Icons.code_rounded, size: 14, color: AppColors.textSecondaryLight),
                Text(row.key, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
              ]),
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
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color, height: 1.1)),
                Text(label, style: context.appText.timestamp, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      );
    }

    summaryRow() {
      final total = controller.items.length;
      final on = controller.items.where((r) => r.defaultEnabled).length;
      return Row(spacing: 12, children: [
        summaryTile(Icons.extension_rounded, AppColors.primary, '$total', 'Services in the catalogue'),
        summaryTile(Icons.toggle_on_rounded, AppColors.success, '$on', 'On by default'),
        summaryTile(Icons.toggle_off_outlined, AppColors.orange, '${total - on}', 'Off by default'),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Services', style: context.appText.sectionHeader.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
          Text(
            'Every product capability societies can use. Switch them per society from a society\'s Services tab. New services ship with a release.',
            style: context.appText.timestamp,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              if (controller.error.value.isNotEmpty) {
                return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load services', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
              }
              return ListView(
                children: [
                  summaryRow(),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, c) {
                    final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
                    final w = (c.maxWidth - (cols - 1) * 14) / cols;
                    return Wrap(spacing: 14, runSpacing: 14, children: [
                      for (final (i, r) in controller.items.indexed) SizedBox(width: w, child: serviceCard(r, i)),
                    ]);
                  }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
