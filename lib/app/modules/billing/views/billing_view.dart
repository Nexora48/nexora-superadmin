import 'package:nexora_superadmin/app/core/widgets/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dialogs.dart' as shared;
import '../../../core/widgets/ui_kit.dart';
import '../../../data/models/billing_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../services/platform_auth_service.dart';
import '../controllers/billing_controller.dart';

class BillingView extends GetView<BillingController> {
  const BillingView({super.key});

  @override
  Widget build(BuildContext context) {
    final canEdit = PlatformAuthService.to.canEdit;

    dialogShell({
      required String title,
      required Widget body,
      required List<Widget> actions,
      String? subtitle,
      IconData? icon,
      Color color = AppColors.primary,
    }) => shared.dialogShell(context, title: title, subtitle: subtitle, icon: icon, color: color, maxWidth: 480, body: body, actions: actions);

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
          subtitle: 'One invoice per billing society',
          icon: Icons.receipt_long_rounded,
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
          subtitle: 'Record the bank transfer',
          icon: Icons.price_check_rounded,
          color: AppColors.success,
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
                  prefixIcon: Icon(Icons.tag_rounded, size: 20),
                  counterText: '',
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
          subtitle: 'What Nexora charges this society',
          icon: Icons.autorenew_rounded,
          color: AppColors.teal,
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
                  prefixIcon: Icon(Icons.home_work_outlined, size: 20),
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
                  prefixIcon: Icon(Icons.payments_outlined, size: 20),
                ),
              ),
              TextField(
                controller: controller.dayCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Billing day (1-28)',
                  prefixIcon: Icon(Icons.event_repeat_rounded, size: 20),
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
      final (color, label) = i.paid
          ? (AppColors.success, 'Paid')
          : i.overdue
          ? (AppColors.error, 'Overdue')
          : (AppColors.orange, 'Open');
      return SoftCard(
        accent: color,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 14,
            children: [
              IconTile(i.paid ? Icons.receipt_long_rounded : Icons.request_quote_outlined, color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text('${i.society} · ${periodLabel(i.period)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Wrap(spacing: 14, runSpacing: 4, children: [
                      MetaItem(Icons.tag_rounded, i.number),
                      MetaItem(Icons.meeting_room_outlined, '${i.units} flats'),
                      MetaItem(Icons.event_outlined, 'Due ${i.dueDate}'),
                      if (i.paid) MetaItem(Icons.check_circle_outline_rounded, 'Paid ${i.paidOn ?? ''}${(i.reference ?? '').isEmpty ? '' : ' · ${i.reference}'}'),
                    ]),
                  ],
                ),
              ),
              Text(rupees(i.amountPaise), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              PillTag(label, color),
              if (canEdit && !i.paid)
                FilledButton.tonalIcon(
                  onPressed: () => paidDialog(i),
                  icon: const Icon(Icons.price_check_rounded, size: 18),
                  label: const Text('Mark paid'),
                ),
            ],
          ),
        ),
      );
    }

    invoicesTab() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Obx(() {
              final keys = BillingController.statusFilters.keys.toList();
              return Segmented(
                items: keys,
                selected: keys.indexOf(controller.statusFilter.value),
                onTap: (i) => controller.statusFilter.value = keys[i],
              );
            }),
            SizedBox(
              width: 190,
              child: Obx(
                () => AppDropdown<String>(
                  initialValue: controller.period.value,
                  isDense: true,
                  decoration: const InputDecoration(isDense: true, labelText: 'Month', prefixIcon: Icon(Icons.calendar_month_outlined, size: 20)),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Every month')),
                    for (final x in controller.periods) DropdownMenuItem(value: x, child: Text(periodLabel(x))),
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
                  invoiceRow(i),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(22), borderRadius: BorderRadius.circular(10)),
                child: Text('$page / ${controller.pages}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
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
      final billing = sub != null && sub.active;
      final unset = sub == null || (sub.ratePerUnitPaise == 0 && sub.flatFeePaise == 0);
      final color = billing ? AppColors.success : AppColors.textSecondaryLight;
      return SoftCard(
        accent: color,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 14,
            children: [
              IconTile(Icons.apartment_rounded, billing ? AppColors.primary : AppColors.textSecondaryLight),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(s.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Wrap(spacing: 14, runSpacing: 4, children: [
                      MetaItem(Icons.meeting_room_outlined, '${s.flats} flats'),
                      if (unset)
                        const MetaItem(Icons.info_outline_rounded, 'No subscription set')
                      else ...[
                        MetaItem(Icons.sell_outlined, '${rupees(sub.ratePerUnitPaise)} per flat${sub.flatFeePaise > 0 ? ' + ${rupees(sub.flatFeePaise)}' : ''}'),
                        MetaItem(Icons.event_repeat_rounded, 'Bills on day ${sub.billingDay}'),
                      ],
                    ]),
                  ],
                ),
              ),
              if (!unset)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rupees(sub.nextAmountPaise), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('a month', style: context.appText.timestamp),
                  ],
                ),
              PillTag(billing ? 'Active' : 'Not billing', color),
              if (canEdit)
                OutlinedButton.icon(
                  onPressed: () => subscriptionDialog(s),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(unset ? 'Set up' : 'Edit'),
                ),
            ],
          ),
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
            subscriptionRow(s),
        ],
      );
    });

    // ── Summary tiles (from the subscriptions) ──────────────────────────────
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
      return Obx(() {
        final subs = controller.subscriptions.values.where((s) => s.active).toList();
        final mrr = subs.fold<int>(0, (sum, s) => sum + s.nextAmountPaise);
        final notBilling = controller.societies.length - subs.length;
        return LayoutBuilder(builder: (context, c) {
          final tiles = [
            summaryTile(Icons.currency_rupee_rounded, AppColors.success, rupees(mrr), 'Monthly recurring revenue'),
            summaryTile(Icons.autorenew_rounded, AppColors.primary, '${subs.length}', 'Societies billing'),
            summaryTile(Icons.pause_circle_outline_rounded, AppColors.orange, '${notBilling < 0 ? 0 : notBilling}', 'Not billing yet'),
            summaryTile(Icons.receipt_long_rounded, AppColors.purple, '${controller.total.value}', 'Invoices in this view'),
          ];
          if (c.maxWidth < 700) {
            return Column(spacing: 10, children: [Row(spacing: 10, children: [tiles[0], tiles[1]]), Row(spacing: 10, children: [tiles[2], tiles[3]])]);
          }
          return Row(spacing: 12, children: tiles);
        });
      });
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billing', style: context.appText.sectionHeader.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('What Nexora charges each society. Payments are recorded here after a bank transfer.', style: context.appText.timestamp),
                  ],
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
          const SizedBox(height: 16),
          summaryRow(),
          const SizedBox(height: 12),
          Obx(
            () => controller.notice.value.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.success.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(controller.notice.value, style: const TextStyle(fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
          ),
          Obx(() => Align(
                alignment: Alignment.centerLeft,
                child: Segmented(items: const ['Invoices', 'Subscriptions'], selected: controller.tab.value, onTap: (i) => controller.tab.value = i),
              )),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(
              () => controller.tab.value == 0 ? invoicesTab() : subscriptionsTab(),
            ),
          ),
        ],
      ),
    );
  }
}
