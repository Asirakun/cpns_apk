# Intro cpns-intro dengan SFX — 1.2.2

21 November 2026. Memakai proyek `cpns-intro` yang disediakan pemilik, bukan membuat animasi baru. Buku tertutup muncul, halaman membuka, jalan tergambar, bendera muncul, judul dan tagline tampil. Durasi 200 frame / 30 fps ≈6,67 detik.

Gradient, lingkaran dan glow latar sumber tidak dibawa. Aplikasi tetap memakai PaperBackdrop dan tema existing. **Tombol Lewati dihapus.** Intro selesai otomatis; tombol Back sistem tetap tersedia. Reduced motion tetap memakai tampilan statis singkat tanpa suara.

SFX memakai salinan persis `cpns-intro/tools/mix-preview.wav`, gabungan tujuh stem asli. Native Android MediaPlayer memakai volume media, audio focus sementara, stop saat background/dispose/selesai, seek saat resume dan ID sesi untuk mencegah replay lama menghentikan suara baru. Tidak menambah plugin Flutter, permission, database atau migrasi. Semua halaman/data selain intro dipertahankan.

APK **1.2.2**, 29.2 MiB, signed dengan kunci release existing. 70 tes Flutter, 33 SQL, 42 pemeriksaan APK dan 118 aset lulus. Lint 0 error / 7 warning; OSV tanpa advisori aktif yang cocok. SHA-256: `46cb55ad5e0a9d366a6559398e19276f773d54deaf3cab4ff0c6a87652a7f795`.

## Bukti dan batas pemeriksaan

- [APK](../build/releases/cpns-journey-1.2.2-arm64-v8a.apk), [pratinjau QHD+ dengan audio](design/v1.2.2/intro/provided-intro-with-sfx.mp4), [screenshot Flutter](design/v1.2.2/intro/flutter-dark-20x9.png), [contact sheet](design/v1.2.2/intro/contact-sheet.png).
- Master dirender pada RTX 3050/D3D11, NVENC required; [bukti GPU](design/v1.2.2/intro/gpu-render.json). Seluruh 200 frame di-decode dan diperiksa resolusi/warna sudut. Track AAC terdeteksi; WAV PCM 44.1k mono berdurasi 6,666667 detik, peak 0.8499, tidak clipping. [QA audio/video](design/v1.2.2/intro/qa.json).
- Tiga screenshot/pixel test gelap/terang 20:9 dan 16:9 teks 1,3× lulus. Tes channel memeriksa play/stop/resume seek dan selesai satu kali; gate first-launch dan reduced motion lulus. WAV dalam APK cocok source serta disimpan uncompressed agar Android openFd dapat dipakai.
- Uji suara, audio focus dan sinkronisasi di HP fisik belum dilakukan; mock channel tidak membuktikan suara terdengar pada semua perangkat. Tidak ada uji Supabase hosted baru.
- [Regresi](security/regression-1.2.2.json), [APK/security](security/release-security-1.2.2.json), [aset](security/ui-assets-1.2.2.json).

Sesudah update, pilih **Profil → Intro CPNS Journey** untuk replay; preferensi first-launch lama tetap dipertahankan.

## Perubahan file

<!-- FILES -->
| File | Status | Perubahan |
| --- | --- | --- |
| `README.md` | modified | Versi 1.2.2 / pipeline verifikasi aset audio. |
| `android/app/src/main/kotlin/id/cpnsjourney/cpns_journey/MainActivity.kt` | modified | Bridge MediaPlayer/audio focus/volume media, isolasi sesi dan cleanup. |
| `assets/intro/book-closed.png` | added | Aset buku/jalan/bendera, mix WAV asli dan kurva Remotion pengganti. |
| `assets/intro/book-open.png` | added | Aset buku/jalan/bendera, mix WAV asli dan kurva Remotion pengganti. |
| `assets/intro/flag.png` | added | Aset buku/jalan/bendera, mix WAV asli dan kurva Remotion pengganti. |
| `assets/intro/intro-sfx.wav` | added | Aset buku/jalan/bendera, mix WAV asli dan kurva Remotion pengganti. |
| `assets/intro/papercut-mark-hd.png` | removed | Aset buku/jalan/bendera, mix WAV asli dan kurva Remotion pengganti. |
| `assets/intro/provided-motion.json` | added | Aset buku/jalan/bendera, mix WAV asli dan kurva Remotion pengganti. |
| `assets/intro/remotion-motion.json` | removed | Aset buku/jalan/bendera, mix WAV asli dan kurva Remotion pengganti. |
| `assets/intro/road-rot.png` | added | Aset buku/jalan/bendera, mix WAV asli dan kurva Remotion pengganti. |
| `docs/INTRO_HD_V1_2_1_FILES.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/INTRO_SFX_V1_2_2.md` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/INTRO_SFX_V1_2_2_FILES.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/KEAMANAN.md` | modified | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/LANJUTKAN_DI_CODEX.md` | modified | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/VERIFIKASI.md` | modified | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/PAPERCUT.md` | modified | Perbarui entry render/QA atau dokumentasi ke intro cpns-intro dengan SFX. |
| `docs/design/v1.2.1/intro/papercut-mark-hd.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.1/intro/remotion-motion.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/contact-sheet.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/flutter-dark-16x9-large-text.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/flutter-dark-20x9.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/flutter-light-20x9.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/frame-180.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/frame-30.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/frame-90.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/gpu-render.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/provided-intro-with-sfx.mp4` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/provided-still.png` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/design/v1.2.2/intro/qa.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/dependency-audit-1.2.2.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/dependency-audit.json` | modified | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/lint-results-release-1.2.2.xml` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/regression-1.2.2.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/release-security-1.2.2.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/release-security.json` | modified | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/source-secrets-1.2.2.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/source-secrets.json` | modified | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `docs/security/ui-assets-1.2.2.json` | added | Bukti render, screenshot, hasil verifikasi atau dokumentasi terbaru. |
| `lib/app/intro.dart` | modified | Layer animasi dari sumber, 200-frame timeline, audio lifecycle, tanpa Lewati. |
| `lib/core/app_version.dart` | modified | Versi 1.2.2 / pipeline verifikasi aset audio. |
| `pubspec.yaml` | modified | Versi 1.2.2 / pipeline verifikasi aset audio. |
| `scripts/render_papercut_intro.ps1` | modified | Perbarui entry render/QA atau dokumentasi ke intro cpns-intro dengan SFX. |
| `scripts/verify_ui_release_assets.ps1` | modified | Versi 1.2.2 / pipeline verifikasi aset audio. |
| `test/intro_hd_test.dart` | modified | Regresi intro/SFX/background/first-launch/lifecycle dan versi konten. |
| `test/provided_intro_test.dart` | added | Regresi intro/SFX/background/first-launch/lifecycle dan versi konten. |
| `test/security_test.dart` | modified | Regresi intro/SFX/background/first-launch/lifecycle dan versi konten. |
| `test/ui_v12_test.dart` | modified | Regresi intro/SFX/background/first-launch/lifecycle dan versi konten. |
| `tools/papercut_intro/README.md` | modified | Perbarui entry render/QA atau dokumentasi ke intro cpns-intro dengan SFX. |
| `tools/papercut_intro/export-provided.mjs` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/package.json` | modified | Perbarui entry render/QA atau dokumentasi ke intro cpns-intro dengan SFX. |
| `tools/papercut_intro/public/book-closed.png` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/book-open.png` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/flag.png` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/road-rot.png` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/sfx/book-appear.wav` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/sfx/flag-pop.wav` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/sfx/pad.wav` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/sfx/page-open.wav` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/sfx/road-draw.wav` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/sfx/sparkle-end.wav` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/public/sfx/title-chime.wav` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/render-provided.mjs` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/src/provided/BookImages.tsx` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/src/provided/CpnsIntro.tsx` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/src/provided/index.tsx` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
| `tools/papercut_intro/verify-provided.mjs` | added | Ekspor/render/QA dari source cpns-intro, font lokal, tanpa background sumber. |
