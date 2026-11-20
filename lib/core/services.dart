import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();
  static const storage = FlutterSecureStorage();
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async =>
      await storage.containsKey(key: 'supabase-session');
  @override
  Future<String?> accessToken() => storage.read(key: 'supabase-session');
  @override
  Future<void> removePersistedSession() =>
      storage.delete(key: 'supabase-session');
  @override
  Future<void> persistSession(String value) =>
      storage.write(key: 'supabase-session', value: value);
}

class CloudConfig {
  static bool ready = false;
  static const buildUrl = String.fromEnvironment('SUPABASE_URL');
  static const buildKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('public-supabase-url') ?? buildUrl;
    final key = prefs.getString('public-supabase-key') ?? buildKey;
    if (url.isNotEmpty && key.isNotEmpty) await connect(url, key);
  }

  static Future<void> connect(String url, String key) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.host.endsWith('.supabase.co')) {
      throw const FormatException(
        'Gunakan URL HTTPS proyek Supabase: https://nama-proyek.supabase.co',
      );
    }
    if (key.startsWith('sb_secret_')) {
      throw const FormatException(
        'Gunakan publishable/anon key. Secret key dilarang.',
      );
    }
    if (key.split('.').length == 3) {
      try {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(key.split('.')[1]))),
        );
        if (payload['role'] != 'anon') {
          throw const FormatException('Hanya anon key yang diizinkan.');
        }
      } on FormatException {
        rethrow;
      }
    } else if (!key.startsWith('sb_publishable_')) {
      throw const FormatException('Publishable/anon key tidak valid.');
    }
    if (ready) await Supabase.instance.dispose();
    await Supabase.initialize(
      url: url.trim(),
      publishableKey: key.trim(),
      authOptions: FlutterAuthClientOptions(
        localStorage: kIsWeb
            ? const EmptyLocalStorage()
            : const SecureSessionStorage(),
        authFlowType: AuthFlowType.pkce,
      ),
    );
    ready = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('public-supabase-url', url.trim());
    await prefs.setString('public-supabase-key', key.trim());
  }
}

class ContentRepository {
  late Json data;
  late Json manifest;
  Json validateBytes(List<int> bytes, String expectedHash) {
    if (bytes.length > 10 * 1024 * 1024 ||
        sha256.convert(bytes).toString() != expectedHash) {
      throw const FormatException(
        'Paket rusak atau hash tidak cocok. Versi sebelumnya dipertahankan.',
      );
    }
    final candidate = jsonDecode(utf8.decode(bytes)) as Json;
    if (candidate['version'] is! String) {
      throw const FormatException('Versi paket tidak valid.');
    }
    validate(candidate);
    return candidate;
  }

  void installBytes(List<int> bytes, String expectedHash) {
    final candidate = validateBytes(bytes, expectedHash);
    data = candidate;
    manifest = {
      'version': candidate['version'],
      'sha256': expectedHash,
      'bytes': bytes.length,
      'questions': questions.length,
      'lessons': lessons.length,
    };
  }

  List<Question> get questions => (data['questions'] as List)
      .cast<Json>()
      .where((q) => q['publication_status'] == 'published')
      .map(Question.new)
      .toList();
  List<Json> get lessons => (data['lessons'] as List)
      .cast<Json>()
      .where(
        (l) =>
            l['status'] == 'published' ||
            l['publication_status'] == 'published',
      )
      .toList();
  List<Json> get packs => (data['packs'] as List)
      .cast<Json>()
      .where((p) => blueprintFor(p)['status'] != 'draft')
      .toList();
  static Json blueprintFor(Json pack) =>
      pack['blueprint_snapshot'] as Json? ??
      {
        'id': pack['blueprint'] ?? 'historical-2024-v1',
        'year': 2024,
        'status': 'historical',
        'passing_grades': {'TWK': 65, 'TIU': 80, 'TKP': 166},
        'distribution': {'TWK': 30, 'TIU': 35, 'TKP': 45},
        'source_url': historicalSource,
      };
  Future<void> load() async {
    final bytes = await rootBundle.load('assets/content/content.json');
    manifest = jsonDecode(
      await rootBundle.loadString('assets/content/manifest.json'),
    ) as Json;
    final raw = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    if (sha256.convert(raw).toString() != manifest['sha256']) {
      throw const FormatException(
        'Paket konten gagal pemeriksaan integritas. Paket lama tidak diubah.',
      );
    }
    final candidate = jsonDecode(utf8.decode(raw)) as Json;
    validate(candidate);
    data = candidate;
  }

  static void validate(Json candidate) {
    final seen = <String>{};
    for (final raw in candidate['questions'] as List) {
      final q = Question(raw as Json);
      if (!seen.add(q.id) ||
          q.explanation.isEmpty ||
          q.options.length != 5 ||
          q.options.map((o) => o['id']).toSet().length != 5) {
        throw const FormatException('Soal tidak valid.');
      }
      final scores = q.options.map((o) => o['score'] as int).toList();
      if (q.domain == 'TKP'
          ? scores.toSet().length != 5 || scores.any((s) => s < 1 || s > 5)
          : scores.where((s) => s == 5).length != 1 ||
                scores.any((s) => s != 0 && s != 5)) {
        throw const FormatException('Rubrik soal tidak valid.');
      }
    }
    for (final p in candidate['packs'] as List) {
      final ids = (p['question_ids'] as List).cast<String>();
      final blueprint = blueprintFor(p as Json);
      final distribution = blueprint['distribution'] as Json;
      final expected = distribution.values.cast<int>().fold(0, (a, b) => a + b);
      final source = Uri.tryParse(blueprint['source_url'] as String? ?? '');
      if (!['historical', 'verified', 'draft'].contains(blueprint['status']) ||
          source?.scheme != 'https' ||
          !(source?.host.endsWith('.go.id') ?? false)) {
        throw const FormatException('Sumber/status blueprint tidak valid.');
      }
      for (final d in domains) {
        final actual = (candidate['questions'] as List)
            .cast<Json>()
            .where(
              (q) =>
                  ids.contains(q['id']) &&
                  q['domain'] == d &&
                  q['publication_status'] == 'published',
            )
            .length;
        if (actual != distribution[d]) {
          throw const FormatException('Komposisi blueprint tidak cocok.');
        }
      }
      if (ids.length != expected ||
          expected > 200 ||
          expected < 1 ||
          ids.toSet().length != expected ||
          !ids.every(seen.contains)) {
        throw const FormatException('Paket CAT tidak lengkap.');
      }
    }
  }
}

class ReminderService {
  final plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;
  Future<bool> enable() async {
    if (kIsWeb) return false;
    tzdata.initializeTimeZones();
    if (!initialized) {
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
        ),
      );
      initialized = true;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        false;
  }

  Future<void> schedule(Json state) async {
    if (!initialized) return;
    await plugin.cancelAll();
    if (state['notifications'] != true) return;
    final location = tz.getLocation('Asia/Jakarta');
    final now = tz.TZDateTime.now(location);
    var study = DateTime(now.year, now.month, now.day, 19);
    if (!study.isAfter(
      DateTime(now.year, now.month, now.day, now.hour, now.minute),
    )) {
      study = study.add(const Duration(days: 1));
    }
    study = outsideQuietHours(
      study,
      state['quiet_start'] as int,
      state['quiet_end'] as int,
    );
    await plugin.zonedSchedule(
      1,
      'Waktu belajar',
      'Lanjutkan target harianmu di CPNS Journey.',
      tz.TZDateTime(
        location,
        study.year,
        study.month,
        study.day,
        study.hour,
        study.minute,
      ),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study',
          'Pengingat belajar',
          channelDescription: 'Jadwal belajar pilihan pengguna',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    for (final e in (state['events'] as List).cast<Json>()) {
      if (e['reminder'] != true) continue;
      final dt = DateTime.parse(e['at'] as String)
          .toUtc()
          .add(const Duration(hours: 7));
      final adjusted = outsideQuietHours(
        DateTime(
          dt.year,
          dt.month,
          dt.day,
          dt.hour,
          dt.minute,
        ).subtract(const Duration(minutes: 60)),
        state['quiet_start'] as int,
        state['quiet_end'] as int,
      );
      final at = tz.TZDateTime(
        location,
        adjusted.year,
        adjusted.month,
        adjusted.day,
        adjusted.hour,
        adjusted.minute,
      );
      if (!at.isAfter(now)) continue;
      final id = int.parse(
        sha256
            .convert(utf8.encode(e['id'] as String))
            .toString()
            .substring(0, 7),
        radix: 16,
      );
      await plugin.zonedSchedule(
        id,
        'Pengingat agenda',
        'Ada agenda yang kamu simpan. Buka CPNS Journey.',
        at,
        const NotificationDetails(
          android: AndroidNotificationDetails('events', 'Agenda pribadi'),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> disable() async {
    if (initialized) await plugin.cancelAll();
  }
}
