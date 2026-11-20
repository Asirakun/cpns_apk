# Melanjutkan CPNS Journey di VS Code

Source Flutter Android dari PRD v2 dan checklist berkas pengguna. Ini implementasi awal yang sudah mempunyai alur aplikasi dan tes lokal; APK distribusi dan koneksi Supabase produksi belum selesai diverifikasi. Baca `README.md` dan `docs/VERIFIKASI.md` sebelum melanjutkan.

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

1. Jalankan build debug Android pada Windows: `flutter build apk --debug --target-platform android-arm64`. Build di lingkungan cloud sebelumnya terhambat unduhan Maven/Flutter embedding yang mengembalikan HTTP 503; belum ada APK sukses. Repositori Android kembali memakai Google Maven dan Maven Central standar. Jangan menyalin proxy/mirror sementara atau path Linux dari sesi cloud.
2. Jalankan tes integrasi pada perangkat uji: `flutter test integration_test/local_journey_test.dart -d DEVICE_ID`. Periksa force-stop/resume, jaringan putus, notifikasi, izin ditolak dan reboot. Tes ini belum dijalankan pada perangkat Android.
3. Siapkan proyek Supabase sendiri sesuai README; uji daftar/verifikasi/login/reset deep link, sinkronisasi dua perangkat, konflik dan hapus akun di layanan hosted. Tes PGlite yang sudah lulus memakai fixture Auth/Storage, bukan layanan hosted.
4. Tinjau materi dan semua soal secara substantif, terutama variasi template dan bobot TKP. Masukkan data 2026 hanya dari sumber resmi terverifikasi.
5. Buat private signing key sendiri sebelum rilis pertama. Kunci sesi cloud tidak dipakai untuk APK yang sudah terdistribusi dan tidak dibawa ke repo ini. Simpan JKS dan backup-nya secara privat pada D; isi `android/key.properties` dari contoh. Jangan commit kedua file tersebut.

Contoh pembuatan kunci, dengan kata sandi diminta interaktif oleh keytool:

```powershell
New-Item -ItemType Directory -Force D:\Development\keys | Out-Null
keytool -genkeypair -v -keystore D:\Development\keys\cpns-journey-release.jks -alias cpnsjourney -keyalg RSA -keysize 2048 -validity 10000
Copy-Item android\key.properties.example android\key.properties
# Edit key.properties di editor, lalu:
flutter build apk --release --target-platform android-arm64
```

## Prompt untuk ekstensi Codex

> Lanjutkan proyek CPNS Journey di repo ini. Baca README.md, docs/VERIFIKASI.md dan docs/LANJUTKAN_DI_CODEX.md terlebih dahulu. Flutter, Android SDK dan cache harus di drive D. Prioritaskan build debug Android dan perbaiki masalah nyata sampai aplikasi bisa dijalankan; jalankan analyze serta tes yang relevan. Pertahankan data offline, deadline CAT, isolasi akun, RLS, dan label historis aturan 2024. Jangan menganggap APK, Supabase hosted, atau tinjauan manusia sudah lulus. Jangan commit kredensial atau private signing key. Setelah build berhasil, lanjutkan UAT Android dan konfigurasi Supabase milik saya.

Dokumen DOCX asli tidak dimasukkan ke repo. Pemilik dapat membukanya kembali di sesi VS Code jika perlu mencocokkan rincian PRD. Konten aplikasi dan aturan checklist sudah terdapat di `assets/content`, `lib/core/models.dart`, dan seed SQL.
