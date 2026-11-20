import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/controller.dart';
import '../core/models.dart';
import '../core/services.dart';
import '../app/widgets.dart';
import '../app/theme.dart';

class TryoutScreen extends ConsumerWidget {
  const TryoutScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return PageBody(
      children: [
        Text(
          'Latihan hari ini,\nlebih siap esok hari.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Kenali ritme CAT, lalu pelajari setiap jawaban.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 22),
        if (app.activeAttempt case final active?) ...[
          ActionTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'Lanjutkan ${active.title}',
            subtitle:
                '${active.answers.length}/${active.questions.length} terjawab · timer tetap berjalan',
            color: teal,
            onTap: () => context.push('/exam/${active.id}'),
          ),
          const SizedBox(height: 18),
        ],
        const Note(
          'Setiap paket memakai blueprint berversi. Aturan historis bukan ketentuan final 2026. Nilai latihan bukan hasil seleksi resmi.',
          color: indigo,
        ),
        SectionTitle(
          'Simulasi CAT penuh',
          subtitle: 'Paket bawaan: historis 2024 · 110 soal · 100 menit',
        ),
        ...app.content.packs.map(
          (pack) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Tag(
                          '${ContentRepository.blueprintFor(pack)['status'] == 'historical' ? 'HISTORIS' : 'TERVERIFIKASI'} ${ContentRepository.blueprintFor(pack)['year']}',
                          color: amber,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.timer_outlined,
                          color: indigo,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      pack['name'] as String,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(pack['question_ids'] as List).length} soal · ${(pack['duration_seconds'] as int) ~/ 60} menit',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _instructions(context, app, pack),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Mulai simulasi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SectionTitle('Latihan singkat'),
        ActionTile(
          icon: Icons.bolt_rounded,
          title: 'Pemanasan 15 soal',
          subtitle: 'Campuran TWK, TIU, TKP · pembahasan setelah selesai',
          color: teal,
          onTap: () => guard(context, () async {
            final a = await app.startAttempt(quick: true);
            if (context.mounted) context.push('/exam/${a.id}');
          }),
        ),
        SectionTitle(
          'Riwayat latihan',
          subtitle: 'Nilai tetap terikat versi soal saat dikerjakan',
        ),
        if (app.results.isEmpty)
          const EmptyCard(
            icon: Icons.history_rounded,
            title: 'Belum ada latihan selesai',
            body: 'Selesaikan latihan untuk melihat nilai dan pembahasannya.',
          )
        else
          ...app.results.reversed.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActionTile(
                icon: Icons.analytics_outlined,
                title: a.title,
                subtitle:
                    '${a.total}/${a.maximum} · ${wibDate(a.json['submitted_at'] as String?)}',
                onTap: () => context.push('/result/${a.id}'),
              ),
            ),
          ),
      ],
    );
  }

  void _instructions(BuildContext context, AppController app, Json pack) {
    final blueprint = ContentRepository.blueprintFor(pack);
    final grades = blueprint['passing_grades'] as Json?;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SheetBody(
        children: [
          Text('Sebelum mulai', style: Theme.of(ctx).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            '• Timer ${(pack['duration_seconds'] as int) ~/ 60} menit tetap berjalan saat aplikasi ditutup.\n• Jawaban langsung disimpan di perangkat.\n• TWK/TIU: benar 5, salah/kosong 0.\n• TKP: opsi berbobot 1–5, kosong 0.\n• Setelah dikumpulkan, jawaban tidak bisa diubah.',
            style: TextStyle(height: 1.9),
          ),
          const SizedBox(height: 14),
          Note(
            'Blueprint ${blueprint['year']} · ${blueprint['status']}. Ambang: ${grades == null ? 'tidak diterapkan' : grades.entries.map((e) => '${e.key} ${e.value}').join(', ')}. Memenuhi ambang latihan tidak menjamin kelulusan seleksi.',
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                openOfficial(ctx, blueprint['source_url'] as String),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text('Referensi blueprint ${blueprint['year']}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => guard(ctx, () async {
              final a = await app.startAttempt(pack: pack);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.push('/exam/${a.id}');
              }
            }),
            child: Text(
              app.activeAttempt == null
                  ? 'Saya siap, mulai CAT'
                  : 'Lanjutkan attempt yang aktif',
            ),
          ),
        ],
      ),
    );
  }
}

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ExamScreen> createState() => _ExamState();
}

class _ExamState extends ConsumerState<ExamScreen> with WidgetsBindingObserver {
  Timer? timer;
  bool submitting = false;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _tick() {
    if (!mounted) return;
    final app = ref.read(appProvider);
    final a = app.attempts.where((a) => a.id == widget.id).firstOrNull;
    if (a == null) return;
    if (a.submitted) {
      context.go('/result/${a.id}');
      return;
    }
    if (a.remaining(DateTime.now()) == 0) {
      unawaited(_finish(a, automatic: true));
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _finish(Attempt a, {bool automatic = false}) async {
    if (submitting) return;
    if (!automatic) {
      final missing = a.questions.length - a.answers.length;
      if (!await confirm(
        context,
        'Kumpulkan latihan?',
        missing > 0
            ? 'Masih ada $missing soal belum dijawab. Setelah dikumpulkan, jawaban tidak dapat diubah.'
            : 'Semua soal terjawab. Setelah dikumpulkan, jawaban tidak dapat diubah.',
        action: 'Kumpulkan',
      )) {
        return;
      }
    }
    if (!mounted) return;
    setState(() => submitting = true);
    try {
      await ref.read(appProvider).submit(a);
      if (mounted) context.go('/result/${a.id}');
    } catch (_) {
      if (mounted) {
        message(context, 'Hasil belum tersimpan. Coba kumpulkan kembali.');
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final a = app.attempts.where((a) => a.id == widget.id).firstOrNull;
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Latihan tidak ditemukan.')),
      );
    }
    if (a.submitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/result/${a.id}');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final index = (a.json['index'] as int).clamp(0, a.questions.length - 1);
    final q = a.questions[index];
    final remaining = a.remaining(DateTime.now());
    final minute = (remaining ~/ 60).toString().padLeft(2, '0'),
        second = (remaining % 60).toString().padLeft(2, '0');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop &&
            await confirm(
              context,
              'Keluar sementara?',
              'Jawaban tersimpan. Timer tetap berjalan sampai batas waktu.',
              action: 'Simpan & keluar',
            )) {
          if (context.mounted) context.go('/tryouts');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Simpan & keluar',
            onPressed: () async {
              if (await confirm(
                context,
                'Keluar sementara?',
                'Jawaban tersimpan; timer tetap berjalan.',
                action: 'Simpan & keluar',
              )) {
                if (context.mounted) context.go('/tryouts');
              }
            },
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text('Soal ${index + 1} / ${a.questions.length}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tag(
                '$minute:$second',
                icon: Icons.timer_outlined,
                color: remaining < 300 ? Colors.red : indigo,
              ),
            ),
          ],
        ),
        body: PageBody(
          children: [
            LinearProgressIndicator(
              value: (index + 1) / a.questions.length,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Tag(q.domain),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(q.topic, style: const TextStyle(fontSize: 12)),
                ),
                IconButton(
                  tooltip: 'Navigator soal',
                  onPressed: () => _navigator(a),
                  icon: const Icon(Icons.grid_view_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              q.text,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (q.json['diagram'] != null) ...[
              const SizedBox(height: 20),
              Center(
                child: Text(
                  q.json['diagram'] as String,
                  style: const TextStyle(fontSize: 32, letterSpacing: 8),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ...q.options.map((o) {
              final selected = a.answers[q.id] == o['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  selected: selected,
                  label: 'Opsi ${o['id']}',
                  child: Material(
                    color: selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: saving || submitting
                          ? null
                          : () async {
                              setState(() => saving = true);
                              try {
                                await app.answer(a, q.id, o['id'] as String);
                              } catch (_) {
                                if (context.mounted) {
                                  message(
                                    context,
                                    'Jawaban belum tersimpan. Coba lagi.',
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => saving = false);
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 27,
                              height: 27,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                              ),
                              child: Text(
                                o['id'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                o['text'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_rounded,
                                size: 19,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Tandai ragu-ragu',
                style: TextStyle(fontSize: 13),
              ),
              value: a.flagged.contains(q.id),
              onChanged: (v) => guard(context, () async {
                v == true ? a.flagged.add(q.id) : a.flagged.remove(q.id);
                await app.save();
              }),
            ),
            Row(
              children: [
                Icon(
                  saving ? Icons.save_outlined : Icons.offline_pin_outlined,
                  size: 14,
                  color: teal,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    saving
                        ? 'Menyimpan jawaban…'
                        : '${a.answers.length} terjawab · tersimpan di perangkat',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: index == 0 || saving
                      ? null
                      : () => _move(a, index - 1),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: saving || submitting
                        ? null
                        : () => index == a.questions.length - 1
                              ? _finish(a)
                              : _move(a, index + 1),
                    icon: Icon(
                      index == a.questions.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      submitting
                          ? 'Menyimpan…'
                          : index == a.questions.length - 1
                          ? 'Kumpulkan'
                          : 'Berikutnya',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Daftar soal',
                  onPressed: () => _navigator(a),
                  icon: const Icon(Icons.grid_view_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _move(Attempt a, int index) async {
    a.json['index'] = index;
    await guard(context, () => ref.read(appProvider).save());
  }

  void _navigator(Attempt a) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .73,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Text(
                      'Navigator soal',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${a.answers.length}/${a.questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Tag('Terjawab', color: teal),
                    Tag('Ragu-ragu', color: amber),
                    Tag('Belum dijawab', color: indigo),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 64,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: a.questions.length,
                  itemBuilder: (ctx, i) {
                    final q = a.questions[i];
                    final flagged = a.flagged.contains(q.id),
                        answered = a.answers.containsKey(q.id);
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: flagged
                            ? amber
                            : answered
                            ? teal
                            : null,
                        backgroundColor:
                            (flagged
                                    ? amber
                                    : answered
                                    ? teal
                                    : indigo)
                                .withValues(alpha: .08),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        unawaited(_move(a, i));
                      },
                      child: Text(
                        '${i + 1}${flagged ? ' ?' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      unawaited(_finish(a));
                    },
                    child: const Text('Kumpulkan latihan'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final a = app.results.where((a) => a.id == id).firstOrNull;
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Hasil belum tersedia.')),
      );
    }
    final full = a.json['pack_id'] != null;
    final grades = a.json['blueprint']['passing_grades'] as Json?;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali ke Tryout',
          onPressed: () => context.go('/tryouts'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Hasil latihan'),
      ),
      body: PageBody(
        children: [
          Center(
            child: Column(
              children: [
                Tag(
                  full
                      ? 'BLUEPRINT ${a.json['blueprint']['status'] == 'historical' ? 'HISTORIS' : 'TERVERIFIKASI'} ${a.json['blueprint']['year']}'
                      : 'LATIHAN PERSONAL',
                  color: teal,
                ),
                const SizedBox(height: 18),
                Text(
                  '${a.total}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 68,
                    letterSpacing: -3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'dari maksimum ${a.maximum}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Text(a.title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  wibDate(a.json['submitted_at'] as String?, time: true),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...domains.map((d) {
            final count = a.questions.where((q) => q.domain == d).length;
            final max = count * 5;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            d,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Text(
                            '${a.scores[d]} / $max',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: max == 0 ? 0 : (a.scores[d] as int) / max,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        color: d == 'TWK'
                            ? indigo
                            : d == 'TIU'
                            ? teal
                            : amber,
                      ),
                      if (full && grades != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ambang ${a.json['blueprint']['status'] == 'historical' ? 'historis ' : ''}${a.json['blueprint']['year']}: ${grades[d]} · ${(a.scores[d] as int) >= (grades[d] as int? ?? 0) ? 'tercapai pada latihan' : 'belum tercapai pada latihan'}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const Note(
            'Nilai ini hasil latihan personal. Ambang 2024 tidak otomatis berlaku 2026. Kelulusan seleksi bergantung pada ketentuan dan pemeringkatan resmi.',
          ),
          const SectionTitle('Ringkasan pengerjaan'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag('${a.answers.length} terjawab', color: teal),
              Tag(
                '${a.questions.length - a.answers.length} kosong',
                color: amber,
              ),
              Tag('${a.flagged.length} ditandai ragu'),
            ],
          ),
          if (a.weaknesses.isNotEmpty) ...[
            const SectionTitle('Topik untuk dikuatkan'),
            ...a.weaknesses.entries
                .take(5)
                .map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.key, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${e.value} respons belum maksimal',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => guard(context, () async {
                      final next = await app.startAttempt(topic: e.key);
                      if (context.mounted) context.push('/exam/${next.id}');
                    }),
                  ),
                ),
          ],
          const SectionTitle(
            'Review & pembahasan',
            subtitle: 'Jawaban dari snapshot versi saat dikerjakan',
          ),
          ...List.generate(a.questions.length, (i) {
            final q = a.questions[i];
            final answer = a.answers[q.id] as String?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ExpansionTile(
                  title: Text(
                    '${i + 1}. ${q.topic}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${q.domain} · ${answer == null ? 'Kosong' : 'Pilihan $answer'} · skor ${q.score(answer)}/${q.maximum}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  childrenPadding: const EdgeInsets.all(18),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.text),
                    const SizedBox(height: 14),
                    ...q.options.map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Text(
                          '${o['id']}. ${o['text']}${q.domain == 'TKP' ? ' [${o['score']}]' : ''}${o['id'] == q.best ? ' ✓' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: o['id'] == q.best
                                ? FontWeight.w800
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    Text(
                      q.explanation,
                      style: const TextStyle(fontSize: 13, height: 1.7),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/tryouts'),
            child: const Text('Kembali ke latihan'),
          ),
        ],
      ),
    );
  }
}
