import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/weight_entry.dart';

/// Simple trend line over recent weight entries. Plots by chronological
/// index rather than actual date spacing — entries are sparse (not
/// logged every day), so even spacing reads more clearly than gaps.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.entries});

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('Log at least 2 days to see a trend.')),
      );
    }

    final theme = Theme.of(context);
    final weights = entries.map((e) => e.weightKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.15 + 0.5;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minWeight - padding,
          maxY: maxWeight + padding,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < entries.length; i++) FlSpot(i.toDouble(), entries[i].weightKg),
              ],
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
