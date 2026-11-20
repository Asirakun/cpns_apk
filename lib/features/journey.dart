import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/controller.dart';
import '../core/models.dart';
import '../app/widgets.dart';
import '../app/theme.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return PageBody(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setiap tahap,\nlebih terarah.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kemenkeu ${app.cycle['year']} · pendidikan ${app.data['education']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Arsip & tahun seleksi',
              onPressed: () => _cycles(context, app),
              icon: const Icon(Icons.inventory_2_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Note(
          'Target Medan belum pasti. Kota ujian bukan kota penempatan. Periksa kebijakan penempatan sebelum memilih formasi.',
          icon: Icons.location_on_outlined,
        ),
        const SectionTitle('Pusat persiapan'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              [
                    ('Formasi', Icons.location_city_outlined, 'formations'),
                    ('Pengumuman', Icons.campaign_outlined, 'sources'),
                    ('Berkas', Icons.folder_open_rounded, 'documents'),
                    ('Agenda WIB', Icons.calendar_month_outlined, 'calendar'),
                    ('Hasil & sanggah', Icons.assignment_outlined, 'results'),
                    ('Persiapan SKB', Icons.work_outline_rounded, 'skb'),
                    (
                      'Anggaran',
                      Icons.account_balance_wallet_outlined,
                      'budget',
                    ),
                  ]
                  .map(
                    (v) => ActionChip(
                      avatar: Icon(v.$2, size: 18),
                      label: Text(v.$1),
                      onPressed: () => context.push('/journey/${v.$3}'),
                    ),
                  )
                  .toList(),
        ),
        SectionTitle(
          'Perjalanan S00–S11',
          subtitle:
              '${app.stagesDone}/12 selesai · ubah berdasarkan bukti resmi',
        ),
        ...List.generate(stageNames.length, (i) {
          final code = 'S${i.toString().padLeft(2, '0')}';
          final status =
              (app.cycle['stages'] as Json)[code] as String? ?? 'BELUM_DIMULAI';
          final done = status == 'SELESAI', active = status == 'AKTIF';
          final color = done
              ? Theme.of(context).colorScheme.secondary
              : active
              ? Theme.of(context).colorScheme.primary
              : status == 'TIDAK_LOLOS'
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: .45),
                          ),
                        ),
                        child: Icon(
                          done
                              ? Icons.check_rounded
                              : active
                              ? Icons.play_arrow_rounded
                              : Icons.circle_outlined,
                          color: color,
                          size: 16,
                        ),
                      ),
                      if (i < 11)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 2,
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          stageNames[i],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            '$code · ${stageLabels[stageStates.indexOf(status)]}',
                            style: TextStyle(fontSize: 11, color: color),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                        onTap: () => _stage(context, app, i),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.folder_open_rounded,
          title: '${app.docsReady} berkas siap',
          subtitle: 'Checklist metadata · riwayat status tetap disimpan',
          onTap: () => context.push('/journey/documents'),
        ),
      ],
    );
  }

  void _stage(BuildContext context, AppController app, int i) async {
    final code = 'S${i.toString().padLeft(2, '0')}';
    var status =
        (app.cycle['stages'] as Json)[code] as String? ?? 'BELUM_DIMULAI';
    final existing = (app.cycle['evidence'] as Json)[code] as Json?;
    final note = TextEditingController(text: existing?['note'] as String?),
        source = TextEditingController(text: existing?['source'] as String?);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SheetBody(
          children: [
            Text(
              '$code · ${stageNames[i]}',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: status,
              isExpanded: true,
              items: List.generate(
                stageStates.length,
                (n) => DropdownMenuItem(
                  value: stageStates[n],
                  child: Text(stageLabels[n]),
                ),
              ),
              onChanged: (v) => set(() => status = v!),
              decoration: const InputDecoration(labelText: 'Status tahap'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: source,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Tautan pengumuman (opsional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Catatan, sesi, lokasi, atau tindak lanjut',
              ),
            ),
            const SizedBox(height: 14),
            const Note(
              'Status dicatat olehmu. Aplikasi tidak menyimpulkan kelulusan dari nilai latihan dan tidak mengirim pendaftaran atau sanggah.',
              color: indigo,
            ),
            if (i == 9) ...[
              const SizedBox(height: 12),
              const Note(
                'DRH, SKCK, kesehatan dan NAPZA disiapkan mengikuti pengumuman pemberkasan. Hindari mengurus dokumen berumur pendek terlalu dini.',
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => guard(ctx, () async {
                if (source.text.isNotEmpty && !isGovernmentUrl(source.text)) {
                  throw const FormatException(
                    'Tautan bukti harus HTTPS pada domain resmi go.id.',
                  );
                }
                (app.cycle['stages'] as Json)[code] = status;
                (app.cycle['evidence'] as Json)[code] = {
                  'note': note.text.trim(),
                  'source': source.text.trim(),
                  'recorded_at': DateTime.now().toUtc().toIso8601String(),
                };
                await app.save();
                if (ctx.mounted) Navigator.pop(ctx);
              }),
              child: const Text('Simpan status tahap'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
    source.dispose();
  }

  void _cycles(BuildContext context, AppController app) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SheetBody(
        children: [
          Text('Riwayat seleksi', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...(app.data['cycles'] as List).cast<Json>().map(
            (c) => ListTile(
              title: Text('${c['agency']} ${c['year']}'),
              subtitle: Text(
                c['id'] == app.data['active_cycle']
                    ? 'Cycle aktif'
                    : 'Arsip · ${(c['stages'] as Json).values.where((s) => s == 'SELESAI').length} tahap selesai',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Note(
            'Memulai cycle baru mengarsipkan cycle aktif. Progres belajar dan hasil latihan tetap tersimpan.',
            color: indigo,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final year = (app.cycle['year'] as int) + 1;
              if (await confirm(
                ctx,
                'Mulai seleksi $year?',
                'Cycle ${app.cycle['year']} akan diarsipkan beserta status dan berkasnya.',
                action: 'Arsipkan & mulai',
              )) {
                if (ctx.mounted) {
                  await guard(ctx, () async {
                    await app.newSelectionCycle(year);
                    if (ctx.mounted) Navigator.pop(ctx);
                  });
                }
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Rencana tahun berikutnya'),
          ),
        ],
      ),
    );
  }
}

bool isGovernmentUrl(String text) {
  final u = Uri.tryParse(text.trim());
  return u != null && u.scheme == 'https' && (u.host.endsWith('.go.id'));
}

class JourneyDetailScreen extends ConsumerStatefulWidget {
  const JourneyDetailScreen({super.key, required this.section});
  final String section;
  @override
  ConsumerState<JourneyDetailScreen> createState() => _JourneyDetailState();
}

class _JourneyDetailState extends ConsumerState<JourneyDetailScreen> {
  String docGroup = 'Semua', education = 'SMA', city = '', role = '';
  bool refreshing = false;
  @override
  void initState() {
    super.initState();
    if (widget.section == 'formations' || widget.section == 'sources') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    final app = ref.read(appProvider);
    if (app.client == null) return;
    setState(() => refreshing = true);
    try {
      final list = widget.section == 'formations'
          ? await app.client!
                .from('formations')
                .select(
                  '*,recruitment_cycles(year,agency),official_sources(url,verified_at,status)',
                )
                .order('role')
          : await app.client!
                .from('official_sources')
                .select()
                .order('verified_at', ascending: false);
      app.data[widget.section == 'formations'
              ? 'formation_cache'
              : 'source_cache'] =
          list;
      app.data['master_cached_at'] = DateTime.now().toUtc().toIso8601String();
      await app.save();
    } catch (_) {
      if (mounted) {
        message(
          context,
          'Data terbaru belum dapat diambil. Menampilkan cache yang tersedia.',
        );
      }
    }
    if (mounted) setState(() => refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final title = switch (widget.section) {
      'formations' => 'Explorer formasi',
      'sources' => 'Sumber & pengumuman',
      'documents' => 'Checklist berkas',
      'calendar' => 'Agenda & pengingat',
      'results' => 'Hasil & sanggah',
      'skb' => 'Persiapan SKB',
      'budget' => 'Anggaran pribadi',
      _ => 'Journey',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.section == 'formations' || widget.section == 'sources')
            IconButton(
              tooltip: 'Perbarui data',
              onPressed: refreshing ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: PageBody(
        children: switch (widget.section) {
          'formations' => _formations(app),
          'sources' => _sources(app),
          'documents' => _documents(app),
          'calendar' => _calendar(app),
          'results' => _results(app),
          'skb' => _skb(app),
          'budget' => _budget(app),
          _ => [const Text('Bagian tidak ditemukan.')],
        },
      ),
    );
  }

  List<Widget> _documents(AppController app) {
    final groups = [
      'Semua',
      ...docRules.map((r) => r['group'] as String).toSet(),
    ];
    final rules = docRules
        .where((r) => docGroup == 'Semua' || r['group'] == docGroup)
        .toList();
    return [
      Text(
        '${app.docsReady} berkas siap',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'Cycle ${app.cycle['year']} · SMA · status tanpa unggah identitas',
        style: const TextStyle(fontSize: 12),
      ),
      const SizedBox(height: 18),
      const Note(
        'Daftar persiapan dari dokumen pengguna, bukan persyaratan final 2026. Format, ukuran dan masa berlaku menunggu pengumuman resmi.',
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: docGroup,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Tahap berkas'),
        items: groups
            .map(
              (g) => DropdownMenuItem(
                value: g,
                child: Text(g, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => docGroup = v!),
      ),
      const SizedBox(height: 18),
      ...rules.map((r) {
        final data = app.docs[r['id']] as Json?;
        final status = app.documentStatus(r);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(
                status == 'Siap'
                    ? Icons.check_circle_rounded
                    : Icons.description_outlined,
                color: status == 'Siap' ? teal : amber,
              ),
              title: Text(
                r['name'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(status, style: const TextStyle(fontSize: 11)),
                  if (data?['expires_at'] != null)
                    Text(
                      'Berlaku hingga ${wibDate(data!['expires_at'] as String?)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _editDocument(app, r),
            ),
          ),
        );
      }),
      const SizedBox(height: 14),
      TextButton.icon(
        onPressed: () =>
            openOfficial(context, sourceLinks['Rekrutmen Kemenkeu']!),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Periksa ketentuan instansi'),
      ),
    ];
  }

  Future<void> _editDocument(AppController app, Json rule) async {
    final previous = app.docs[rule['id']] as Json?;
    var status = app.documentStatus(rule);
    String? expiry = previous?['expires_at'] as String?;
    final note = TextEditingController(text: previous?['note'] as String?);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SheetBody(
          children: [
            Text(
              rule['name'] as String,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(rule['note'] as String, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: status,
              isExpanded: true,
              items: documentStates
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => set(() => status = v!),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              maxLines: 3,
              maxLength: 700,
              decoration: const InputDecoration(
                labelText: 'Catatan (tanpa NIK/KK lengkap)',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2040),
                );
                if (d != null) set(() => expiry = d.toUtc().toIso8601String());
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                expiry == null
                    ? 'Masa berlaku (opsional)'
                    : 'Berlaku hingga ${wibDate(expiry)}',
              ),
            ),
            if (expiry != null)
              TextButton(
                onPressed: () => set(() => expiry = null),
                child: const Text('Hapus tanggal berlaku'),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => guard(ctx, () async {
                final history = (previous?['history'] as List? ?? []).toList();
                history.add({
                  'status': status,
                  'at': DateTime.now().toUtc().toIso8601String(),
                  'note': note.text.trim(),
                });
                app.docs[rule['id']] = {
                  'status': status,
                  'note': note.text.trim(),
                  'expires_at': expiry,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                  'history': history,
                };
                await app.save();
                if (ctx.mounted) Navigator.pop(ctx);
              }),
              child: const Text('Simpan status berkas'),
            ),
            if ((previous?['history'] as List? ?? []).isNotEmpty) ...[
              const SectionTitle('Riwayat perubahan'),
              ...(previous!['history'] as List)
                  .cast<Json>()
                  .reversed
                  .take(5)
                  .map(
                    (h) => Text(
                      '${h['status']} · ${wibDate(h['at'] as String?, time: true)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
            ],
            const SizedBox(height: 14),
            const Note(
              'Aplikasi menyimpan status dan catatan saja. Berkas identitas asli tetap di tempat pribadi.',
              color: teal,
            ),
          ],
        ),
      ),
    );
    note.dispose();
  }

  List<Widget> _formations(AppController app) {
    final cached = (app.data['formation_cache'] as List? ?? []).cast<Json>();
    final list = cached.where((f) {
      final cycle = f['recruitment_cycles'] as Json?;
      return cycle?['year'] == app.cycle['year'] &&
          (f['eligible_educations'] as List).contains(education) &&
          (city.isEmpty ||
              '${f['location_formasi']}'.toLowerCase().contains(
                city.toLowerCase(),
              )) &&
          (role.isEmpty ||
              '${f['role']} ${f['unit'] ?? ''}'.toLowerCase().contains(
                role.toLowerCase(),
              ));
    }).toList();
    return [
      const Note(
        'Medan sebagai preferensi tidak menjamin penempatan. Data formasi hanya digunakan jika memiliki sumber dan status verifikasi.',
      ),
      const SizedBox(height: 18),
      DropdownButtonFormField<String>(
        initialValue: education,
        decoration: const InputDecoration(labelText: 'Pendidikan formasi'),
        items: [
          'SMA',
          'D3',
          'S1',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => education = v!),
      ),
      const SizedBox(height: 12),
      TextField(
        onChanged: (v) => setState(() => city = v),
        decoration: const InputDecoration(
          labelText: 'Kota formasi',
          hintText: 'Misalnya Medan',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        onChanged: (v) => setState(() => role = v),
        decoration: const InputDecoration(labelText: 'Jabatan / unit'),
      ),
      const SizedBox(height: 18),
      if (refreshing) const LinearProgressIndicator(),
      if (list.isEmpty)
        EmptyCard(
          icon: Icons.travel_explore_rounded,
          title: 'Belum ada formasi yang cocok',
          body:
              'Belum ada data resmi ${app.cycle['year']} untuk filter ini. Periksa portal instansi dan jangan menganggap lokasi ujian sebagai lokasi kerja.',
          action: 'Buka rekrutmen Kemenkeu',
          onAction: () =>
              openOfficial(context, sourceLinks['Rekrutmen Kemenkeu']!),
        )
      else
        ...list.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ActionTile(
              icon: Icons.work_outline_rounded,
              title: f['role'] as String,
              subtitle:
                  '${f['location_formasi'] ?? 'Lokasi belum pasti'} · ${f['placement_policy']}',
              onTap: () => _selectFormation(app, f),
            ),
          ),
        ),
      if (app.cycle['formation'] != null) ...[
        const SectionTitle('Pilihan tercatat'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${app.cycle['formation']['role']}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${app.cycle['formation']['location_formasi']} · ${app.cycle['formation']['placement_policy']}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Tag('Pilihan pribadi · cek pengumuman', color: amber),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 14),
      Text(
        'Cache terakhir: ${wibDate(app.data['master_cached_at'] as String?, time: true)}',
        style: const TextStyle(fontSize: 11),
      ),
    ];
  }

  Future<void> _selectFormation(AppController app, Json f) async {
    if (!eligibleEducation(
      (f['eligible_educations'] as List).cast<String>(),
      app.data['education'] as String,
      app.data['d3_status'] as String,
    )) {
      message(
        context,
        'Pendidikan yang sudah dimiliki belum memenuhi. D3 yang sedang ditempuh tidak dihitung lulus.',
      );
      return;
    }
    final source = f['official_sources'] as Json?;
    if (source?['status'] != 'verified' || source?['url'] == null) {
      message(
        context,
        'Formasi belum memiliki sumber terverifikasi. Pilihan belum dapat disimpan.',
      );
      return;
    }
    if (await confirm(
      context,
      'Periksa kebijakan penempatan',
      '${f['role']}\n\nKota formasi: ${f['location_formasi'] ?? 'Belum disebutkan'}\nKota ujian: ${f['test_city'] ?? 'Belum ditetapkan'}\nPenempatan: ${f['placement_policy']}\n\nTarget ${app.data['target_city']} tidak dijamin. Pastikan kamu memahami dan bersedia mengikuti ketentuan resmi.',
      action: 'Saya memahami, simpan',
    )) {
      if (mounted) {
        await guard(context, () async {
          app.cycle['formation'] = {
            ...f,
            'risk_acknowledged': true,
            'selected_at': DateTime.now().toUtc().toIso8601String(),
          };
          await app.save();
        });
      }
    }
  }

  List<Widget> _sources(AppController app) {
    final cached = (app.data['source_cache'] as List? ?? []).cast<Json>();
    return [
      Text(
        'Mulai dari sumbernya.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 14),
      const Note(
        'Tautan di bawah adalah referensi dari dokumen, bukan klaim pengumuman 2026 sudah terbit. Tanggal pemeriksaan dokumen: 20 November 2026.',
        color: indigo,
      ),
      if (cached.isNotEmpty) ...[
        const SectionTitle('Pengumuman dari katalog cloud'),
        ...cached.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ActionTile(
              icon: Icons.article_outlined,
              title: s['title'] as String,
              subtitle:
                  '${s['publisher']} · ${s['status']}\nDiverifikasi: ${wibDate(s['verified_at'] as String?)}',
              onTap: () => openOfficial(context, s['url'] as String),
            ),
          ),
        ),
      ],
      const SectionTitle('Portal & referensi resmi'),
      ...sourceLinks.entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ActionTile(
            icon: Icons.open_in_new_rounded,
            title: e.key,
            subtitle: e.key.contains('2024')
                ? 'Referensi historis 2024'
                : 'Portal resmi · cek periode seleksi',
            color: e.key.contains('2024') ? amber : indigo,
            onTap: () => openOfficial(context, e.value),
          ),
        ),
      ),
    ];
  }

  List<Widget> _calendar(AppController app) {
    final events = (app.data['events'] as List).cast<Json>().toList()
      ..sort((a, b) => (a['at'] as String).compareTo(b['at'] as String));
    return [
      Text(
        'Jadwal yang jelas,\npikiran lebih tenang.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 14),
      const Note(
        'Semua waktu ditampilkan dalam WIB. Jadwal pribadi/estimasi diberi label; countdown resmi hanya untuk data admin yang terverifikasi.',
        color: indigo,
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () => _editEvent(app),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah agenda pribadi'),
      ),
      const SectionTitle('Agenda tersimpan'),
      if (events.isEmpty)
        const EmptyCard(
          icon: Icons.calendar_month_outlined,
          title: 'Belum ada jadwal',
          body: 'Tambahkan jadwal belajar atau tanggal yang kamu catat dari pengumuman. Belum ada deadline resmi yang dimuat.',
        )
      else
        ...events.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.event_outlined, color: indigo),
                title: Text(
                  e['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '${wibDate(e['at'] as String?, time: true)}\n${e['kind']} · catatan pribadi',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => _editEvent(app, existing: e),
                trailing: IconButton(
                  tooltip: 'Hapus agenda',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    if (await confirm(
                      context,
                      'Hapus agenda?',
                      'Agenda ini akan dihapus dari perangkat dan disinkronkan ke akun jika terhubung.',
                      action: 'Hapus',
                    )) {
                      if (mounted) {
                        await guard(context, () async {
                          (app.data['events'] as List).removeWhere(
                            (v) => v['id'] == e['id'],
                          );
                          await app.save();
                          await app.reminders.schedule(app.data);
                        });
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Future<void> _editEvent(AppController app, {Json? existing}) async {
    final title = TextEditingController(text: existing?['title'] as String?),
        source = TextEditingController(text: existing?['source'] as String?);
    final w = DateTime.now().toUtc().add(const Duration(hours: 7));
    var date = DateTime(w.year, w.month, w.day, 19);
    if (existing != null) {
      final d = DateTime.parse(existing['at'] as String)
          .toUtc()
          .add(const Duration(hours: 7));
      date = DateTime(d.year, d.month, d.day, d.hour, d.minute);
    }
    String kind = existing?['kind'] as String? ?? 'Pribadi';
    bool reminder = existing?['reminder'] as bool? ?? false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SheetBody(
          children: [
            Text('Agenda pribadi', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Nama agenda'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: kind,
              items: [
                'Pribadi',
                'Estimasi',
                'Dicatat dari pengumuman',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => set(() => kind = v!),
              decoration: const InputDecoration(labelText: 'Status tanggal'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2040),
                );
                if (d == null || !ctx.mounted) return;
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(date),
                );
                if (t != null) {
                  set(
                    () => date = DateTime(
                      d.year,
                      d.month,
                      d.day,
                      t.hour,
                      t.minute,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                '${date.day}/${date.month}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: source,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Tautan sumber (jika dari pengumuman)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ingatkan sebelum agenda'),
              subtitle: const Text(
                'Memerlukan izin notifikasi; mengikuti jam tenang',
                style: TextStyle(fontSize: 11),
              ),
              value: reminder,
              onChanged: (v) => set(() => reminder = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => guard(ctx, () async {
                if (title.text.trim().isEmpty) {
                  throw const FormatException('Isi nama agenda.');
                }
                if (kind == 'Dicatat dari pengumuman' &&
                    !isGovernmentUrl(source.text)) {
                  throw const FormatException(
                    'Tambahkan URL HTTPS dari domain resmi go.id.',
                  );
                }
                if (reminder && app.data['notifications'] != true) {
                  await app.setNotifications(true);
                }
                final e = <String, dynamic>{
                  'id': existing?['id'] ?? app.uuid.v4(),
                  'title': title.text.trim(),
                  'at': DateTime.utc(
                    date.year,
                    date.month,
                    date.day,
                    date.hour,
                    date.minute,
                  ).subtract(const Duration(hours: 7)).toIso8601String(),
                  'kind': kind,
                  'source': source.text.trim(),
                  'reminder': reminder,
                  'verified': false,
                };
                (app.data['events'] as List).removeWhere(
                  (v) => v['id'] == e['id'],
                );
                (app.data['events'] as List).add(e);
                await app.save();
                await app.reminders.schedule(app.data);
                if (ctx.mounted) Navigator.pop(ctx);
              }),
              child: const Text('Simpan agenda'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    source.dispose();
  }

  List<Widget> _results(AppController app) {
    final result = app.cycle['results'] as Json;
    return [
      const Note(
        'Catat hasil pengumuman resmi secara manual. Skor latihan tidak digunakan untuk menetapkan status seleksi. Sanggah dilakukan di portal resmi.',
        color: indigo,
      ),
      const SizedBox(height: 16),
      ...['Administrasi', 'SKD', 'SKB', 'Hasil akhir', 'Penempatan'].map((
        stage,
      ) {
        final r = result[stage] as Json?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ActionTile(
            icon: Icons.assignment_outlined,
            title: stage,
            subtitle: r == null
                ? 'Belum dicatat / menunggu pengumuman'
                : '${r['status']} · ${r['note']}\n${wibDate(r['at'] as String?)}',
            onTap: () => _editResult(app, stage),
          ),
        );
      }),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => openOfficial(context, sourceLinks['SSCASN BKN']!),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Buka portal SSCASN'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => context.push('/journey/calendar'),
        child: const Text('Catat batas waktu sanggah'),
      ),
    ];
  }

  Future<void> _editResult(AppController app, String stage) async {
    final prev = (app.cycle['results'] as Json)[stage] as Json?;
    String status = prev?['status'] as String? ?? 'Menunggu pengumuman';
    final note = TextEditingController(text: prev?['note'] as String?),
        source = TextEditingController(text: prev?['source'] as String?);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SheetBody(
          children: [
            Text('Hasil $stage', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: status,
              isExpanded: true,
              items:
                  [
                        'Menunggu pengumuman',
                        'Lolos menurut pengumuman',
                        'Tidak lolos menurut pengumuman',
                        'Dalam masa sanggah',
                        'Sudah ditetapkan',
                      ]
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
              onChanged: (v) => set(() => status = v!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: stage == 'SKD'
                    ? 'Nilai TWK/TIU/TKP resmi & catatan'
                    : 'Catatan hasil / kota dan kantor resmi',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: source,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL pengumuman resmi',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => guard(ctx, () async {
                if (status != 'Menunggu pengumuman' &&
                    !isGovernmentUrl(source.text)) {
                  throw const FormatException(
                    'Sertakan tautan pengumuman HTTPS resmi go.id.',
                  );
                }
                (app.cycle['results'] as Json)[stage] = {
                  'status': status,
                  'note': note.text.trim(),
                  'source': source.text.trim(),
                  'at': DateTime.now().toUtc().toIso8601String(),
                };
                await app.save();
                if (ctx.mounted) Navigator.pop(ctx);
              }),
              child: const Text('Simpan catatan hasil'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
    source.dispose();
  }

  List<Widget> _skb(AppController app) {
    final formation = app.cycle['formation'] as Json?;
    return [
      if (formation == null)
        EmptyCard(
          icon: Icons.work_outline_rounded,
          title: 'Menunggu formasi yang dipilih',
          body: 'Materi SKB mengikuti jabatan dan ketentuan instansi. Belum ada paket SKB universal yang ditampilkan.',
          action: 'Periksa formasi',
          onAction: () => context.push('/journey/formations'),
        )
      else ...[
        Text(
          'SKB · ${formation['role']}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const Note(
          'Belum ada materi SKB jabatan terverifikasi yang dimuat. Gunakan pengumuman resmi untuk kisi-kisi dan tes tambahan.',
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.open_in_new_rounded,
          title: 'Periksa ketentuan SKB',
          subtitle: 'Rekrutmen resmi Kemenkeu',
          onTap: () =>
              openOfficial(context, sourceLinks['Rekrutmen Kemenkeu']!),
        ),
      ],
      const SectionTitle('Persiapan mandiri'),
      ActionTile(
        icon: Icons.event_note_rounded,
        title: 'Jadwal & catatan tes tambahan',
        subtitle: 'Simpan agenda setelah jadwal diumumkan',
        onTap: () => context.push('/journey/calendar'),
      ),
    ];
  }

  List<Widget> _budget(AppController app) {
    final items = (app.data['budget'] as List).cast<Json>();
    final estimate = items.fold<num>(0, (s, e) => s + (e['estimate'] as num));
    final actual = items.fold<num>(0, (s, e) => s + (e['actual'] as num));
    return [
      Text(
        'Anggaran seleksi',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 14),
      const Note(
        'Catatan pengeluaran pribadi seperti transportasi, cetak dan pemeriksaan. Aplikasi tidak menambahkan biaya pendaftaran CPNS.',
        color: indigo,
      ),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimasi ${rupiah(estimate)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text('Realisasi ${rupiah(actual)}'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () => _editBudget(app),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah pengeluaran'),
      ),
      ...items.map(
        (e) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(e['name'] as String),
          subtitle: Text(
            'Estimasi ${rupiah(e['estimate'] as num)} · aktual ${rupiah(e['actual'] as num)}',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: IconButton(
            tooltip: 'Hapus pengeluaran',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => guard(context, () async {
              (app.data['budget'] as List).removeWhere(
                (v) => v['id'] == e['id'],
              );
              await app.save();
            }),
          ),
        ),
      ),
    ];
  }

  Future<void> _editBudget(AppController app) async {
    final name = TextEditingController(),
        estimate = TextEditingController(),
        actual = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SheetBody(
        children: [
          Text(
            'Pengeluaran pribadi',
            style: Theme.of(ctx).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Keperluan'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: estimate,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Estimasi (rupiah)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: actual,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Realisasi (rupiah, opsional)',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => guard(ctx, () async {
              final e = int.tryParse(estimate.text),
                  a = actual.text.isEmpty ? 0 : int.tryParse(actual.text);
              if (name.text.trim().isEmpty ||
                  e == null ||
                  a == null ||
                  e < 0 ||
                  a < 0) {
                throw const FormatException(
                  'Isi keperluan dan nominal rupiah bulat yang valid.',
                );
              }
              (app.data['budget'] as List).add({
                'id': app.uuid.v4(),
                'name': name.text.trim(),
                'estimate': e,
                'actual': a,
              });
              await app.save();
              if (ctx.mounted) Navigator.pop(ctx);
            }),
            child: const Text('Simpan pengeluaran'),
          ),
        ],
      ),
    );
    name.dispose();
    estimate.dispose();
    actual.dispose();
  }
}
