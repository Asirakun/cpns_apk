import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/controller.dart';
import '../core/models.dart';
import '../core/services.dart';
import '../app/widgets.dart';
import '../app/theme.dart';
import '../app/paper.dart';
import '../app/study_activity.dart';
import '../core/analytics.dart';

class TryoutScreen extends ConsumerStatefulWidget {
  const TryoutScreen({super.key});
  @override
  ConsumerState<TryoutScreen> createState() => _TryoutCatalogState();
}

class _TryoutCatalogState extends ConsumerState<TryoutScreen> {
  final catalogSearch = TextEditingController();
  final historySearch = TextEditingController();
  String catalogQuery = '', historyQuery = '', historyKind = 'Semua';
  int visibleHistory = 20;
  @override
  void dispose() {
    catalogSearch.dispose();
    historySearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    return DefaultTabController(
      length: 2,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ruang latihan',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pilih soal, pelajari hasilmu.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const PaperArt(PaperAsset.checklist, size: 48),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Soal'),
                  Tab(text: 'Riwayat'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [_catalog(context, app), _history(context, app)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _search(
    TextEditingController controller,
    String hint,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
    child: TextField(
      controller: controller,
      onChanged: change,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: PaperArt(PaperAsset.search, size: 24),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  change('');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  );

  Widget _catalog(BuildContext context, AppController app) {
    final q = catalogQuery.trim().toLowerCase();
    final packs = app.content.packs
        .where(
          (p) =>
              '${p['name']} cat simulasi ${ContentRepository.blueprintFor(p)['year']}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
    final topics = app.content.questions.map((q) => q.topic).toSet().toList()
      ..sort();
    final matchingTopics = topics
        .where((t) => t.toLowerCase().contains(q))
        .toList();
    final quick =
        q.isEmpty ||
        'latihan singkat pemanasan 15 soal twk tiu tkp'.contains(q);
    return Column(
      children: [
        _search(
          catalogSearch,
          'Cari paket atau topik',
          (v) => setState(() => catalogQuery = v),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
            children: [
              if (app.activeAttempt case final a?) ...[
                ActionTile(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Lanjutkan ${a.title}',
                  subtitle:
                      '${a.answers.length}/${a.questions.length} terjawab · timer tetap berjalan',
                  onTap: () => context.push('/exam/${a.id}'),
                ),
                const SizedBox(height: 12),
              ],
              if (packs.isNotEmpty)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Simulasi CAT penuh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Aturan & sumber latihan',
                      onPressed: () => _about(context),
                      icon: const Icon(Icons.info_outline_rounded, size: 21),
                    ),
                  ],
                ),
              ...packs.map(
                (pack) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                              const PaperArt(PaperAsset.clock, size: 30),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            pack['name'] as String,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${(pack['question_ids'] as List).length} soal · ${(pack['duration_seconds'] as int) ~/ 60} menit',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _instructions(context, app, pack),
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
              if (quick) ...[
                const SectionTitle('Latihan singkat'),
                ActionTile(
                  icon: Icons.bolt_rounded,
                  title: 'Pemanasan 15 soal',
                  subtitle: 'TWK, TIU, TKP · review setelah selesai',
                  onTap: () => _startTopic(context, app),
                ),
              ],
              if (q.isNotEmpty && matchingTopics.isNotEmpty) ...[
                const SectionTitle('Topik yang cocok'),
                ...matchingTopics.map((t) => _topicTile(context, app, t)),
              ] else if (q.isEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'Latihan per topik',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  children: topics
                      .map((t) => _topicTile(context, app, t))
                      .toList(),
                ),
              if (packs.isEmpty && !quick && matchingTopics.isEmpty)
                const EmptyCard(
                  icon: Icons.search_rounded,
                  title: 'Tidak ditemukan',
                  body: 'Coba nama paket atau topik lain.',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topicTile(BuildContext context, AppController app, String topic) {
    final category = app.content.questions
        .firstWhere((q) => q.topic == topic)
        .domain;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      title: Text(topic, style: const TextStyle(fontSize: 14)),
      subtitle: Text(category, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _startTopic(context, app, topic: topic),
    );
  }

  void _startTopic(BuildContext context, AppController app, {String? topic}) =>
      guard(context, () async {
        final a = await app.startAttempt(topic: topic, quick: topic == null);
        if (context.mounted) context.push('/exam/${a.id}');
      });

  Widget _history(BuildContext context, AppController app) {
    final q = historyQuery.trim().toLowerCase();
    final completed = app.results
      ..sort((a, b) {
        final first = timestamp(a.json['submitted_at']) ?? DateTime.utc(1970);
        final second = timestamp(b.json['submitted_at']) ?? DateTime.utc(1970);
        return second.compareTo(first);
      });
    final all = completed.where((a) {
      final cat = isCat(a.json);
      final kind =
          historyKind == 'Semua' || (historyKind == 'Tryout' ? cat : !cat);
      final blueprint = a.json['blueprint'];
      final year = blueprint is Map ? blueprint['year'] ?? '' : '';
      return kind &&
          '${a.title} $year ${a.questions.map((q) => '${q.domain} ${q.topic}').join(' ')}'
              .toLowerCase()
              .contains(q);
    }).toList();
    final shown = all.take(visibleHistory).toList();
    return Column(
      children: [
        _search(
          historySearch,
          'Cari riwayat latihan',
          (v) => setState(() {
            historyQuery = v;
            visibleHistory = 20;
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['Semua', 'Tryout', 'Latihan']
                .map(
                  (kind) => ChoiceChip(
                    label: Text(kind),
                    showCheckmark: false,
                    selected: historyKind == kind,
                    onSelected: (_) => setState(() {
                      historyKind = kind;
                      visibleHistory = 20;
                    }),
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 12, 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${all.length} latihan selesai',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/analytics'),
                child: const Text('Analisis'),
              ),
            ],
          ),
        ),
        Expanded(
          child: all.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    EmptyCard(
                      icon: Icons.history_rounded,
                      title: q.isEmpty
                          ? 'Belum ada riwayat'
                          : 'Riwayat tidak ditemukan',
                      body: q.isEmpty
                          ? 'Hasil muncul setelah latihan dikumpulkan.'
                          : 'Ubah kata pencarian atau kategori.',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: shown.length + (shown.length < all.length ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == shown.length) {
                      return OutlinedButton(
                        onPressed: () => setState(() => visibleHistory += 20),
                        child: const Text('Muat lebih banyak'),
                      );
                    }
                    final a = shown[i];
                    final cat = isCat(a.json);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        key: ValueKey('history-${a.id}'),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          leading: PaperArt(
                            cat ? PaperAsset.checklist : PaperAsset.target,
                            size: 36,
                          ),
                          title: Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${cat ? 'Tryout' : 'Latihan'} · ${a.total}/${a.maximum}\n${wibDate(a.json['submitted_at'] as String?)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/result/${a.id}'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _about(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SheetBody(
      children: [
        Text('Aturan latihan', style: Theme.of(ctx).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text(
          'Setiap paket memakai snapshot soal dan blueprint berversi. Aturan historis 2024 bukan ketentuan final 2026. Nilai latihan bukan hasil seleksi resmi.',
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );
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
    return StudyActivity(
      kind: isCat(a.json) ? 'cat' : 'practice',
      category: q.domain,
      topic: q.topic,
      attemptId: a.id,
      child: PopScope(
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
                          ? answeredColor(context).withValues(alpha: .15)
                          : Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: selected
                              ? answeredColor(context)
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
                                      ? answeredColor(context)
                                      : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                ),
                                child: Text(
                                  o['id'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? paperInk
                                              : Colors.white)
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
                                  color: answeredColor(context),
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
              Padding(
                padding: EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Tag('Terjawab', color: answeredColor(ctx)),
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
                        foregroundColor: answered
                            ? answeredColor(ctx)
                            : flagged
                            ? Theme.of(ctx).colorScheme.tertiary
                            : null,
                        backgroundColor:
                            (answered
                                    ? answeredColor(ctx)
                                    : flagged
                                    ? Theme.of(ctx).colorScheme.tertiary
                                    : indigo)
                                .withValues(alpha: answered ? .18 : .08),
                        side: BorderSide(
                          color: answered
                              ? answeredColor(ctx)
                              : Theme.of(ctx).colorScheme.outline,
                        ),
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
