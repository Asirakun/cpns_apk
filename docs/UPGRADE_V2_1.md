# Upgrade PRD v2.1 — aplikasi existing

Tanggal kerja: 21 November 2026 (WIB). Spesifikasi: `PRD_CPNS_Journey_Android_v2.1_Upgrade_Tanpa_Buat_Ulang.docx`, khususnya addendum A1–A7. **Arahan pengguna terbaru beserta screenshot acuan mempertahankan Beranda papercut bergambar peserta CPNS/gedung, kartu biru bergelombang, tombol kuning, dan ikon lama; perubahan UI dibatasi pada penambahan chart lewat Analisis performa.** Arahan tersebut menggantikan spesifikasi compact layout dan regenerasi ikon. Isi dokumen dipakai sebagai spesifikasi produk; perintah contoh di A8 tidak dijalankan sebagai perintah shell.

## Tahap 0 — audit sebelum perubahan

- Baseline aplikasi 1.0.2+3; branch `feat/prd-v2.1-analytics`. Perubahan keamanan/desain yang sudah ada tetap dipertahankan. Checkpoint lengkap 137 file, manifest SHA-256, status dan patch awal tersimpan lokal di `work/baseline-prd-v2.1/` (diabaikan Git); tidak membuat commit berisi perubahan lama tanpa memeriksanya.
- `lib/main.dart`: Riverpod ChangeNotifier + go_router, lima tab dan route reader/CAT/hasil/detail Journey. Tidak ada halaman Analisis.
- `lib/core/models.dart`: payload `schema_version: 1`, attempt menyimpan snapshot soal, opsi berbobot, jawaban final, blueprint dan deadline. Skor historis dihitung deterministik. `study_days` hanya tanggal aktivitas, bukan durasi.
- `lib/core/controller.dart`: namespace guest/per akun, antrean write, outbox UUID, retry dan konflik versi eksplisit. `startAttempt`, `answer`, `submit`, bookmark, completion dan cache paket harus tetap kompatibel.
- `lib/core/local_store_native.dart`: database **cpns_journey** yang sama, tabel `local_state` dan `outbox`; snapshot AES-GCM per namespace. Schema SQLite 1. Tidak perlu membuat database atau mengubah tabel untuk field payload tambahan.
- `supabase/migrations/202611200001_initial.sql` sampai `003_security_hardening.sql`: RLS, `user_snapshots(payload,version)`, RPC `sync_user_state`; schema payload 1, submitted attempt immutable, operasi idempotent. Payload menerima field tambahan, sehingga analitik dapat ditambahkan kompatibel. Konflik snapshot tidak boleh menimpa sesi lintas perangkat secara diam-diam.
- Beranda memanjang; grafik `ScoreChart` mencampur persentase berbagai latihan. Durasi aktif, sejarah target, dan elapsed per soal belum dicatat. Tidak akan mengisi durasi lama atau kecepatan dengan estimasi.
- Fitur existing mencakup login/reset, 450 soal/3 CAT, materi, bookmark, flashcard, paket offline, S00–S11, dokumen metadata, jadwal, formasi/sumber, SKB, anggaran, ekspor dan penghapusan. Semuanya harus tetap dapat dicapai.

Baseline: `flutter analyze --no-pub` bersih; `flutter test --no-pub --concurrency=1`: **33 lulus, 1 screenshot opt-in dilewati**. Tidak ada perangkat Android terhubung; tes perangkat dan Supabase hosted tidak dinyatakan lulus.

## Rencana bertahap

1. UI existing: pulihkan tema, kartu, ikon, ilustrasi dan kelima tab dari checkpoint awal; ubah tujuan pintasan Analisis ke halaman chart tambahan. Compact UI tidak menjadi scope akhir sesuai koreksi pengguna.
2. Analytics lokal: Harian 7/14, Mingguan 8/12, Bulanan 6/12, kategori dan mode, metrik dari snapshot asli, blueprint sejenis, tabel alternatif dan empty/unknown state.
3. Instrumentasi additive: field payload opsional untuk sesi UUID, cakupan pencatatan dan target efektif; timer foreground/idle 120 detik, checkpoint periodik, UTC/WIB, deduplikasi. Tidak mengubah snapshot attempt yang submitted.
4. Detail chart: kualitas topik dari jawaban final dengan label sampel kurang dari 10, CAT per blueprint, sumber/rumus dan tabel alternatif. Pengaturan target, review, rekomendasi, logout dan halaman existing mempertahankan alur sebelumnya.
5. Regresi AC01–AC14, keamanan/RLS, render screenshot 360/430dp dark/light 1.3×, build ulang signed APK dengan kunci existing. Hasil aktual dan perubahan per file ditambahkan di bawah setelah verifikasi.

## Status implementasi dan hasil akhir

UI acuan sudah dipulihkan. Beranda hasil render identik SHA-256 dengan screenshot versi 1.0.2; seluruh 18 aset ikon/ilustrasi existing identik dengan checkpoint. Halaman chart memakai gaya kartu/warna lama, diakses melalui pintasan existing dan tombol Lihat Analisis pada bagian perkembangan latihan.

Hasil akhir: analyze bersih, **55 tes Flutter lulus / 2 capture opt-in dilewati**, **33 pemeriksaan SQL/RLS lulus**, dan **11 screenshot berhasil dirender**. CAT 110 soal diuji lewat UI sampai hasil 550; analisis tidak mengubah snapshot jawaban/nilai. Android Lint **0 error / 7 warning**, OSV mencocokkan **234 dependency tanpa advisori aktif yang cocok**, serta **42 pemeriksaan APK lulus** dengan sertifikat release existing.

APK **1.1.0+4** (ARM64 split `versionCode=2004`), **27.226.148 byte (26,0 MiB)**, Android 7.0+ / target SDK 36:

- `build/releases/cpns-journey-1.1.0-arm64-v8a.apk` (salinan bernama versi untuk penyerahan).
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (output Flutter).
- SHA-256: `4bb65189a54772ef3d60f0f77395aaf7917ebf47508f7694a75478a166adcd26`.
- APK lama 1.0.2 disimpan sebagai referensi di `build/releases/cpns-journey-1.0.2-arm64-v8a.apk`. Kunci signing privat tidak diubah, disalin ke repository atau ditampilkan. Update 1.0.2 → 1.1.0 menggunakan signer yang sama; jangan uninstall atau membersihkan data untuk memasang pembaruan.

Log full suite di `work/release-1.1.0.log`; tahap build/lint/audit/APK dilanjutkan melalui `work/finish-release-1.1.0.ps1` dengan log `work/release-1.1.0-finish.log`. Pengalihan stderr PowerShell awal memperlakukan warning KGP plugin sebagai error; log akhir memakai redirection cmd tanpa menyembunyikan exit code. Peringatan kompatibilitas plugin/font yang sudah ada tidak menghalangi build; final APK dan resource diverifikasi. Bukti mesin terkini berada di `docs/security/`, bukti 1.0.2 disimpan dengan suffix versi.

| Skenario | Bukti lokal / batas |
| --- | --- |
| AC01 akun/data lama | Migrasi field opsional idempotent, JSON lama tidak berubah, encrypted cold reopen serta outbox tetap utuh; bukan akses data produksi pengguna |
| AC02 compact | Digantikan arahan screenshot pengguna: desain lama dipertahankan dan diverifikasi identik, tidak menerapkan compact layout |
| AC03 aksesibilitas | Lima tab lama 360/430dp dark 1,3×; chart 360×800 dark/light 1,3×; render Beranda 430dp light 1,3× |
| AC04–AC06 rumus | Unknown berbeda dari nol, total chart = ringkasan, pembagian sesi WIB/Senin/akhir bulan, akurasi dan kualitas TKP terpisah |
| AC07 retry | Duplikasi attempt/soal/sesi tidak menambah angka; SQL sync 3× tetap sekali, konflik immutable ditolak |
| AC08–AC09 histori minim | Empty CTA bekerja; skor lama tanpa durasi tetap tersedia, waktu tidak diperkirakan |
| AC10 idle/background | Clock monoton diuji dengan idle 120 detik/background dan perubahan jam; observer route/lifecycle dipasang. Perangkat nyata belum diuji |
| AC11 isolasi | Namespace A/B/guest, respons akun lama terlambat, dan sesi beda generasi terisolasi; autentikasi hosted belum diuji |
| AC12 offline/sync | SQLite terenkripsi dibuka ulang dengan data dan outbox utuh, agregasi lokal tanpa jaringan; PGlite menguji reconcile UUID. Belum uji mode pesawat Android nyata |
| AC13 kontrol | Pintasan chart, periode/rentang/kategori, mode nilai CAT dan tabel data diuji; CTA lama dipertahankan |
| AC14 regresi | 110 jawaban CAT melalui widget, 550 terverifikasi, hasil immutable, lima tab, dokumen/cycle/model, sumber/enkripsi/network tests existing lulus. Login/email/reset dan notifikasi perangkat tetap perlu lingkungan pemilik |

Screenshot berada di `docs/design/screenshots/v1.1.0/`; render Flutter asli dengan font/gambar aplikasi. Grafik yang berisi fixture diberi label DATA UJI; tidak dimasukkan ke akun pengguna. Lihat `docs/design/PAPERCUT.md` untuk seluruh tautan.

## Perubahan kode dan verifikasinya

| File | Perubahan akhir | Pengujian terkait |
| --- | --- | --- |
| `lib/core/analytics.dart` | Read model lokal; agregasi WIB harian/mingguan/bulanan, final answer unik, akurasi/TKP, cakupan waktu, target efektif, cohort CAT, merge UUID | 17 tes agregasi, widget chart |
| `lib/core/study_clock.dart` | Durasi monoton foreground dan idle 120 detik | AC10 idle/background/perubahan jam |
| `lib/app/study_activity.dart` | Hook reader/player; lifecycle, route, checkpoint dan perlindungan generasi akun; penulisan di luar fase build | CAT 110 soal, timer unit, isolasi akun |
| `lib/core/controller.dart` | Migrasi field opsional, cache read model, pencatatan sesi/target, cek kemampuan migrasi cloud dan reconcile analitik | Migrasi/cold reopen, A/B/guest, outbox/retry, SQL |
| `lib/features/analytics.dart` | Halaman chart tambahan dengan periode/rentang/filter, CAT sejenis, tabel dan keterangan sumber; tema lama | Widget 360dp dark/light 1,3×, screenshot |
| `lib/features/analytics_charts.dart` | Bar/stacked bar/line, tooltip, legenda, alternatif tabel, nilai CAT per attempt/per bulan | Widget chart, rumus, screenshot |
| `lib/features/home.dart` | Dua tujuan tautan ke Analisis; susunan/ilustrasi/kartu/ikon tetap | Screenshot Beranda identik baseline; uji pintasan |
| `lib/main.dart` | Route Analisis dan observer waktu belajar; navigation shell lama tetap | Lima tab dan route chart/CAT |
| `lib/features/learn.dart` | Wrapper pencatatan waktu materi/flashcard; UI lama tetap | Regresi lima tab, pembacaan/kontroller existing |
| `lib/features/tryout.dart` | Wrapper pencatatan waktu saat soal tampil; timer, hasil, review dan katalog lama tetap | CAT 110 jawaban → 550, deadline/immutable tests |
| `lib/features/profile.dart` | Penyimpanan pengaturan target existing menambah riwayat target efektif; UI lama tetap | Pengaturan/controller/riwayat target |
| `lib/core/app_version.dart`, `pubspec.yaml` | Versi 1.1.0+4; dependency dan aset lama dipertahankan | Version contract, lockfile, APK |
| `supabase/migrations/202611210001_analytics_additive.sql` | Trigger/fungsi additive pada snapshot existing; merge immutable UUID dan capability check, tanpa tabel baru | 33 pemeriksaan PGlite/SQL/RLS |
| `supabase/tests/security.mjs` | Migrasi di atas snapshot lama, session retry/merge, rollback/collision, client lama dan permission capability | Seluruh 33 lulus |
| `test/analytics_aggregation_test.dart` | 17 tes rumus, kompatibilitas, waktu, isolasi dan recovery | Flutter test |
| `test/analytics_ui_test.dart` | Kontrol chart, empty CTA dan pintasan pada desain lama | Flutter widget test |
| `test/cat_flow_test.dart` | CAT penuh melalui UI sampai hasil dan chart, snapshot tetap | 110 soal, total 550 |
| `test/support/analytics_fixture.dart` | Data uji terisolasi; bukan seed akun nyata | Tes/preview saja, tidak dibundel aplikasi |
| `test/analytics_preview_test.dart` | Screenshot opt-in memakai renderer/font/aset asli, label DATA UJI pada fixture | 11 render terpisah |
| `test/security_test.dart` | Ekspektasi minimum versi mengikuti 1.1.0 | Security/version contract |
| `scripts/capture_design_previews.ps1` | Reproduksi screenshot baru dan chart pada MemoryStore | 11 render lulus |

Tema (`lib/app/theme.dart`), widget umum (`lib/app/widgets.dart`), ikon (`lib/app/paper.dart`), Journey (`lib/features/journey.dart`), tes dasar dan semua aset lama yang sempat terkena refactor dipulihkan. Tidak ada perubahan akhir pada file-file tersebut dibanding checkpoint awal. File desain/source keamanan yang sudah berubah sebelum tugas ini tidak dihitung sebagai perubahan upgrade.

Daftar lengkap **47 file ditambah/diubah, 0 file existing dihapus**, termasuk setiap dokumentasi, bukti mesin dan PNG beserta SHA-256 sebelum/sesudah, tersedia dalam [UPGRADE_V2_1_FILES.json](UPGRADE_V2_1_FILES.json). Pemeriksaan tambahan 17 tes agregasi setelah build juga lulus, termasuk penolakan callback dari generasi akun lama ketika akun yang sama dibuka kembali. Tidak ada commit/push atau deployment cloud yang dilakukan.

## Kompatibilitas dan penerapan cloud

- Tidak membuat aplikasi/database/proyek Supabase baru. Nama database SQLite, schema SQLite 1, payload `schema_version: 1`, applicationId, kunci enkripsi dan sertifikat signing dipertahankan.
- Field opsional `analytics` berisi versi, awal pencatatan, interval aktivitas UUID dan perubahan target efektif. Migrasi baca-tulis tidak mengubah raw attempt, jawaban, skor, berkas, cycle, bookmark atau preferensi lama. Durasi sebelum pencatatan tidak diisi perkiraan.
- `202611210001_analytics_additive.sql` menambahkan fungsi dan trigger pada `user_snapshots` existing; tidak menulis ulang data saat migrasi, membuat tabel, menghapus atau mereset data. Trigger menggabungkan interval/target immutable dengan UUID, menolak benturan isi, dan mempertahankan catatan baru ketika payload dari client lama dikirim. Konflik versi dan validasi submitted attempt pada RPC existing tetap berjalan.
- Aplikasi memeriksa `analytics_capabilities` sebelum menyinkron. Pada proyek cloud existing, terapkan migration baru **setelah** 001–003 dengan alur deployment pemilik. Tidak ada koneksi/kredensial proyek hosted yang dipakai dalam pekerjaan ini, sehingga penerapan produksi tidak diklaim selesai. Tanpa migrasi, data lokal dan chart tetap tersedia; UI menjelaskan bahwa sinkron memerlukan migrasi.
- Sesudah sync, hanya field analitik direkonsiliasi dari server dengan catatan lokal yang mungkin muncul ketika request berjalan. UUID menjaga retry tetap satu kali. Mengambil data cloud saat menyelesaikan konflik juga mempertahankan interval lokal.
- Hook reader/CAT/flashcard hanya mencatat aktivitas; susunan dan kontrol layar lama dipulihkan. Durasi memakai clock monoton, berhenti saat route tertutup/background dan idle 120 detik. Checkpoint tiap 15 detik; penulisan terakhir yang belum selesai dapat hilang saat force-stop. Deadline CAT tetap memakai mekanisme existing.
- Timestamp UTC, hari kalender WIB, minggu mulai Senin. Akurasi TWK/TIU terpisah dari kualitas skor TKP. Blueprint CAT yang berbeda tidak dicampur. Data waktu unknown berbeda dari nol; perbandingan nol tidak dibagi nol. Kecepatan per soal tidak ditampilkan karena belum ada elapsed_ms.
- File tema, widget bersama, pemetaan ikon dan halaman Journey dipulihkan identik SHA-256 terhadap baseline. Semua 16 ikon lama dan kedua ilustrasi lama tetap digunakan. Atlas baru dan UI compact yang dibatalkan dipindahkan ke `work/rejected-compact-ui/` yang diabaikan Git, dan tidak dimasukkan ke APK.
- Fitur rekomendasi/target baru, menu sesi baru dan refactor compact tidak diaktifkan sesuai arahan terakhir. Pengaturan target yang sudah ada tetap tampil sama; penyimpanannya juga mencatat target efektif untuk chart.
