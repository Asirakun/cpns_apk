import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/analytics.dart';
import '../core/controller.dart';
import '../core/models.dart';
import '../app/widgets.dart';
import '../app/paper.dart';
import 'analytics_charts.dart';

// An additional chart page; the existing five tabs and papercut UI stay intact.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, this.initialCategory = 'Semua'});
  final String initialCategory;
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod period = AnalyticsPeriod.daily;
  StudyMode mode = StudyMode.all;
  late String category;
  int count = 7;
  bool monthlyScores = false;
  String? cohortKey;
  @override
  void initState() {
    super.initState();
    category = domains.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'Semua';
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final analytics = app.analytics;
    final buckets = analytics.buckets(
      period,
      count,
      category: category,
      mode: mode,
    );
    final summary = analytics.summary(
      buckets.first.start,
      buckets.last.end,
      category: category,
      mode: mode,
    );
    final compare = analytics.comparison(
      period,
      category: category,
      mode: mode,
    );
    final topics = analytics.topics(category: category, mode: mode);
    final ranges = switch (period) {
      AnalyticsPeriod.daily => [7, 14],
      AnalyticsPeriod.weekly => [8, 12],
      AnalyticsPeriod.monthly => [6, 12],
    };
    final unit = switch (period) {
      AnalyticsPeriod.daily => 'hari',
      AnalyticsPeriod.weekly => 'minggu',
      AnalyticsPeriod.monthly => 'bulan',
    };
    final cohorts = analytics
        .cohorts()
        .map(
          (c) => CatCohort(
            c.key,
            c.attempts
                .where(
                  (v) =>
                      !wibDay(timestamp(v['submitted_at'])!)
                          .isBefore(buckets.first.start) &&
                      wibDay(timestamp(v['submitted_at'])!)
                          .isBefore(buckets.last.end),
                )
                .toList(),
          ),
        )
        .where((c) => c.attempts.isNotEmpty)
        .toList();
    final cohort =
        cohorts.where((c) => c.key == cohortKey).firstOrNull ??
        cohorts.firstOrNull;
    final mixed =
        analytics.attempts.any(isCat) &&
        (analytics.attempts.any((v) => !isCat(v)) ||
            analytics.sessions.any((s) => s.kind != 'cat'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis belajar'),
        actions: [
          IconButton(
            tooltip: app.syncLabel,
            onPressed: () => _sources(context, app),
            icon: Icon(
              app.queued > 0 || app.namespace == 'guest'
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_done_outlined,
              size: 21,
            ),
          ),
          IconButton(
            tooltip: 'Sumber & rumus grafik',
            onPressed: () => _sources(context, app),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: PaperBackdrop(
        child: SafeArea(
          top: false,
          child: PageBody(
            children: [
              SegmentedButton<AnalyticsPeriod>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AnalyticsPeriod.daily,
                    label: Text('Harian'),
                  ),
                  ButtonSegment(
                    value: AnalyticsPeriod.weekly,
                    label: Text('Mingguan'),
                  ),
                  ButtonSegment(
                    value: AnalyticsPeriod.monthly,
                    label: Text('Bulanan'),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (v) => setState(() {
                  period = v.first;
                  count = switch (period) {
                    AnalyticsPeriod.daily => 7,
                    AnalyticsPeriod.weekly => 8,
                    AnalyticsPeriod.monthly => 6,
                  };
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  DropdownButton<int>(
                    value: count,
                    underline: const SizedBox(),
                    items: ranges
                        .map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text(
                              '$n $unit',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (n) => setState(() => count = n!),
                  ),
                  const Spacer(),
                  if (mixed)
                    PopupMenuButton<StudyMode>(
                      tooltip: 'Jenis aktivitas',
                      initialValue: mode,
                      onSelected: (m) => setState(() => mode = m),
                      itemBuilder: (_) => StudyMode.values
                          .map(
                            (m) => PopupMenuItem(
                              value: m,
                              child: Text(
                                m == StudyMode.all
                                    ? 'Semua aktivitas'
                                    : m == StudyMode.learn
                                    ? 'Belajar / latihan'
                                    : 'Tryout CAT',
                              ),
                            ),
                          )
                          .toList(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mode == StudyMode.all
                                  ? 'Semua aktivitas'
                                  : mode == StudyMode.learn
                                  ? 'Belajar'
                                  : 'Tryout',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 7),
                            const Icon(Icons.tune_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ['Semua', ...domains]
                    .map(
                      (d) => ChoiceChip(
                        label: Text(d),
                        showCheckmark: false,
                        selected: category == d,
                        onSelected: (_) => setState(() => category = d),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              Card(
                child: InkWell(
                  onTap: () => _sources(context, app),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _number('Waktu aktif', minuteText(summary.seconds)),
                        _number('Soal final', '${summary.finalCount}'),
                        _number(
                          category == 'TKP' ? 'Kualitas TKP' : 'TWK / TIU',
                          percentText(
                            category == 'TKP'
                                ? summary.tkpQuality
                                : summary.accuracy,
                          ),
                          detail: category == 'Semua'
                              ? 'TKP ${percentText(summary.tkpQuality)}'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _paper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            period == AnalyticsPeriod.monthly && monthlyScores
                                ? 'Tren skor'
                                : 'Waktu belajar',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (buckets.any((b) => !b.complete))
                          Tooltip(
                            message: 'Durasi sebelum pencatatan belum diketahui. Batang pudar menunjukkan cakupan parsial.',
                            child: Text(
                              'Parsial',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (period == AnalyticsPeriod.monthly) ...[
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: false, label: Text('Menit')),
                          ButtonSegment(value: true, label: Text('Nilai CAT')),
                        ],
                        selected: {monthlyScores},
                        onSelectionChanged: (v) =>
                            setState(() => monthlyScores = v.first),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (period == AnalyticsPeriod.monthly && monthlyScores)
                      if (cohort == null || mode == StudyMode.learn)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Text('Belum ada CAT selesai.'),
                        )
                      else ...[
                        _cohortPicker(cohorts, cohort),
                        CatMonthlyChart(
                          cohort: cohort,
                          buckets: buckets,
                          category: category,
                        ),
                      ]
                    else
                      ActivityChart(
                        buckets: buckets,
                        period: period,
                        syncLabel: app.syncLabel,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      compare == null
                          ? 'Belum ada pembanding'
                          : '${compare.deltaMinutes >= 0 ? '+' : ''}${compare.deltaMinutes.toStringAsFixed(1)} mnt vs periode lalu${compare.percent == null ? '' : ' · ${compare.percent!.toStringAsFixed(0)}%'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '${summary.activeDays} hari aktif',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Tooltip(
                    message: 'Target global; hanya hari yang sudah lewat dan tercatat lengkap dihitung.',
                    child: Text(
                      'Target ${summary.achievedDays}/${summary.targetDays} hari',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (summary.averageActiveMinutes != null)
                    Text(
                      'Rerata ${summary.averageActiveMinutes!.toStringAsFixed(0)} mnt/hari aktif',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              if (analytics.sessions.isEmpty && analytics.attempts.isEmpty) ...[
                const SizedBox(height: 14),
                EmptyCard(
                  icon: Icons.analytics_outlined,
                  title: 'Belum ada aktivitas',
                  body: 'Mulai latihan pertamamu.',
                  action: 'Buka latihan',
                  onAction: () => context.go('/tryouts'),
                ),
              ],
              if (category != 'Semua')
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Tren $category · 4 minggu',
                    style: const TextStyle(fontSize: 14),
                  ),
                  children: [
                    _paper(
                      child: ActivityChart(
                        buckets: analytics.buckets(
                          AnalyticsPeriod.weekly,
                          4,
                          category: category,
                          mode: mode,
                        ),
                        period: AnalyticsPeriod.weekly,
                        syncLabel: app.syncLabel,
                      ),
                    ),
                  ],
                ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Kualitas topik · 30 hari',
                  style: TextStyle(fontSize: 14),
                ),
                children: topics.isEmpty
                    ? [
                        const ListTile(
                          title: Text(
                            'Belum ada jawaban final.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ]
                    : topics
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.topic,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${t.quality.round()}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: t.quality / 100,
                                    minHeight: 5,
                                    color: categoryColor(context, t.domain),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${t.domain} · n=${t.count}${t.sufficient ? '' : ' · sampel awal'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
              ),
              if (cohort != null && mode != StudyMode.learn)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'Tren nilai CAT',
                    style: TextStyle(fontSize: 14),
                  ),
                  children: [
                    _paper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cohortPicker(cohorts, cohort),
                          const SizedBox(height: 12),
                          Text(
                            'Rerata ${cohortAverage(cohort, category).toStringAsFixed(1)} poin · n=${cohort.attempts.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          CatScoreChart(cohort: cohort, category: category),
                          ...cohort.attempts.reversed
                              .take(5)
                              .map(
                                (a) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${wibDate(a['submitted_at'] as String?)} · ${cohortScore(a, category).round()} poin',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () =>
                                      context.push('/result/${a['id']}'),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _number(String label, String value, {String? detail}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        if (detail != null)
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 10),
          ),
      ],
    ),
  );
  Widget _paper({required Widget child}) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
  Widget _cohortPicker(List<CatCohort> cohorts, CatCohort cohort) =>
      DropdownButtonFormField<String>(
        key: ValueKey(cohort.key),
        initialValue: cohort.key,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Blueprint'),
        items: cohorts
            .map(
              (c) => DropdownMenuItem(
                value: c.key,
                child: Text(
                  c.label,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => cohortKey = v),
      );

  void _sources(
    BuildContext context,
    AppController app,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SheetBody(
        children: [
          Text(
            'Sumber & rumus grafik',
            style: Theme.of(ctx).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Grafik dihitung dari snapshot lokal akun ini.\n\nWaktu aktif = jumlah detik sesi foreground ÷ 60. Idle 120 detik dan background tidak dihitung. Checkpoint setiap 15 detik; interval terakhir yang belum tersimpan bisa hilang saat force-stop. Durasi tidak diambil dari deadline CAT.\n\nSoal final unik per attempt + soal dari latihan yang dikumpulkan. TWK/TIU = benar ÷ jawaban final. Kualitas TKP = jumlah skor opsi ÷ jumlah maksimum snapshot. — berarti tanpa sampel.\n\nWaktu sebelum pencatatan ditandai unknown, bukan nol. Target hanya dari hari bertarget yang telah lewat dan waktunya tercatat lengkap. Filter kategori tidak membagi target global.\n\nCAT dibandingkan hanya pada blueprint dan aturan skor yang sama; kecepatan jawab disembunyikan karena elapsed_ms belum tercatat. Bukan prediksi kelulusan.\n\n${app.syncLabel}',
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    ),
  );
}
