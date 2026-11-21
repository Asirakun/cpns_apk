# Pemeriksaan keamanan CPNS Journey

## Navbar kapsul 1.2.3 — terbaru

APK **1.2.3**, 29.2 MiB, signed dengan kunci release existing. 70 tes Flutter, 33 SQL, 42 pemeriksaan APK dan 118 aset lulus. Lint 0 error / 7 warning. Audit OSV tidak menemukan advisori aktif yang cocok pada dependensi terkunci.

[Laporan setiap file, tes dan screenshot](NAVBAR_V1_2_3.md). Ikon lama tetap dipakai; APK sudah memuat intro dengan SFX tanpa Lewati. Bagian selanjutnya adalah arsip versi sebelumnya.

## Intro dengan SFX 1.2.2 — arsip

APK **1.2.2**, 29.2 MiB, signed dengan kunci release existing. 70 tes Flutter, 33 SQL, 42 pemeriksaan APK dan 118 aset lulus. Lint 0 error / 7 warning; OSV tanpa advisori aktif yang cocok. SHA-256: `46cb55ad5e0a9d366a6559398e19276f773d54deaf3cab4ff0c6a87652a7f795`.

[Perubahan intro, setiap file dan pengujian](INTRO_SFX_V1_2_2.md). Gunakan animasi/SFX cpns-intro, tanpa latar gradient/rings sumber dan tanpa tombol Lewati. Uji HP fisik belum dijalankan. Bagian selanjutnya adalah arsip versi sebelumnya.

## Intro HD 1.2.1 — hasil terbaru

APK signed ARM64 **1.2.1 / versionCode 2006**, Android 7.0+, **30.521.841 byte (29,1 MiB)**, signer release existing. SHA-256: `10fbcbb3a480992665ec9d90f9c1f17ba2874ccc74cfdcf54666d109e25440dc`. Analyze bersih; **70 tes Flutter / 33 SQL / 42 pemeriksaan APK / 109 pemeriksaan aset UI** lulus, 3 capture lama opt-in dilewati. Lint **0 error / 7 warning**, OSV 234 paket dan audit npm tooling tanpa advisori aktif yang cocok.

Master 1440 × 3200 dirender pada RTX 3050/NVENC; aplikasi memakai PNG alpha 1080 px + kurva Remotion, teks/latar native tanpa bidang video. Halaman/data existing dipertahankan. [Perubahan setiap file dan bukti](INTRO_HD_V1_2_1.md). Uji HP fisik/hosted belum dilakukan. Bagian selanjutnya menyimpan hasil versi terdahulu.

Tanggal pemeriksaan: 20–21 November 2026 (WIB), hingga perbaikan intro HD 1.2.1. Flutter 3.50.1 / Dart 3.14.0, minimum Android 7.0. Identitas penandatangan dan perlindungan data existing dipertahankan. Pemeriksaan dilakukan pada source lokal dan artefak build; bukan sertifikasi independen atau jaminan bebas malware/celah.

## Hasil 1.2.0 - arsip

- APK signed ARM64 **1.2.0 / versionCode 2005**, Android 7.0+ (min 24 / target 36), **29.781.539 byte (28,4 MiB)**, sertifikat release existing yang dipin. [APK lokal](../build/releases/cpns-journey-1.2.0-arm64-v8a.apk).
- SHA-256: `c299bd1b26877daadae3ce1280b1e89a9059d6dfd34ae6a1cf601a0e422227ad`.
- **67 tes Flutter lulus / 3 capture opt-in dilewati**, analyze tanpa temuan. CAT penuh 110 soal menghasilkan 550 lewat UI; cold reopen/enkripsi, isolasi akun, data lama, chart, tab/pencarian/filter dan intro skip/replay diuji.
- **33 SQL/RLS**, **13 screenshot**, Android Lint **0 error / 7 warning**, OSV **136 Pub + 97 Maven + 1 npm** tanpa advisori aktif yang cocok.
- **42 pemeriksaan APK keamanan** dan **106 pemeriksaan aset UI** lulus. Ke-40 aset artwork Flutter cocok byte dengan source; pixel terlihat launcher legacy/foreground lima density cocok dengan logo hasil generasi; adaptive XML ada.
- Tooling intro: TypeScript bersih, npm audit 0 advisori; video 96 frame final + 96 frame debug lulus QA dan contact sheet/frame ukuran penuh ditinjau. WebP 248.614 byte, 540 × 960, 41 frame hasil penggabungan frame diam, total 3.200 ms; MP4 H.264 720 × 1280 hanya stream video.
- Bukti: [regresi](security/regression-1.2.0.json), [APK](security/release-security-1.2.0.json), [aset/logo APK](security/ui-assets-1.2.0.json), [OSV](security/dependency-audit-1.2.0.json), [npm intro](security/intro-npm-audit-1.2.0.json), [Lint](security/lint-results-release-1.2.0.xml).

UI/intro tidak menambah permission, plugin Flutter, tabel atau database. Kode enkripsi/penyimpanan/controller dan read model analisis identik dengan checkpoint 1.1.0. Intro memakai flag preferensi lokal terpisah; render screenshot hanya MemoryStore. Laporan lengkap: [UPGRADE_UI_V1_2.md](UPGRADE_UI_V1_2.md). Bukti 1.1.0 tetap diarsipkan dengan suffix `-1.1.0`; JSON utama menunjuk 1.2.0.

## Temuan dan perbaikan

Tambahan 1.1.0: **55 tes Flutter**, **33 SQL/RLS**, serta **42 pemeriksaan APK** lulus. Interval aktivitas dan target efektif ditambahkan pada payload terenkripsi yang sama. Trigger additive menggabungkan UUID immutable, mempertahankan analytics saat client lama melakukan sync, dan menolak durasi/identitas yang tidak valid. Aplikasi mengecek kemampuan migrasi sebelum sync. Tidak ada penambahan izin Android, SDK pelacakan pihak ketiga, database atau proyek baru. Migrasi hosted belum dijalankan; pengujian memakai PGlite dan penyimpanan terisolasi. Detail ada di [laporan upgrade](UPGRADE_V2_1.md). Bukti 1.0.2 diarsipkan dengan suffix `-1.0.2`; Arsip 1.1.0 tersedia dengan suffix `-1.1.0`; JSON utama kini 1.2.0.

| Area | Temuan awal | Perbaikan |
| --- | --- | --- |
| Distribusi | APK sebelumnya debug dan memakai identitas debug | Build release, `debuggable=false`, JNI debugging dimatikan, R8/resource shrinking dan obfuscation Dart; kunci release privat tersendiri |
| Data perangkat | Payload progres tersimpan sebagai JSON terbuka dalam SQLite | AES-256-GCM dengan nonce acak, kunci acak 256 bit disimpan melalui Flutter Secure Storage; namespace akun menjadi authenticated additional data |
| Migrasi data | Penggantian penyimpanan berisiko kehilangan progres lama | Semua baris lama dienkripsi dalam transaksi; kegagalan membatalkan perubahan. `secure_delete`, VACUUM dan checkpoint mengurangi sisa plaintext di file SQLite. Ciphertext rusak/kunci hilang menyebabkan kegagalan baca, tanpa reset data otomatis |
| Sesi akun | Kunci penyimpanan sesi belum dipisahkan per proyek; penyimpanan PKCE memakai default SDK | Sesi dan PKCE pada Android memakai secure storage dengan namespace proyek. Sesi lama tanpa namespace dihapus sehingga pengguna perlu login kembali; progres akun tidak dihapus |
| Konfigurasi cloud | Validasi hanya memeriksa suffix host dan sebagian format key | URL hanya origin HTTPS proyek Supabase, port 443, tanpa userinfo/path/query/fragment. Secret dan JWT service-role ditolak. Tidak ada service-role key yang diperlukan oleh aplikasi |
| Pembaruan konten | Unduhan dapat mengikuti redirect; host boleh proyek Supabase lain; perubahan akun saat unduhan belum dijaga | Storage publik pada proyek yang sedang terhubung, redirect ditolak, tanpa header Authorization, maksimum 10 MiB dan deadline total 30 detik, hash/versi tetap diperiksa, hasil lama dibatalkan bila akun berubah |
| Tautan resmi | Tombol tautan memeriksa HTTPS saja | Tautan resmi dibatasi ke HTTPS domain `.go.id`, port standar dan tanpa kredensial pada URL. Ini memvalidasi struktur host, bukan keaslian seluruh isi situs pemerintah |
| CSV | Prefix formula setelah whitespace/control characters belum ditangani | Netralisasi prefix ASCII/full-width dan whitespace/control characters sebelum quoting. Pengubahan dan penyimpanan ulang oleh aplikasi spreadsheet tetap perlu kehati-hatian |
| Backup/jaringan | `allowBackup=false` belum dilengkapi aturan ekstraksi Android modern | Aturan pengecualian cloud backup serta device transfer; cleartext dilarang; konfigurasi trust anchor sistem tanpa debug override |
| RPC sinkronisasi | Tes membuktikan `p_expected_version=null` melewati pemeriksaan konflik; schema/koleksi dan beberapa skor null belum ditolak dengan tegas | Migrasi `202611200003_security_hardening.sql`: argumen null dan bentuk payload salah ditolak; rubrik skor diperketat; CREATE pada schema public dicabut untuk role aplikasi |

Tidak ada pemindahan data tamu ke akun secara otomatis. Deadline CAT, penyimpanan atomik snapshot/outbox, isolasi akun, submitted attempt yang immutable dan label aturan historis 2024 dipertahankan.

## Bukti pengujian

- Analisis Flutter bersih; 33 tes Flutter lulus pada 1.0.2. Cakupannya meliputi enkripsi dengan nonce berbeda, manipulasi ciphertext, pertukaran namespace, kunci salah/hilang, migrasi SQLite dan rollback, cold reopen, sesi/PKCE lintas proyek, validasi URL/key, redirect, batas stream, CSV, aset papercut, serta regresi CAT/UI. Capture screenshot terpisah bersifat opt-in dan dilewati pada suite normal. Tes secure storage memakai mock platform; Keystore Android nyata belum diuji.
- Pada 1.0.2, 25 pemeriksaan PGlite/SQL lulus; 1.2.0 menjalankan 33 pemeriksaan. Cakupan awal meliputi termasuk akses antar akun, semua 13 tabel milik pengguna, RLS pada 27 tabel public, larangan penulisan langsung, konflik/idempotensi, null version, payload malformed, rubrik, penghapusan akun, serta bucket privat. Ini memakai fixture Auth/Storage, bukan layanan Supabase hosted.
- OSV: 136 paket Pub, 97 komponen Maven release runtime dan 1 paket npm dicocokkan berdasarkan versi. Tidak ditemukan advisori aktif yang cocok pada saat pemeriksaan. Hasil kosong tidak membuktikan seluruh dependensi bebas celah; engine Flutter/Dart, binary native dan sistem operasi tidak seluruhnya tercakup oleh pencocokan paket ini.
- `npm audit`: tidak ditemukan advisori pada dependensi pengujian npm.
- Pemindaian pola secret memeriksa source teks tracked/unignored, tanpa menampilkan nilai rahasia. Ini bukan pencarian secret menyeluruh dan tidak memeriksa seluruh riwayat Git. `android/key.properties` diabaikan Git.
- `scripts/verify_release_apk.ps1` memeriksa manifest APK final, izin, ABI, tanda tangan, konfigurasi backup/TLS, ketiadaan kernel debug/berkas privat dan stripping DWARF pada library AOT. Metadata/tanda tangan yang valid bukan bukti bebas malware.

Android Lint 1.2.0: **0 error, 7 peringatan**, tanpa suppression/baseline baru untuk menyembunyikan error. Rincian ada di XML release. Build juga menampilkan peringatan kompatibilitas KGP share_plus dan referensi font Cupertino dari dependensi; seluruh regresi UI aplikasi lulus. Peringatan DWARF saat kompilasi diperiksa kembali pada library APK final yang sudah di-strip.

**APK 1.2.0 - arsip:** `build/releases/cpns-journey-1.2.0-arm64-v8a.apk`, 29.781.539 byte (28,4 MiB), versi 1.2.0 / versionCode 2005, minimum SDK 24 / target 36 / ABI `arm64-v8a`. 42 pemeriksaan keamanan APK dan 106 aset UI lulus. SHA-256: `c299bd1b26877daadae3ce1280b1e89a9059d6dfd34ae6a1cf601a0e422227ad`. Bukti versi lama diarsipkan dengan suffix versi masing-masing.

Bukti: [pemeriksaan APK](security/release-security.json), [audit dependensi](security/dependency-audit.json), [pemindaian pola secret](security/source-secrets.json), [Android Lint](security/lint-results-release.xml), [sertifikat publik](security/release-certificate.der) dan [fingerprint penandatangan](security/release-certificate.sha256). Tidak ada private key atau kata sandi di folder bukti ini.

## Kunci dan pemasangan

Kunci privat: `D:\Development\keys\cpns-journey-release.p12`. Kredensial: `D:\Development\keys\cpns-journey-release.credentials.json`. Akses Windows dibatasi ke pemilik, SYSTEM dan administrator. Konfigurasi lokal `android/key.properties` juga dibatasi dan tidak boleh di-commit. Simpan backup privat kunci dan kredensial; gunakan identitas yang sama untuk pembaruan berikutnya. Simbol deobfuscation disimpan per versi; versi terkini pada `D:\Development\symbols\cpns-1.2.1`.

Tanda tangan release berbeda dari APK debug sebelumnya. Jika APK debug sudah dipasang, ekspor progres melalui Profil sebelum mengganti aplikasi; Android dapat menolak pembaruan dengan tanda tangan berbeda. Belum ada UI impor JSON sehingga pemulihan ekspor memerlukan langkah manual. Jangan menghapus aplikasi/data sebelum memastikan cara memulihkan progres. Tidak ada uninstall atau penghapusan data perangkat yang dilakukan selama pemeriksaan ini.

## Batas yang masih memerlukan verifikasi

- Belum ada perangkat Android terhubung. Perilaku Keystore nyata, instalasi/peluncuran ARM64, force-stop/reboot, notifikasi, backup/transfer pada vendor HP, dan inspeksi TLS saat runtime belum diuji di perangkat.
- Belum ada proyek Supabase hosted milik pengguna yang terhubung. Email/reset/deep link, konfigurasi Auth/Storage nyata, rate limiting dan sinkronisasi dua perangkat belum diverifikasi. Jalankan keempat migrasi sesuai urutan pada proyek milik sendiri sebelum menggunakan cloud.
- Enkripsi melindungi payload SQLite, bukan seluruh file database: namespace akun dan metadata outbox masih dapat terlihat. Ekspor PDF/CSV/JSON yang dipilih pengguna tetap berisi data terbuka; UI mengingatkan agar menyimpannya di tujuan tepercaya. Preview web memakai penyimpanan berbeda dan tidak termasuk klaim enkripsi Android.
- Tidak ada jaminan terhadap perangkat rooted/OS yang sudah dikuasai penyerang, forensik seluruh media penyimpanan, atau endpoint/proyek cloud yang dikuasai pihak lain. Penghapusan SQLite tidak diklaim sebagai penghapusan forensik semua salinan historis pada flash/storage.
- Tidak ada pengunggahan APK/source ke VirusTotal/MobSF atau layanan pemindaian publik; tidak ada hasil antivirus/pentest dinamis yang diklaim lulus.
- Soal masih memerlukan tinjauan manusia. Skor latihan berasal dari snapshot latihan pengguna; aplikasi ini tidak menyediakan anti-cheat ujian resmi.
- `share_plus` masih mengeluarkan peringatan KGP untuk kompatibilitas Flutter mendatang; tidak ada advisori aktif yang cocok pada audit saat ini.

## Mengulang pemeriksaan

```powershell
npm ci --ignore-scripts
.\scripts\build_verified_release_windows.ps1
```

Skrip memakai SDK/cache/TEMP di D, memeriksa lockfile, analisis, tes Flutter dan SQL, secret, build release, lint, OSV serta APK. Build release dijalankan melalui Flutter dengan pub aktif agar registrant tidak memakai daftar plugin debug. Path `local.properties` dinormalisasi setelah build untuk aturan lint Windows. Fingerprint sertifikat publik dipakai untuk memeriksa identitas penandatangan.

Untuk inventaris dan audit dependensi:

```powershell
Push-Location android
.\gradlew.bat -I ..\scripts\security_dependencies.init.gradle :app:securityDependencyInventory
Pop-Location
node scripts/audit_dependencies.mjs
```

Perintah ini menulis inventaris Maven aktual pada `work/maven-dependencies.json`. Skrip OSV mengirim nama/versi dependensi ke API OSV, bukan source, APK atau kredensial. Hasil baru harus diperiksa setiap dependensi berubah.

Rujukan: [Android debuggable](https://developer.android.com/privacy-and-security/risks/android-debuggable), [keamanan backup Android](https://developer.android.com/privacy-and-security/risks/backup-best-practices), [cryptography](https://pub.dev/packages/cryptography), [OSV API](https://google.github.io/osv.dev/post-v1-querybatch/), [OWASP CSV Injection](https://community.owasp.org/attacks/CSV_Injection).
