import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'services.dart';
import 'local_store.dart';
import 'network_policy.dart';
import 'app_version.dart';
import 'analytics.dart';
import 'study_clock.dart';

final appProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw UnimplementedError('Override at startup'),
);

class AppController extends ChangeNotifier {
  AppController([LocalStore? local, ContentRepository? contents])
    : store = local ?? createStore(),
      content = contents ?? ContentRepository();
  final LocalStore store;
  final ContentRepository content;
  final reminders = ReminderService();
  final uuid = const Uuid();
  Json data = initialData();
  String namespace = 'guest';
  bool syncing = false;
  bool conflict = false;
  bool passwordRecovery = false;
  bool switchingAccount = false;
  String? error;
  int queued = 0;
  int _failures = 0;
  int _namespaceTicket = 0;
  int get namespaceGeneration => _namespaceTicket;
  bool _disposed = false;
  bool _analyticsCloudReady = false;
  Timer? _retry;
  StreamSubscription<AuthState>? _auth;
  Future<void> _writes = Future.value();
  final studyFlushers = <VoidCallback>{};
  LearningAnalytics? _analyticsCache;
  int? _analyticsMinute;
  LearningAnalytics get analytics {
    final now = DateTime.now().toUtc();
    final minute = now.millisecondsSinceEpoch ~/ 60000;
    if (_analyticsCache == null || _analyticsMinute != minute) {
      _analyticsCache = LearningAnalytics(data, now: now);
      _analyticsMinute = minute;
    }
    return _analyticsCache!;
  }

  void _flushStudy() {
    for (final flush in studyFlushers.toList()) {
      flush();
    }
  }

  Future<void> recordStudySpan(
    ActiveSpan span, {
    required String owner,
    required String kind,
    int? generation,
    String? category,
    String? topic,
    String? attemptId,
  }) async {
    if (_disposed ||
        owner != namespace ||
        switchingAccount ||
        span.seconds <= 0 ||
        (generation != null && generation != _namespaceTicket)) {
      return;
    }
    ensureAnalytics(data, span.start, uuid.v4());
    final sessions = (data['analytics'] as Json)['sessions'] as List;
    // Split exactly at WIB midnight; category changes create a fresh interval.
    var cursor = span.start;
    while (cursor.isBefore(span.end)) {
      final midnight = dayUtc(wibDay(cursor).add(const Duration(days: 1)));
      final end = span.end.isBefore(midnight) ? span.end : midnight;
      final seconds =
          span.seconds *
          end.difference(cursor).inMicroseconds /
          span.end.difference(span.start).inMicroseconds;
      sessions.add({
        'id': uuid.v4(),
        'local_day': calendarKey(wibDay(cursor)),
        'category': category,
        'kind': kind,
        'topic_id': topic,
        'started_at': cursor.toUtc().toIso8601String(),
        'ended_at': end.toUtc().toIso8601String(),
        'active_seconds': seconds,
        'source_attempt_id': attemptId,
        'source': 'foreground-v1',
        'created_at': end.toUtc().toIso8601String(),
      });
      cursor = end;
    }
    await save();
  }

  Future<void> setDailyGoal(int minutes) async {
    if (minutes < 15 || minutes > 180) {
      throw ArgumentError('Target 15–180 menit.');
    }
    final now = DateTime.now().toUtc();
    ensureAnalytics(data, now, uuid.v4());
    if (data['minutes'] == minutes) return;
    ((data['analytics'] as Json)['goals'] as List).add({
      'id': uuid.v4(),
      'effective_day': calendarKey(wibDay(now)),
      'minutes': minutes,
      'created_at': now.toIso8601String(),
    });
    data['minutes'] = minutes;
    await save();
  }

  String get syncLabel => syncing
      ? 'Menyinkronkan…'
      : conflict
      ? 'Perlu selesaikan konflik'
      : namespace == 'guest'
      ? 'Tersimpan di perangkat'
      : queued > 0
      ? 'Tersimpan di HP · menunggu sinkron'
      : 'Sinkronisasi selesai';
  SupabaseClient? get client =>
      CloudConfig.ready ? Supabase.instance.client : null;
  List<Attempt> get attempts =>
      (data['attempts'] as List).cast<Json>().map(Attempt.new).toList();
  Attempt? get activeAttempt => attempts.where((a) => !a.submitted).firstOrNull;
  List<Attempt> get results => attempts.where((a) => a.submitted).toList();
  Json get cycle => (data['cycles'] as List).cast<Json>().firstWhere(
    (c) => c['id'] == data['active_cycle'],
  );
  Json get docs => cycle['documents'] as Json;
  int get docsReady =>
      docRules.where((r) => documentStatus(r) == 'Siap').length;
  String documentStatus(Json rule) =>
      (docs[rule['id']] as Json?)?['status'] as String? ??
      rule['status'] as String;
  int get stagesDone =>
      (cycle['stages'] as Json).values.where((s) => s == 'SELESAI').length;
  String get dayKey => DateTime.now()
      .toUtc()
      .add(const Duration(hours: 7))
      .toIso8601String()
      .substring(0, 10);
  Map<String, int> get weaknesses {
    final counts = <String, int>{};
    for (final a in results) {
      a.weaknesses.forEach((k, v) => counts[k] = (counts[k] ?? 0) + v);
    }
    return counts;
  }

  List<String> get recommendedTopics {
    final entries = weaknesses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).take(3).toList();
  }

  Future<void> initialize() async {
    await switchNamespace(client?.auth.currentUser?.id ?? 'guest', pull: true);
    listenAuth();
    if (data['notifications'] == true && !kIsWeb) {
      try {
        await reminders.enable();
        await reminders.schedule(data);
      } catch (_) {
        error = 'Pengingat belum dapat dijadwalkan. Periksa izin Android.';
      }
    }
    if (activeAttempt case final a?) {
      if (a.remaining(DateTime.now()) == 0) await submit(a);
    }
  }

  void listenAuth() {
    _auth?.cancel();
    _auth = client?.auth.onAuthStateChange.listen((e) async {
      if (e.event == AuthChangeEvent.passwordRecovery) {
        passwordRecovery = true;
        notifyListeners();
      }
      final next = e.session?.user.id ?? 'guest';
      if (next != namespace) await switchNamespace(next, pull: true);
    });
  }

  Future<void> switchNamespace(String next, {bool pull = false}) async {
    _flushStudy();
    _analyticsCloudReady = false;
    final ticket = ++_namespaceTicket;
    switchingAccount = true;
    notifyListeners();
    try {
      await _writes;
      if (ticket != _namespaceTicket) return;
      namespace = next;
      data = initialData();
      final saved = await store.read(next);
      if (ticket != _namespaceTicket) return;
      data = saved ?? initialData();
      _analyticsCache = null;
      error = null;
      conflict = false;
      await _restoreContent(generation: ticket);
      if (ticket != _namespaceTicket) return;
      final pending = await store.pending(next);
      if (ticket != _namespaceTicket) return;
      queued = pending.length;
      notifyListeners();
      if (pull && next != 'guest' && client != null) {
        final session = client!.auth.currentSession;
        if (session == null || session.user.id != next) return;
        try {
          final remote = await client!
              .from('user_snapshots')
              .select('payload,version')
              .eq('user_id', next)
              .maybeSingle()
              .setHeader('Authorization', 'Bearer ${session.accessToken}');
          if (ticket != _namespaceTicket) return;
          if (remote != null && queued == 0) {
            data = {
              ...initialData(),
              ...Map<String, dynamic>.from(remote['payload'] as Map),
              'server_version': remote['version'],
            };
            _analyticsCache = null;
            await _restoreContent(generation: ticket);
            if (ticket != _namespaceTicket) return;
            await _metadata();
          } else if (remote != null &&
              remote['version'] != data['server_version']) {
            conflict = true;
          }
        } catch (_) {
          if (ticket == _namespaceTicket) {
            error = 'Cloud belum terjangkau. Data perangkat tetap tersedia.';
          }
        }
        if (ticket != _namespaceTicket) return;
        notifyListeners();
        if (!conflict) unawaited(sync());
      }
      if (ticket == _namespaceTicket &&
          ensureAnalytics(data, DateTime.now().toUtc(), uuid.v4())) {
        await save();
      }
    } finally {
      if (ticket == _namespaceTicket) {
        switchingAccount = false;
        notifyListeners();
      }
    }
  }

  Future<void> save() async {
    ensureAnalytics(data, DateTime.now().toUtc(), uuid.v4());
    _analyticsCache = null;
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final target = namespace;
    final snapshot = deepCopy(data);
    final id = uuid.v4();
    notifyListeners();
    final job = _writes.then((_) => store.write(target, snapshot, id));
    _writes = job.catchError((Object e) {
      error = 'Penyimpanan perangkat gagal. Kosongkan ruang lalu coba lagi.';
      if (!_disposed) notifyListeners();
    });
    await job;
    if (target == namespace && !_disposed) {
      queued = (await store.pending(target)).length;
      notifyListeners();
    }
    if (target != 'guest' && !_disposed) _scheduleSync();
  }

  Future<void> _metadata() async {
    final id = uuid.v4();
    final target = namespace;
    final snapshot = deepCopy(data);
    await store.write(target, snapshot, id);
    await store.acknowledge(target, [id]);
  }

  void _scheduleSync() {
    if (conflict) return;
    _retry?.cancel();
    _retry = Timer(
      Duration(seconds: min(300, 2 * (1 << min(_failures, 7)))),
      () => unawaited(sync()),
    );
  }

  Future<void> sync({bool force = false}) async {
    if (client == null ||
        namespace == 'guest' ||
        syncing ||
        (conflict && !force)) {
      return;
    }
    final target = namespace, ticket = _namespaceTicket;
    await _writes;
    if (ticket != _namespaceTicket) return;
    final ids = await store.pending(target);
    if (ticket != _namespaceTicket || (ids.isEmpty && !force)) return;
    final session = client!.auth.currentSession;
    if (session == null || session.user.id != target) return;
    final snapshot = deepCopy(data);
    syncing = true;
    error = null;
    notifyListeners();
    try {
      if (!_analyticsCloudReady) {
        final capability = await client!
            .rpc('analytics_capabilities')
            .setHeader('Authorization', 'Bearer ${session.accessToken}');
        if (ticket != _namespaceTicket) return;
        if (capability['version'] != 1) {
          throw StateError('Versi migrasi analitik cloud belum sesuai.');
        }
        _analyticsCloudReady = true;
      }
      final response = await client!
          .rpc(
            'sync_user_state',
            params: {
              'p_operation_id': ids.isEmpty ? uuid.v4() : ids.last,
              'p_expected_version': force ? -1 : snapshot['server_version'],
              'p_payload': snapshot,
            },
          )
          .setHeader('Authorization', 'Bearer ${session.accessToken}');
      if (ticket != _namespaceTicket) return;
      if (response['conflict'] == true) {
        conflict = true;
        error = 'Ada perubahan dari perangkat lain. Pilih data yang akan dipakai di Profil.';
      } else {
        // The additive server trigger preserves sessions from other devices.
        // Reconcile only analytics; edits made while sync ran stay in data.
        final remote = await client!
            .from('user_snapshots')
            .select('payload')
            .eq('user_id', target)
            .single()
            .setHeader('Authorization', 'Bearer ${session.accessToken}');
        if (ticket != _namespaceTicket) return;
        final merged = mergeAnalytics(
          analyticsOf(data),
          analyticsOf(Map<String, dynamic>.from(remote['payload'] as Map)),
        );
        if (merged != null) data['analytics'] = merged;
        _analyticsCache = null;
        data['server_version'] = response['version'];
        data['last_sync'] = DateTime.now().toUtc().toIso8601String();
        await store.acknowledge(target, ids);
        if (ticket != _namespaceTicket) return;
        await _metadata();
        final pending = await store.pending(target);
        if (ticket != _namespaceTicket) return;
        queued = pending.length;
        conflict = false;
        _failures = 0;
      }
    } catch (failure) {
      if (ticket == _namespaceTicket) {
        _failures++;
        if (failure is PostgrestException && failure.code == 'PGRST202') {
          error = 'Cloud memerlukan migrasi analitik v2.1 (202611210001). Data tetap tersimpan di HP. Terapkan migrasi lalu coba sinkron lagi.';
        } else {
          error = 'Belum tersinkron. Jawaban tersimpan di HP; aplikasi akan mencoba lagi.';
          _scheduleSync();
        }
      }
    } finally {
      syncing = false;
      notifyListeners();
      if (ticket != _namespaceTicket && namespace != 'guest' && queued > 0) {
        _scheduleSync();
      }
    }
  }

  Future<void> useCloud() async {
    if (client == null) return;
    final target = namespace, ticket = _namespaceTicket;
    await _writes;
    if (ticket != _namespaceTicket) return;
    final session = client!.auth.currentSession;
    if (session == null || session.user.id != target) return;
    final revision = data['updated_at'], ids = await store.pending(target);
    final remote = await client!
        .from('user_snapshots')
        .select()
        .eq('user_id', target)
        .single()
        .setHeader('Authorization', 'Bearer ${session.accessToken}');
    if (ticket != _namespaceTicket) return;
    if (data['updated_at'] != revision) {
      throw StateError(
        'Ada perubahan baru di HP. Periksa kembali pilihan konflik.',
      );
    }
    await store.acknowledge(target, ids);
    if (ticket != _namespaceTicket) return;
    if (data['updated_at'] != revision) {
      throw StateError(
        'Ada perubahan baru di HP. Periksa kembali pilihan konflik.',
      );
    }
    final localAnalytics = analyticsOf(data);
    data = {
      ...initialData(),
      ...Map<String, dynamic>.from(remote['payload'] as Map),
      'server_version': remote['version'],
    };
    final merged = mergeAnalytics(localAnalytics, analyticsOf(data));
    if (merged != null) data['analytics'] = merged;
    ensureAnalytics(data, DateTime.now().toUtc(), uuid.v4());
    _analyticsCache = null;
    conflict = false;
    queued = 0;
    await _restoreContent(generation: ticket);
    if (ticket != _namespaceTicket) return;
    await _metadata();
    // Retained local intervals must also reach the cloud after choosing cloud.
    if (localAnalytics != null) await save();
    notifyListeners();
  }

  Future<void> logout() async {
    _flushStudy();
    await _writes;
    final old = namespace;
    await client?.auth.signOut();
    if (old != 'guest') await store.remove(old);
    await reminders.disable();
    await switchNamespace('guest');
  }

  Future<void> deleteAll() async {
    _flushStudy();
    final old = namespace, ticket = _namespaceTicket;
    await _writes;
    if (ticket != _namespaceTicket) {
      throw StateError('Akun berubah. Penghapusan dibatalkan.');
    }
    if (old != 'guest') {
      final session = client!.auth.currentSession;
      if (session == null || session.user.id != old) {
        throw StateError('Identitas akun berubah. Penghapusan dibatalkan.');
      }
      await client!
          .rpc('delete_my_account')
          .setHeader('Authorization', 'Bearer ${session.accessToken}');
      if (ticket != _namespaceTicket) {
        await store.remove(old);
        return;
      }
      await client!.auth.signOut(scope: SignOutScope.local);
    }
    _namespaceTicket++;
    await store.remove(old);
    await reminders.disable();
    await switchNamespace('guest');
  }

  Future<Attempt> startAttempt({
    Json? pack,
    String? topic,
    bool quick = false,
  }) async {
    if (activeAttempt != null) return activeAttempt!;
    if (data['downloaded_version'] == null) {
      throw StateError('Simpan paket offline terlebih dahulu.');
    }
    var chosen = <Question>[];
    if (pack != null) {
      final ids = (pack['question_ids'] as List).cast<String>();
      chosen = ids
          .map((id) => content.questions.firstWhere((q) => q.id == id))
          .toList();
    } else {
      final pool =
          content.questions
              .where((q) => topic == null || q.topic == topic)
              .toList()
            ..shuffle(Random());
      if (topic != null) {
        chosen = pool.take(10).toList();
      } else {
        for (final d in domains) {
          chosen.addAll(pool.where((q) => q.domain == d).take(5));
        }
      }
    }
    if (chosen.isEmpty) throw StateError('Belum ada soal untuk topik ini.');
    final now = DateTime.now().toUtc();
    final duration = pack?['duration_seconds'] as int? ?? chosen.length * 75;
    final a = Attempt({
      'id': uuid.v4(),
      'title':
          pack?['name'] ?? (topic == null ? 'Latihan cepat' : 'Latihan $topic'),
      'pack_id': pack?['id'],
      'content_version': content.data['version'],
      'seed': Random().nextInt(1 << 31),
      'started_at': now.toIso8601String(),
      'deadline_at': now.add(Duration(seconds: duration)).toIso8601String(),
      'submitted_at': null,
      'duration_seconds': duration,
      'questions': chosen.map((q) => deepCopy(q.json)).toList(),
      'answers': <String, dynamic>{},
      'flagged': <String>[],
      'index': 0,
      'blueprint': pack == null
          ? {
              'id': 'practice-v1',
              'year': 2024,
              'status': 'practice',
              'passing_grades': null,
              'source_url': historicalSource,
            }
          : deepCopy(ContentRepository.blueprintFor(pack)),
    });
    (data['attempts'] as List).add(a.json);
    await save();
    return a;
  }

  Future<void> answer(Attempt a, String q, String option) async {
    if (a.answer(q, option, DateTime.now())) await save();
  }

  Future<void> submit(Attempt a) async {
    if (!a.submit(DateTime.now())) return;
    final days = data['study_days'] as List;
    if (!days.contains(dayKey)) days.add(dayKey);
    await save();
  }

  Future<void> bookmark(String id) async {
    final b = data['bookmarks'] as List;
    b.contains(id) ? b.remove(id) : b.add(id);
    await save();
  }

  Future<void> completeLesson(String id) async {
    final c = data['completed'] as List;
    if (!c.contains(id)) c.add(id);
    final days = data['study_days'] as List;
    if (!days.contains(dayKey)) days.add(dayKey);
    await save();
  }

  Future<void> downloadContent() async {
    await _restoreContent();
    data['downloaded_version'] = content.data['version'];
    await save();
  }

  Future<void> _restoreContent({int? generation}) async {
    final ticket = generation ?? _namespaceTicket;
    final encoded = data['content_package_b64'] as String?;
    if (encoded != null) {
      try {
        final bytes = base64Decode(encoded);
        final hash = data['content_package_hash'] as String;
        content.validateBytes(bytes, hash);
        if (ticket == _namespaceTicket) content.installBytes(bytes, hash);
        return;
      } catch (_) {
        /* Keep attempts intact and fall back to a verified bundled package. */
      }
    }
    final bundled = ContentRepository();
    await bundled.load();
    if (ticket != _namespaceTicket) return;
    content.data = bundled.data;
    content.manifest = bundled.manifest;
    if (encoded != null) {
      data.remove('content_package_b64');
      data.remove('content_package_hash');
      data['downloaded_version'] = content.data['version'];
      error = 'Cache paket tidak valid. Paket bawaan dipakai; attempt lama tetap aman.';
    }
  }

  Future<String> checkContentUpdates() async {
    if (client == null || namespace == 'guest') {
      throw StateError(
        'Masuk ke akun Supabase untuk memeriksa pembaruan cloud.',
      );
    }
    final ticket = _namespaceTicket;
    void checkAccount() {
      if (ticket != _namespaceTicket) {
        throw StateError('Akun berubah. Pembaruan paket dibatalkan.');
      }
    }

    final release = await client!
        .from('content_releases')
        .select()
        .order('published_at', ascending: false)
        .limit(1)
        .maybeSingle();
    checkAccount();
    if (release == null || release['version'] == content.data['version']) {
      return 'Paket ${content.data['version']} sudah versi terbaru yang tersedia.';
    }
    if (!supportsContentMinimum(release['minimum_app_version'] as String?)) {
      throw StateError(
        'Paket ini membutuhkan versi aplikasi yang lebih baru. Perbarui APK terlebih dahulu.',
      );
    }
    final uri = publicContentUri(
      release['download_url'] as String? ?? '',
      CloudConfig.projectOrigin!,
    );
    final connection = http.Client();
    try {
      final bytes = await downloadPublicContent(connection, uri);
      checkAccount();
      final candidate = content.validateBytes(
        bytes,
        release['content_hash'] as String,
      );
      if (candidate['version'] != release['version']) {
        throw const FormatException('Versi konten tidak cocok dengan katalog.');
      }
      final previous = deepCopy(data),
          oldContent = content.data,
          oldManifest = content.manifest;
      try {
        data['content_package_b64'] = base64Encode(bytes);
        data['content_package_hash'] = release['content_hash'];
        data['downloaded_version'] = candidate['version'];
        await save();
        checkAccount();
        content.installBytes(bytes, release['content_hash'] as String);
        notifyListeners();
      } catch (_) {
        if (ticket == _namespaceTicket) {
          data = previous;
          content.data = oldContent;
          content.manifest = oldManifest;
        }
        rethrow;
      }
      return 'Paket ${candidate['version']} tersimpan. Riwayat attempt tetap memakai versi aslinya.';
    } finally {
      connection.close();
    }
  }

  Future<void> setNotifications(bool enabled) async {
    if (enabled) {
      if (!await reminders.enable()) {
        throw StateError(
          kIsWeb ? 'Pengingat lokal tersedia pada APK Android.' : 'Izin notifikasi belum diberikan. Aktifkan di pengaturan Android.',
        );
      }
    }
    data['notifications'] = enabled;
    await save();
    await reminders.schedule(data);
  }

  Future<void> newSelectionCycle(int year) async {
    cycle['archived'] = true;
    final c = newCycle(uuid.v4(), year);
    (data['cycles'] as List).add(c);
    data['active_cycle'] = c['id'];
    await save();
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _auth?.cancel();
    super.dispose();
  }
}
