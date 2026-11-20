import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/controller.dart';
import '../core/models.dart';
import '../app/widgets.dart';
import '../app/theme.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});
  @override
  ConsumerState<LearnScreen> createState() => _LearnState();
}

class _LearnState extends ConsumerState<LearnScreen> {
  String domain = 'Semua', search = '';
  bool bookmarks = false;
  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final all = app.content.lessons;
    final lessons = all
        .where(
          (l) =>
              (domain == 'Semua' || l['domain'] == domain) &&
              (!bookmarks ||
                  (app.data['bookmarks'] as List).contains(l['id'])) &&
              ('${l['title']} ${l['topic']}'.toLowerCase().contains(
                search.toLowerCase(),
              )),
        )
        .toList();
    return PageBody(
      children: [
        Text('Ruang belajar', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text(
          'Pahami pelan-pelan. Kuasai satu per satu.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 22),
        TextField(
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            hintText: 'Cari materi atau topik',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Semua', ...domains]
              .map(
                (d) => ChoiceChip(
                  label: Text(d),
                  selected: domain == d,
                  onSelected: (_) => setState(() => domain = d),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilterChip(
              label: const Text('Tersimpan'),
              avatar: const Icon(Icons.bookmark_border_rounded, size: 17),
              selected: bookmarks,
              onSelected: (v) => setState(() => bookmarks = v),
            ),
            const Spacer(),
            Text(
              '${lessons.length} materi',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (lessons.isEmpty)
          const EmptyCard(
            icon: Icons.search_off_rounded,
            title: 'Belum ada materi yang cocok',
            body: 'Coba kata lain atau ubah filter.',
          )
        else
          ...lessons.map((l) {
            final done = (app.data['completed'] as List).contains(l['id']);
            final saved = (app.data['bookmarks'] as List).contains(l['id']);
            final color = switch (l['domain']) {
              'TWK' => indigo,
              'TIU' => teal,
              _ => amber,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/lesson/${l['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Tag(l['domain'] as String, color: color),
                            const SizedBox(width: 8),
                            Text(
                              '${l['minutes']} menit',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: saved
                                  ? 'Hapus bookmark'
                                  : 'Simpan materi',
                              onPressed: () => guard(
                                context,
                                () => app.bookmark(l['id'] as String),
                              ),
                              icon: Icon(
                                saved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          l['title'] as String,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          l['topic'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 17),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: done
                                    ? 1
                                    : ((app.data['lesson_positions']
                                                      as Json)[l['id']]
                                                  as int? ??
                                              0) /
                                          (l['body'] as List).length,
                                minHeight: 5,
                                color: color,
                                backgroundColor: color.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              done ? 'Selesai' : 'Buka materi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        SectionTitle(
          'Paket offline',
          subtitle: 'Paket awal tersedia bersama aplikasi',
        ),
        ActionTile(
          icon: Icons.download_for_offline_outlined,
          title: '450 soal · 12 materi · 3 CAT',
          subtitle: app.data['downloaded_version'] == null
              ? 'Aktifkan untuk mulai latihan'
              : 'Versi ${app.data['downloaded_version']} · tersimpan di HP',
          color: teal,
          onTap: () => showModalBottomSheet(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (ctx) => SheetBody(
              children: [
                Text(
                  'Belajar tanpa koneksi',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Paket bawaan ${app.content.manifest['version']} · ${(app.content.manifest['bytes'] as int) / 1048576 < 1 ? 'kurang dari 1 MB' : '${((app.content.manifest['bytes'] as int) / 1048576).toStringAsFixed(1)} MB'}',
                ),
                const SizedBox(height: 12),
                const Note(
                  'Konten latihan original berbasis template. Validasi struktur dan skor dilakukan otomatis; tinjauan ahli materi belum final. Bukan soal bocoran atau bank soal resmi.',
                  color: indigo,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => guard(ctx, () async {
                    await app.downloadContent();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      message(context, 'Paket valid dan siap dipakai offline.');
                    }
                  }),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Periksa & aktifkan paket'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => guard(ctx, () async {
                    final status = await app.checkContentUpdates();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      message(context, status);
                    }
                  }),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Periksa pembaruan cloud'),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(
          'Latihan terarah',
          subtitle: 'Rekomendasi memakai kesalahan latihanmu sendiri',
        ),
        if (app.recommendedTopics.isEmpty)
          const Note(
            'Selesaikan satu latihan untuk mendapatkan prioritas topik berdasarkan jawabanmu.',
            color: teal,
          )
        else
          ...app.recommendedTopics.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ActionTile(
                icon: Icons.psychology_outlined,
                title: t,
                subtitle:
                    '${app.weaknesses[t]} respons belum maksimal · dari histori',
                onTap: () => guard(context, () async {
                  final a = await app.startAttempt(topic: t);
                  if (context.mounted) context.push('/exam/${a.id}');
                }),
              ),
            ),
          ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.style_outlined,
          title: 'Kartu pengulangan',
          subtitle: 'Tinjau soal yang perlu dikuatkan dengan jadwal ringan',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const FlashcardScreen()),
          ),
        ),
      ],
    );
  }
}

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<LessonScreen> createState() => _LessonState();
}

class _LessonState extends ConsumerState<LessonScreen> {
  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final l = app.content.lessons
        .where((l) => l['id'] == widget.id)
        .firstOrNull;
    if (l == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Materi tidak ditemukan.')),
      );
    }
    final saved = (app.data['bookmarks'] as List).contains(widget.id);
    final done = (app.data['completed'] as List).contains(widget.id);
    final paragraphs = (l['body'] as List).cast<String>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l['domain'] as String),
        actions: [
          IconButton(
            tooltip: saved ? 'Hapus bookmark' : 'Simpan materi',
            onPressed: () => guard(context, () => app.bookmark(widget.id)),
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: PageBody(
        children: [
          Tag(
            '${l['minutes']} menit · tersedia offline',
            color: teal,
            icon: Icons.offline_pin_outlined,
          ),
          const SizedBox(height: 20),
          Text(
            l['title'] as String,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l['topic'] as String,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(
            paragraphs.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                paragraphs[i],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const Note(
            'Ringkasan latihan original. Gunakan naskah resmi untuk ketentuan hukum dan aturan seleksi; konten belum ditinjau ahli materi.',
            color: indigo,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => guard(context, () async {
              (app.data['lesson_positions'] as Json)[widget.id] =
                  paragraphs.length;
              await app.completeLesson(widget.id);
              if (context.mounted) {
                message(
                  context,
                  'Materi selesai. Progres tersimpan di perangkat.',
                );
              }
            }),
            icon: Icon(done ? Icons.check_circle_rounded : Icons.check_rounded),
            label: Text(done ? 'Sudah dipelajari' : 'Tandai selesai'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => guard(context, () async {
              final a = await app.startAttempt(topic: l['topic'] as String);
              if (context.mounted) context.push('/exam/${a.id}');
            }),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Latihan topik ini'),
          ),
          const SectionTitle('Referensi resmi'),
          ...sourceLinks.entries
              .take(4)
              .map(
                (e) => TextButton.icon(
                  onPressed: () => openOfficial(context, e.value),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(e.key),
                ),
              ),
        ],
      ),
    );
  }
}

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});
  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardState();
}

class _FlashcardState extends ConsumerState<FlashcardScreen> {
  int index = 0;
  bool flipped = false;
  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final wrong = <String, Question>{};
    for (final a in app.results) {
      for (final q in a.questions) {
        if (q.score(a.answers[q.id] as String?) < q.maximum) wrong[q.id] = q;
      }
    }
    final reviews = app.data['reviews'] as Json;
    final cards = wrong.values.where((q) {
      final due = (reviews[q.id] as Json?)?['due'] as String?;
      return due == null ||
          !DateTime.parse(due).isAfter(DateTime.now().toUtc());
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Kartu pengulangan')),
      body: PageBody(
        children: [
          if (cards.isEmpty)
            EmptyCard(
              icon: Icons.style_outlined,
              title: wrong.isEmpty
                  ? 'Belum ada kartu'
                  : 'Sesi hari ini selesai',
              body: wrong.isEmpty
                  ? 'Kartu dibuat dari jawaban yang belum maksimal pada latihan selesai.'
                  : 'Kartu berikutnya muncul sesuai jadwal pengulanganmu.',
            )
          else ...[
            Tag(
              '${index % cards.length + 1} / ${cards.length} kartu jatuh tempo',
              color: teal,
            ),
            const SizedBox(height: 20),
            Card(
              child: InkWell(
                onTap: () => setState(() => flipped = !flipped),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cards[index % cards.length].topic,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        flipped
                            ? cards[index % cards.length].explanation
                            : cards[index % cards.length].text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        flipped
                            ? 'Nilai pemahamanmu di bawah'
                            : 'Ketuk untuk membuka pembahasan',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (flipped)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    [(1, 'Ulang besok'), (3, 'Mulai paham'), (7, 'Sudah ingat')]
                        .map(
                          (v) => OutlinedButton(
                            onPressed: () => guard(context, () async {
                              final q = cards[index % cards.length];
                              reviews[q.id] = {
                                'due': DateTime.now()
                                    .toUtc()
                                    .add(Duration(days: v.$1))
                                    .toIso8601String(),
                                'interval_days': v.$1,
                              };
                              await app.save();
                              if (mounted) {
                                setState(() {
                                  index = 0;
                                  flipped = false;
                                });
                              }
                            }),
                            child: Text(v.$2),
                          ),
                        )
                        .toList(),
              )
            else
              FilledButton(
                onPressed: () => setState(() => flipped = true),
                child: const Text('Buka pembahasan'),
              ),
          ],
        ],
      ),
    );
  }
}
