import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_theme.dart';

// Small shared view helpers (functions, not widget classes, to match the project's view style).

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatDate(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')} ${_months[l.month - 1]} ${l.year}';
}

String formatDateTime(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  final h = l.hour.toString().padLeft(2, '0');
  final m = l.minute.toString().padLeft(2, '0');
  return '${formatDate(l)}, $h:$m';
}

/// "5 min ago", "3 h ago", "2 d ago" or the date.
String timeAgo(DateTime? d) {
  if (d == null) return 'never';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 30) return '${diff.inDays} d ago';
  return formatDate(d);
}

/// Coloured pill for a society status.
Widget statusChip(String status) {
  final (bg, fg, label) = switch (status) {
    'active' => (AppColors.successLight, AppColors.success, 'Active'),
    'trial' => (AppColors.primaryLighter, AppColors.primary, 'Trial'),
    'suspended' => (AppColors.errorLight, AppColors.error, 'Suspended'),
    _ => (AppColors.backgroundLight, AppColors.textSecondaryLight, status),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
  );
}

/// White bordered card.
Widget cardBox({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: AppRadius.lgAll,
      border: Border.all(color: AppColors.dividerLight),
    ),
    child: child,
  );
}

/// Centered icon + title + subtitle with an optional button (empty and error states).
Widget stateMessage(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? subtitle,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.textSecondaryLight),
          const SizedBox(height: 12),
          Text(title, style: context.appText.sectionHeader, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: context.appText.timestamp, textAlign: TextAlign.center),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    ),
  );
}

/// Inline red error line that renders nothing when empty.
Widget errorLine(String message) {
  if (message.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
  );
}
