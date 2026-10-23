import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/common.dart';
import '../controllers/services_controller.dart';

class ServicesView extends GetView<ServicesController> {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    serviceRow(row) {
      return cardBox(
        child: Row(
          children: [
            const Icon(Icons.extension_outlined, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(row.description.isEmpty ? row.key : row.description, style: context.appText.timestamp),
                ],
              ),
            ),
            Text(row.key, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondaryLight)),
            const SizedBox(width: 14),
            statusChip(row.defaultEnabled ? 'active' : 'suspended'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Services', style: context.appText.sectionHeader.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Every product capability societies can use. Switch them per society from a society\'s Services tab. New services ship with a release.',
            style: context.appText.timestamp,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
              if (controller.error.value.isNotEmpty) {
                return stateMessage(context, icon: Icons.cloud_off_rounded, title: 'Could not load services', subtitle: controller.error.value, actionLabel: 'Retry', onAction: controller.load);
              }
              return ListView.separated(
                itemCount: controller.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => serviceRow(controller.items[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}
