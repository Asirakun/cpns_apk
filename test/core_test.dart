import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'support/memory_store.dart';
import 'support/test_cipher.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:cpns_journey/core/models.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/services.dart';
import 'package:cpns_journey/core/local_store_native.dart';

Json content =
    jsonDecode(File('assets/content/content.json').readAsStringSync()) as Json;
Attempt makeAttempt({int count = 110}) {
  final ids = (content['packs'][0]['question_ids'] as List)
      .cast<String>()
      .take(count)
      .toSet();
  final qs = (content['questions'] as List)
      .cast<Json>()
      .where((q) => ids.contains(q['id']))
      .map(deepCopy)
      .toList();
  final start = DateTime.utc(2026, 11, 20, 10);
  return Attempt({
    'id': const Uuid().v4(),
    'title': 'Test CAT',
    'started_at': start.toIso8601String(),
    'deadline_at': start.add(const Duration(minutes: 100)).toIso8601String(),
    'questions': qs,
    'answers': <String, dynamic>{},
    'flagged': <String>[],
    'index': 0,
    'submitted_at': null,
    'blueprint': {'status': 'historical'},
  });
}

void main() {
  test('a delayed account A read cannot overwrite active account B', () async {
    final store = DelayedStore();
    final bytes = utf8.encode(jsonEncode(content));
    final b = initialData()
      ..['alias'] = 'Account B'
      ..['bookmarks'] = ['B-only']
      ..['content_package_b64'] = base64Encode(bytes)
      ..['content_package_hash'] = sha256.convert(bytes).toString();
    store.states['B'] = b;
    final repo = ContentRepository()
      ..data = deepCopy(content)
      ..manifest = {'version': '1.0.0'};
    final app = AppController(store, repo);
    final oldRead = app.switchNamespace('A');
    await Future<void>.delayed(Duration.zero);
    await app.switchNamespace('B');
    store.delayedA.complete(
      initialData()
        ..['alias'] = 'Account A'
        ..['bookmarks'] = ['A-only'],
    );
    await oldRead;
    expect(app.namespace, 'B');
    expect(app.data['alias'], 'Account B');
    expect(app.data['bookmarks'], ['B-only']);
    app.dispose();
  });

  test(
    'quick practice has exactly 15 unique questions and immutable snapshots',
    () async {
      final repo = ContentRepository()..data = deepCopy(content);
      final app = AppController(MemoryStore(), repo);
      app.data['downloaded_version'] = '1.0.0';
      final attempt = await app.startAttempt(quick: true);
      expect(attempt.questions.length, 15);
      expect(attempt.questions.map((q) => q.id).toSet().length, 15);
      expect(attempt.questions.where((q) => q.domain == 'TKP').length, 5);
      final text = attempt.questions.first.text;
      repo.data['questions'][0]['text'] = 'Master updated';
      expect(attempt.questions.first.text, text);
      app.dispose();
    },
  );
  test('corrupt content package rolls back; valid version retains old attempt snapshot', () {
    final repo = ContentRepository()
      ..data = deepCopy(content)
      ..manifest = {'version': '1.0.0'};
    final previous = repo.data;
    final bytes = utf8.encode(jsonEncode({...content, 'version': '1.0.1'}));
    expect(
      () => repo.installBytes(bytes, 'invalid-hash'),
      throwsFormatException,
    );
    expect(identical(repo.data, previous), isTrue);
    final attempt = makeAttempt();
    final oldSnapshot = jsonEncode(attempt.json);
    repo.installBytes(bytes, sha256.convert(bytes).toString());
    expect(repo.data['version'], '1.0.1');
    expect(jsonEncode(attempt.json), oldSnapshot);
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  test('450 valid original questions, 3 complete disjoint CAT packs', () {
    ContentRepository.validate(content);
    expect((content['questions'] as List).length, 450);
    final all = <String>{};
    for (final pack in (content['packs'] as List).cast<Json>()) {
      final ids = (pack['question_ids'] as List).cast<String>();
      expect(ids.length, 110);
      expect(all.intersection(ids.toSet()), isEmpty);
      all.addAll(ids);
      for (final item in {'TWK': 30, 'TIU': 35, 'TKP': 45}.entries) {
        expect(
          (content['questions'] as List)
              .cast<Json>()
              .where((q) => ids.contains(q['id']) && q['domain'] == item.key)
              .length,
          item.value,
        );
      }
    }
  });
  test('all maximum answers = TWK150 TIU175 TKP225, total550', () {
    final a = makeAttempt();
    for (final q in a.questions) {
      expect(a.answer(q.id, q.best, DateTime.utc(2026, 11, 20, 10, 1)), isTrue);
    }
    expect(a.scores, {'TWK': 150, 'TIU': 175, 'TKP': 225});
    expect(a.total, 550);
  });
  test('blank zero; wrong single answers zero; lowest TKP gives45', () {
    final a = makeAttempt();
    expect(a.total, 0);
    for (final q in a.questions) {
      final option = q.options.reduce(
        (a, b) => (a['score'] as int) < (b['score'] as int) ? a : b,
      );
      a.answer(q.id, option['id'] as String, DateTime.utc(2026, 11, 20, 10, 1));
    }
    expect(a.scores, {'TWK': 0, 'TIU': 0, 'TKP': 45});
  });
  test('every TKP weight is respected independently', () {
    for (final q
        in (content['questions'] as List)
            .cast<Json>()
            .where((q) => q['domain'] == 'TKP')
            .map(Question.new)) {
      for (final option in q.options) {
        expect(q.score(option['id'] as String), option['score']);
      }
      expect(q.score(null), 0);
    }
  });
  test('deadline survives serialization and disallows late answers', () {
    final a = makeAttempt();
    final b = Attempt(deepCopy(a.json));
    expect(b.remaining(DateTime.utc(2026, 11, 20, 10, 30)), 4200);
    expect(
      b.answer(b.questions.first.id, 'A', DateTime.utc(2026, 11, 20, 11, 40)),
      isFalse,
    );
    expect(b.remaining(DateTime.utc(2026, 11, 21)), 0);
  });
  test('submit is idempotent and freezes answers, including timeout', () {
    final a = makeAttempt();
    expect(a.submit(DateTime.utc(2026, 11, 20, 12)), isTrue);
    final stamp = a.json['submitted_at'];
    expect(stamp, a.json['deadline_at']);
    expect(a.submit(DateTime.utc(2026, 11, 21)), isFalse);
    expect(a.json['submitted_at'], stamp);
    expect(
      a.answer(a.questions.first.id, 'A', DateTime.utc(2026, 11, 20, 10, 5)),
      isFalse,
    );
  });
  test('snapshot survives changes to the content master', () {
    final a = makeAttempt();
    final before = jsonEncode(a.json);
    final original = (content['questions'] as List).first as Json;
    final text = original['text'];
    original['text'] = 'new revision';
    expect(jsonEncode(a.json), before);
    original['text'] = text;
  });
  test('D3 underway does not count as completed D3', () {
    expect(eligibleEducation(['D3'], 'SMA', 'Sedang kuliah'), isFalse);
    expect(eligibleEducation(['D3'], 'D3', 'Sedang kuliah'), isFalse);
    expect(eligibleEducation(['SMA'], 'SMA', 'Sedang kuliah'), isTrue);
    expect(eligibleEducation(['D3'], 'D3', 'Lulus'), isTrue);
  });
  test('quiet hours respect same-day and overnight windows', () {
    expect(
      outsideQuietHours(DateTime(2026, 11, 20, 22), 21, 7),
      DateTime(2026, 11, 21, 7),
    );
    expect(
      outsideQuietHours(DateTime(2026, 11, 20, 3), 21, 7),
      DateTime(2026, 11, 20, 7),
    );
    expect(
      outsideQuietHours(DateTime(2026, 11, 20, 19), 21, 7),
      DateTime(2026, 11, 20, 19),
    );
    expect(
      outsideQuietHours(DateTime(2026, 11, 20, 13), 12, 14),
      DateTime(2026, 11, 20, 14),
    );
  });
  test('Drift cold reopen preserves answers, deadlines, score and immutable submission', () async {
    final dir = await Directory.systemTemp.createTemp('cpns-recovery-');
    final path = File('${dir.path}/test.sqlite');
    var store = DriftStore(JourneyDatabase(NativeDatabase(path)), testCipher());
    final state = initialData();
    final a = makeAttempt();
    a.answer(
      a.questions.first.id,
      a.questions.first.best,
      DateTime.utc(2026, 11, 20, 10, 5),
    );
    state['attempts'] = [a.json];
    await store.write('user-A', state, 'operation-1');
    await store.close();
    store = DriftStore(JourneyDatabase(NativeDatabase(path)), testCipher());
    final recovered = Attempt(
      (await store.read('user-A'))!['attempts'][0] as Json,
    );
    expect(recovered.answers, a.answers);
    expect(recovered.deadline, a.deadline);
    expect(recovered.total, 5);
    recovered.submit(DateTime.utc(2026, 11, 20, 10, 6));
    state['attempts'] = [recovered.json];
    await store.write('user-A', state, 'operation-2');
    await store.close();
    store = DriftStore(JourneyDatabase(NativeDatabase(path)), testCipher());
    final result = Attempt(
      (await store.read('user-A'))!['attempts'][0] as Json,
    );
    expect(result.submitted, isTrue);
    expect(result.total, 5);
    await store.close();
    await dir.delete(recursive: true);
  });
  test('SQLite namespaces and outbox isolate two users; duplicate operation is idempotent', () async {
    final store = DriftStore(
      JourneyDatabase(NativeDatabase.memory()),
      testCipher(),
    );
    await store.write('A', {'alias': 'A'}, 'op-A');
    await store.write('B', {'alias': 'B'}, 'op-B');
    await store.write('A', {'alias': 'A-new'}, 'op-A');
    expect(await store.pending('A'), ['op-A']);
    await store.acknowledge('B', ['op-A']);
    expect(await store.pending('A'), ['op-A']);
    await store.remove('A');
    expect(await store.read('A'), isNull);
    expect((await store.read('B'))!['alias'], 'B');
    await store.close();
  });
  test(
    'profile and cycle edits preserve past attempts and prior-cycle documents',
    () async {
      final store = DriftStore(
        JourneyDatabase(NativeDatabase.memory()),
        testCipher(),
      );
      final repo = ContentRepository()..data = content;
      final app = AppController(store, repo);
      final a = makeAttempt();
      app.data['attempts'] = [a.json];
      app.docs['ijazah'] = {'status': 'Siap'};
      app.data['alias'] = 'New alias';
      await app.save();
      await app.newSelectionCycle(2027);
      expect(app.attempts.single.id, a.id);
      expect((app.data['cycles'][0]['documents']['ijazah']['status']), 'Siap');
      expect(app.docs, isEmpty);
      expect(app.cycle['year'], 2027);
      await store.close();
      app.dispose();
    },
  );
}

class DelayedStore extends MemoryStore {
  final delayedA = Completer<Json?>();
  @override
  Future<Json?> read(String namespace) =>
      namespace == 'A' ? delayedA.future : super.read(namespace);
}
