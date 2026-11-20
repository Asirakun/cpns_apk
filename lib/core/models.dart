import 'dart:convert';
import 'dart:math';

typedef Json = Map<String, dynamic>;
const domains = ['TWK', 'TIU', 'TKP'];
const stageNames = [
  'Target & persiapan',
  'Pengumuman formasi',
  'Akun SSCASN',
  'Pendaftaran',
  'Administrasi & sanggah',
  'Seleksi kompetensi dasar',
  'Hasil SKD',
  'Seleksi kompetensi bidang',
  'Hasil akhir & sanggah',
  'DRH & pemberkasan',
  'Pengangkatan & penempatan',
  'Arsip / coba lagi',
];
const stageStates = [
  'BELUM_DIMULAI',
  'AKTIF',
  'MENUNGGU_HASIL',
  'SELESAI',
  'TIDAK_LOLOS',
];
const stageLabels = [
  'Belum dimulai',
  'Aktif',
  'Menunggu hasil',
  'Selesai',
  'Tidak lolos',
];
const documentStates = [
  'Belum siap',
  'Siap',
  'Menunggu format resmi',
  'Belum berlaku',
  'Tidak diperlukan',
];
const historicalSource =
    'https://www.bkn.go.id/wp-content/uploads/2024/08/2024kepmenpanrb321-Nilai-Ambang-Batas.pdf';
const sourceLinks = <String, String>{
  'SSCASN BKN': 'https://sscasn.bkn.go.id/',
  'Pembuatan akun SSCASN': 'https://daftar-sscasn.bkn.go.id/akun',
  'Rekrutmen Kemenkeu': 'https://rekrutmen.kemenkeu.go.id/',
  'Panduan CAT BKN': 'https://cat.bkn.go.id/faq',
  'PermenPANRB 6/2024':
      'https://jdih.menpan.go.id/common/dokumen/2024permenpanrb006.pdf',
  'Blueprint SKD historis 2024': historicalSource,
};

class Question {
  Question(this.json);
  final Json json;
  String get id => json['id'] as String;
  String get domain => json['domain'] as String;
  String get topic => json['topic'] as String;
  String get text => json['text'] as String;
  String get explanation => json['explanation'] as String;
  List<Json> get options => (json['options'] as List).cast<Json>();
  int score(String? option) => option == null
      ? 0
      : options
                .where((o) => o['id'] == option)
                .map((o) => o['score'] as int)
                .firstOrNull ??
            0;
  int get maximum => options.map((o) => o['score'] as int).reduce(max);
  String get best =>
      options.firstWhere((o) => o['score'] == maximum)['id'] as String;
}

class Attempt {
  Attempt(this.json);
  final Json json;
  String get id => json['id'] as String;
  String get title => json['title'] as String;
  bool get submitted => json['submitted_at'] != null;
  List<Question> get questions => (json['questions'] as List)
      .map((q) => Question(Map<String, dynamic>.from(q as Map)))
      .toList();
  Json get answers => json['answers'] as Json;
  List get flagged => json['flagged'] as List;
  DateTime get deadline => DateTime.parse(json['deadline_at'] as String);
  int remaining(DateTime now) =>
      max(0, deadline.difference(now.toUtc()).inSeconds);
  Json get scores {
    final result = <String, dynamic>{for (final d in domains) d: 0};
    for (final q in questions) {
      result[q.domain] =
          (result[q.domain] as int) + q.score(answers[q.id] as String?);
    }
    return result;
  }

  int get total => scores.values.cast<int>().fold(0, (a, b) => a + b);
  int get maximum => questions.fold(0, (a, q) => a + q.maximum);
  Map<String, int> get weaknesses {
    final result = <String, int>{};
    for (final q in questions) {
      if (q.score(answers[q.id] as String?) < q.maximum) {
        result[q.topic] = (result[q.topic] ?? 0) + 1;
      }
    }
    return result;
  }

  bool answer(String questionId, String optionId, DateTime now) {
    if (submitted || remaining(now) <= 0) return false;
    final q = questions.firstWhere((q) => q.id == questionId);
    if (!q.options.any((o) => o['id'] == optionId)) return false;
    answers[questionId] = optionId;
    json['answered_at'] = now.toUtc().toIso8601String();
    return true;
  }

  bool submit(DateTime now) {
    if (submitted) return false;
    json['submitted_at'] =
        (now.toUtc().isAfter(deadline) ? deadline : now.toUtc())
            .toIso8601String();
    json['scores'] = scores;
    return true;
  }
}

Json deepCopy(Json value) => jsonDecode(jsonEncode(value)) as Json;
bool eligibleEducation(
  List<String> accepted,
  String completed,
  String d3Status,
) => accepted.contains(completed) && (completed != 'D3' || d3Status == 'Lulus');
DateTime outsideQuietHours(DateTime wib, int start, int end) {
  if (start == end) return wib;
  final quiet = start < end
      ? wib.hour >= start && wib.hour < end
      : wib.hour >= start || wib.hour < end;
  if (!quiet) return wib;
  var adjusted = DateTime(wib.year, wib.month, wib.day, end);
  if (!adjusted.isAfter(wib)) adjusted = adjusted.add(const Duration(days: 1));
  return adjusted;
}

Json newCycle(String id, int year) => {
  'id': id,
  'year': year,
  'agency': 'Kemenkeu',
  'stages': {'S00': 'AKTIF'},
  'evidence': <String, dynamic>{},
  'results': <String, dynamic>{},
  'documents': <String, dynamic>{},
  'formation': null,
  'archived': false,
};
Json initialData() => {
  'schema_version': 1,
  'onboarded': false,
  'alias': 'Pejuang CPNS',
  'education': 'SMA',
  'd3_status': 'Sedang kuliah',
  'graduation': '2027-04-01',
  'target_city': 'Medan',
  'minutes': 45,
  'plan_days': 30,
  'theme': 'system',
  'bookmarks': <String>[],
  'completed': <String>[],
  'lesson_positions': <String, dynamic>{},
  'reviews': <String, dynamic>{},
  'attempts': <Json>[],
  'cycles': [newCycle('cycle-2026', 2026)],
  'active_cycle': 'cycle-2026',
  'events': <Json>[],
  'budget': <Json>[],
  'study_days': <String>[],
  'daily_tasks': <String>[],
  'notifications': false,
  'quiet_start': 21,
  'quiet_end': 7,
  'downloaded_version': null,
  'last_sync': null,
  'server_version': 0,
  'updated_at': null,
};

const docRules = <Json>[
  {
    'id': 'akun-sscasn',
    'stage': 2,
    'name': 'Akun SSCASN',
    'note': 'Buat hanya di portal resmi saat periode dibuka. Jangan simpan password SSCASN di aplikasi.',
    'group': 'Sebelum daftar',
    'status': 'Belum berlaku',
  },
  {
    'id': 'ktp',
    'stage': 2,
    'name': 'KTP asli / dokumen Dukcapil',
    'note': 'Cocokkan identitas. Simpan pindai di lokasi pribadi; NIK tidak perlu dimasukkan.',
    'group': 'Sebelum daftar',
    'status': 'Belum siap',
  },
  {
    'id': 'kk',
    'stage': 2,
    'name': 'Kartu Keluarga',
    'note': 'Pastikan identitas konsisten dengan KTP. Jangan tulis nomor KK di aplikasi.',
    'group': 'Sebelum daftar',
    'status': 'Belum siap',
  },
  {
    'id': 'ijazah',
    'stage': 3,
    'name': 'Ijazah SMA/sederajat asli',
    'note': 'Gunakan ijazah yang sudah dimiliki dan sesuai formasi; D3 berlangsung bukan pengganti.',
    'group': 'Sebelum daftar',
    'status': 'Belum siap',
  },
  {
    'id': 'nilai',
    'stage': 3,
    'name': 'Daftar nilai SMA',
    'note': 'Siapkan nilai yang menyertai ijazah jika diminta.',
    'group': 'Sebelum daftar',
    'status': 'Belum siap',
  },
  {
    'id': 'foto',
    'stage': 3,
    'name': 'Pasfoto formal terbaru',
    'note': 'Siapkan latar merah; format dan ukuran mengikuti pengumuman tahun seleksi.',
    'group': 'Sebelum daftar',
    'status': 'Belum siap',
  },
  {
    'id': 'swafoto',
    'stage': 2,
    'name': 'Swafoto / verifikasi wajah',
    'note': 'Buat mengikuti instruksi portal ketika periode akun dibuka.',
    'group': 'Sebelum daftar',
    'status': 'Belum berlaku',
  },
  {
    'id': 'kontak',
    'stage': 2,
    'name': 'Email & nomor HP aktif',
    'note':
        'Jaga akses sepanjang seleksi. Gunakan kata sandi yang kuat dan unik.',
    'group': 'Sebelum daftar',
    'status': 'Belum siap',
  },
  {
    'id': 'identitas',
    'stage': 2,
    'name': 'Konsistensi data pendidikan',
    'note': 'Cocokkan ejaan nama, kota dan tanggal lahir pada KTP dan ijazah.',
    'group': 'Sebelum daftar',
    'status': 'Belum siap',
  },
  {
    'id': 'lamaran',
    'stage': 3,
    'name': 'Surat lamaran',
    'note': 'Tunggu template resmi, aturan tanda tangan dan meterai.',
    'group': 'Tunggu pengumuman',
    'status': 'Menunggu format resmi',
  },
  {
    'id': 'pernyataan',
    'stage': 3,
    'name': 'Surat pernyataan resmi',
    'note': 'Ikuti ketentuan dan template instansi pada tahun seleksi.',
    'group': 'Tunggu pengumuman',
    'status': 'Menunggu format resmi',
  },
  {
    'id': 'meterai',
    'stage': 3,
    'name': 'Meterai / e-meterai',
    'note': 'Gunakan hanya setelah ketentuan terbaru diumumkan.',
    'group': 'Tunggu pengumuman',
    'status': 'Menunggu format resmi',
  },
  {
    'id': 'khusus',
    'stage': 3,
    'name': 'Persyaratan khusus jabatan',
    'note': 'Periksa usia, tinggi badan, kesehatan dan sertifikasi jabatan.',
    'group': 'Tunggu pengumuman',
    'status': 'Menunggu format resmi',
  },
  {
    'id': 'sertifikat',
    'stage': 3,
    'name': 'Sertifikat bahasa / keahlian',
    'note': 'Hanya jika jelas menjadi syarat formasi yang dipilih.',
    'group': 'Tunggu pengumuman',
    'status': 'Menunggu format resmi',
  },
  {
    'id': 'kartu',
    'stage': 5,
    'name': 'Kartu peserta ujian',
    'note': 'Unduh dan cetak ketika tersedia pada akun seleksi.',
    'group': 'Saat ujian CAT',
    'status': 'Belum berlaku',
  },
  {
    'id': 'identitas-ujian',
    'stage': 5,
    'name': 'Identitas resmi saat ujian',
    'note': 'Bawa KTP/KK/IKD sesuai ketentuan terbaru dan kartu ujian.',
    'group': 'Saat ujian CAT',
    'status': 'Belum berlaku',
  },
  {
    'id': 'sesi',
    'stage': 5,
    'name': 'Lokasi, sesi & waktu hadir',
    'note': 'Referensi BKN: paling lambat 60 menit sebelumnya atau sesuai instansi.',
    'group': 'Saat ujian CAT',
    'status': 'Belum berlaku',
  },
  {
    'id': 'pakaian',
    'stage': 5,
    'name': 'Pakaian sesuai tata tertib',
    'note':
        'Periksa ketentuan terbaru; referensi: bukan kaos, jeans atau sandal.',
    'group': 'Saat ujian CAT',
    'status': 'Belum berlaku',
  },
  {
    'id': 'drh',
    'stage': 9,
    'name': 'DRH SSCASN',
    'note':
        'Isi, cetak dan tanda tangani setelah diumumkan. Contoh historis 2024.',
    'group': 'Jika lulus akhir · historis 2024',
    'status': 'Belum berlaku',
  },
  {
    'id': 'ijazah-akhir',
    'stage': 9,
    'name': 'Ijazah & nilai saat pemberkasan',
    'note': 'Gunakan dokumen yang dipakai melamar.',
    'group': 'Jika lulus akhir · historis 2024',
    'status': 'Belum berlaku',
  },
  {
    'id': 'skck',
    'stage': 9,
    'name': 'SKCK kepolisian',
    'note': 'Jangan diurus terlalu dini. Cek masa berlaku yang ditetapkan.',
    'group': 'Jika lulus akhir · historis 2024',
    'status': 'Belum berlaku',
  },
  {
    'id': 'sehat',
    'stage': 9,
    'name': 'Sehat jasmani & rohani',
    'note': 'Tunggu pengumuman fasilitas/petugas dan tanggal berlaku.',
    'group': 'Jika lulus akhir · historis 2024',
    'status': 'Belum berlaku',
  },
  {
    'id': 'napza',
    'stage': 9,
    'name': 'Bebas NAPZA',
    'note': 'Jangan tes terlalu dini; jenis pemeriksaan mengikuti instansi.',
    'group': 'Jika lulus akhir · historis 2024',
    'status': 'Belum berlaku',
  },
  {
    'id': 'lima-poin',
    'stage': 9,
    'name': 'Surat pernyataan 5 poin',
    'note': 'Ikuti template pemberkasan tahun seleksi.',
    'group': 'Jika lulus akhir · historis 2024',
    'status': 'Belum berlaku',
  },
  {
    'id': 'tambahan-akhir',
    'stage': 9,
    'name': 'Tambahan pemberkasan instansi',
    'note': 'Pada 2024 ada bebas HIV/AIDS dan deklarasi benturan kepentingan. Tidak otomatis berlaku 2026.',
    'group': 'Jika lulus akhir · historis 2024',
    'status': 'Belum berlaku',
  },
  {
    'id': 'penempatan',
    'stage': 10,
    'name': 'Identitas / penempatan tambahan',
    'note': 'Hanya jika ditetapkan berikutnya. Penempatan Medan belum dijamin.',
    'group': 'Jika lulus akhir · historis 2024',
    'status': 'Belum berlaku',
  },
];
