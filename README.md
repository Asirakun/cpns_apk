# CPNS Journey

Aplikasi Android Flutter Material 3 untuk belajar CPNS dan mencatat seleksi S00–S11. Dibangun dari PRD v2 dan Checklist Berkas CPNS Kemenkeu yang diberikan. Tidak membutuhkan XAMPP, Flask, website, atau VPS sendiri.

Untuk melanjutkan melalui ekstensi Codex di VS Code, baca [panduan lanjutan](docs/LANJUTKAN_DI_CODEX.md). Proyek dan Flutter disiapkan untuk drive D pada Windows.

## Menjalankan aplikasi dan status APK

**Status sesi ini:** kode Flutter dan build web lokal telah diuji. Build APK belum berhasil karena unduhan dependensi Android berulang kali mengembalikan HTTP 503 (termasuk `androidx.datastore:datastore-core-android:1.2.1`). Belum ada APK yang siap dipasang dari sesi ini.

Setelah build Android berhasil:

1. Pasang APK pada Android 6.0+ **ARM64**. Izinkan instalasi dari sumber yang kamu pilih saat Android meminta.
2. Buka aplikasi, isi nama panggilan, lalu **Mulai di perangkat**. Materi, CAT dan checklist bisa digunakan tanpa akun/internet.
3. Untuk cloud, siapkan proyek Supabase sendiri, jalankan SQL di bawah, lalu Profil → Akun → masukkan Project URL dan publishable/anon key. Jangan masukkan secret/service_role key.

Konfigurasi signed release telah disiapkan; simpan kunci rilis milikmu di tempat privat agar pembaruan berikutnya memakai tanda tangan yang sama. Source tidak menyertakan private key. Mode perangkat dan mode akun sengaja mempunyai namespace terpisah; progres tamu tidak otomatis dipindah ke akun. Ekspor sebelum beralih atau menghapus data.

## Flutter di drive D (Windows)

Lokasi yang digunakan: `D:\Development\flutter`, SDK pada `D:\Development\Android\Sdk`, cache Pub/Gradle pada `D:\Development\cache`. Proyek dapat diekstrak ke `D:\Projects\CPNSJourney`.

Jalankan PowerShell dari folder proyek:

```powershell
.\scripts\setup_windows_d.ps1
# Setelah JDK 21 tersedia; skrip menampilkan persetujuan lisensi SDK:
.\scripts\setup_windows_d.ps1 -InstallAndroidSdk
```

Skrip memerlukan Git, akses internet dan drive D. Tidak mengubah HOME/USERPROFILE, tidak menghapus instalasi Flutter lama pada C, dan tidak perlu hak administrator. Telemetri Flutter dinonaktifkan dan cache analyzer diarahkan ke D. Skrip Windows disediakan untuk dijalankan pada komputer Windows; pengujian sesi ini dilakukan pada Linux, bukan pada drive C komputer pengguna.

```powershell
flutter doctor
flutter pub get
flutter run
flutter analyze
flutter test
```

Versi build: Flutter 3.50.1 / Dart 3.14.0, JDK 21, compile/target SDK 36, minimum SDK 23. Material UI dipakai melalui paket resmi `material_ui` karena Flutter 3.50 telah memindahkan library Material dari impor lama. Dependency `image` dipin 4.5.4 untuk kompatibilitas dengan `archive` yang tersedia; lockfile disertakan.

## Supabase

1. Buat proyek Supabase. Paket/kuota/pausing mengikuti ketentuan Supabase, bukan jaminan aplikasi.
2. Jalankan `supabase/migrations/202611200001_initial.sql`, kemudian `supabase/seed.sql` di SQL Editor. Supabase CLI `supabase db push` dapat dipakai sebagai alternatif.
3. Migration kedua berisi bucket **private** untuk pengembangan unggah di masa depan; UI v1 tetap metadata-only. Tidak ada kebutuhan mengunggah KTP/KK.
4. Aktifkan email/password dan email confirmation. Tambahkan `id.cpnsjourney://login-callback` pada Auth → URL Configuration → Redirect URLs, dan konfigurasi email/SMTP untuk verifikasi/reset sesuai layananmu.
5. Hubungkan Project URL dan **publishable/anon** key dari aplikasi. Alternatif build: `--dart-define-from-file=.env.json` dengan objek JSON public settings. Jangan menyimpan secret/service-role key dalam source/APK.
6. Untuk pembaruan paket, unggah JSON berversi (format sama dengan assets/content/content.json) ke bucket konten publik terpisah seperti `content-packages`, lalu isi `download_url`, `content_hash` SHA-256, `size_bytes`, `reviewer` dan `publication_status=published` pada content_releases. Jangan gunakan bucket dokumen pribadi.
7. Untuk konten resmi, kurasi melalui Studio. Set `publication_status=published` hanya setelah tinjauan. Formasi harus merujuk sumber HTTPS resmi dengan `status=verified` dan `verified_at`. Tidak ada formasi/deadline 2026 fiktif pada seed.

RLS aktif pada 27 tabel public. Master hanya dapat dibaca jika published; penulisan user dilakukan lewat RPC `sync_user_state` yang mengambil identitas dari JWT, menggunakan lock/version, UUID operation id dan transaksi. Snapshot adalah sumber sinkronisasi utama; profil, attempt/jawaban, dokumen, tahap dan progres juga diproyeksikan ke tabel terstruktur. Kolom/tabel lain disiapkan untuk pengembangan; bukan semua diisi sebagai data terpisah oleh UI saat ini.

SQLite/Drift menyimpan snapshot per namespace dan outbox atomik di Android. Jawaban dan deadline disimpan setelah tiap perubahan. Retry menggunakan backoff; UI menyatakan **tersimpan di HP** sampai cloud mengonfirmasi. Konflik versi meminta pemilihan data. Memilih perangkat tidak boleh mengubah attempt cloud yang sudah submitted; jika riwayat berbeda, gunakan data cloud atau backup lengkap. Logout menghapus cache akun di perangkat setelah konfirmasi. Hapus akun memanggil RPC dan cascade ke seluruh data miliknya.

## Fitur yang tersedia

- Lima tab: Beranda, Belajar, Tryout, Journey, Profil; terang/gelap/sistem; font lokal Plus Jakarta Sans; layout ponsel/tablet.
- Onboarding, profil SMA/D3/Medan, autentikasi email, reset password, mode perangkat.
- 12 materi, pencarian/filter, bookmark, progres; prioritas topik dari kesalahan dan kartu pengulangan 1/3/7 hari.
- 450 soal original berbasis template, 3 paket CAT penuh non-overlap (30 TWK + 35 TIU + 45 TKP, 100 menit), latihan singkat/topik, timer persisten, navigator, ragu-ragu, autosave, submit satu kali dan review.
- Skor deterministik, grafik dari riwayat aktual; semua ambang/preset 2024 diberi label historis. Tidak ada klaim lulus resmi.
- Tracker S00–S11, status/evidence pribadi, arsip cycle, formasi dan sumber berkatalog, peringatan pendidikan dan penempatan, SKB bersyarat.
- Checklist dari dokumen pengguna dengan catatan, histori, expiry; agenda WIB, pengingat Android opt-in dan quiet hours; anggaran rupiah.
- Ekspor PDF/CSV/JSON melalui menu berbagi Android; penghapusan data/akun; tidak ada analytics pelacak.
- Validasi SHA-256 paket bawaan; snapshot attempt tetap memuat versi soalnya.

## Konten dan batas rilis

**450 soal adalah latihan original yang dibuat secara template dan divalidasi secara otomatis, belum bank soal yang telah ditinjau ahli materi.** Variasi dapat mempunyai pola serupa, terutama TWK recall dan TKP. Tiga CAT memakai ID soal yang tidak tumpang tindih, bukan jaminan konsepnya berbeda seluruhnya. Materi ini tidak diklaim sebagai konten resmi atau soal bocoran. Tinjauan substantif satu per satu tetap diperlukan sebelum penggunaan publik berisiko tinggi.

Tidak ada data resmi formasi/jadwal 2026 yang diasumsikan benar. Portal merupakan tautan referensi dari dokumen tanggal 20 November 2026. Materi SKB spesifik menunggu formasi dan pengumuman yang benar. V1 tidak menyediakan scan dokumen, pendaftaran/sanggah otomatis, Play Store, atau anti-cheat resmi. Pembaruan paket dapat diperiksa secara manual dari Belajar → Paket offline → Periksa pembaruan cloud. Admin menerbitkan content_releases dengan download_url HTTPS Supabase, SHA-256 dan versi yang cocok. File JSON divalidasi sebelum dipasang; paket rusak ditolak dan attempt lama mempertahankan snapshot versinya. Paket bawaan juga dapat diperbarui lewat APK baru. Belum ada akun Supabase produksi yang dihubungkan pada APK distribusi.

## Build signed release

Buat `android/key.properties` dari contohnya, lalu arahkan ke JKS privat milikmu pada D. Untuk memperbarui APK kelak, gunakan kunci rilis yang sama. Naikkan angka `+versionCode` pada pubspec untuk update.

```powershell
flutter build apk --release --target-platform android-arm64
```

Untuk perangkat ARM 32-bit, build terpisah dengan `--target-platform android-arm`. Play Store/AAB berada di luar distribusi pribadi ini. Jangan commit `key.properties`, JKS, atau kredensial privat.

## Verifikasi

```sh
flutter analyze
flutter test
npm ci
npm run test:security
python scripts/generate_content.py
python scripts/import_content/build_seed.py
```

Pengujian database memakai PostgreSQL embedded PGlite dengan fixture auth/storage dan dua identitas. Ini memverifikasi aturan SQL/RLS, bukan pengganti pengujian layanan Auth/Storage hosted. Lihat `docs/VERIFIKASI.md` untuk hasil aktual, cakupan, dan langkah UAT Android fisik/Supabase yang masih diperlukan.

## Struktur

`lib/app` tema/router widgets; `lib/core` model, Drift, cloud/sync, notifikasi/ekspor; `lib/features` layar lima tab dan alurnya; `assets/content` paket berversi; `supabase` migrasi/seed/security tests; `scripts` setup drive D dan generator/import konten. Target web hanya digunakan untuk pengujian UI lokal, bukan website yang di-host.

Aplikasi independen, bukan produk BKN/Kemenkeu; tidak terhubung SSCASN serta tidak menjamin kelulusan atau lokasi Medan.
