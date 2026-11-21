# Navbar kapsul — 1.2.3

21 November 2026. Navbar mengikuti bentuk referensi: kapsul mengambang, outline halus, bayangan dan bidang aktif membulat yang membungkus ikon beserta label. Warna mengikuti tema dark blue/terang aplikasi. Kelima ikon papercut existing, label dan rute tetap sama. Area sentuh mempunyai semantics tombol/selected dan animasi mengikuti pengaturan reduced motion. SafeArea memberi jarak dari navigasi sistem; layar lebar tetap memakai NavigationRail.

Tidak ada perubahan database, migrasi, permission atau dependensi. Intro cpns-intro dengan SFX, latar asli aplikasi dan tanpa tombol Lewati dari 1.2.2 ikut dalam APK ini. [Rincian intro](INTRO_SFX_V1_2_2.md), [video dengan SFX](design/v1.2.2/intro/provided-intro-with-sfx.mp4).

APK **1.2.3**, 29.2 MiB, signed dengan kunci release existing. 70 tes Flutter, 33 SQL, 42 pemeriksaan APK dan 118 aset lulus. Lint 0 error / 7 warning. Audit OSV tidak menemukan advisori aktif yang cocok pada dependensi terkunci.

[Unduh APK](../build/releases/cpns-journey-1.2.3-arm64-v8a.apk). SHA-256: `973120969d2e31c436d10397be41539d96b454eae6098d23f8fa30e03724eb1f`.

## Screenshot dan pengujian

- Screenshot engine Flutter dengan data uji: [Beranda](design/screenshots/v1.2.3/home.png), [Profil](design/screenshots/v1.2.3/profile.png), [Tryout](design/screenshots/v1.2.3/tryouts.png). Banner DATA UJI mendapat area tersendiri 16 dp di luar viewport aplikasi supaya tidak menutup lengkungan navbar. Tidak membuka database pengguna.
- Regresi empat kombinasi lebar 360/430 dp, teks 1,3× dan tema gelap/terang memeriksa StadiumBorder, margin 12 dp, urutan lima aset lama dan perpindahan semua tab tanpa exception/overflow.
- Analisis Dart bersih; 70 tes lulus, 3 capture opt-in dilewati dalam suite reguler. Tiga capture screenshot dijalankan terpisah dan lulus.
- [Hasil regresi](security/regression-1.2.3.json), [APK/security](security/release-security-1.2.3.json), [integritas aset](security/ui-assets-1.2.3.json), [dependensi](security/dependency-audit-1.2.3.json). Pemeriksaan hash memastikan ikon, intro/SFX, lockfile, core penyimpanan/enkripsi/analisis dan halaman fitur tidak berubah dari versi sebelumnya.
- Pengujian audio/focus/sinkronisasi pada HP Android fisik belum dilakukan. Hasil audit kode/APK tidak menjamin semua perangkat atau seluruh risiko keamanan. Tidak ada uji Supabase hosted baru.

## Perubahan setiap file

<!-- FILES -->
| File | Status | Perubahan |
| --- | --- | --- |
| `README.md` | modified | Nomor versi rilis 1.2.3. |
| `docs/KEAMANAN.md` | modified | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/LANJUTKAN_DI_CODEX.md` | modified | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/NAVBAR_V1_2_3.md` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/NAVBAR_V1_2_3_FILES.json` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/VERIFIKASI.md` | modified | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/design/PAPERCUT.md` | modified | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/design/screenshots/v1.2.3/home.png` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/design/screenshots/v1.2.3/profile.png` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/design/screenshots/v1.2.3/tryouts.png` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/dependency-audit-1.2.3.json` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/dependency-audit.json` | modified | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/lint-results-release-1.2.3.xml` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/regression-1.2.3.json` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/release-security-1.2.3.json` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/release-security.json` | modified | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/source-secrets-1.2.3.json` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/source-secrets.json` | modified | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `docs/security/ui-assets-1.2.3.json` | added | Dokumentasi, screenshot atau bukti verifikasi rilis 1.2.3. |
| `lib/app/floating_nav.dart` | added | Widget navbar kapsul, SafeArea, tema, selected state, semantics dan ikon existing. |
| `lib/core/app_version.dart` | modified | Nomor versi rilis 1.2.3. |
| `lib/main.dart` | modified | Shell mobile memakai FloatingPaperNavBar; rute dan rail existing dipertahankan. |
| `pubspec.yaml` | modified | Nomor versi rilis 1.2.3. |
| `test/security_test.dart` | modified | Sesuaikan batas versi konten dengan rilis 1.2.3. |
| `test/ui_v12_preview_test.dart` | modified | Capture versi 1.2.3 dengan banner data uji di luar viewport aplikasi. |
| `test/widget_test.dart` | modified | Regresi bentuk, margin, ikon dan lima tab pada empat kombinasi ukuran/tema. |
| `tools/papercut_intro/package.json` | modified | Finalisasi entry studio ke sumber intro dengan SFX. |
