import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/controller.dart';
import '../core/export.dart';
import '../app/widgets.dart';
import '../app/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return PageBody(
      children: [
        Text(
          'Ruang pribadimu',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const BrandMark(size: 58),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.data['alias'] as String,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        app.namespace == 'guest'
                            ? 'Mode perangkat · tanpa akun'
                            : 'Akun tersambung',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      const Tag('Satu langkah setiap hari', color: teal),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ActionTile(
          icon: Icons.school_outlined,
          title: 'Pendidikan & tujuan',
          subtitle:
              'Melamar ${app.data['education']} · D3 ${app.data['d3_status']}\nPreferensi ${app.data['target_city']}',
          onTap: () => _editProfile(context, app),
        ),
        const SectionTitle('Belajar sesuai ritmemu'),
        ActionTile(
          icon: Icons.tune_rounded,
          title: 'Rencana ${app.data['plan_days']} hari',
          subtitle:
              '${app.data['minutes']} menit/hari · perubahan tidak menghapus progres',
          onTap: () => _studyPlan(context, app),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tampilan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            (
                              'system',
                              'Sistem',
                              Icons.brightness_auto_outlined,
                            ),
                            ('light', 'Terang', Icons.light_mode_outlined),
                            ('dark', 'Gelap', Icons.dark_mode_outlined),
                          ]
                          .map(
                            (t) => ChoiceChip(
                              avatar: Icon(t.$3, size: 17),
                              label: Text(t.$2),
                              selected: app.data['theme'] == t.$1,
                              onSelected: (_) => guard(context, () async {
                                app.data['theme'] = t.$1;
                                await app.save();
                              }),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Pengingat lokal',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Belajar pukul 19.00 WIB, mengikuti jam tenang',
                  style: TextStyle(fontSize: 11),
                ),
                value: app.data['notifications'] == true,
                onChanged: (v) => guard(context, () => app.setNotifications(v)),
              ),
              ListTile(
                title: const Text('Jam tenang', style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  '${app.data['quiet_start'].toString().padLeft(2, '0')}.00–${app.data['quiet_end'].toString().padLeft(2, '0')}.00 WIB',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _quietHours(context, app),
              ),
            ],
          ),
        ),
        const SectionTitle('Akun & penyimpanan'),
        ActionTile(
          icon: Icons.cloud_sync_outlined,
          title: app.syncLabel,
          subtitle: app.namespace == 'guest'
              ? 'Masuk untuk mengaktifkan sinkronisasi Supabase'
              : 'Terakhir: ${wibDate(app.data['last_sync'] as String?, time: true)}\n${app.queued} perubahan dalam antrean',
          onTap: () => app.namespace == 'guest'
              ? context.push('/auth')
              : guard(context, () async {
                  await app.sync();
                  if (context.mounted) {
                    message(context, app.error ?? app.syncLabel);
                  }
                }),
        ),
        if (app.conflict) ...[
          const SizedBox(height: 14),
          const Note(
            'Perubahan dari perangkat lain terdeteksi. Ekspor data sebelum memilih versi yang akan digunakan.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => guard(context, () => app.useCloud()),
                child: const Text('Gunakan data cloud'),
              ),
              OutlinedButton(
                onPressed: () async {
                  if (await confirm(
                    context,
                    'Gunakan data perangkat?',
                    'Versi cloud akan diperbarui dengan data perangkat ini. Attempt yang sudah dikumpulkan tetap tidak dapat diubah.',
                    action: 'Gunakan perangkat',
                  )) {
                    if (context.mounted) {
                      await guard(context, () => app.sync(force: true));
                    }
                  }
                },
                child: const Text('Gunakan data perangkat'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.ios_share_rounded,
          title: 'Ekspor & backup',
          subtitle: 'PDF ringkasan · CSV · JSON lengkap',
          onTap: () => showModalBottomSheet(
            context: context,
            showDragHandle: true,
            builder: (ctx) => SheetBody(
              children: [
                Text(
                  'Simpan salinan progres',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'JSON menyertakan riwayat, jawaban dan checklist pribadi. Simpan di lokasi yang kamu percaya.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                ...['pdf', 'csv', 'json'].map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton.icon(
                      onPressed: () => guard(ctx, () => exportProgress(app, f)),
                      icon: const Icon(Icons.download_rounded),
                      label: Text('Ekspor ${f.toUpperCase()}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (app.namespace != 'guest') ...[
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.logout_rounded,
            title: 'Keluar dari akun',
            subtitle: 'Cache akun di perangkat dibersihkan setelah keluar',
            onTap: () async {
              if (await confirm(
                context,
                'Keluar dari akun?',
                '${app.queued > 0 ? 'Masih ada perubahan yang belum tersinkron. Ekspor atau sinkronkan terlebih dahulu agar tidak kehilangan salinan lokal.\n\n' : ''}Cache akun di HP akan dihapus; data cloud tetap ada.',
                action: 'Keluar',
              )) {
                if (context.mounted) await guard(context, () => app.logout());
              }
            },
          ),
        ],
        const SectionTitle('Kepercayaan & privasi'),
        ActionTile(
          icon: Icons.verified_user_outlined,
          title: 'Privasi & batas penggunaan',
          subtitle: 'Tanpa NIK, KK, scan identitas, atau password SSCASN',
          color: teal,
          onTap: () => _privacy(context),
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.link_rounded,
          title: 'Sumber & lisensi',
          subtitle: 'Referensi resmi · konten latihan original CC BY 4.0',
          onTap: () => context.push('/journey/sources'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            if (await confirm(
              context,
              app.namespace == 'guest'
                  ? 'Hapus semua data perangkat?'
                  : 'Hapus akun dan seluruh datanya?',
              app.namespace == 'guest'
                  ? 'Semua jawaban, progres, checklist dan agenda mode perangkat akan dihapus permanen. Ekspor terlebih dahulu.'
                  : 'Akun Supabase dan seluruh data miliknya akan dihapus permanen. Tindakan ini memerlukan internet dan tidak dapat dibatalkan. Ekspor terlebih dahulu.',
              action: 'Hapus permanen',
              danger: true,
            )) {
              if (context.mounted) {
                await guard(context, () async {
                  await app.deleteAll();
                  if (context.mounted) context.go('/onboarding');
                });
              }
            }
          },
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(
            app.namespace == 'guest'
                ? 'Hapus data perangkat'
                : 'Hapus akun & data',
          ),
        ),
        const SizedBox(height: 22),
        const Center(
          child: Text(
            'CPNS Journey 1.0.0 · Persiapan yang terarah\nIndependen, tanpa afiliasi BKN/Kemenkeu',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, height: 1.8),
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile(BuildContext context, AppController app) async {
    final alias = TextEditingController(text: app.data['alias'] as String),
        city = TextEditingController(text: app.data['target_city'] as String);
    String education = app.data['education'] as String,
        d3 = app.data['d3_status'] as String;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SheetBody(
          children: [
            Text(
              'Pendidikan & tujuan',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alias,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Nama panggilan'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: education,
              decoration: const InputDecoration(
                labelText: 'Ijazah yang dipakai melamar',
              ),
              items: [
                'SMA',
                'D3',
                'S1',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => set(() => education = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: d3,
              decoration: const InputDecoration(
                labelText: 'Status D3 Teknik Informatika',
              ),
              items: [
                'Sedang kuliah',
                'Lulus',
                'Tidak ditempuh',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => set(() => d3 = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: city,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Kota penempatan yang diinginkan',
              ),
            ),
            const SizedBox(height: 12),
            const Note(
              'Kuliah D3 yang masih berlangsung bukan pengganti ijazah D3. Preferensi kota berbeda dari penempatan yang benar-benar ditetapkan.',
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => guard(ctx, () async {
                if (alias.text.trim().isEmpty || city.text.trim().isEmpty) {
                  throw const FormatException(
                    'Isi nama panggilan dan kota tujuan.',
                  );
                }
                if (education == 'D3' && d3 != 'Lulus') {
                  throw const FormatException(
                    'Ijazah D3 hanya bisa digunakan jika sudah lulus.',
                  );
                }
                app.data['alias'] = alias.text.trim();
                app.data['target_city'] = city.text.trim();
                app.data['education'] = education;
                app.data['d3_status'] = d3;
                await app.save();
                if (ctx.mounted) Navigator.pop(ctx);
              }),
              child: const Text('Simpan profil'),
            ),
          ],
        ),
      ),
    );
    alias.dispose();
    city.dispose();
  }

  Future<void> _studyPlan(BuildContext context, AppController app) async {
    var minutes = (app.data['minutes'] as int).toDouble(),
        days = app.data['plan_days'] as int;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SheetBody(
          children: [
            Text(
              'Belajar dengan ritmemu',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('${minutes.round()} menit per hari'),
            Slider(
              value: minutes,
              min: 15,
              max: 120,
              divisions: 7,
              label: '${minutes.round()} menit',
              onChanged: (v) => set(() => minutes = v),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 hari')),
                ButtonSegment(value: 30, label: Text('30 hari')),
              ],
              selected: {days},
              onSelectionChanged: (v) => set(() => days = v.first),
            ),
            const SizedBox(height: 16),
            const Note(
              'Ubah rencana kapan saja. Progres dan histori latihan tetap tersimpan.',
              color: teal,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => guard(ctx, () async {
                app.data['minutes'] = minutes.round();
                app.data['plan_days'] = days;
                await app.save();
                if (ctx.mounted) Navigator.pop(ctx);
              }),
              child: const Text('Simpan rencana'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quietHours(BuildContext context, AppController app) async {
    int start = app.data['quiet_start'] as int,
        end = app.data['quiet_end'] as int;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SheetBody(
          children: [
            Text('Jam tenang · WIB', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: start,
              decoration: const InputDecoration(labelText: 'Mulai'),
              items: List.generate(
                24,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text('${i.toString().padLeft(2, '0')}.00'),
                ),
              ),
              onChanged: (v) => set(() => start = v!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: end,
              decoration: const InputDecoration(labelText: 'Selesai'),
              items: List.generate(
                24,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text('${i.toString().padLeft(2, '0')}.00'),
                ),
              ),
              onChanged: (v) => set(() => end = v!),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pengingat yang jatuh pada jam tenang digeser ke akhir jam tenang. Waktu mulai = selesai berarti tanpa jam tenang.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => guard(ctx, () async {
                app.data['quiet_start'] = start;
                app.data['quiet_end'] = end;
                await app.save();
                await app.reminders.schedule(app.data);
                if (ctx.mounted) Navigator.pop(ctx);
              }),
              child: const Text('Simpan jam tenang'),
            ),
          ],
        ),
      ),
    );
  }

  void _privacy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const SheetBody(
        children: [
          Text(
            'Belajar dengan kendali atas datamu',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 18),
          Text(
            '• Mode perangkat menyimpan data secara lokal.\n• Cloud hanya aktif setelah kamu menghubungkan Supabase dan masuk.\n• Token akun Android disimpan melalui secure storage.\n• NIK, KK, password SSCASN dan unggah scan identitas tidak diperlukan; versi ini memakai metadata saja.\n• Catatan dan ekspor dapat memuat informasi pribadi yang kamu ketik sendiri.\n• Pengingat bersifat pilihan dan tidak memuat detail sensitif.\n• Tidak ada analitik pelacak yang dipasang.\n• Hapus akun akan menghapus data cloud milik akun melalui fungsi database; salinan backup yang kamu simpan tetap berada di bawah kendalimu.',
            style: TextStyle(fontSize: 14, height: 1.9),
          ),
          SizedBox(height: 18),
          Note(
            'Aplikasi independen. Tidak mendaftarkan CPNS, tidak mengirim sanggah, tidak menjamin lulus atau penempatan Medan. Ketentuan final mengikuti sumber resmi.',
            color: indigo,
          ),
        ],
      ),
    );
  }
}
