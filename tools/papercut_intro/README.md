# Intro CPNS Journey

Versi terbaru **1.2.2** memakai animasi/aset dari folder `cpns-intro` milik pemilik. Durasi 200 frame pada 30 fps, sekitar 6,67 detik. Tujuh SFX dipakai dari sumber asli; gradient/rings/glow latar sumber dihapus. Aplikasi memakai PaperBackdrop existing dan tanpa tombol Lewati.

Jalankan `scripts/render_papercut_intro.ps1` dari root. `export-provided.mjs` mengekspor kurva buku/jalan/bendera/title; `render-provided.mjs` mengadaptasi source ke font lokal dan RTX/NVENC, `verify-provided.mjs` memeriksa 200 frame dan WAV/video. Source `cpns-intro` tidak diubah. Jika mengubah timing di source, sesuaikan ekspor kurva juga. Audio APK memakai mix-preview.wav yang sama dengan sumber, melalui native Android MediaPlayer. Playback berhenti saat background/selesai; resume memakai posisi timeline, volume media dan audio focus sementara. Tidak ada plugin Flutter/permission baru.

Hasil terbaru ada di `docs/design/v1.2.2/intro/`. Uji audio pada HP fisik belum dilakukan. Instruksi dan hasil 1.2.1 di bawah disimpan sebagai arsip; entry render/QA default sekarang memakai source dengan SFX.

## Arsip 1.2.1

Intro papercut 3,2 detik tanpa suara. Master **1440 × 3200 / 30 fps**, di-render pada RTX 3050 6 GB Laptop GPU melalui Chromium ANGLE Direct3D11 dan encoder **NVENC required**, tanpa fallback encoder CPU. Pemeriksaan GPU dan waktu uji encode tersimpan di `docs/design/v1.2.1/intro/gpu-render.json`.

Pada versi 1.2.0, aset 540 × 960 lossy diperbesar di HP. Latar `#0A263E` dan gradient/wave yang dibakar ke gambar berbeda dari navy aplikasi `#08223B`; `BoxFit.contain` dalam SafeArea juga menyisakan bidang untuk rasio layar yang berbeda.

Versi baru mengekspor PNG alpha **1080 × 1080** dari frame GPU akhir tanpa resize/kompresi lossy, serta 96 sampel kurva asli `spring()`/`interpolate()` Remotion. Flutter memutar transform/opacity dari kurva tersebut pada refresh rate layar, sementara tulisan dan PaperBackdrop dirender native. Logo sekitar 965 KiB, tanpa decode 96 gambar berukuran penuh saat startup. Latar memenuhi viewport dan mengikuti tema; teks tetap tajam pada DPR/font scale berbeda. Preferensi intro, skip/replay dan reduced motion tetap tersedia.

Jalankan dari root pada Windows, Node 22+ dan driver NVIDIA/NVENC yang sesuai:

```powershell
.\scripts\render_papercut_intro.ps1 -InstallDependencies
# Render berikutnya:
.\scripts\render_papercut_intro.ps1
# Tes dan screenshot Flutter tanpa database pengguna:
flutter test test/intro_hd_test.dart --dart-define=CAPTURE_INTRO_PREVIEWS=true
```

Remotion/renderer/CLI dikunci 4.0.545; lockfile npm tetap digunakan. Tooling ini tidak dikemas ke APK. Tidak memasang CUDA, mengubah registry/pengaturan GPU Windows, atau memakai cloud render. Penggunaan RTX diperiksa dari renderer WebGL browser yang **sama** dengan browser render; gagal jika bukan RTX 3050. Probe NVENC harus lulus sebelum render penuh. Tidak ada klaim GPU selalu lebih cepat untuk semua proyek 2D.

Hasil utama:

- `docs/design/v1.2.1/intro/papercut-intro-qhd.mp4`: master NVENC QHD+.
- `assets/intro/papercut-mark-hd.png`: raster akhir GPU, alpha, 1080 × 1080.
- `assets/intro/remotion-motion.json`: 96 frame × 30 fps, total 3.200 ms, kurva mark/title/subtitle.
- `docs/design/v1.2.1/intro/{gpu-render,asset-metadata,qa}.json`: bukti GPU, provenance, frame QA.
- `docs/design/v1.2.1/intro/flutter-*.png`: screenshot Flutter berbagai rasio/tema/DPR; bukan foto HP.

`src/index.tsx` memiliki `Intro` untuk master dan `IntroMark` untuk frame alpha. `render-hd.mjs` membundel, membuka renderer GPU terverifikasi, merender frame/master, lalu `export-native.mjs` mengekspor PNG dan kurva. `qa-hd.mjs` memeriksa seluruh 96 frame video final, 96 debug frame, transparansi sudut 96 frame mark, safe area teks dan kecocokan PNG dengan frame GPU. Contact sheet dan frame ukuran penuh tetap ditinjau visual. Uji Flutter membandingkan pixel sudut logo dengan PaperBackdrop tanpa intro agar persegi latar yang berbeda terdeteksi.

`encode-webp.mjs` merupakan ekspor lossless opsional ke `out/hd/`, **tidak dipakai APK**. Bukti/MP4 1.2.0 tetap diarsipkan di folder versi sebelumnya. QA Node menggantikan CLI inline-props/Python yang tidak tersedia pada lingkungan ini; tidak mengklaim OCR atau pengujian playback Android fisik.

Referensi: [Remotion Chromium flags](https://www.remotion.dev/docs/options/chromium-flags), [hardware acceleration](https://www.remotion.dev/docs/options/hardware-acceleration), [encoding](https://www.remotion.dev/docs/encoding/). `src/debug.tsx` diadaptasi dari scaffold Motioncraft berlisensi MIT.
