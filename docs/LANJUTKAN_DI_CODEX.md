# Melanjutkan CPNS Journey di VS Code

## Intro HD 1.2.1 — hasil terbaru

## Navbar kapsul 1.2.3 — terbaru

APK **1.2.3**, 29.2 MiB, signed dengan kunci release existing. 70 tes Flutter, 33 SQL, 42 pemeriksaan APK dan 118 aset lulus. Lint 0 error / 7 warning. Audit OSV tidak menemukan advisori aktif yang cocok pada dependensi terkunci.

[Laporan setiap file, tes dan screenshot](NAVBAR_V1_2_3.md). Ikon lama tetap dipakai; APK sudah memuat intro dengan SFX tanpa Lewati. Bagian selanjutnya adalah arsip versi sebelumnya.

## Intro dengan SFX 1.2.2 — arsip

APK **1.2.2**, 29.2 MiB, signed dengan kunci release existing. 70 tes Flutter, 33 SQL, 42 pemeriksaan APK dan 118 aset lulus. Lint 0 error / 7 warning; OSV tanpa advisori aktif yang cocok. SHA-256: `46cb55ad5e0a9d366a6559398e19276f773d54deaf3cab4ff0c6a87652a7f795`.

[Perubahan intro, setiap file dan pengujian](INTRO_SFX_V1_2_2.md). Gunakan animasi/SFX cpns-intro, tanpa latar gradient/rings sumber dan tanpa tombol Lewati. Uji HP fisik belum dijalankan. Bagian selanjutnya adalah arsip versi sebelumnya.

APK signed ARM64 **1.2.1 / versionCode 2006**, Android 7.0+, **30.521.841 byte (29,1 MiB)**, signer release existing. SHA-256: `10fbcbb3a480992665ec9d90f9c1f17ba2874ccc74cfdcf54666d109e25440dc`. Analyze bersih; **70 tes Flutter / 33 SQL / 42 pemeriksaan APK / 109 pemeriksaan aset UI** lulus, 3 capture lama opt-in dilewati. Lint **0 error / 7 warning**, OSV 234 paket dan audit npm tooling tanpa advisori aktif yang cocok.

Master 1440 × 3200 dirender pada RTX 3050/NVENC; aplikasi memakai PNG alpha 1080 px + kurva Remotion, teks/latar native tanpa bidang video. Halaman/data existing dipertahankan. [Perubahan setiap file dan bukti](INTRO_HD_V1_2_1.md). Uji HP fisik/hosted belum dilakukan. Bagian selanjutnya menyimpan hasil versi terdahulu.

Source Flutter Android existing, terbaru 1.2.1. Baca docs/INTRO_HD_V1_2_1.md untuk perbaikan intro HD/RTX dan docs/UPGRADE_UI_V1_2.md untuk fitur UI 1.2.0 yang tetap dipertahankan. Gunakan PNG alpha 1080 px dan kurva hasil ekspor Remotion, teks serta PaperBackdrop native; hindari mengembalikan WebP 540x960/latar video lama. Pertahankan semua fitur, 39 artwork existing dan penyimpanan pengguna. Tidak ada migrasi baru pada tahap ini; cloud existing tetap memerlukan migrasi analisis additive 1.1.0.

## Membuka proyek pada drive D

Jalankan PowerShell. Git dan VS Code harus sudah tersedia.

```powershell
New-Item -ItemType Directory -Force D:\Projects | Out-Null
Set-Location D:\Projects
git clone https://github.com/Asirakun/cpns_apk.git
Set-Location cpns_apk
code .
```

Jika sudah mempunyai clone, jalankan `git pull --ff-only` dari folder clone itu. Simpan perubahan lokal sebelum menarik perubahan baru.

Terminal PowerShell dari folder proyek:

```powershell
.\scripts\setup_windows_d.ps1
```

Skrip memasang Flutter 3.50.1 di `D:\Development\flutter` dan mengarahkan cache Pub, Gradle, analyzer, serta Android ke D. Jika PowerShell memblokir skrip, pemilik komputer dapat menjalankannya satu kali dengan `powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows_d.ps1`; pengaturan execution policy permanen tidak perlu diubah.

Pasang JDK 21 pada D, arahkan `JAVA_HOME` ke folder JDK tersebut dan tambahkan folder `bin` ke PATH. Setelah `java -version` dan `javac -version` menampilkan JDK yang sama:

```powershell
.\scripts\setup_windows_d.ps1 -InstallAndroidSdk
flutter doctor -v
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter devices
flutter run -d DEVICE_ID
```

Tinjau lisensi Android SDK saat diminta. Tutup dan buka kembali VS Code setelah skrip selesai agar environment baru terbaca. Pengaturan VS Code di repo menunjuk Flutter pada D. Gunakan ponsel Android dengan USB debugging untuk pengujian tanpa mengunduh emulator.

Node.js hanya diperlukan untuk tes SQL: `npm ci` lalu `npm run test:security`. Node bukan backend aplikasi.

## Status implementasi

- Flutter Material 3, Riverpod, go_router; Android memakai Drift/SQLite, web preview memakai SharedPreferences.
- Lima tab, onboarding, mode perangkat, materi/bookmark/flashcard, latihan dan CAT 110 soal dengan deadline persisten, snapshot jawaban, submit satu kali dan pembahasan.
- Journey S00–S11, cycle/arsip, 26 checklist berkas dari dokumen, agenda WIB, pengingat opt-in, anggaran, ekspor PDF/CSV/JSON, profil dan pendidikan.
- Supabase Auth dan sinkronisasi snapshot/outbox, penanganan konflik versi, isolasi namespace akun, SQL/RLS, seed konten dan tes keamanan database disediakan. Belum terhubung ke proyek Supabase hosted milik pengguna.
- 450 soal original berbasis template, 12 materi dan 3 CAT tanpa ID soal yang berulang antar paket. Validasi otomatis tersedia; peninjauan substansi manusia masih diperlukan.
- Belum ada formasi, tenggat atau pengumuman resmi 2026 yang diasumsikan benar. Ambang SKD 2024 diberi label historis. D3 yang masih berjalan tidak dihitung sebagai ijazah D3 selesai; preferensi Medan tidak menjamin penempatan.

## Pekerjaan berikutnya

1. Build release ARM64 1.1.0 berhasil pada Windows (21 November 2026). Untuk mengulang beserta pemeriksaan otomatis: `.\scripts\build_verified_release_windows.ps1`. Hasilnya `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`, untuk Android 7.0+ ARM64. Desain dan screenshot render Flutter tersedia di `docs/design/PAPERCUT.md`. Repositori Android memakai Google Maven dan Maven Central standar. Jangan menyalin proxy/mirror sementara atau path Linux dari sesi cloud. Build debug lama merupakan artefak sebelum hardening; gunakan release terbaru.
2. Jalankan tes integrasi pada perangkat uji: `flutter test integration_test/local_journey_test.dart -d DEVICE_ID`. Periksa force-stop/resume, jaringan putus, notifikasi, izin ditolak dan reboot. Tes ini belum dijalankan pada perangkat Android.
3. Gunakan proyek Supabase existing sesuai README; uji daftar/verifikasi/login/reset deep link, sinkronisasi dua perangkat, konflik dan hapus akun di layanan hosted. Tes PGlite yang sudah lulus memakai fixture Auth/Storage, bukan layanan hosted.
4. Tinjau materi dan semua soal secara substantif, terutama variasi template dan bobot TKP. Masukkan data 2026 hanya dari sumber resmi terverifikasi.
5. Kunci release baru milik instalasi Windows ini sudah dibuat di `D:\Development\keys\cpns-journey-release.p12`, dengan kredensial privat di folder yang sama dan konfigurasi `android/key.properties` yang diabaikan Git. Simpan backup privat dan gunakan identitas yang sama untuk update. Kunci sesi cloud tidak digunakan. Jangan membuat kunci pengganti untuk update atau meng-commit file privat.

Untuk mengulang build release dan pemeriksaan otomatis, gunakan JDK 21 pada D serta dependensi tes npm yang sudah terpasang:

```powershell
.\scripts\build_verified_release_windows.ps1
```

## Prompt untuk ekstensi Codex

> Lanjutkan proyek CPNS Journey di repo ini. Baca README.md, docs/VERIFIKASI.md, docs/KEAMANAN.md dan docs/LANJUTKAN_DI_CODEX.md terlebih dahulu. Flutter, JDK, Android SDK dan cache harus di drive D. Pertahankan enkripsi data lokal, deadline CAT, isolasi akun, RLS, dan label historis aturan 2024. Gunakan kunci release privat yang sudah ada untuk update; jangan commit kredensial atau private signing key. Verifikasi source dan artefak APK tidak membuktikan UAT Android/Supabase hosted sudah lulus. Lanjutkan UAT perangkat dan konfigurasi Supabase bila diminta pemilik.

Dokumen DOCX asli tidak dimasukkan ke repo. Pemilik dapat membukanya kembali di sesi VS Code jika perlu mencocokkan rincian PRD. Konten aplikasi dan aturan checklist sudah terdapat di `assets/content`, `lib/core/models.dart`, dan seed SQL.
