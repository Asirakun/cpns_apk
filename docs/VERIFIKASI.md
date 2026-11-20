# Verifikasi dan status distribusi

Aplikasi disusun berdasarkan PRD v2 dan checklist pengguna. Ini adalah implementasi awal; kriteria rilis publik yang membutuhkan akun produksi, peninjau materi manusia dan perangkat fisik tidak dianggap selesai hanya karena kode/tes lokal lulus.

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

Build web release lokal berhasil. Build Android ARM64 release telah dicoba dengan JDK 21 dan SDK 35/36, cache serta mirror Maven, tetapi belum berhasil melewati unduhan dependensi (HTTP 503). APK signed, pengukuran performa Android dan pengujian dua perangkat belum dapat dinyatakan lulus.

Source disiapkan untuk dilanjutkan melalui repositori GitHub dan VS Code. Build/cache lokal, konfigurasi SDK mesin, kredensial, serta private signing key tidak disertakan. Panduan Windows pada drive D tersedia di `docs/LANJUTKAN_DI_CODEX.md`.
