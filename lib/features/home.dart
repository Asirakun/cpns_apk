import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/controller.dart';
import '../core/models.dart';
import '../app/theme.dart';
import '../app/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final last = app.results.lastOrNull;
    final completed = (app.data['completed'] as List).length;
    final date = DateTime.now().toUtc().add(const Duration(hours: 7));
    final day = (app.data['study_days'] as List).length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang, ${app.data['alias']}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Siap melangkah\nlebih dekat?',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: indigo.withValues(alpha: .1),
                  child: Text(
                    (app.data['alias'] as String).isEmpty
                        ? 'CJ'
                        : (app.data['alias'] as String)
                              .substring(0, 1)
                              .toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  app.namespace == 'guest'
                      ? Icons.offline_pin_outlined
                      : Icons.cloud_done_outlined,
                  size: 14,
                  color: teal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    app.syncLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year} · WIB',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4653D9), Color(0xFF4F5DCC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'FOKUS HARI INI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFD7DBFF),
                        size: 26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${app.data['minutes']} menit untuk\nmasa depanmu.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1.3,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    day == 0
                        ? 'Mulai ringan. Satu materi, lalu satu latihan.'
                        : 'Sudah belajar pada $day hari. Lanjutkan sesuai ritmemu.',
                    style: const TextStyle(
                      color: Color(0xFFE4E7FF),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: indigo,
                    ),
                    onPressed: () async {
                      try {
                        final a = await app.startAttempt(quick: true);
                        if (context.mounted) context.push('/exam/${a.id}');
                      } catch (e) {
                        if (context.mounted) {
                          message(
                            context,
                            'Aktifkan paket offline melalui tab Belajar.',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      app.activeAttempt == null
                          ? 'Mulai latihan'
                          : 'Lanjutkan latihan',
                    ),
                  ),
                ],
              ),
            ),
            SectionMetrics(last: last),
            SectionTitleWithCount(count: completed),
            Card(
              child: Column(
                children: [
                  _task(
                    context,
                    app,
                    'materi',
                    'Baca satu materi',
                    'Ringkas, sekitar 10–15 menit',
                    Icons.menu_book_rounded,
                    () => context.go('/learn'),
                  ),
                  _task(
                    context,
                    app,
                    'latihan',
                    'Selesaikan latihan singkat',
                    '15 soal untuk mengasah pemahaman',
                    Icons.edit_note_rounded,
                    () async {
                      final a = await app.startAttempt(quick: true);
                      if (context.mounted) context.push('/exam/${a.id}');
                    },
                  ),
                  _task(
                    context,
                    app,
                    'berkas',
                    'Cek satu berkas persiapan',
                    'Cukup status, tanpa unggah dokumen',
                    Icons.task_alt_rounded,
                    () => context.push('/journey/documents'),
                  ),
                ],
              ),
            ),
            if (app.recommendedTopics.isNotEmpty) ...[
              const SectionTitleWithText(
                title: 'Prioritas belajarmu',
                subtitle: 'Berdasarkan jawaban pada latihan yang selesai',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: app.recommendedTopics
                    .map(
                      (t) => ActionChip(
                        label: Text('$t · ${app.weaknesses[t]} perlu ditinjau'),
                        avatar: const Icon(Icons.psychology_outlined, size: 17),
                        onPressed: () async {
                          final a = await app.startAttempt(
                            topic: t,
                            quick: true,
                          );
                          if (context.mounted) context.push('/exam/${a.id}');
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            SectionTitleWithAction(onTap: () => context.go('/tryouts')),
            if (app.results.isEmpty)
              const EmptyCard(
                icon: Icons.show_chart_rounded,
                title: 'Setiap progres punya awal',
                body: 'Tren nilaimu akan muncul setelah menyelesaikan latihan pertama.',
              )
            else
              ScoreChart(attempts: app.results),
            const SectionTitleWithText(
              title: 'Perjalanan seleksimu',
              subtitle: 'Kemenkeu · pendidikan melamar SMA',
            ),
            ActionTile(
              icon: Icons.route_rounded,
              title: '${app.stagesDone} dari 12 tahap selesai',
              subtitle: 'Status dicatat sendiri dari pengumuman resmi',
              color: teal,
              onTap: () => context.go('/journey'),
              trailing: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: app.stagesDone / 12,
                      strokeWidth: 4,
                      backgroundColor: teal.withValues(alpha: .1),
                      color: teal,
                    ),
                    Text(
                      '${(app.stagesDone / 12 * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Note(
              'Target Medan belum pasti. Formasi dan jadwal seleksi belum dimasukkan sebagai data resmi 2026.',
              icon: Icons.location_on_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _task(
    BuildContext c,
    AppController app,
    String key,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback action,
  ) {
    final id = '${app.dayKey}:$key';
    final done = (app.data['daily_tasks'] as List).contains(id);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Checkbox(
        value: done,
        onChanged: (v) async {
          final tasks = app.data['daily_tasks'] as List;
          v == true ? tasks.add(id) : tasks.remove(id);
          await app.save();
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: IconButton(
        tooltip: 'Buka $title',
        icon: Icon(icon, size: 22, color: Theme.of(c).colorScheme.primary),
        onPressed: action,
      ),
    );
  }
}

class SectionMetrics extends StatelessWidget {
  const SectionMetrics({super.key, this.last});
  final Attempt? last;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tag(domains[i], color: [indigo, teal, amber][i]),
                    const SizedBox(height: 12),
                    Text(
                      last == null ? '—' : '${last!.scores[domains[i]]}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      last == null ? 'Belum latihan' : 'Latihan terakhir',
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class SectionTitleWithCount extends StatelessWidget {
  const SectionTitleWithCount({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext c) => Section(
    title: 'Langkah kecil hari ini',
    subtitle: '$count materi selesai · ritme belajar fleksibel',
  );
}

class SectionTitleWithText extends StatelessWidget {
  const SectionTitleWithText({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext c) => Section(title: title, subtitle: subtitle);
}

class SectionTitleWithAction extends StatelessWidget {
  const SectionTitleWithAction({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => Section(
    title: 'Perkembangan latihan',
    action: 'Lihat semua',
    onAction: onTap,
  );
}

// Small wrapper keeps screen sections consistent.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });
  final String title;
  final String? subtitle, action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext c) => SectionHeader(
    title: title,
    subtitle: subtitle,
    action: action,
    onAction: onAction,
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });
  final String title;
  final String? subtitle, action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext c) => SectionTitle(
    title,
    subtitle: subtitle,
    action: action,
    onAction: onAction,
  );
}

class ScoreChart extends StatelessWidget {
  const ScoreChart({super.key, required this.attempts});
  final List<Attempt> attempts;
  @override
  Widget build(BuildContext context) {
    final list = attempts.take(10).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Persentase skor maksimum',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 145,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  minX: 0,
                  maxX: list.length < 2 ? 1 : (list.length - 1).toDouble(),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 33,
                        interval: 50,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        list.length,
                        (i) => FlSpot(
                          i.toDouble(),
                          list[i].total / list[i].maximum * 100,
                        ),
                      ),
                      isCurved: false,
                      color: indigo,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: indigo.withValues(alpha: .07),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${list.length} latihan · skor latihan personal',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
