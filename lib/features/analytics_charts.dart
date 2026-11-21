import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../core/analytics.dart';

String minuteText(double seconds) =>
    seconds > 0 && seconds < 60 ? '<1 mnt' : '${(seconds / 60).round()} mnt';
String percentText(double? value) => value == null ? '—' : '${value.round()}%';
String bucketLabel(AnalyticsBucket b, AnalyticsPeriod period) => DateFormat(
  period == AnalyticsPeriod.monthly ? 'MMM yy' : 'd MMM',
  'id_ID',
).format(b.start);
Color categoryColor(BuildContext context, String d) => switch (d) {
  'TWK' => Theme.of(context).colorScheme.primary,
  'TIU' => Theme.of(context).colorScheme.secondary,
  'TKP' => Theme.of(context).colorScheme.tertiary,
  _ => Theme.of(context).colorScheme.onSurfaceVariant,
};

class ActivityChart extends StatelessWidget {
  const ActivityChart({
    super.key,
    required this.buckets,
    required this.period,
    this.compact = false,
    this.syncLabel = 'Data lokal',
  });
  final List<AnalyticsBucket> buckets;
  final AnalyticsPeriod period;
  final bool compact;
  final String syncLabel;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasData = buckets.any((b) => b.minutes != null);
    final maxY = math.max(
      1.0,
      buckets.fold<double>(0, (v, b) => math.max(v, b.minutes ?? 0)) * 1.22,
    );
    final interval = math.max(1, (maxY / 3).ceil()).toDouble();
    final titles = FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        axisNameWidget: compact
            ? null
            : const Text('Menit', style: TextStyle(fontSize: 11)),
        sideTitles: SideTitles(
          showTitles: !compact,
          reservedSize: 31,
          interval: interval,
          getTitlesWidget: (v, _) =>
              Text('${v.round()}', style: const TextStyle(fontSize: 10)),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: compact ? 23 : 30,
          interval: 1,
          getTitlesWidget: (v, _) {
            final i = v.round();
            if (i < 0 || i >= buckets.length || v != i.toDouble()) {
              return const SizedBox();
            }
            if (buckets.length > 7 && i % 2 != 0 && i != buckets.length - 1) {
              return const SizedBox();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                compact
                    ? '${buckets[i].start.day}'
                    : bucketLabel(buckets[i], period),
                style: TextStyle(
                  fontSize: compact ? 10 : 9,
                  color: colors.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
    );
    final grid = FlGridData(
      show: !compact,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) => FlLine(
        color: colors.outlineVariant.withValues(alpha: .5),
        strokeWidth: .5,
      ),
    );
    String tip(int i) {
      final b = buckets[i];
      return '${bucketLabel(b, period)}\n${b.minutes == null ? 'Durasi belum tersedia' : '${b.minutes!.toStringAsFixed(1)} menit${b.complete ? '' : ' tercatat (parsial)'}'}\n${b.samples} jawaban final\n$syncLabel';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: compact ? 96 : 205,
          child: !hasData
              ? Center(
                  child: Text(
                    'Durasi belum tersedia',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : Semantics(
                  label: 'Grafik waktu belajar. Alternatif tabel data tersedia di bawah.',
                  child: period == AnalyticsPeriod.monthly
                      ? LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: math.max(1, buckets.length - 1).toDouble(),
                            minY: 0,
                            maxY: maxY,
                            gridData: grid,
                            titlesData: titles,
                            borderData: FlBorderData(show: false),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (spots) => spots
                                    .map(
                                      (s) => LineTooltipItem(
                                        tip(s.x.round()),
                                        TextStyle(
                                          color: colors.onSurface,
                                          fontSize: 11,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                getTooltipColor: (_) =>
                                    colors.surfaceContainerHighest,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                color: colors.primary,
                                barWidth: 3,
                                isCurved: false,
                                spots: List.generate(
                                  buckets.length,
                                  (i) => buckets[i].minutes == null
                                      ? FlSpot.nullSpot
                                      : FlSpot(
                                          i.toDouble(),
                                          buckets[i].minutes!,
                                        ),
                                ),
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                          duration: Duration.zero,
                        )
                      : BarChart(
                          BarChartData(
                            minY: 0,
                            maxY: maxY,
                            gridData: grid,
                            titlesData: titles,
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (_, i, _, _) => BarTooltipItem(
                                  tip(i),
                                  TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 11,
                                  ),
                                ),
                                getTooltipColor: (_) =>
                                    colors.surfaceContainerHighest,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                              ),
                            ),
                            barGroups: List.generate(buckets.length, (i) {
                              final b = buckets[i];
                              var cursor = 0.0;
                              final stacks = <BarChartRodStackItem>[];
                              if (period == AnalyticsPeriod.weekly) {
                                for (final e in b.secondsByCategory.entries) {
                                  final next = cursor + e.value / 60;
                                  stacks.add(
                                    BarChartRodStackItem(
                                      cursor,
                                      next,
                                      categoryColor(context, e.key),
                                    ),
                                  );
                                  cursor = next;
                                }
                              }
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: b.minutes ?? 0,
                                    width: compact
                                        ? 14
                                        : math.min(20, 160 / buckets.length),
                                    color: colors.primary.withValues(
                                      alpha: b.complete ? 1 : .55,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    rodStackItems: stacks,
                                  ),
                                ],
                              );
                            }),
                          ),
                          duration: Duration.zero,
                        ),
                ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          if (period == AnalyticsPeriod.weekly)
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children:
                  [
                        'TWK',
                        'TIU',
                        'TKP',
                        if (buckets.any(
                          (b) => b.secondsByCategory.containsKey(
                            'Tidak diketahui',
                          ),
                        ))
                          'Tidak diketahui',
                      ]
                      .map(
                        (d) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              color: categoryColor(context, d),
                            ),
                            const SizedBox(width: 5),
                            Text(d, style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: 5),
          Text(
            'WIB · minggu mulai Senin',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 10),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Data grafik', style: TextStyle(fontSize: 13)),
            children: buckets
                .map(
                  (b) => Semantics(
                    label:
                        '${bucketLabel(b, period)}, ${b.minutes == null ? 'durasi belum diketahui' : '${b.minutes!.toStringAsFixed(1)} menit'}, ${b.samples} jawaban final, ${b.complete ? 'pencatatan lengkap' : 'pencatatan parsial'}',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        '${bucketLabel(b, period)} · ${b.minutes == null ? '—' : '${b.minutes!.toStringAsFixed(1)} mnt'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        '${b.samples} soal${b.complete ? '' : ' · parsial'}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class CatScoreChart extends StatelessWidget {
  const CatScoreChart({
    super.key,
    required this.cohort,
    this.category = 'Semua',
  });
  final CatCohort cohort;
  final String category;
  @override
  Widget build(BuildContext context) {
    final list = cohort.attempts;
    return SizedBox(
      height: 185,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: math.max(
            1.0,
            list.map((a) => cohortScore(a, category)).reduce(math.max) * 1.15,
          ),
          minX: 0,
          maxX: math.max(1, list.length - 1).toDouble(),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 25,
                interval: 1,
                getTitlesWidget: (v, _) => v == v.roundToDouble()
                    ? Text(
                        '#${v.toInt() + 1}',
                        style: const TextStyle(fontSize: 10),
                      )
                    : const SizedBox(),
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 35),
            ),
          ),
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${calendarKey(wibDay(timestamp(list[s.x.toInt()]['submitted_at'])!))}\n${s.y.round()} poin',
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  )
                  .toList(),
              getTooltipColor: (_) =>
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                list.length,
                (i) => FlSpot(i.toDouble(), cohortScore(list[i], category)),
              ),
              color: Theme.of(context).colorScheme.primary,
              isCurved: false,
              barWidth: 3,
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}

double cohortScore(Map<String, dynamic> a, String category) =>
    category == 'Semua'
    ? catScore(a)
    : ((a['scores'] as Map?)?[category] as num? ?? 0).toDouble();
double cohortAverage(CatCohort c, String category) =>
    c.attempts.fold<double>(0, (n, a) => n + cohortScore(a, category)) /
    c.attempts.length;

class CatMonthlyChart extends StatelessWidget {
  const CatMonthlyChart({
    super.key,
    required this.cohort,
    required this.buckets,
    required this.category,
  });
  final CatCohort cohort;
  final List<AnalyticsBucket> buckets;
  final String category;
  @override
  Widget build(BuildContext context) {
    final monthly = buckets
        .map(
          (b) => cohort.attempts.where((a) {
            final d = wibDay(timestamp(a['submitted_at'])!);
            return !d.isBefore(b.start) && d.isBefore(b.end);
          }).toList(),
        )
        .toList();
    final points = List.generate(
      buckets.length,
      (i) => monthly[i].isEmpty
          ? FlSpot.nullSpot
          : FlSpot(
              i.toDouble(),
              monthly[i].fold<double>(
                    0,
                    (n, a) => n + cohortScore(a, category),
                  ) /
                  monthly[i].length,
            ),
    );
    final max = math.max(
      1.0,
      points
              .where((s) => s != FlSpot.nullSpot)
              .fold<double>(0, (v, s) => math.max(v, s.y)) *
          1.2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Rata-rata nilai $category per bulan · satu blueprint',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: max,
              minX: 0,
              maxX: (buckets.length - 1).toDouble(),
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 35),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      return i >= 0 &&
                              i < buckets.length &&
                              v == i.toDouble() &&
                              (buckets.length <= 6 || i.isEven)
                          ? Text(
                              bucketLabel(buckets[i], AnalyticsPeriod.monthly),
                              style: const TextStyle(fontSize: 9),
                            )
                          : const SizedBox();
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          '${bucketLabel(buckets[s.x.toInt()], AnalyticsPeriod.monthly)}\n${s.y.toStringAsFixed(1)} poin · n=${monthly[s.x.toInt()].length}',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      )
                      .toList(),
                  getTooltipColor: (_) =>
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isCurved: false,
                ),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Tabel nilai bulanan',
            style: TextStyle(fontSize: 13),
          ),
          children: List.generate(
            buckets.length,
            (i) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${bucketLabel(buckets[i], AnalyticsPeriod.monthly)} · ${monthly[i].isEmpty ? '—' : points[i].y.toStringAsFixed(1)} poin · n=${monthly[i].length}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
