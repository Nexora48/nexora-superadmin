import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/m10_models.dart';
import '../theme/app_colors.dart';

/// Short day label for a YYYY-MM-DD string ("7 Nov").
String shortDay(String day) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final p = day.split('-');
  if (p.length != 3) return day;
  return '${int.parse(p[2])} ${m[int.parse(p[1]) - 1]}';
}

/// Compact number: 1.2k, 3.4M.
String compact(num v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
  return '${v.round()}';
}

/// A daily line chart with a soft area under it. Empty or all-zero series draw a flat line.
Widget trendChart(
  List<Point> pts, {
  Color color = AppColors.primary,
  double height = 190,
  String Function(int)? format,
}) {
  if (pts.isEmpty) return SizedBox(height: height);
  final fmt = format ?? (n) => compact(n);
  final maxV = pts.map((p) => p.value).fold<int>(0, math.max);
  final top = maxV == 0 ? 4.0 : (maxV * 1.2).ceilToDouble();
  final step = math.max(1, (pts.length / 6).ceil());
  return SizedBox(
    height: height,
    child: LineChart(
      LineChartData(
        minY: 0,
        maxY: top,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: top / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.dividerLight, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: top / 4,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  fmt(v.round()),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: step.toDouble(),
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 || i >= pts.length || i % step != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    shortDay(pts[i].day),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${shortDay(pts[s.x.round()].day)}\n${fmt(s.y.round())}',
                  const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < pts.length; i++)
                FlSpot(i.toDouble(), pts[i].value.toDouble()),
            ],
            isCurved: true,
            curveSmoothness: 0.2,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A labelled bar showing used / max (grey when unlimited, amber at 90 %, red when over).
Widget limitBar(UsageRow u) {
  final color = u.exceeded
      ? AppColors.error
      : u.atWarning
      ? AppColors.warning
      : AppColors.primary;
  final maxText = u.max == null ? 'unlimited' : '${u.max}';
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                u.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${u.used} / $maxText',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: u.exceeded
                    ? AppColors.error
                    : AppColors.textSecondaryLight,
              ),
            ),
            if (!u.hard)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text(
                  'soft',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: u.max == null ? 0 : u.ratio.clamp(0, 1).toDouble(),
            backgroundColor: AppColors.dividerLight,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    ),
  );
}
