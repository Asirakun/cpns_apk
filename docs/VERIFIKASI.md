# Verifikasi dan status distribusi

Aplikasi disusun berdasarkan PRD v2 dan checklist pengguna. Ini adalah implementasi awal; kriteria rilis publik yang membutuhkan akun produksi, peninjau materi manusia dan perangkat fisik tidak dianggap selesai hanya karena kode/tes lokal lulus.

## Hasil 1.2.0 — 21 November 2026

## Navbar kapsul 1.2.3 — terbaru

APK **1.2.3**, 29.2 MiB, signed dengan kunci release existing. 70 tes Flutter, 33 SQL, 42 pemeriksaan APK dan 118 aset lulus. Lint 0 error / 7 warning. Audit OSV tidak menemukan advisori aktif yang cocok pada dependensi terkunci.

[Laporan setiap file, tes dan screenshot](NAVBAR_V1_2_3.md). Ikon lama tetap dipakai; APK sudah memuat intro dengan SFX tanpa Lewati. Bagian selanjutnya adalah arsip versi sebelumnya.

## Intro dengan SFX 1.2.2 — arsip

APK **1.2.2**, 29.2 MiB, signed dengan kunci release existing. 70 tes Flutter, 33 SQL, 42 pemeriksaan APK dan 118 aset lulus. Lint 0 error / 7 warning; OSV tanpa advisori aktif yang cocok. SHA-256: `46cb55ad5e0a9d366a6559398e19276f773d54deaf3cab4ff0c6a87652a7f795`.

[Perubahan intro, setiap file dan pengujian](INTRO_SFX_V1_2_2.md). Gunakan animasi/SFX cpns-intro, tanpa latar gradient/rings sumber dan tanpa tombol Lewati. Uji HP fisik belum dijalankan. Bagian selanjutnya adalah arsip versi sebelumnya.

## Intro HD 1.2.1 — hasil terbaru

APK signed ARM64 **1.2.1 / versionCode 2006**, Android 7.0+, **30.521.841 byte (29,1 MiB)**, signer release existing. SHA-256: `10fbcbb3a480992665ec9d90f9c1f17ba2874ccc74cfdcf54666d109e25440dc`. Analyze bersih; **70 tes Flutter / 33 SQL / 42 pemeriksaan APK / 109 pemeriksaan aset UI** lulus, 3 capture lama opt-in dilewati. Lint **0 error / 7 warning**, OSV 234 paket dan audit npm tooling tanpa advisori aktif yang cocok.

Master 1440 × 3200 dirender pada RTX 3050/NVENC; aplikasi memakai PNG alpha 1080 px + kurva Remotion, teks/latar native tanpa bidang video. Halaman/data existing dipertahankan. [Perubahan setiap file dan bukti](INTRO_HD_V1_2_1.md). Uji HP fisik/hosted belum dilakukan. Bagian selanjutnya menyimpan hasil versi terdahulu.

- APK signed ARM64 **1.2.0 / versionCode 2005**, Android 7.0+ (min 24 / target 36), **29.781.539 byte (28,4 MiB)**, sertifikat release existing yang dipin. [APK lokal](../build/releases/cpns-journey-1.2.0-arm64-v8a.apk).
- SHA-256: `c299bd1b26877daadae3ce1280b1e89a9059d6dfd34ae6a1cf601a0e422227ad`.
- **67 tes Flutter lulus / 3 capture opt-in dilewati**, analyze tanpa temuan. CAT penuh 110 soal menghasilkan 550 lewat UI; cold reopen/enkripsi, isolasi akun, data lama, chart, tab/pencarian/filter dan intro skip/replay diuji.
- **33 SQL/RLS**, **13 screenshot**, Android Lint **0 error / 7 warning**, OSV **136 Pub + 97 Maven + 1 npm** tanpa advisori aktif yang cocok.
- **42 pemeriksaan APK keamanan** dan **106 pemeriksaan aset UI** lulus. Ke-40 aset artwork Flutter cocok byte dengan source; pixel terlihat launcher legacy/foreground lima density cocok dengan logo hasil generasi; adaptive XML ada.
- Tooling intro: TypeScript bersih, npm audit 0 advisori; video 96 frame final + 96 frame debug lulus QA dan contact sheet/frame ukuran penuh ditinjau. WebP 248.614 byte, 540 × 960, 41 frame hasil penggabungan frame diam, total 3.200 ms; MP4 H.264 720 × 1280 hanya stream video.
- Bukti: [regresi](security/regression-1.2.0.json), [APK](security/release-security-1.2.0.json), [aset/logo APK](security/ui-assets-1.2.0.json), [OSV](security/dependency-audit-1.2.0.json), [npm intro](security/intro-npm-audit-1.2.0.json), [Lint](security/lint-results-release-1.2.0.xml).

Perubahan fungsi dan setiap file: [UPGRADE_UI_V1_2.md](UPGRADE_UI_V1_2.md). Data screenshot adalah fixture terisolasi. Tidak membuat/menghapus database atau progres; Android fisik/Supabase hosted belum diuji.

## Hasil 1.1.0 — arsip

Desain dan seluruh ikon lama dipertahankan sesuai screenshot terakhir pemilik, dengan tambahan chart Harian/Mingguan/Bulanan pada halaman Analisis. Screenshot Beranda identik SHA-256 dengan versi 1.0.2; 18 aset ikon/ilustrasi juga identik. Tidak menerapkan compact redesign.

- APK ARM64 signed 1.1.0 (`versionCode=2004`), Android 7.0+, 27.226.148 byte (26,0 MiB), sertifikat release existing. Berkas penyerahan: `build/releases/cpns-journey-1.1.0-arm64-v8a.apk`.
- Analyze bersih, **55 tes Flutter lulus / 2 capture opt-in dilewati**, **33 SQL/RLS**, **11 screenshot** dari renderer Flutter. CAT penuh 110 soal lewat UI menghasilkan 550; isolasi namespace, migrasi/cold reopen, waktu idle/background, rumus/filter chart dan data lama diuji.
- Android Lint 0 error / 7 warning; OSV 136 Pub + 97 Maven + 1 npm tanpa advisori aktif yang cocok; secret pattern scan tanpa temuan; 42 pemeriksaan APK lulus.
- SHA-256: `4bb65189a54772ef3d60f0f77395aaf7917ebf47508f7694a75478a166adcd26`.
- Migrasi `202611210001_analytics_additive.sql` menambah fungsi/trigger pada snapshot existing, tanpa tabel/database baru dan tanpa menulis ulang data lama. Belum diterapkan ke proyek hosted yang tidak terhubung; diperlukan sebelum sync v2.1. Analisis lokal tetap tersedia.

Lihat [laporan file dan pengujian](UPGRADE_V2_1.md) serta [screenshot](design/PAPERCUT.md). Data contoh pada grafik berlabel DATA UJI; tidak dimasukkan ke akun nyata. Pengujian Android fisik, login/reset hosted dan runtime Keystore/notifikasi tetap belum dijalankan.

## Hasil papercut 1.0.2 — arsip

APK release ARM64 1.0.2 (`versionCode=2003`) berhasil dibangun dengan identitas privat pemilik yang sama, obfuscation Dart dan optimasi R8. Desain papercut dark blue memakai 16 ikon potongan atlas dan 2 ilustrasi baru sesuai referensi. Berkas: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`, 26.964.004 byte (25,7 MiB), Android 7.0+.

- Analisis Flutter: tidak ada temuan; 33 tes Flutter lulus (satu capture opt-in dilewati pada suite normal). Tes widget lima tab pada 360/430 dp dengan teks 1,3× lulus. Enam screenshot diekspor dari render Flutter 390×900 dp dengan font dan gambar asli; bukan uji pada ponsel fisik. Lihat `docs/design/PAPERCUT.md`.
- 25 pemeriksaan SQL/RLS lulus, termasuk regresi bypass null version dan seluruh 13 tabel milik pengguna. Migrasi tambahan: `202611200003_security_hardening.sql`.
- Android Lint: 0 error, 7 peringatan (dependency update, resource qualifier lama dan bentuk launcher icon). Tidak ada lint suppression/baseline yang dipakai untuk menyembunyikan error.
- OSV: 136 paket Pub, 97 komponen Maven dan 1 paket npm, tanpa advisori aktif yang cocok saat pemeriksaan. `npm audit`: 0 advisori. Ini tidak membuktikan seluruh binary/engine bebas celah.
- 42 pemeriksaan APK final lulus: tanda tangan sesuai fingerprint sertifikat release, debugging mati, cleartext/backup dilarang, aturan XML benar-benar dirujuk manifest, ABI ARM64, AOT tanpa kernel debug/DWARF, ikon notifikasi tetap terpaket dan file privat tidak ikut APK.
- SHA-256 APK: `1e6015c37c43eca3d405955816a018a81a9ca4b84668518428be81ccbc278d69`.

Perubahan mencakup enkripsi payload SQLite, sesi/PKCE yang dipisahkan per proyek, pembatasan URL/redirect, ekspor CSV, backup dan validasi RPC. Lihat [laporan keamanan](KEAMANAN.md) dan bukti mesin di `docs/security/`. Pengujian perangkat dan Supabase hosted ditunda sesuai pilihan pemilik; tidak diklaim lulus. Bagian di bawah menyimpan hasil sesi sebelumnya.

## Hasil yang telah dijalankan

- `flutter analyze`: tidak ada temuan pada analisis terakhir.
- `flutter test --concurrency=1`: 18 tes lulus. Mencakup komposisi 450 soal/3 CAT, skor 550 dan TKP per opsi, jawaban kosong/salah, deadline persisten, submit satu kali, isolasi namespace/outbox (termasuk pembacaan akun lama yang terlambat), cold reopen Drift, snapshot soal, profil/cycle tidak menghapus riwayat, pendidikan SMA/D3, quiet hours dan paket rusak.
- Tes widget: lima tab pada 360 dan 430 dp, mode gelap, teks 1,3× dan onboarding. Memakai font aplikasi sesungguhnya; overflow judul kecil sudah diperbaiki.
- PostgreSQL embedded **PGlite 0.5.17**: 12 pemeriksaan lulus. RLS di 27 tabel, akun A/B terisolasi, anon/master write ditolak, retry idempotent, konflik versi terdeteksi, attempt submitted immutable, nilai tidak konsisten ditolak, bucket privat terisolasi, hapus akun cascade.
- Headless Chromium pada build web lokal: onboarding, menjawab saat jaringan offline, reload dengan jawaban dan deadline yang sama, submit latihan singkat, lalu CAT 110 soal sampai hasil TWK150/TIU175/TKP225 = 550. Tidak menggunakan kredensial Supabase. Browser memakai adapter penyimpanan web; adapter Android Drift diuji secara terpisah melalui cold reopen database nyata.
- Paket bawaan SHA-256 diverifikasi saat dibuka. Seluruh soal memiliki lima opsi, kunci/bobot, pembahasan, ID dan versi; tiga paket CAT tidak mempunyai ID soal tumpang tindih.
- Pemeriksaan browser tambahan: perubahan status/catatan/histori dokumen tersimpan; ekspor PDF, CSV dan JSON dapat dibaca kembali. Tidak ada error browser pada alur ini.

Tes browser merupakan pemeriksaan aplikasi lokal, bukan situs publik yang diterbitkan dan bukan pengganti uji Android fisik. Android SDK/JDK dan dependency diunduh ke direktori kerja Linux. Komputer Windows pengguna tidak dipasangi Flutter pada C oleh proses ini.

## UAT yang memerlukan lingkungan pemilik

1. Hubungkan proyek Supabase milik pemilik aplikasi; uji daftar, email confirmation, login, pemulihan password/deep link dan hapus akun pada layanan hosted.
2. Uji akun A/B serta satu akun pada dua perangkat dengan jaringan terputus/terhubung kembali; verifikasi hasil RPC dan outbox di Studio.
3. Uji APK pada minimal dua perangkat Android, satu fisik: cold start, aksesibilitas, dark mode, force-stop/resume, mode pesawat, pengingat, izin ditolak, reboot dan quiet hours. Cold start <=3 detik belum diklaim.
4. Jalankan `flutter test integration_test/local_journey_test.dart -d DEVICE_ID` pada perangkat uji Android. Suite ini memakai database terisolasi, bukan akun/data produksi pengguna.
5. Tinjau substansi semua materi dan soal secara manusia. Status saat ini **automated_validation_only**, bukan konten resmi/ditinjau ahli. Uji figural/simbol pada font perangkat.
6. Masukkan formasi/aturan/jadwal 2026 hanya setelah sumber resmi tersedia dan diverifikasi. Periksa format berkas, batas waktu, ijazah yang digunakan, serta kebijakan penempatan nasional.
7. Untuk pembaruan konten, uji paket valid/rusak dan minimum versi aplikasi. Untuk rilis publik, lengkapi kebijakan retensi, backup operasional dan audit tambahan sesuai pengguna aktual.

Unggah dokumen sensitif tidak diaktifkan pada UI v1, sehingga tidak ada uji upload scan yang diklaim lulus. Migration bucket private merupakan fondasi fitur opsional. Contoh jadwal/historis tidak pernah diperlakukan sebagai jadwal resmi yang baru.

## Build dan penyerahan berkas

Build web release lokal sebelumnya berhasil. Percobaan build Android ARM64 release pada sesi cloud sebelumnya terhambat unduhan dependensi (HTTP 503).

### Verifikasi Windows — 20 November 2026

- Flutter 3.50.1 / Dart 3.14.0 pada `D:\Development\flutter`, JDK 21.0.10 pada `D:\Android\jbr`, Gradle 9.5.0. Android SDK berada di `D:\Development\Android\Sdk`; cache Pub/Gradle/analyzer dan file sementara build diarahkan ke `D:\Development\cache`.
- `flutter pub get --enforce-lockfile` berhasil tanpa mengubah lockfile.
- `flutter analyze --no-pub`: tidak ada temuan. `flutter test --no-pub --concurrency=1 --reporter expanded`: seluruh 18 tes lulus, termasuk cold reopen SQLite dan tes widget.
- `flutter build apk --debug --target-platform android-arm64 --split-per-abi --no-pub` berhasil. Berkas: `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`, ukuran 112.475.344 byte (107,3 MiB).
- `aapt dump badging`: aplikasi `id.cpnsjourney.app`, versi `1.0.0`, versionCode `2001` (APK split ARM64), minimum SDK 24, target SDK 36, native ABI hanya `arm64-v8a`. Minimum Android diperbarui menjadi Android 7.0 mengikuti migrasi Flutter; APK ini tidak mendukung Android 6.0.
- `apksigner verify --verbose`: valid, APK Signature Scheme v2, satu penanda tangan debug.
- SHA-256 APK: `1be984513d9636673868b9ac5c2ec78c8853597f3503cb1f8e9d7e8b854d37ad`.
- Build menampilkan peringatan penggunaan Kotlin Gradle Plugin oleh `share_plus` 12.0.2. Build saat ini lulus; kompatibilitas Built-in Kotlin perlu diperiksa saat memperbarui Flutter/plugin.

Pada sesi debug 20 November, `adb devices -l` belum mendeteksi perangkat Android dan build rilis belum dilakukan. Status terbaru build release tercantum di atas; instalasi/peluncuran, tes integrasi Android fisik, Supabase hosted, pengukuran performa dan dua perangkat tetap belum diverifikasi.

Source disiapkan untuk dilanjutkan melalui repositori GitHub dan VS Code. Build/cache lokal, konfigurasi SDK mesin, kredensial, serta private signing key tidak disertakan. Panduan Windows pada drive D tersedia di `docs/LANJUTKAN_DI_CODEX.md`.
