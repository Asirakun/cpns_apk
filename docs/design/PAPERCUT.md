# Papercut dark blue

## Navbar kapsul 1.2.3

Bentuk floating capsule sesuai referensi, lima ikon lama dan tema aplikasi dipertahankan. [Beranda](screenshots/v1.2.3/home.png), [Profil](screenshots/v1.2.3/profile.png), [Tryout](screenshots/v1.2.3/tryouts.png), [laporan/tes](../NAVBAR_V1_2_3.md). Intro SFX versi sebelumnya tetap digunakan.

## Intro dengan SFX 1.2.2

[Pratinjau dengan suara](v1.2.2/intro/provided-intro-with-sfx.mp4), [screenshot Flutter](v1.2.2/intro/flutter-dark-20x9.png), [laporan perubahan/tes](../INTRO_SFX_V1_2_2.md). Memakai source cpns-intro yang disediakan pemilik, tanpa gradient/rings/glow latarnya dan tanpa tombol Lewati. Halaman/ikon aplikasi lainnya dipertahankan; bagian berikut adalah arsip versi sebelumnya.

## Intro HD 1.2.1

[Video QHD+ RTX/NVENC](v1.2.1/intro/papercut-intro-qhd.mp4), [screenshot Flutter](v1.2.1/intro/flutter-dark-20x9.png), [laporan](../INTRO_HD_V1_2_1.md). Intro memakai latar asli aplikasi dan teks native, PNG transparan 1080 px dari render GPU, serta kurva Remotion. Bagian di bawah adalah arsip desain 1.2.0/1.1.0.

## Pembaruan UI 1.2.0

Mengikuti permintaan terbaru pemilik, ilustrasi Beranda dan 16 ikon original tetap dipakai. Ditambahkan 20 ikon fungsi agar Profil/menu lain tidak memakai tanaman untuk fungsi berbeda, logo buku/jalan/bendera, kartu persiapan 3–3–1, tab Soal/Riwayat dengan pencarian/filter, kartu prioritas bernomor, analisis lebih ringkas, serta jawaban/navigator hijau.

Intro Remotion 3,2 detik tanpa suara diputar offline sekali, dapat dilewati, dan bisa diputar ulang lewat Profil. Launcher/splash memakai logo baru. [Laporan file/pengujian](../UPGRADE_UI_V1_2.md) dan [provenance aset](v1.2.0/ASSETS.md).

- [Ringkasan enam tampilan](screenshots/v1.2.0/overview.png)
- [Profil](screenshots/v1.2.0/profile-icons.png), [pusat persiapan](screenshots/v1.2.0/preparation.png), [Soal](screenshots/v1.2.0/tryouts.png), [Riwayat](screenshots/v1.2.0/history.png)
- [Prioritas](screenshots/v1.2.0/priorities.png), [harian](screenshots/v1.2.0/daily.png), [mingguan](screenshots/v1.2.0/weekly.png), [bulanan](screenshots/v1.2.0/monthly.png), [navigator](screenshots/v1.2.0/navigator.png)
- [Video intro](v1.2.0/intro/papercut-intro.mp4), [frame QA](v1.2.0/intro/qa-contact-sheet.png)

Ke-13 screenshot merupakan render Flutter memakai font/aset aplikasi dengan **DATA UJI**, bukan pengujian HP. Reproduksi terbaru: `powershell -ExecutionPolicy Bypass -File scripts/capture_design_previews.ps1`. Capture tidak membuka database pengguna; PNG versi 1.0.2/1.1.0 dipertahankan sebagai arsip. Bagian selanjutnya mencatat keputusan desain pada versi terdahulu.

## Pembaruan chart 1.1.0 — desain lama dipulihkan

Arahan terakhir pemilik: kembalikan UI dan ikon sebelumnya, hanya tambahkan chart. Tema, widget bersama, pemetaan ikon dan Journey dipulihkan dari checkpoint sebelum upgrade; 16 ikon dan 2 ilustrasi tetap identik byte demi byte. Screenshot Beranda baru identik SHA-256 dengan `v1.0.2/01-beranda.png`: `112d960f963fe3efeadac2ce7a3fe35b7c28bdfaaf7c849537a693c51dfb9f5e`.

Pintasan **Analisis performa** membuka halaman grafik tambahan. Tidak ada tab keenam, hero baru, penggantian ikon atau compact layout pada layar existing. Grafik Harian 7/14 hari, Mingguan 8/12 minggu dan Bulanan 6/12 bulan memakai warna dan kartu tema lama, dengan filter kategori serta pemisahan nilai CAT per blueprint.

Screenshot render Flutter 390×900 dp (PNG 780×1800); `light-large` 430×900 dp dengan font 1,3×. Beranda kosong memakai state awal asli. Screenshot lainnya memakai fixture terisolasi dan diberi label **DATA UJI • bukan riwayat pengguna**. Ini render engine Flutter dengan font/aset asli, bukan foto perangkat/emulator.

- [Beranda yang dipulihkan](screenshots/v1.1.0/home-empty.png)
- [Harian](screenshots/v1.1.0/daily.png), [Mingguan](screenshots/v1.1.0/weekly.png), [Bulanan](screenshots/v1.1.0/monthly.png)
- [Detail TKP](screenshots/v1.1.0/category.png), [terang/font 1,3×](screenshots/v1.1.0/light-large.png)
- [Belajar](screenshots/v1.1.0/learn.png), [Tryout](screenshots/v1.1.0/tryouts.png), [Journey](screenshots/v1.1.0/journey.png), [Profil](screenshots/v1.1.0/profile.png)

Reproduksi: `powershell -ExecutionPolicy Bypass -File scripts/capture_design_previews.ps1`. Renderer menggunakan MemoryStore dan tidak membuka database pengguna atau Supabase. Atlas 25 ikon yang sempat dibuat untuk desain compact yang dibatalkan diarsipkan di `work/rejected-compact-ui/`, bukan aset aplikasi.

## Desain dan aset existing

Perubahan desain 21 November 2026. Tema utama: navy gelap, biru berlapis, kertas krem dan kuning hangat. Setelah referensi tambahan dari pemilik, Beranda memakai ilustrasi peserta CPNS/gedung, panel biru dengan potongan kertas bergelombang, statistik aktivitas, fokus belajar bertombol kuning dan progres per domain. Sudut membulat sedikit asimetris, dengan lapisan di bawahnya dan bayangan lembut. Font lokal Plus Jakarta Sans tetap digunakan.

Tema gelap menjadi default untuk data pengguna baru. Pilihan terang/gelap/sistem dan preferensi yang sudah tersimpan tetap tersedia. Payload progres, CAT, sinkronisasi dan perlindungan keamanan sebelumnya dipertahankan.

## Ikon

Ikon dibuat memakai **built-in imagegen**, satu generasi atlas lalu satu edit untuk merapikan alpha. Tidak memakai API/CLI fallback. Atlas yang dipilih: [papercut-icon-atlas-clean.png](papercut-icon-atlas-clean.png). Versi generasi pertama juga disimpan sebagai referensi: [papercut-icon-atlas.png](papercut-icon-atlas.png).

Atlas final berukuran 1280 × 1280 piksel, terdiri atas 4 × 4 sel. `scripts/crop_papercut_icons.ps1` memotongnya menjadi 16 PNG 320 × 320 di `assets/papercut/`, dengan alpha dipertahankan. Objek tidak digambar ulang oleh skrip pemotong.

| Baris | Kolom 1 | Kolom 2 | Kolom 3 | Kolom 4 |
| --- | --- | --- | --- | --- |
| 1 | book | checklist | route | home |
| 2 | target | graduation | documents | calendar |
| 3 | bell | medal | sprout | flashcards |
| 4 | avatar | shield | clock | balloon |

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/crop_papercut_icons.ps1 -AtlasPath docs/design/papercut-icon-atlas-clean.png
```

### Prompt generasi

```text
Use case: stylized-concept. Asset type: ONE production sprite atlas for a dark navy Indonesian CPNS study app, for deterministic cropping into 16 separate icons. Generate a square 2048 x 2048 PNG with a genuinely TRANSPARENT alpha background. The composition is an EXACT evenly spaced 4 columns by 4 rows grid of 16 separate icons. Each icon is centered inside its own equal 512 x 512 cell. Each object fits within the central 350 x 350 area of its cell, generous transparent gutters, nothing overlaps cell boundaries. No visible grid, no labels, no letters, no numerals, no text, no logos, no watermark. All sixteen icons have the same hand-cut layered cardstock / papercraft illustration style: clean playful cut-paper silhouettes, 4 to 6 stacked paper layers, visible paper edge thickness, delicate matte paper texture, soft lower-right cast shadows, orthographic slightly tilted front view, crisp readable silhouette at small mobile UI sizes. Palette exclusively midnight navy #101E39, slate blue #274C78, medium blue #4D8EC6, pale sky blue #B9DDF3, warm ivory #FFF2D8, and small honey yellow #F4C76B accents. Favor ivory and pale blue top faces so these icons read beautifully against dark navy app cards; use dark navy for thin edges and depth. Exact row-major subjects: ROW 1: (1) open study book with a little honey bookmark, (2) clipboard with checked boxes and a pencil, (3) winding journey path rising to a small flag, (4) a miniature cozy home with navy roof. ROW 2: (5) a bullseye target with one arrow, (6) a small graduation cap with honey tassel, (7) a stack of official paper documents with one seal, (8) a desk calendar with a blank blue page and small checkmark. ROW 3: (9) a compact ringing notification bell, (10) a gold star medal with blue ribbon, (11) a small potted sprout, (12) two overlapping flashcards with a tiny star. ROW 4: (13) one friendly personal profile/avatar bust on a circular paper disc, (14) a simple shield with one checkmark, (15) a small clock with simple hands but no numbers, (16) a cheerful paper-cut hot air balloon with blue and ivory striped canopy and honey basket. Each icon must be a SINGLE coherent illustrated object, not multiple repeated alternatives. Real transparent background, preserve all alpha and subtle cast shadows.
```

### Prompt edit atlas terpilih

```text
Edit target: this exact 4 by 4 sprite atlas of 16 layered paper-cut icons. Preserve every icon, its order, its object design, its colors, and its clean cut-paper style. Make ONE change: produce clean, professionally isolated transparent-background silhouettes. Remove all stray colored pixels, white background flecks, noisy white/cyan fringes and residual background around every object, including the balloon, avatar, book and documents. Keep only the physical cardstock object and a very subtle clean semi-transparent shadow immediately beside it. The true transparent background must have zero RGB/alpha noise in the gutters. Preserve real fully opaque ivory paper inside the objects. Each of the 16 objects must be cleanly separated, centered in exactly the same regular four-column four-row grid, and fit within its cell with at least 20 transparent pixels of padding at each side. No text, no labels, no grid lines, no new objects. High-quality crisp alpha edges with modest antialiasing, no halo, no fuzz, no splatter. Real transparent PNG alpha background.
```

Ukuran 2048 diminta dalam prompt; generator mengembalikan 1280. Skrip memotong berdasarkan dimensi file aktual. Ikon utama memakai atlas; ikon kontrol kecil seperti pencarian, kembali, dan checkbox tetap memakai glyph Material agar terbaca pada ukuran kecil.

## Ilustrasi Beranda dari referensi pemilik

Pemilik memberikan screenshot papercut biru dengan peserta CPNS, gedung, bendera, clipboard dan tombol kuning. Referensi dipakai untuk arah visual; UI tetap widget Flutter yang dapat digunakan.

Satu generasi **built-in imagegen** tambahan menghasilkan [atlas dua ilustrasi](home-illustrations-atlas.png). Bagian kiri dipotong menjadi `assets/papercut_home/welcome.png` dan bagian kanan menjadi `assets/papercut_home/focus.png`. Skrip membatasi crop ke sel masing-masing dan memangkas margin transparan berdasarkan alpha, tanpa menggambar ulang isi.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/crop_home_illustrations.ps1 -AtlasPath docs/design/home-illustrations-atlas.png
```

### Prompt ilustrasi Beranda

```text
Use the attached mobile screenshot ONLY as a visual style reference for dark-blue layered papercut illustrations. Generate a NEW asset sheet, NOT a screenshot or user interface. ONE wide landscape transparent PNG, approximately 2:1 aspect ratio, divided into exactly TWO equally sized side-by-side cells. Each cell contains one coherent large papercraft illustration cluster, centered with a generous transparent margin so the two cells can be cropped separately. No text, no letters, no numbers, no UI panels, no borders or divider, no watermark. Material/style: polished tactile cut-paper / layered cardstock with rounded silhouettes, several navy and cobalt paper layers, slightly raised ivory top faces, soft cast shadows to lower right, subtle paper grain, friendly and professional. Colors deep midnight navy #082440, rich blue #176098, sky blue #86C8ED, ivory #FFF4DC and cheerful yellow #FFC644. LEFT CELL: a friendly smiling young adult Indonesian male CPNS aspirant, with neatly combed dark hair, wearing a bright blue blazer over an ivory shirt, holding a honey-yellow folder against his chest, with his other hand raised in a welcoming wave. Behind him to the right stands a small generic Indonesian civic office building with white columns and a blue triangular roof, with a small Indonesian flag, RED upper band and WHITE lower band, on its roof. Add two small ivory paper clouds and blue/teal paper shrub silhouettes at the base. Compose as one compact horizontal cluster, face and office building both clearly readable at 180px wide; no official logos or emblems. RIGHT CELL: one large cheerful ivory-and-sky-blue clipboard, slightly tilted clockwise, with three dark blue checkmarks and short blank blue strokes instead of text; a chunky yellow pencil diagonally against its right edge; two little yellow celebration rays near the top and two offset blue paper sheets underneath. Crisp recognizable silhouette at mobile size. These two assets will appear on dark blue cards: use clean real transparency with no white matte, no scattered pixels or colored fringe, preserve clean antialiased alpha edges and close soft shadows. Keep every object inside its own half of the sheet, do not overlap the middle gutter.
```

Target menit memakai preferensi pengguna, statistik hari dihitung dari riwayat belajar, dan progres TWK/TIU/TKP dihitung dari posisi materi serta materi yang selesai. Angka contoh pada referensi tidak disalin sebagai progres fiktif. Statistik yang tampil pada screenshot adalah keadaan awal (0 hari, 0/7, 0%). Untuk pengguna lama dengan mode sistem/terang, tema gelap dapat dipilih melalui Profil → Tampilan → Gelap.

## Screenshot

Screenshot diambil langsung dari render widget Flutter ukuran **390 × 900 logical pixels**, diekspor pada skala 2× menjadi PNG 780 × 1800. Font aplikasi, ikon hasil generasi, dan bayangan asli dimuat sebelum capture. Ini adalah UI aplikasi yang diimplementasikan, dengan data mode perangkat awal/progres kosong; bukan mockup AI atau screenshot dari ponsel fisik.

Browser lokal gagal tersambung pada sesi ini, sehingga capture dilakukan melalui Flutter test renderer. Masing-masing layar dirender terpisah supaya layer yang tersimpan pada render sebelumnya tidak memengaruhi screenshot berikutnya.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/capture_design_previews.ps1
```

- [Beranda](screenshots/v1.0.2/01-beranda.png)
- [Belajar](screenshots/v1.0.2/02-belajar.png)
- [Tryout](screenshots/v1.0.2/03-tryout.png)
- [Journey](screenshots/v1.0.2/04-journey.png)
- [Profil](screenshots/v1.0.2/05-profil.png)
- [Onboarding](screenshots/v1.0.2/06-onboarding.png)

Pemeriksaan responsif juga memakai tes widget 360 dan 430 dp dengan skala teks 1,3×. APK pembaruan menggunakan identitas release privat yang sama; versi dinaikkan menjadi 1.0.2+3.
