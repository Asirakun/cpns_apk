# Perbaikan intro HD CPNS Journey 1.2.1

21 November 2026. Memperbaiki ketajaman dan batas gambar intro sesuai permintaan pemilik, memakai RTX 3050 laptop. Database, fitur dan tata letak halaman aplikasi dipertahankan.

## Penyebab dan hasil

| Bagian | 1.2.0 | 1.2.1 |
| --- | --- | --- |
| Master | 720 × 1280 | 1440 × 3200 QHD+, 30 fps, NVENC required |
| Aset runtime | WebP lossy 540 × 960, logo hanya sebagian frame | PNG lossless alpha 1080 × 1080 dari frame GPU akhir |
| Gerak | Decode animasi raster penuh | 96 sampel spring/opacity asli Remotion, diputar Flutter pada refresh rate layar |
| Teks | Teks terpanggang dan ikut diperbesar | Font aplikasi dirender native pada DPR/font scale perangkat |
| Latar | Bidang video #0A263E, gradient/wave dan letterbox SafeArea | PaperBackdrop memenuhi viewport, navy aplikasi #08223B/tema terang, tanpa persegi video |

PNG 987.557 byte dan file kurva kecil dipakai agar playback tidak perlu mendecode puluhan gambar besar. Master QHD+ disediakan terpisah; MP4/tooling tidak dimasukkan ke APK. Source logo diambil dari generasi asli 1254 × 1254, bukan pembesaran turunan launcher 512 px. Aset lama diarsipkan di folder bukti 1.2.0.

## GPU dan QA

- Renderer browser yang sama dengan render: `ANGLE (NVIDIA, NVIDIA GeForce RTX 3050 6GB Laptop GPU (0x000025EC) Direct3D11 vs_5_0 ps_5_0, D3D11)`. GPU compositing aktif; rasterization enabled_force. Tidak mengubah registry/preferensi GPU global atau memasang CUDA/driver baru.
- NVENC memakai `hardwareAcceleration: required`; probe 8 frame lulus dan master selesai tanpa fallback CPU. Ini membuktikan jalur GPU yang dipakai, tanpa klaim semua operasi/PNG compression berjalan di GPU atau selalu lebih cepat untuk semua animasi 2D.
- Seluruh **96 frame video final**, **96 frame debug terverifikasi**, dan **96 frame mark alpha** diperiksa; 0 masalah QA. PNG aplikasi cocok pixel demi pixel dengan frame GPU akhir. Contact sheet serta frame ukuran penuh ditinjau visual.
- Screenshot Flutter dark/light 360 × 800 dp pada DPR 3 dan 360 × 640 dp pada DPR 2, teks 1,3×. Piksel sudut layar/mark dibandingkan dengan PaperBackdrop polos dan sama persis. Capture hanya IntroScreen, tidak membuka database atau akun.

APK signed ARM64 **1.2.1 / versionCode 2006**, Android 7.0+, **30.521.841 byte (29,1 MiB)**, signer release existing. SHA-256: `10fbcbb3a480992665ec9d90f9c1f17ba2874ccc74cfdcf54666d109e25440dc`. Analyze bersih; **70 tes Flutter / 33 SQL / 42 pemeriksaan APK / 109 pemeriksaan aset UI** lulus, 3 capture lama opt-in dilewati. Lint **0 error / 7 warning**, OSV 234 paket dan audit npm tooling tanpa advisori aktif yang cocok.

Bukti: [regresi](security/regression-1.2.1.json), [APK](security/release-security-1.2.1.json), [aset dalam APK](security/ui-assets-1.2.1.json), [GPU](design/v1.2.1/intro/gpu-render.json), [QA frame](design/v1.2.1/intro/qa.json), [npm](security/intro-npm-audit-1.2.1.json).

## Hasil untuk dilihat

- [APK pembaruan](../build/releases/cpns-journey-1.2.1-arm64-v8a.apk)
- [Master QHD+](design/v1.2.1/intro/papercut-intro-qhd.mp4), [still](design/v1.2.1/intro/intro-still.png), [contact sheet](design/v1.2.1/intro/qa-contact-sheet.png)
- [Flutter gelap 20:9](design/v1.2.1/intro/flutter-dark-20x9.png), [terang 20:9](design/v1.2.1/intro/flutter-light-20x9.png), [16:9 + teks besar](design/v1.2.1/intro/flutter-dark-16x9-large-text.png)
- [Source dan panduan render](../tools/papercut_intro/README.md)

Flag intro existing dipertahankan: sesudah update, gunakan **Profil → Intro CPNS Journey** untuk replay. Skip, reduced motion dan durasi 3,2 detik tetap tersedia. Tidak ada database/migrasi/permission/plugin Flutter baru. Semua 39 aset existing, storage/cipher/controller, read model analisis dan halaman lain identik dengan checkpoint sebelum perbaikan ini. Uji playback Android fisik dan Supabase hosted belum dilakukan.

Reproduksi: `scripts/render_papercut_intro.ps1` dan `scripts/build_verified_release_windows.ps1 -CaptureIntroPreviews`. Master/PNG baru berasal dari render lokal, tidak memakai layanan cloud.

## Perubahan setiap file

<!-- FILES -->
| File | Status | Perubahan |
| --- | --- | --- |
| `README.md` | modified | Laporan/panduan dan perubahan setiap file untuk intro HD 1.2.1. |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | modified | Warna splash/window native #08223B sesuai aplikasi; bitmap launcher existing tetap. |
| `android/app/src/main/res/drawable/launch_background.xml` | modified | Warna splash/window native #08223B sesuai aplikasi; bitmap launcher existing tetap. |
| `android/app/src/main/res/values-night-v31/styles.xml` | modified | Warna splash/window native #08223B sesuai aplikasi; bitmap launcher existing tetap. |
| `android/app/src/main/res/values-night/styles.xml` | modified | Warna splash/window native #08223B sesuai aplikasi; bitmap launcher existing tetap. |
| `android/app/src/main/res/values-v31/styles.xml` | modified | Warna splash/window native #08223B sesuai aplikasi; bitmap launcher existing tetap. |
| `android/app/src/main/res/values/launcher_colors.xml` | modified | Warna splash/window native #08223B sesuai aplikasi; bitmap launcher existing tetap. |
| `android/app/src/main/res/values/styles.xml` | modified | Warna splash/window native #08223B sesuai aplikasi; bitmap launcher existing tetap. |
| `assets/intro/papercut-intro.webp` | removed | Diganti PNG/kurva; aset WebP lama dipindah ke arsip bukti 1.2.0. |
| `assets/intro/papercut-mark-hd.png` | added | PNG alpha lossless 1080×1080, copy persis hasil render GPU akhir tanpa resize. |
| `assets/intro/remotion-motion.json` | added | 96 sampel kurva Remotion / 30 fps / 3200 ms, bukan data pengguna. |
| `docs/INTRO_HD_V1_2_1.md` | added | Laporan/panduan dan perubahan setiap file untuk intro HD 1.2.1. |
| `docs/INTRO_HD_V1_2_1_FILES.json` | added | Laporan/panduan dan perubahan setiap file untuk intro HD 1.2.1. |
| `docs/KEAMANAN.md` | modified | Laporan/panduan dan perubahan setiap file untuk intro HD 1.2.1. |
| `docs/LANJUTKAN_DI_CODEX.md` | modified | Laporan/panduan dan perubahan setiap file untuk intro HD 1.2.1. |
| `docs/VERIFIKASI.md` | modified | Laporan/panduan dan perubahan setiap file untuk intro HD 1.2.1. |
| `docs/design/PAPERCUT.md` | modified | Laporan/panduan dan perubahan setiap file untuk intro HD 1.2.1. |
| `docs/design/v1.2.0/intro/papercut-intro.webp` | added | Arsip aset runtime 1.2.0 untuk menjaga bukti historis. |
| `docs/design/v1.2.1/intro/asset-metadata.json` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/flutter-dark-16x9-large-text.png` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/flutter-dark-20x9.png` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/flutter-light-20x9.png` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/frame-20.png` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/frame-48.png` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/frame-95.png` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/gpu-render.json` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/intro-still.png` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/papercut-intro-qhd.mp4` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/qa-contact-sheet.png` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/design/v1.2.1/intro/qa.json` | added | Artefak GPU, master, QA atau screenshot Flutter baru; tidak dikemas ke APK. |
| `docs/security/dependency-audit-1.2.1.json` | added | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/dependency-audit.json` | modified | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/intro-npm-audit-1.2.1.json` | added | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/lint-results-release-1.2.1.xml` | added | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/regression-1.2.1.json` | added | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/release-security-1.2.1.json` | added | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/release-security.json` | modified | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/source-secrets-1.2.1.json` | added | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/source-secrets.json` | modified | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `docs/security/ui-assets-1.2.1.json` | added | Bukti source/dependensi/regresi/Lint/APK/aset terbaru 1.2.1. |
| `lib/app/intro.dart` | modified | Latar PaperBackdrop penuh, font native, PNG alpha HD dan kurva Remotion; skip/replay/reduced motion tetap ada. |
| `lib/core/app_version.dart` | modified | Versi 1.2.1 sesuai kontrak konten. |
| `pubspec.yaml` | modified | Versi 1.2.1+6 tanpa tambahan plugin Flutter. |
| `scripts/build_verified_release_windows.ps1` | modified | Opsi capture intro selama suite regresi release. |
| `scripts/render_papercut_intro.ps1` | modified | Orkestrasi render RTX/NVENC dan QA HD. |
| `scripts/verify_ui_release_assets.ps1` | modified | Pastikan WebP intro lama/opsional tidak terkemas. |
| `test/intro_hd_test.dart` | added | Tes pixel background pada dark/light 20:9 dan 16:9, DPR/font besar; tiga screenshot Flutter. |
| `test/security_test.dart` | modified | Sesuaikan versi konten masa depan yang harus ditolak. |
| `test/ui_v12_test.dart` | modified | Regresi decode PNG 1080, kurva/durasi, first launch, skip/replay dan reduced motion. |
| `tools/papercut_intro/.gitignore` | modified | Brief, entry render/QA, konfigurasi output atau panduan tooling GPU. |
| `tools/papercut_intro/README.md` | modified | Brief, entry render/QA, konfigurasi output atau panduan tooling GPU. |
| `tools/papercut_intro/brief.json` | modified | Brief, entry render/QA, konfigurasi output atau panduan tooling GPU. |
| `tools/papercut_intro/encode-webp.mjs` | modified | WebP opsional disimpan di output ignored, tidak dipakai aplikasi. |
| `tools/papercut_intro/export-native.mjs` | added | Ekspor PNG GPU dan 96 sampel spring/interpolate langsung dari Remotion. |
| `tools/papercut_intro/gpu-browser.mjs` | added | Fail closed jika WebGL browser render bukan RTX 3050; catat status D3D11/rasterization. |
| `tools/papercut_intro/package.json` | modified | Brief, entry render/QA, konfigurasi output atau panduan tooling GPU. |
| `tools/papercut_intro/public/intro-logo.png` | added | Crop alpha logo generasi asli 1254 px, tanpa memakai turunan launcher 512 px. |
| `tools/papercut_intro/qa-hd.mjs` | added | QA seluruh 96 frame final/debug/alpha, batas teks dan kecocokan PNG/frame GPU. |
| `tools/papercut_intro/render-hd.mjs` | added | Bundle, probe NVENC required, master QHD+, frame PNG alpha dan ekspor native. |
| `tools/papercut_intro/src/index.tsx` | modified | Komposisi master QHD+ / mark alpha dan palet sesuai aplikasi. |
| `tools/papercut_intro/src/style.json` | modified | Komposisi master QHD+ / mark alpha dan palet sesuai aplikasi. |
