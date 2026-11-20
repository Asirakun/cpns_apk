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
  Timer? _retry;
  StreamSubscription<AuthState>? _auth;
  Future<void> _writes = Future.value();
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
    } finally {
      if (ticket == _namespaceTicket) {
        switchingAccount = false;
        notifyListeners();
      }
    }
  }

  Future<void> save() async {
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final target = namespace;
    final snapshot = deepCopy(data);
    final id = uuid.v4();
    notifyListeners();
    final job = _writes.then((_) => store.write(target, snapshot, id));
    _writes = job.catchError((Object e) {
      error = 'Penyimpanan perangkat gagal. Kosongkan ruang lalu coba lagi.';
      notifyListeners();
    });
    await job;
    if (target == namespace) {
      queued = (await store.pending(target)).length;
      notifyListeners();
    }
    if (target != 'guest') _scheduleSync();
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
    } catch (_) {
      if (ticket == _namespaceTicket) {
        _failures++;
        error = 'Belum tersinkron. Jawaban tersimpan di HP; aplikasi akan mencoba lagi.';
        _scheduleSync();
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
    data = {
      ...initialData(),
      ...Map<String, dynamic>.from(remote['payload'] as Map),
      'server_version': remote['version'],
    };
    conflict = false;
    queued = 0;
    await _restoreContent(generation: ticket);
    if (ticket != _namespaceTicket) return;
    await _metadata();
    notifyListeners();
  }

  Future<void> logout() async {
    await _writes;
    final old = namespace;
    await client?.auth.signOut();
    if (old != 'guest') await store.remove(old);
    await reminders.disable();
    await switchNamespace('guest');
  }

  Future<void> deleteAll() async {
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
    final release = await client!
        .from('content_releases')
        .select()
        .order('published_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (release == null || release['version'] == content.data['version']) {
      return 'Paket ${content.data['version']} sudah versi terbaru yang tersedia.';
    }
    final minimum = (release['minimum_app_version'] as String? ?? '1.0.0')
        .split('.')
        .map(int.tryParse)
        .toList();
    if (minimum.length != 3 ||
        minimum.any((n) => n == null) ||
        minimum[0]! > 1 ||
        (minimum[0] == 1 && (minimum[1]! > 0 || minimum[2]! > 0))) {
      throw StateError(
        'Paket ini membutuhkan versi aplikasi yang lebih baru. Perbarui APK terlebih dahulu.',
      );
    }
    final uri = Uri.tryParse(release['download_url'] as String? ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.host.endsWith('.supabase.co')) {
      throw StateError(
        'Paket baru belum memiliki URL HTTPS Supabase yang valid.',
      );
    }
    final connection = http.Client();
    try {
      final response = await connection
          .send(http.Request('GET', uri))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw StateError(
          'Paket belum dapat diunduh. Versi sebelumnya tetap tersedia.',
        );
      }
      if ((response.contentLength ?? 0) > 10 * 1024 * 1024) {
        throw StateError('Paket melebihi batas 10 MB.');
      }
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        bytes.addAll(chunk);
        if (bytes.length > 10 * 1024 * 1024) {
          throw StateError('Paket melebihi batas 10 MB.');
        }
      }
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
        content.installBytes(bytes, release['content_hash'] as String);
        notifyListeners();
      } catch (_) {
        data = previous;
        content.data = oldContent;
        content.manifest = oldManifest;
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
    _retry?.cancel();
    _auth?.cancel();
    super.dispose();
  }
}
