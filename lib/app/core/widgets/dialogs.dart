import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_theme.dart';

/// Standard dialog frame: tinted header with an optional icon and subtitle, scrollable body, action row.
Widget dialogShell(
  BuildContext context, {
  required String title,
  required Widget body,
  required List<Widget> actions,
  double maxWidth = 520,
  String? subtitle,
  IconData? icon,
  Color color = AppColors.primary,
}) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: color.withAlpha(20),
            padding: const EdgeInsets.fromLTRB(20, 16, 10, 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)),
                    child: Icon(icon, color: AppColors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.appText.sectionHeader.copyWith(fontWeight: FontWeight.w800)),
                      if (subtitle != null) Text(subtitle, style: context.appText.timestamp),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: body,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
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
}

/// Small coloured pill.
Widget pill(String text, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
  child: Text(
    text,
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
  ),
);

/// Red error line inside a dialog bound to an observable message.
Widget dialogErrorText(RxString message) => Obx(
  () => message.value.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            message.value,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
);

/// Green confirmation bar (auto-cleared by the controller).
Widget noticeBar(RxString notice) => Obx(
  () => notice.value.isEmpty
      ? const SizedBox.shrink()
      : Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: AppRadius.mdAll,
          ),
          child: Text(
            notice.value,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
);
