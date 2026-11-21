import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/controller.dart';
import '../core/models.dart';
import '../app/theme.dart';
import '../app/widgets.dart';
import '../app/paper.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final completed = (app.data['completed'] as List).length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            _WelcomePaper(app: app),
            const SizedBox(height: 9),
            _StudyStats(app: app),
            const SizedBox(height: 13),
            _FocusPaper(app: app),
            const SectionTitle(
              'Progres Belajar',
              subtitle: 'Pantau langkah kecilmu di setiap materi.',
            ),
            _LearningPapers(app: app),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HomeShortcut(
                    title: 'Tryout',
                    subtitle: 'Uji kesiapanmu\ndengan simulasi lengkap',
                    asset: PaperAsset.target,
                    onTap: () => context.go('/tryouts'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HomeShortcut(
                    title: 'Analisis\nperforma',
                    subtitle: app.results.isEmpty
                        ? 'Mulai latihan pertamamu'
                        : 'Lihat kekuatan belajarmu',
                    asset: PaperAsset.medal,
                    onTap: () => context.push('/analytics'),
                  ),
                ),
              ],
            ),
            SectionTitle(
              'Langkah Kecil Hari Ini',
              subtitle: '$completed materi selesai · tetap belajar fleksibel',
            ),
            Card(
              child: Column(
                children: [
                  _task(
                    context,
                    app,
                    'materi',
                    'Baca satu materi',
                    'Sekitar 10–15 menit',
                    PaperAsset.book,
                    () => context.go('/learn'),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _task(
                    context,
                    app,
                    'latihan',
                    'Latihan singkat',
                    '15 soal untuk mengasah pemahaman',
                    PaperAsset.target,
                    () => guard(context, () async {
                      final a = await app.startAttempt(quick: true);
                      if (context.mounted) context.push('/exam/${a.id}');
                    }),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _task(
                    context,
                    app,
                    'berkas',
                    'Cek satu berkas',
                    'Cukup status, tanpa unggah dokumen',
                    PaperAsset.checklist,
                    () => context.push('/journey/documents'),
                  ),
                ],
              ),
            ),
            if (app.recommendedTopics.isNotEmpty) ...[
              const SectionTitle(
                'Prioritas belajarmu',
                subtitle: 'Dari jawaban latihan yang selesai',
              ),
              ...app.recommendedTopics.asMap().entries.map((entry) {
                final topic = entry.value;
                final question = app.content.questions
                    .where((q) => q.topic == topic)
                    .firstOrNull;
                final category = question?.domain;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    key: ValueKey('priority-$topic'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      leading: CircleAvatar(
                        radius: 19,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                        child: Text(
                          (entry.key + 1).toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        topic,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${category ?? 'Topik'} · ${app.weaknesses[topic]} soal perlu ditinjau',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => guard(context, () async {
                        final a = await app.startAttempt(
                          topic: topic,
                          quick: true,
                        );
                        if (context.mounted) context.push('/exam/${a.id}');
                      }),
                    ),
                  ),
                );
              }),
            ],
            SectionTitle(
              'Perkembangan latihan',
              action: 'Lihat Analisis',
              onAction: () => context.push('/analytics'),
            ),
            if (app.results.isEmpty)
              const EmptyCard(
                icon: Icons.show_chart_rounded,
                title: 'Setiap progres punya awal',
                body: 'Tren nilaimu muncul setelah latihan pertama selesai.',
              )
            else
              ScoreChart(attempts: app.results),
            const SectionTitle(
              'Perjalanan seleksimu',
              subtitle: 'Status pribadi, berdasarkan sumber resmi',
            ),
            ActionTile(
              icon: Icons.route_rounded,
              title: '${app.stagesDone} dari 12 tahap selesai',
              subtitle: 'Buka peta perjalananmu',
              color: teal,
              onTap: () => context.go('/journey'),
              trailing: Text(
                '${(app.stagesDone / 12 * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.offline_pin_outlined, size: 14, color: teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    app.syncLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
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
    BuildContext context,
    AppController app,
    String key,
    String title,
    String subtitle,
    PaperAsset asset,
    VoidCallback action,
  ) {
    final id = '${app.dayKey}:$key';
    final done = (app.data['daily_tasks'] as List).contains(id);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      leading: Checkbox(
        value: done,
        onChanged: (v) => guard(context, () async {
          final tasks = app.data['daily_tasks'] as List;
          v == true ? tasks.add(id) : tasks.remove(id);
          await app.save();
        }),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
      trailing: IconButton(
        tooltip: 'Buka $title',
        onPressed: action,
        icon: PaperArt(asset, size: 32),
      ),
    );
  }
}

class _WelcomePaper extends StatelessWidget {
  const _WelcomePaper({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        flex: 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang, ${app.data['alias'] as String}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Siap melangkah\nlebih dekat?',
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontSize: 24, height: 1.17),
            ),
            const SizedBox(height: 9),
            CustomPaint(size: const Size(90, 7), painter: _UnderlinePainter()),
          ],
        ),
      ),
      const Expanded(flex: 5, child: HomeIllustration('welcome', height: 138)),
    ],
  );
}

class _UnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(1, 6)
        ..quadraticBezierTo(42, -2, 88, 5),
      Paint()
        ..color = const Color(0xFFFFCC54)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter oldDelegate) => false;
}

class _StudyStats extends StatelessWidget {
  const _StudyStats({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) {
    final days = (app.data['study_days'] as List).cast<String>().toSet();
    final now = DateTime.parse(app.dayKey);
    final firstDay = now.subtract(Duration(days: now.weekday - 1));
    final week = days.where((s) {
      final day = DateTime.tryParse(s);
      return day != null && !day.isBefore(firstDay) && !day.isAfter(now);
    }).length;
    final all = app.content.lessons.length;
    final progress = all == 0
        ? 0
        : ((app.data['completed'] as List).length / all * 100)
              .clamp(0, 100)
              .round();
    return BluePaperPanel(
      deep: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _stat(
                Icons.local_fire_department_rounded,
                '${days.length} hari',
                'Hari belajar',
              ),
            ),
            const VerticalDivider(
              width: 13,
              thickness: .7,
              color: Color(0xFF3F6B90),
            ),
            Expanded(
              child: _stat(
                Icons.my_location_rounded,
                '$week/7',
                'Belajar pekan ini',
              ),
            ),
            const VerticalDivider(
              width: 13,
              thickness: .7,
              color: Color(0xFF3F6B90),
            ),
            Expanded(
              child: _stat(
                Icons.bar_chart_rounded,
                '$progress%',
                'Materi selesai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Row(
    children: [
      Icon(icon, color: const Color(0xFFFFCF61), size: 22),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: paperCream,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFC2D8E9), fontSize: 7),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FocusPaper extends StatelessWidget {
  const _FocusPaper({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => BluePaperPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFE5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.track_changes_rounded,
                          size: 12,
                          color: paperInk,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Fokus Hari Ini',
                          style: TextStyle(
                            color: paperInk,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${app.data['minutes']} menit',
                    style: const TextStyle(
                      color: paperCream,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -.8,
                    ),
                  ),
                  const Text(
                    'untuk masa depanmu.',
                    style: TextStyle(
                      color: Color(0xFFB9DFFF),
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Sedikit hari ini.\nLebih siap setiap hari.',
                    style: TextStyle(
                      color: Color(0xFFC5DDEF),
                      fontSize: 9,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              flex: 4,
              child: HomeIllustration('focus', width: 125, height: 126),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              flex: 6,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCB4F),
                  foregroundColor: paperInk,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
                onPressed: () => guard(context, () async {
                  final a = await app.startAttempt(quick: true);
                  if (context.mounted) context.push('/exam/${a.id}');
                }),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(
                  app.activeAttempt == null
                      ? 'Mulai latihan'
                      : 'Lanjutkan latihan',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 5,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: paperCream,
                  side: const BorderSide(color: Color(0xFFA5C8E5)),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                ),
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.calendar_month_outlined, size: 15),
                label: const Text(
                  'Atur target',
                  style: TextStyle(fontSize: 9, fontFamily: 'PlusJakarta'),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _LearningPapers extends StatelessWidget {
  const _LearningPapers({required this.app});
  final AppController app;
  double _progress(String domain) {
    final lessons = app.content.lessons
        .where((l) => l['domain'] == domain)
        .toList();
    if (lessons.isEmpty) return 0;
    double sum = 0;
    for (final lesson in lessons) {
      if ((app.data['completed'] as List).contains(lesson['id'])) {
        sum += 1;
        continue;
      }
      final length = (lesson['body'] as List).length;
      final position =
          (app.data['lesson_positions'] as Json)[lesson['id']] as int? ?? 0;
      if (length > 0) sum += (position / length).clamp(0, 1);
    }
    return sum / lessons.length;
  }

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
            child: BluePaperPanel(
              padding: const EdgeInsets.all(10),
              child: InkWell(
                onTap: () => context.go('/learn'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaperArt(
                          [
                            PaperAsset.book,
                            PaperAsset.target,
                            PaperAsset.avatar,
                          ][i],
                          size: 26,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                domains[i],
                                style: const TextStyle(
                                  color: paperCream,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                [
                                  'Wawasan\nKebangsaan',
                                  'Tes Inteligensi\nUmum',
                                  'Karakteristik\nPribadi',
                                ][i],
                                style: const TextStyle(
                                  color: Color(0xFFC5DEEF),
                                  fontSize: 6.5,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(_progress(domains[i]) * 100).round()}%',
                      style: const TextStyle(
                        color: paperCream,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: _progress(domains[i]),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: const Color(0xFF17456F),
                      color: i == 2
                          ? const Color(0xFFFFCD58)
                          : const Color(0xFFAADEFF),
                    ),
                    const SizedBox(height: 5),
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

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onTap,
  });
  final String title, subtitle;
  final PaperAsset asset;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => BluePaperPanel(
    padding: const EdgeInsets.all(12),
    child: InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaperArt(asset, size: 36),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: paperCream,
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFCAE0F0),
                    fontSize: 7.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 13, color: paperBlue),
        ],
      ),
    ),
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
                  titlesData: FlTitlesData(
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
                        reservedSize: 46,
                        interval: 50,
                        getTitlesWidget: (value, _) => Text(
                          '${value.round()}%',
                          maxLines: 1,
                          style: const TextStyle(fontSize: 10),
                        ),
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
