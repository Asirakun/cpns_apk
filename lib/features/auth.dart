import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/controller.dart';
import '../core/services.dart';
import '../app/widgets.dart';
import '../app/theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  final alias = TextEditingController();
  int minutes = 45;
  int plan = 30;
  bool busy = false;
  @override
  void dispose() {
    alias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      BrandMark(),
                      SizedBox(width: 12),
                      Text(
                        'CPNS Journey',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Tag('LANGKAH PERTAMA', color: teal),
                  const SizedBox(height: 18),
                  Text(
                    'Perjalanan besar.\nMulai dari hari ini.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ruang belajarmu, dari persiapan hingga penempatan. Satu langkah yang terarah setiap hari.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: alias,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Nama panggilan',
                      hintText: 'Bagaimana kami menyapamu?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Note(
                    'Rencana awal: melamar dengan ijazah SMA, D3 Teknik Informatika masih berlangsung (target April 2027). Preferensi Medan belum menjamin penempatan.',
                    icon: Icons.school_outlined,
                    color: indigo,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Waktu belajar per hari',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [30, 45, 60, 90]
                        .map(
                          (m) => ChoiceChip(
                            label: Text('$m menit'),
                            selected: minutes == m,
                            onSelected: (_) => setState(() => minutes = m),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Rencana belajar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7 hari')),
                      ButtonSegment(value: 30, label: Text('30 hari')),
                    ],
                    selected: {plan},
                    onSelectionChanged: (v) => setState(() => plan = v.first),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              setState(() => busy = true);
                              final app = ref.read(appProvider);
                              try {
                                app.data['alias'] = alias.text.trim().isEmpty
                                    ? 'Pejuang CPNS'
                                    : alias.text.trim();
                                app.data['minutes'] = minutes;
                                app.data['plan_days'] = plan;
                                app.data['onboarded'] = true;
                                await app.downloadContent();
                                if (context.mounted) context.go('/home');
                              } catch (_) {
                                if (context.mounted) {
                                  message(
                                    context,
                                    'Paket belum tersimpan. Periksa ruang penyimpanan lalu coba lagi.',
                                  );
                                  setState(() => busy = false);
                                }
                              }
                            },
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        busy
                            ? 'Menyiapkan ruang belajar…'
                            : 'Mulai di perangkat',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/auth'),
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Materi dan latihan awal tersedia offline. Alat belajar independen, bukan aplikasi resmi BKN/Kemenkeu. Tidak terhubung ke akun SSCASN.',
                    style: TextStyle(fontSize: 11, height: 1.7),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthState();
}

class _AuthState extends ConsumerState<AuthScreen> {
  final email = TextEditingController(),
      password = TextEditingController(),
      url = TextEditingController(),
      key = TextEditingController();
  String mode = 'login';
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    url.dispose();
    key.dispose();
    super.dispose();
  }

  Future<void> act() async {
    setState(() {
      busy = true;
      error = null;
    });
    final app = ref.read(appProvider);
    try {
      if (!CloudConfig.ready) {
        await CloudConfig.connect(url.text, key.text);
        app.listenAuth();
        if (mounted) {
          message(context, 'Proyek Supabase terhubung. Lanjutkan masuk akun.');
        }
      } else if (app.passwordRecovery) {
        if (password.text.length < 8) {
          throw const FormatException('Kata sandi minimal 8 karakter.');
        }
        await app.client!.auth.updateUser(
          UserAttributes(password: password.text),
        );
        app.passwordRecovery = false;
        if (mounted) context.go('/home');
      } else if (mode == 'reset') {
        await app.client!.auth.resetPasswordForEmail(
          email.text.trim(),
          redirectTo: 'id.cpnsjourney://login-callback',
        );
        if (mounted) {
          message(
            context,
            'Jika email terdaftar, tautan pemulihan akan dikirim.',
          );
        }
      } else {
        if (!email.text.contains('@')) {
          throw const FormatException('Masukkan email yang valid.');
        }
        if (password.text.length < 8) {
          throw const FormatException('Kata sandi minimal 8 karakter.');
        }
        final response = mode == 'register'
            ? await app.client!.auth.signUp(
                email: email.text.trim(),
                password: password.text,
                emailRedirectTo: 'id.cpnsjourney://login-callback',
              )
            : await app.client!.auth.signInWithPassword(
                email: email.text.trim(),
                password: password.text,
              );
        if (response.session == null) {
          if (mounted) {
            message(
              context,
              'Periksa email untuk verifikasi akun sebelum masuk.',
            );
          }
        } else {
          await app.switchNamespace(response.user!.id, pull: true);
          if (mounted) {
            context.go(app.data['onboarded'] == true ? '/home' : '/onboarding');
          }
        }
      }
    } on AuthException catch (e) {
      error = e.message;
    } on FormatException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Belum dapat terhubung. Periksa internet, URL/key, dan migrasi Supabase.';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final recovery = app.passwordRecovery;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            app.passwordRecovery = false;
            context.go('/home');
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Akun & sinkronisasi'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const BrandMark(size: 58),
              const SizedBox(height: 26),
              Text(
                !CloudConfig.ready
                    ? 'Hubungkan ruang cloud'
                    : recovery
                    ? 'Buat kata sandi baru'
                    : mode == 'register'
                    ? 'Simpan perjalananmu'
                    : mode == 'reset'
                    ? 'Pulihkan akses akun'
                    : 'Selamat datang kembali',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                !CloudConfig.ready
                    ? 'Masukkan konfigurasi publik proyek Supabase milikmu. Jalankan migrasi yang disertakan sebelum memakai sinkronisasi.'
                    : 'Akun CPNS Journey berbeda dari akun SSCASN. Progres mode perangkat tetap terpisah dari progres akun.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 26),
              if (!CloudConfig.ready) ...[
                TextField(
                  controller: url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Supabase Project URL',
                    hintText: 'https://proyek.supabase.co',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: key,
                  decoration: const InputDecoration(
                    labelText: 'Publishable / anon key',
                  ),
                ),
                const SizedBox(height: 14),
                const Note(
                  'Jangan gunakan service_role atau secret key. Konfigurasi ini bersifat publik; perlindungan data berasal dari RLS.',
                  color: indigo,
                ),
              ],
              if (CloudConfig.ready && !recovery) ...[
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
              ],
              if (CloudConfig.ready && (mode != 'reset' || recovery))
                TextField(
                  controller: password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi (minimal 8 karakter)',
                  ),
                ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Note(error!, color: Colors.red),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: busy ? null : act,
                child: Text(
                  busy
                      ? 'Memproses…'
                      : !CloudConfig.ready
                      ? 'Hubungkan Supabase'
                      : recovery
                      ? 'Simpan kata sandi'
                      : mode == 'register'
                      ? 'Daftar akun'
                      : mode == 'reset'
                      ? 'Kirim tautan pemulihan'
                      : 'Masuk',
                ),
              ),
              if (CloudConfig.ready && !recovery) ...[
                TextButton(
                  onPressed: () => setState(
                    () => mode = mode == 'register' ? 'login' : 'register',
                  ),
                  child: Text(
                    mode == 'register'
                        ? 'Sudah punya akun? Masuk'
                        : 'Buat akun baru',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => mode = mode == 'reset' ? 'login' : 'reset',
                  ),
                  child: Text(
                    mode == 'reset' ? 'Kembali masuk' : 'Lupa kata sandi?',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Note(
                'Login pertama dan pemulihan akun memerlukan internet. Belajar offline tetap tersedia melalui mode perangkat.',
                color: teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
