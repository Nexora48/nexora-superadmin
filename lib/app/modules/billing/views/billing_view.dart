import 'package:nexora_superadmin/app/core/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/billing_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/billing_controller.dart';

class BillingView extends GetView<BillingController> {
  const BillingView({super.key});

  @override
  Widget build(BuildContext context) {
    final canEdit = PlatformAuthService.to.canEdit;

    pill(String text, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );

    dialogShell({
      required String title,
      required Widget body,
      required List<Widget> actions,
    }) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: context.appText.sectionHeader),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(20), child: body),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );

    dialogError() => Obx(
      () => controller.dialogError.value.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                controller.dialogError.value,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
    );

    // ── Generate ────────────────────────────────────────────────────────────
    generateDialog() {
      controller.dialogError.value = '';
      final p = controller.periods[1].obs; // the current month
      Get.dialog(
        dialogShell(
          title: 'Generate invoices',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creates the month\'s invoice for every society with an active subscription. Societies that already have one are skipped.',
                style: context.appText.timestamp,
              ),
              const SizedBox(height: 12),
              Obx(
                () => AppDropdown<String>(
                  initialValue: p.value,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    isDense: true,
                  ),
                  items: [
                    for (final x in controller.periods)
                      DropdownMenuItem(value: x, child: Text(periodLabel(x))),
                  ],
                  onChanged: (v) => p.value = v ?? p.value,
                ),
              ),
              dialogError(),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        if (await controller.generate(p.value)) Get.back();
                      },
                child: Text(controller.busy.value ? 'Working…' : 'Generate'),
              ),
            ),
          ],
        ),
      );
    }

    // ── Mark paid ───────────────────────────────────────────────────────────
    paidDialog(PlatformInvoice i) {
      controller.dialogError.value = '';
      controller.referenceCtrl.clear();
      Get.dialog(
        dialogShell(
          title: 'Mark ${i.number} as paid',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${i.society} · ${rupees(i.amountPaise)} for ${periodLabel(i.period)}',
                style: context.appText.timestamp,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.referenceCtrl,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Bank reference (required)',
                  counterText: '',
                  isDense: true,
                ),
              ),
              dialogError(),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        if (await controller.markPaid(i)) Get.back();
                      },
                child: const Text('Mark as paid'),
              ),
            ),
          ],
        ),
      );
    }

    // ── Subscription ────────────────────────────────────────────────────────
    subscriptionDialog(SocietyRow s) {
      controller.openSubscription(s);
      Get.dialog(
        dialogShell(
          title: 'Subscription · ${s.name}',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                '${s.flats} flats. The monthly invoice is rate × flats + the flat fee.',
                style: context.appText.timestamp,
              ),
              TextField(
                controller: controller.rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Rate per flat per month',
                  prefixText: '₹ ',
                  isDense: true,
                ),
              ),
              TextField(
                controller: controller.flatCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Flat monthly fee (optional)',
                  prefixText: '₹ ',
                  isDense: true,
                ),
              ),
              TextField(
                controller: controller.dayCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Billing day (1-28)',
                  isDense: true,
                ),
              ),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: controller.subActive.value,
                  onChanged: (v) => controller.subActive.value = v,
                  title: const Text('Subscription active'),
                ),
              ),
              dialogError(),
            ],
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('Cancel')),
            Obx(
              () => FilledButton(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        if (await controller.saveSubscription(s)) Get.back();
                      },
                child: Text(controller.busy.value ? 'Saving…' : 'Save'),
              ),
            ),
          ],
        ),
      );
    }

    // ── Invoices ────────────────────────────────────────────────────────────
    invoiceRow(PlatformInvoice i) {
      final (fg, bg, label) = i.paid
          ? (AppColors.success, AppColors.successLight, 'Paid')
          : i.overdue
          ? (AppColors.error, AppColors.errorLight, 'Overdue')
          : (AppColors.orange, AppColors.warningLight, 'Open');
      return cardBox(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i.society} · ${periodLabel(i.period)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${i.number} · ${i.units} flats · due ${i.dueDate}${i.paid ? ' · paid ${i.paidOn ?? ''} · ${i.reference ?? ''}' : ''}',
                    style: context.appText.timestamp,
                  ),
                ],
              ),
            ),
            Text(
              rupees(i.amountPaise),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            pill(label, fg, bg),
            if (canEdit && !i.paid) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => paidDialog(i),
                child: const Text('Mark paid'),
              ),
            ],
          ],
        ),
      );
    }

    invoicesTab() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Obx(
              () => Wrap(
                spacing: 8,
                children: [
                  for (final f in BillingController.statusFilters.keys)
                    ChoiceChip(
                      label: Text(f),
                      selected: controller.statusFilter.value == f,
                      onSelected: (_) => controller.statusFilter.value = f,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 170,
              child: Obx(
                () => AppDropdown<String>(
                  initialValue: controller.period.value,
                  isDense: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Every month'),
                    ),
                    for (final x in controller.periods)
                      DropdownMenuItem(value: x, child: Text(periodLabel(x))),
                  ],
                  onChanged: (v) => controller.period.value = v ?? '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error.value.isNotEmpty &&
                controller.invoices.isEmpty) {
              return stateMessage(
                context,
                icon: Icons.cloud_off_rounded,
                title: 'Could not load invoices',
                subtitle: controller.error.value,
                actionLabel: 'Retry',
                onAction: controller.load,
              );
            }
            if (controller.invoices.isEmpty) {
              return stateMessage(
                context,
                icon: Icons.receipt_long_rounded,
                title: 'No invoices yet',
                subtitle:
                    'Set a subscription for a society, then generate the month\'s invoices.',
              );
            }
            return ListView(
              children: [
                for (final i in controller.invoices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: invoiceRow(i),
                  ),
              ],
            );
          }),
        ),
        Obx(() {
          final page = controller.page.value;
          return Row(
            children: [
              Text(
                '${controller.total.value} invoices',
                style: context.appText.timestamp,
              ),
              const Spacer(),
              IconButton(
                onPressed: page > 1
                    ? () => controller.goToPage(page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '$page / ${controller.pages}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: page < controller.pages
                    ? () => controller.goToPage(page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          );
        }),
      ],
    );

    // ── Subscriptions ───────────────────────────────────────────────────────
    subscriptionRow(SocietyRow s) {
      final sub = controller.subscriptions[s.id];
      return cardBox(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sub == null ||
                            (sub.ratePerUnitPaise == 0 && sub.flatFeePaise == 0)
                        ? '${s.flats} flats · no subscription set'
                        : '${s.flats} flats · ${rupees(sub.ratePerUnitPaise)} per flat${sub.flatFeePaise > 0 ? ' + ${rupees(sub.flatFeePaise)}' : ''} · ${rupees(sub.nextAmountPaise)} a month',
                    style: context.appText.timestamp,
                  ),
                ],
              ),
            ),
            if (sub != null && sub.active)
              pill('Active', AppColors.success, AppColors.successLight)
            else
              pill(
                'Not billing',
                AppColors.textSecondaryLight,
                AppColors.backgroundLight,
              ),
            if (canEdit) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => subscriptionDialog(s),
                child: const Text('Edit'),
              ),
            ],
          ],
        ),
      );
    }

    subscriptionsTab() => Obx(() {
      if (controller.loadingSubs.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.societies.isEmpty) {
        return stateMessage(
          context,
          icon: Icons.apartment_rounded,
          title: 'No societies yet',
          subtitle: 'Create a society first.',
        );
      }
      return ListView(
        children: [
          for (final s in controller.societies)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: subscriptionRow(s),
            ),
        ],
      );
    });

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Billing',
                  style: context.appText.sectionHeader.copyWith(fontSize: 20),
                ),
              ),
              if (canEdit)
                FilledButton.icon(
                  onPressed: generateDialog,
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Generate invoices'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'What Nexora charges each society. Payments are recorded here after a bank transfer.',
            style: context.appText.timestamp,
          ),
          const SizedBox(height: 12),
          Obx(
            () => controller.notice.value.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(controller.notice.value)),
                      ],
                    ),
                  ),
          ),
          Obx(
            () => Wrap(
              spacing: 8,
              children: [
                for (final t in const [
                  'Invoices',
                  'Subscriptions',
                ].asMap().entries)
                  ChoiceChip(
                    label: Text(t.value),
                    selected: controller.tab.value == t.key,
                    onSelected: (_) => controller.tab.value = t.key,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(
              () => controller.tab.value == 0
                  ? invoicesTab()
                  : subscriptionsTab(),
            ),
          ),
        ],
      ),
    );
  }
}
