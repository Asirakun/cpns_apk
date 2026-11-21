# Pembaruan UI CPNS Journey 1.2.0

21 November 2026. Melanjutkan aplikasi existing 1.1.0 sesuai permintaan terbaru pemilik. Checkpoint source sebelum pekerjaan ini tersimpan lokal di `work/baseline-ui-v1.2/` (166 file). Tidak membuat aplikasi/database baru, tidak menghapus progres, tidak menerapkan migrasi baru pada tahap UI ini.

## Perilaku akhir

- **Ikon:** 20 ikon fungsi papercut baru dipotong dari atlas hasil generasi. Profil memakai perangkat/awan sinkronisasi, kotak backup, perisai privasi dan buku referensi yang berbeda. Pemetaan ikon tidak lagi memakai tanaman untuk fungsi yang belum dikenali. Kontrol tanpa aset yang sesuai memakai ikon Material aslinya. Ke-16 ikon original dan kedua ilustrasi Beranda dipertahankan; logo merek di header diganti sesuai permintaan launcher baru.
- **Pusat persiapan:** tujuh kartu berukuran sama dalam susunan 3–3–1; Anggaran di tengah baris terakhir. Formasi, Pengumuman, Berkas, Agenda WIB, Hasil & sanggah, Persiapan SKB dan Anggaran tetap membuka route existing.
- **Tryout:** tab Soal/Riwayat terpisah. Soal dapat dicari berdasarkan paket/topik, dengan akses lanjut sesi aktif, CAT penuh dan latihan singkat/per topik. Riwayat dapat dicari dan difilter Semua/Tryout/Latihan; urutan terbaru, 20 hasil per batch dengan Muat lebih banyak. Klik hasil membuka pembahasan existing. Filter tidak mengubah attempt/jawaban tersimpan.
- **Prioritas belajar:** tiga kartu bernomor, judul topik, kategori dan jumlah soal yang perlu ditinjau. Klik tetap memulai latihan pada topik terkait. Grafik Beranda mempertahankan tampilan lama; label 100% diperbaiki agar tidak terpotong menjadi beberapa baris.
- **Analisis:** ringkasan tiga angka, satu grafik utama dan kontrol periode/filter. Kualitas topik, tren CAT, tabel data dan rincian TKP memakai bagian yang dapat dibuka. Penjelasan sumber, rumus dan batas data tersedia lewat tombol informasi/tooltip. Rumus, rentang, WIB dan pemisahan cohort CAT tetap memakai read model 1.1.0.
- **Jawaban:** opsi terpilih serta nomor navigator yang sudah dijawab berwarna hijau. Nomor yang sudah dijawab dan ragu tetap hijau dengan tanda `?`; nomor ragu yang belum dijawab tetap dibedakan. Tidak mengubah skor, timer atau aturan submit.
- **Logo/intro:** logo buku, jalan dan bendera dibuat dengan imagegen. Launcher legacy/adaptive lima density dan splash Android memakai logo baru dengan navy. Intro dibuat di Remotion: 3,2 detik, tanpa suara, offline, dapat dilewati, otomatis sekali per preferensi instalasi. Profil menyediakan replay; codec baru memastikan replay mulai dari awal. Pengurangan animasi sistem memakai logo statis selama 300 ms.

## Data dan regresi

SQLite/tabel dan payload pengguna tidak berubah pada tahap ini. Flag intro tersimpan terpisah di SharedPreferences, bukan snapshot belajar. Semua screenshot memakai MemoryStore dan data uji berlabel; proses capture tidak membuka database pengguna. Akun, sinkronisasi, ekspor, notifikasi, checklist, riwayat, CAT penuh dan analisis tetap ada.

Migrasi additive analisis dari 1.1.0 (`202611210001_analytics_additive.sql`) tetap tersedia dan belum diterapkan ke layanan hosted yang tidak terhubung. Tidak ada tindakan pada database Supabase produksi. `pubspec.lock`, soal/materi bawaan dan kode penyimpanan/enkripsi dipertahankan dari checkpoint 1.1.0.

## Bukti tampilan dan intro

Screenshot berasal dari renderer Flutter, font dan aset aplikasi nyata, 390 × 900 dp pada PNG 780 × 1800; `light-large` pada 430 dp dengan teks 1,3×. Ini bukan screenshot HP/emulator. Angka contoh bukan progres pengguna.

| Tampilan | Berkas |
| --- | --- |
| Beranda dan ilustrasi lama | [home.png](design/screenshots/v1.2.0/home.png) |
| Profil atas / ikon fungsi | [profile.png](design/screenshots/v1.2.0/profile.png), [profile-icons.png](design/screenshots/v1.2.0/profile-icons.png) |
| Kartu persiapan 3–3–1 | [preparation.png](design/screenshots/v1.2.0/preparation.png) |
| Tab Soal / Riwayat | [tryouts.png](design/screenshots/v1.2.0/tryouts.png), [history.png](design/screenshots/v1.2.0/history.png) |
| Kartu prioritas | [priorities.png](design/screenshots/v1.2.0/priorities.png) |
| Analisis harian/mingguan/bulanan | [daily.png](design/screenshots/v1.2.0/daily.png), [weekly.png](design/screenshots/v1.2.0/weekly.png), [monthly.png](design/screenshots/v1.2.0/monthly.png) |
| Rincian TKP / terang + teks besar | [category.png](design/screenshots/v1.2.0/category.png), [light-large.png](design/screenshots/v1.2.0/light-large.png) |
| Navigator jawaban hijau | [navigator.png](design/screenshots/v1.2.0/navigator.png) |
| Intro | [MP4](design/v1.2.0/intro/papercut-intro.mp4), [contact sheet](design/v1.2.0/intro/qa-contact-sheet.png), [QA frame](design/v1.2.0/intro/qa.json) |

Generasi dan pemotongan aset dijelaskan di [ASSETS.md](design/v1.2.0/ASSETS.md). [Source/panduan Remotion](../tools/papercut_intro/README.md) memakai tooling lokal terpisah dari runtime Android.

## Hasil pengujian

<!-- VERIFICATION:BEGIN -->
- APK signed ARM64 **1.2.0 / versionCode 2005**, Android 7.0+ (min 24 / target 36), **29.781.539 byte (28,4 MiB)**, sertifikat release existing yang dipin. [APK lokal](../build/releases/cpns-journey-1.2.0-arm64-v8a.apk).
- SHA-256: `c299bd1b26877daadae3ce1280b1e89a9059d6dfd34ae6a1cf601a0e422227ad`.
- **67 tes Flutter lulus / 3 capture opt-in dilewati**, analyze tanpa temuan. CAT penuh 110 soal menghasilkan 550 lewat UI; cold reopen/enkripsi, isolasi akun, data lama, chart, tab/pencarian/filter dan intro skip/replay diuji.
- **33 SQL/RLS**, **13 screenshot**, Android Lint **0 error / 7 warning**, OSV **136 Pub + 97 Maven + 1 npm** tanpa advisori aktif yang cocok.
- **42 pemeriksaan APK keamanan** dan **106 pemeriksaan aset UI** lulus. Ke-40 aset artwork Flutter cocok byte dengan source; pixel terlihat launcher legacy/foreground lima density cocok dengan logo hasil generasi; adaptive XML ada.
- Tooling intro: TypeScript bersih, npm audit 0 advisori; video 96 frame final + 96 frame debug lulus QA dan contact sheet/frame ukuran penuh ditinjau. WebP 248.614 byte, 540 × 960, 41 frame hasil penggabungan frame diam, total 3.200 ms; MP4 H.264 720 × 1280 hanya stream video.
- Bukti: [regresi](security/regression-1.2.0.json), [APK](security/release-security-1.2.0.json), [aset/logo APK](security/ui-assets-1.2.0.json), [OSV](security/dependency-audit-1.2.0.json), [npm intro](security/intro-npm-audit-1.2.0.json), [Lint](security/lint-results-release-1.2.0.xml).
<!-- VERIFICATION:END -->

Pengujian Android fisik, pemutaran intro/launcher pada vendor HP, Keystore/notifikasi runtime dan sinkronisasi Supabase hosted belum dijalankan. Pemeriksaan otomatis dan metadata APK tidak membuktikan keamanan tanpa batas atau performa semua perangkat.

Untuk mengulang:

```powershell
.\scripts\capture_design_previews.ps1
.\scripts\build_verified_release_windows.ps1
# Hanya jika mengubah intro:
.\scripts\render_papercut_intro.ps1 -InstallDependencies
```

## Perubahan per file

Daftar berikut membandingkan checkpoint 1.1.0 sebelum permintaan ini, termasuk file yang sebelumnya belum di-commit. Perubahan keamanan/analisis dari sesi sebelumnya dipertahankan. Hash lengkap, status dan bukti validasi per file tersedia di `UPGRADE_UI_V1_2_FILES.json`. APK/cache/source sementara tidak masuk daftar source.

<!-- FILES:BEGIN -->
| File | Status | Perubahan / bukti |
| --- | --- | --- |
| `README.md` | modified | Perbarui status release, panduan dan bukti terbaru; pertahankan hasil lama sebagai arsip. |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | modified | Splash/normal background navy dan logo baru, termasuk Android 12+ dan tema gelap. |
| `android/app/src/main/res/drawable/launch_background.xml` | modified | Splash/normal background navy dan logo baru, termasuk Android 12+ dan tema gelap. |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | added | Adaptive launcher memakai foreground dan background navy. |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | modified | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png` | added | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | modified | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png` | added | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | modified | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png` | added | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | modified | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png` | added | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | modified | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` | added | Launcher/foreground Android dari logo baru pada density terkait. |
| `android/app/src/main/res/values-night-v31/styles.xml` | added | Splash/normal background navy dan logo baru, termasuk Android 12+ dan tema gelap. |
| `android/app/src/main/res/values-night/styles.xml` | modified | Splash/normal background navy dan logo baru, termasuk Android 12+ dan tema gelap. |
| `android/app/src/main/res/values-v31/styles.xml` | added | Splash/normal background navy dan logo baru, termasuk Android 12+ dan tema gelap. |
| `android/app/src/main/res/values/launcher_colors.xml` | added | Warna background logo/splash navy. |
| `android/app/src/main/res/values/styles.xml` | modified | Splash/normal background navy dan logo baru, termasuk Android 12+ dan tema gelap. |
| `assets/brand/logo.png` | added | Logo merek papercut buku/jalan/bendera, PNG transparan. |
| `assets/intro/papercut-intro.webp` | added | Intro WebP offline 3,2 detik, 540×960, 41 frame setelah penggabungan frame diam. |
| `assets/papercut_functions/analytics.png` | added | Ikon fungsi analytics dipotong dari atlas bersih. |
| `assets/papercut_functions/announcements.png` | added | Ikon fungsi announcements dipotong dari atlas bersih. |
| `assets/papercut_functions/backup.png` | added | Ikon fungsi backup dipotong dari atlas bersih. |
| `assets/papercut_functions/briefcase.png` | added | Ikon fungsi briefcase dipotong dari atlas bersih. |
| `assets/papercut_functions/cloudSync.png` | added | Ikon fungsi cloudSync dipotong dari atlas bersih. |
| `assets/papercut_functions/device.png` | added | Ikon fungsi device dipotong dari atlas bersih. |
| `assets/papercut_functions/download.png` | added | Ikon fungsi download dipotong dari atlas bersih. |
| `assets/papercut_functions/formation.png` | added | Ikon fungsi formation dipotong dari atlas bersih. |
| `assets/papercut_functions/help.png` | added | Ikon fungsi help dipotong dari atlas bersih. |
| `assets/papercut_functions/logout.png` | added | Ikon fungsi logout dipotong dari atlas bersih. |
| `assets/papercut_functions/moon.png` | added | Ikon fungsi moon dipotong dari atlas bersih. |
| `assets/papercut_functions/plan.png` | added | Ikon fungsi plan dipotong dari atlas bersih. |
| `assets/papercut_functions/privacy.png` | added | Ikon fungsi privacy dipotong dari atlas bersih. |
| `assets/papercut_functions/results.png` | added | Ikon fungsi results dipotong dari atlas bersih. |
| `assets/papercut_functions/review.png` | added | Ikon fungsi review dipotong dari atlas bersih. |
| `assets/papercut_functions/search.png` | added | Ikon fungsi search dipotong dari atlas bersih. |
| `assets/papercut_functions/settings.png` | added | Ikon fungsi settings dipotong dari atlas bersih. |
| `assets/papercut_functions/sources.png` | added | Ikon fungsi sources dipotong dari atlas bersih. |
| `assets/papercut_functions/verified.png` | added | Ikon fungsi verified dipotong dari atlas bersih. |
| `assets/papercut_functions/wallet.png` | added | Ikon fungsi wallet dipotong dari atlas bersih. |
| `docs/KEAMANAN.md` | modified | Perbarui status release, panduan dan bukti terbaru; pertahankan hasil lama sebagai arsip. |
| `docs/LANJUTKAN_DI_CODEX.md` | modified | Perbarui status release, panduan dan bukti terbaru; pertahankan hasil lama sebagai arsip. |
| `docs/UPGRADE_UI_V1_2.md` | added | Laporan perubahan per file dan hasil pengujian tahap UI 1.2.0. |
| `docs/UPGRADE_UI_V1_2_FILES.json` | added | Laporan perubahan per file dan hasil pengujian tahap UI 1.2.0. |
| `docs/VERIFIKASI.md` | modified | Perbarui status release, panduan dan bukti terbaru; pertahankan hasil lama sebagai arsip. |
| `docs/design/PAPERCUT.md` | modified | Perbarui status release, panduan dan bukti terbaru; pertahankan hasil lama sebagai arsip. |
| `docs/design/screenshots/v1.2.0/category.png` | added | Screenshot category.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/daily.png` | added | Screenshot daily.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/history.png` | added | Screenshot history.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/home.png` | added | Screenshot home.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/light-large.png` | added | Screenshot light-large.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/monthly.png` | added | Screenshot monthly.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/navigator.png` | added | Screenshot navigator.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/overview.png` | added | Montase enam screenshot Flutter nyata untuk tinjauan cepat. |
| `docs/design/screenshots/v1.2.0/preparation.png` | added | Screenshot preparation.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/priorities.png` | added | Screenshot priorities.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/profile-icons.png` | added | Screenshot profile-icons.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/profile.png` | added | Screenshot profile.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/screenshots.json` | added | Metadata dimensi, viewport dan SHA-256 ke-13 screenshot Flutter. |
| `docs/design/screenshots/v1.2.0/tryouts.png` | added | Screenshot tryouts.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/screenshots/v1.2.0/weekly.png` | added | Screenshot weekly.png dari renderer Flutter dengan label DATA UJI. |
| `docs/design/v1.2.0/ASSETS.md` | added | Provenance dan sumber generasi ikon/logo; atlas utuh tidak dikemas ke APK. |
| `docs/design/v1.2.0/function-icons-atlas-clean.png` | added | Provenance dan sumber generasi ikon/logo; atlas utuh tidak dikemas ke APK. |
| `docs/design/v1.2.0/function-icons-atlas.png` | added | Provenance dan sumber generasi ikon/logo; atlas utuh tidak dikemas ke APK. |
| `docs/design/v1.2.0/intro/asset-metadata.json` | added | Artefak video/still/QA intro final, tidak dikemas sebagai MP4 ke APK. |
| `docs/design/v1.2.0/intro/frame-20.png` | added | Artefak video/still/QA intro final, tidak dikemas sebagai MP4 ke APK. |
| `docs/design/v1.2.0/intro/frame-48.png` | added | Artefak video/still/QA intro final, tidak dikemas sebagai MP4 ke APK. |
| `docs/design/v1.2.0/intro/frame-95.png` | added | Artefak video/still/QA intro final, tidak dikemas sebagai MP4 ke APK. |
| `docs/design/v1.2.0/intro/intro-still.png` | added | Artefak video/still/QA intro final, tidak dikemas sebagai MP4 ke APK. |
| `docs/design/v1.2.0/intro/papercut-intro.mp4` | added | Artefak video/still/QA intro final, tidak dikemas sebagai MP4 ke APK. |
| `docs/design/v1.2.0/intro/qa-contact-sheet.png` | added | Artefak video/still/QA intro final, tidak dikemas sebagai MP4 ke APK. |
| `docs/design/v1.2.0/intro/qa.json` | added | Artefak video/still/QA intro final, tidak dikemas sebagai MP4 ke APK. |
| `docs/design/v1.2.0/logo-source.png` | added | Provenance dan sumber generasi ikon/logo; atlas utuh tidak dikemas ke APK. |
| `docs/security/dependency-audit-1.1.0.json` | added | Arsip bukti keamanan release 1.1.0 sebelum hasil terbaru diganti. |
| `docs/security/dependency-audit-1.2.0.json` | added | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/dependency-audit.json` | modified | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/intro-npm-audit-1.2.0.json` | added | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/lint-results-release-1.1.0.xml` | added | Arsip bukti keamanan release 1.1.0 sebelum hasil terbaru diganti. |
| `docs/security/lint-results-release-1.2.0.xml` | added | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/regression-1.2.0.json` | added | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/release-security-1.1.0.json` | added | Arsip bukti keamanan release 1.1.0 sebelum hasil terbaru diganti. |
| `docs/security/release-security-1.2.0.json` | added | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/release-security.json` | modified | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/source-secrets-1.1.0.json` | added | Arsip bukti keamanan release 1.1.0 sebelum hasil terbaru diganti. |
| `docs/security/source-secrets-1.2.0.json` | added | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/source-secrets.json` | modified | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `docs/security/ui-assets-1.2.0.json` | added | Bukti pemeriksaan release/dependensi/source 1.2.0. |
| `lib/app/intro.dart` | added | Intro offline sekali tampil, skip/replay, codec baru dan reduced motion; preferensi terpisah dari snapshot. |
| `lib/app/paper.dart` | modified | 20 aset fungsi dan pemetaan semantik; hapus fallback tanaman untuk kontrol tanpa pemetaan. |
| `lib/app/theme.dart` | modified | Warna hijau jawaban yang dapat dibaca pada tema gelap/terang. |
| `lib/app/widgets.dart` | modified | ActionTile mendukung aset/leading eksplisit; BrandMark memakai logo baru; fallback Material sesuai fungsi. |
| `lib/core/app_version.dart` | modified | Versi aplikasi menjadi 1.2.0 untuk kontrak konten. |
| `lib/features/analytics.dart` | modified | Ringkasan tiga angka, filter ringkas, rincian/sumber dapat dibuka tanpa mengubah rumus. |
| `lib/features/analytics_charts.dart` | modified | Caption, legenda dan tabel grafik lebih ringkas; data serta skala dipertahankan. |
| `lib/features/home.dart` | modified | Prioritas belajar menjadi kartu bernomor; perbaiki label sumbu skor 100%. |
| `lib/features/journey.dart` | modified | Tujuh menu persiapan menjadi kartu seragam 3–3–1 dengan kartu terakhir di tengah. |
| `lib/features/profile.dart` | modified | Ikon perangkat/sync/backup/privasi/sumber berbeda dan akses replay intro. |
| `lib/features/tryout.dart` | modified | Tab Soal/Riwayat, pencarian, filter dan batch riwayat, urutan tanggal aman untuk metadata lama; jawaban/navigator hijau. |
| `lib/main.dart` | modified | IntroGate di runtime dan route replay /intro, routing existing tetap tersedia. |
| `pubspec.yaml` | modified | Versi 1.2.0+5 dan bundel folder aset baru; tidak menambah dependensi Flutter. |
| `scripts/build_verified_release_windows.ps1` | modified | Tambahkan verifikasi byte artwork dan pixel launcher ke pipeline release existing. |
| `scripts/capture_design_previews.ps1` | modified | Capture 13 skenario UI 1.2.0 tanpa database pengguna. |
| `scripts/prepare_papercut_v12.ps1` | added | Pemotongan atlas bersih dan resize logo/launcher lima density dengan alpha. |
| `scripts/render_papercut_intro.ps1` | added | Render MP4/PNG Remotion, encode WebP, decode dan QA dengan tooling lokal. |
| `scripts/verify_ui_release_assets.ps1` | added | Periksa 40 aset artwork Flutter, pixel lima density launcher/foreground, adaptive XML dan monochrome pada APK final. |
| `test/analytics_preview_test.dart` | modified | Precache path aset lama/baru; fixture preview dipakai ulang. |
| `test/analytics_ui_test.dart` | modified | Sesuaikan interaksi rentang dropdown pada regresi grafik dan tema/font besar. |
| `test/papercut_preview_test.dart` | modified | Verifikasi seluruh 36 ikon dikemas dan gunakan path aset per keluarga. |
| `test/security_test.dart` | modified | Sesuaikan versi konten tak didukung terhadap release 1.2.0. |
| `test/ui_v12_preview_test.dart` | added | Renderer 13 screenshot UI/data uji terisolasi, opt-in. |
| `test/ui_v12_test.dart` | added | Regresi ikon, simetri kartu, pencarian/filter/history lama, hijau jawaban, durasi/skip/replay/reduced motion intro. |
| `test/widget_test.dart` | modified | Regresi lima tab pada 360/430 dp, teks 1,3×, kedua tema serta onboarding. |
| `tools/papercut_intro/.gitignore` | added | Konfigurasi, brief atau panduan render intro lokal. |
| `tools/papercut_intro/README.md` | added | Konfigurasi, brief atau panduan render intro lokal. |
| `tools/papercut_intro/brief.json` | added | Konfigurasi, brief atau panduan render intro lokal. |
| `tools/papercut_intro/contact-sheet.mjs` | added | Gabungkan capture Flutter nyata ke overview; catat dimensi/hash ke-13 screenshot. |
| `tools/papercut_intro/encode-webp.mjs` | added | Gabungkan PNG Remotion menjadi WebP dengan pemeriksaan dimensi/durasi. |
| `tools/papercut_intro/package-lock.json` | added | Dependensi tooling Remotion/React/Sharp dikunci; terpisah dari APK. |
| `tools/papercut_intro/package.json` | added | Dependensi tooling Remotion/React/Sharp dikunci; terpisah dari APK. |
| `tools/papercut_intro/public/PlusJakartaSans.ttf` | added | Salinan lokal logo/font untuk renderer Remotion; sumber aplikasi tetap tersedia. |
| `tools/papercut_intro/public/logo.png` | added | Salinan lokal logo/font untuk renderer Remotion; sumber aplikasi tetap tersedia. |
| `tools/papercut_intro/qa.mjs` | added | QA seluruh frame final/debug, safe area teks dan contact sheet. |
| `tools/papercut_intro/src/debug.tsx` | added | Komposisi/warna/debug Remotion intro papercut. |
| `tools/papercut_intro/src/index.tsx` | added | Komposisi/warna/debug Remotion intro papercut. |
| `tools/papercut_intro/src/style.json` | added | Komposisi/warna/debug Remotion intro papercut. |
| `tools/papercut_intro/tsconfig.json` | added | Konfigurasi, brief atau panduan render intro lokal. |
<!-- FILES:END -->
