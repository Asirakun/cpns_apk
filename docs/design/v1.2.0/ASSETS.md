# Aset papercut 1.2.0

Permintaan pemilik: ikon sesuai fungsi, tanpa pengulangan gambar tanaman untuk menu yang berbeda; pertahankan ilustrasi dan tema dark blue yang disukai, tambahkan identitas aplikasi dan intro Remotion.

Tiga hasil generasi raster dibuat dengan tool imagegen: atlas awal, edit pembersihan atlas, dan logo. Bukan unduhan ikon pihak ketiga. Semua memakai warna navy/denim/biru muda/ivory/kuning, lapisan kertas matte, bayangan potongan kertas dan latar transparan. Generasi tidak diminta memakai logo instansi/pemerintah.

Ringkasan instruksi atlas: 20 simbol tunggal terpisah dalam grid 5 kolom × 4 baris, jarak aman antar sel, tanpa teks atau label, gaya konsisten dengan elemen aplikasi. Urutan dan penggunaan:

| Baris | Kolom 1 | Kolom 2 | Kolom 3 | Kolom 4 | Kolom 5 |
| --- | --- | --- | --- | --- | --- |
| 1 | cloudSync · akun/sinkronisasi | backup · ekspor | privacy · privasi | sources · referensi | settings · pengaturan |
| 2 | formation · formasi | announcements · pengumuman | results · hasil/sanggah | briefcase · SKB | wallet · anggaran |
| 3 | analytics · analisis | review · tinjauan belajar | logout · keluar | search · cari | download · unduh |
| 4 | device · simpan lokal | moon · jam tenang | help · bantuan | plan · rencana | verified · verifikasi |

Edit pembersihan menghapus serbuk/halo dekoratif di sekitar simbol agar potongan jelas pada kartu aplikasi. `function-icons-atlas.png` menyimpan hasil awal; **`function-icons-atlas-clean.png` adalah sumber potongan yang dipakai**. `scripts/prepare_papercut_v12.ps1` memotong masing-masing sel, menghitung batas alpha, mempertahankan pixel transparan, lalu menyesuaikan ke PNG 256 × 256. Atlas utuh tidak dimasukkan ke APK.

Ringkasan instruksi logo: satu buku terbuka ivory dengan lapisan biru, jalan navy berkelok menuju satu bendera emas, bahan papercut, tanpa huruf, tanpa bingkai, latar transparan. `logo-source.png` menjadi `assets/brand/logo.png` dan launcher Android lima density, termasuk foreground adaptive. Background launcher/splash navy `#0A263E`.

Adaptive launcher juga menyediakan layer monochrome dari alpha foreground untuk pilihan themed icon. Susunan resource mengikuti [panduan ikon Android](https://developer.android.com/codelabs/basic-android-kotlin-compose-training-change-app-icon); tampilan pada launcher/vendor HP nyata belum diuji.

Ke-16 ikon original di `assets/papercut/` dan kedua ilustrasi Beranda di `assets/papercut_home/` dipertahankan. Ikon boleh berulang untuk makna yang sama (misalnya kalender untuk agenda/target), sementara kontrol tanpa pemetaan memakai ikon Material yang sesuai, tanpa fallback tanaman. Logo buku/path merupakan identitas merek sehingga juga dipakai pada header, launcher dan replay intro.

Intro: [video](intro/papercut-intro.mp4), [still](intro/intro-still.png), [QA](intro/qa.json), dan [source/panduan render](../../../tools/papercut_intro/README.md). MP4 pratinjau tidak dikemas ke APK; aplikasi memakai WebP offline sekitar 243 KiB.
