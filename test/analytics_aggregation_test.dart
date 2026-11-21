import 'dart:convert';
import 'dart:io';

import 'package:cpns_journey/core/analytics.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/local_store_native.dart';
import 'package:cpns_journey/core/models.dart';
import 'package:cpns_journey/core/services.dart';
import 'package:cpns_journey/core/study_clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/analytics_fixture.dart';
import 'support/memory_store.dart';
import 'support/test_cipher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 11, 21, 10);
  test('AC01 additive schema-1 migration is idempotent and preserves every old field', () {
    final old = initialData()
      ..['attempts'] = [fixtureAttempt(cat: true)]
      ..['custom_extension'] = {'kept': true}
      ..['bookmarks'] = ['lesson-01'];
    (old['cycles'][0]['documents'] as Json)['ijazah'] = {
      'status': 'Siap',
      'note': 'Tetap ada',
    };
    final before = deepCopy(old);
    expect(ensureAnalytics(old, now, 'migration-goal'), isTrue);
    expect(
      ensureAnalytics(old, now.add(const Duration(days: 1)), 'new-goal'),
      isFalse,
    );
    final migrated = deepCopy(old)..remove('analytics');
    expect(migrated, before);
    expect(old['schema_version'], 1);
    expect(
      (old['analytics'] as Json)['tracking_started_at'],
      now.toIso8601String(),
    );
  });
  test('AC04 known zero days differ from unknown history; charts share the summary total', () {
    final state = fixtureState(
      start: DateTime.utc(2026, 11, 17, 1),
      sessions: [
        fixtureSession('s1', DateTime.utc(2026, 11, 18, 1)),
        fixtureSession('s2', DateTime.utc(2026, 11, 20, 1), seconds: 30),
      ],
    );
    final a = LearningAnalytics(state, now: now);
    final buckets = a.buckets(AnalyticsPeriod.daily, 7);
    expect(buckets.map((b) => b.minutes), [
      null,
      null,
      null,
      1.0,
      0.0,
      .5,
      0.0,
    ]);
    final total = a.summary(buckets.first.start, buckets.last.end);
    expect(total.seconds, 90);
    expect(buckets.fold<double>(0, (n, b) => n + b.seconds), total.seconds);
    expect(total.averageActiveMinutes, .75);
  });
  test(
    'AC05 UTC->WIB midnight splits Sunday/Monday across a month boundary',
    () async {
      final app = AppController(MemoryStore());
      app.data = fixtureState(start: DateTime.utc(2026, 10, 1));
      final start = DateTime.utc(2026, 11, 29, 16, 59, 30);
      await app.recordStudySpan(
        ActiveSpan(start, start.add(const Duration(seconds: 60)), 60),
        owner: 'guest',
        kind: 'lesson',
        category: 'TIU',
      );
      final a = LearningAnalytics(app.data, now: DateTime.utc(2026, 12, 1));
      expect(a.sessions.map((s) => s.json['local_day']), [
        '2026-11-29',
        '2026-11-30',
      ]);
      expect(a.sessions.map((s) => s.seconds), [30, 30]);
      final weeks = a.buckets(AnalyticsPeriod.weekly, 2);
      expect(weeks.map((b) => calendarKey(b.start)), [
        '2026-11-23',
        '2026-11-30',
      ]);
      expect(weeks.map((b) => b.seconds), [30, 30]);
      expect(wibDay(DateTime.utc(2026, 11, 30, 17)), DateTime.utc(2026, 12, 1));
      app.dispose();
    },
  );
  test('AC06 TWK/TIU accuracy and weighted TKP quality use final answered denominators', () {
    final attempt = fixtureAttempt(option: 'A');
    (attempt['answers'] as Json)['TKP-1'] = 'C';
    (attempt['answers'] as Json).remove('TWK-1');
    final a = LearningAnalytics(fixtureState(attempts: [attempt]), now: now);
    final s = a.summary(a.today, a.today.add(const Duration(days: 1)));
    expect(s.finalCount, 5);
    expect(s.accuracy, 0);
    expect(s.tkpQuality, 40);
    final blank = fixtureAttempt()..['answers'] = <String, dynamic>{};
    final empty = LearningAnalytics(fixtureState(attempts: [blank]), now: now);
    expect(
      empty
          .summary(empty.today, empty.today.add(const Duration(days: 1)))
          .accuracy,
      isNull,
    );
  });
  test(
    'AC07 retry copies deduplicate session and attempt+question identities',
    () {
      final attempt = fixtureAttempt();
      final session = fixtureSession(
        'same-session',
        DateTime.utc(2026, 11, 21, 1),
        kind: 'practice',
      );
      final a = LearningAnalytics(
        fixtureState(
          attempts: [attempt, deepCopy(attempt), deepCopy(attempt)],
          sessions: [session, deepCopy(session), deepCopy(session)],
        ),
        now: now,
      );
      expect(a.answers.length, 6);
      expect(a.sessions.length, 1);
      expect(
        a.summary(a.today, a.today.add(const Duration(days: 1))).seconds,
        60,
      );
      // Attempt wall duration is deliberately never added to session duration.
    },
  );
  test(
    'AC08 empty state has no fabricated points, accuracy, delta or targets',
    () {
      final a = LearningAnalytics(initialData(), now: now);
      expect(
        a.buckets(AnalyticsPeriod.daily, 7).every((b) => b.minutes == null),
        isTrue,
      );
      expect(a.answers, isEmpty);
      final s = a.summary(a.today, a.today.add(const Duration(days: 1)));
      expect(s.accuracy, isNull);
      expect(s.tkpQuality, isNull);
      expect(s.adherence, isNull);
      expect(a.comparison(AnalyticsPeriod.weekly), isNull);
    },
  );
  test(
    'AC09 score-only history keeps CAT scores without inferring any study time',
    () {
      final old = fixtureAttempt(cat: true)
        ..remove('questions')
        ..remove('answers');
      final state = initialData()..['attempts'] = [old];
      final before = jsonEncode(state);
      final a = LearningAnalytics(state, now: now);
      expect(a.cohorts().single.average, 30);
      expect(a.sessions, isEmpty);
      expect(a.answers, isEmpty);
      expect(
        a.buckets(AnalyticsPeriod.monthly, 6).every((b) => b.minutes == null),
        isTrue,
      );
      expect(jsonEncode(state), before);
    },
  );
  test(
    'AC10 idle at 120 seconds and background never add unobserved duration',
    () {
      var mono = Duration.zero;
      final clock = StudyClock(
        utcNow: () => now.add(mono),
        monotonicNow: () => mono,
      );
      mono = const Duration(seconds: 90);
      expect(clock.take()!.seconds, 90);
      mono = const Duration(seconds: 200);
      expect(clock.take()!.seconds, 30);
      mono = const Duration(seconds: 300);
      expect(clock.take(), isNull);
      clock.interact();
      mono += const Duration(seconds: 10);
      expect(clock.take()!.seconds, 10);
      clock.setForeground(false);
      mono += const Duration(hours: 1);
      expect(clock.take(), isNull);
      clock.setForeground(true);
      mono += const Duration(seconds: 15);
      expect(clock.take()!.seconds, 15);
    },
  );
  test('AC10 changing wall clock does not inflate monotonic active time', () {
    var mono = Duration.zero;
    var wall = now;
    final clock = StudyClock(utcNow: () => wall, monotonicNow: () => mono);
    mono = const Duration(seconds: 15);
    wall = now.add(const Duration(hours: 4));
    expect(clock.take()!.seconds, 15);
  });
  test('AC11 A/B/guest cache and delayed study flush remain isolated across namespaces', () async {
    final store = MemoryStore();
    final content = ContentRepository();
    await content.load();
    final app = AppController(store, content);
    await app.switchNamespace('A');
    final firstGeneration = app.namespaceGeneration;
    app.data['alias'] = 'A';
    await app.save();
    await app.recordStudySpan(
      ActiveSpan(now.subtract(const Duration(seconds: 60)), now, 60),
      owner: 'A',
      kind: 'lesson',
      category: 'TWK',
    );
    final aState = deepCopy(app.data);
    await app.switchNamespace('guest');
    expect(app.namespace, 'guest');
    expect(app.analytics.sessions, isEmpty);
    await app.switchNamespace('B');
    expect(app.analytics.sessions, isEmpty);
    await app.recordStudySpan(
      ActiveSpan(now.subtract(const Duration(seconds: 15)), now, 15),
      owner: 'A',
      kind: 'lesson',
      category: 'TWK',
    );
    expect(app.analytics.sessions, isEmpty);
    await app.switchNamespace('A');
    expect(app.data['analytics'], aState['analytics']);
    expect(app.data['alias'], 'A');
    await app.recordStudySpan(
      ActiveSpan(now.subtract(const Duration(seconds: 15)), now, 15),
      owner: 'A',
      generation: firstGeneration,
      kind: 'lesson',
      category: 'TWK',
    );
    expect(app.data['analytics'], aState['analytics']);
    app.dispose();
    await store.close();
  });
  test('AC12 encrypted cold reopen keeps additive payload, raw CAT and pending operation IDs', () async {
    final dir = await Directory.systemTemp.createTemp('cpns-analytics-');
    final file = File('${dir.path}/existing.sqlite');
    var store = DriftStore(JourneyDatabase(NativeDatabase(file)), testCipher());
    final state = fixtureState(
      attempts: [fixtureAttempt(cat: true)],
      sessions: [
        fixtureSession('offline-session', DateTime.utc(2026, 11, 20, 1)),
      ],
    );
    await store.write('user-A', state, 'offline-op');
    await store.close();
    store = DriftStore(JourneyDatabase(NativeDatabase(file)), testCipher());
    expect(await store.read('user-A'), state);
    expect(await store.pending('user-A'), ['offline-op']);
    expect(await store.read('user-B'), isNull);
    await store.write('user-A', state, 'offline-op');
    expect(await store.pending('user-A'), ['offline-op']);
    await store.close();
    await dir.delete(recursive: true);
  });
  test('multi-device UUID union is idempotent and rejects conflicting immutable records', () {
    final a = analyticsOf(
      fixtureState(sessions: [fixtureSession('A', DateTime.utc(2026, 11, 20))]),
    )!;
    final b = analyticsOf(
      fixtureState(sessions: [fixtureSession('B', DateTime.utc(2026, 11, 20))]),
    )!;
    final merged = mergeAnalytics(a, b)!;
    expect((merged['sessions'] as List).length, 2);
    expect(mergeAnalytics(merged, b), merged);
    final bad = deepCopy(a);
    bad['sessions'][0]['active_seconds'] = 30;
    expect(() => mergeAnalytics(a, bad), throwsStateError);
  });
  test('target changes preserve old days and exclude today, no-target and unknown days', () {
    final state = fixtureState(start: DateTime.utc(2026, 11, 17, 1));
    (state['analytics']['goals'] as List).add({
      'id': 'goal-new',
      'effective_day': '2026-11-20',
      'minutes': 15,
      'created_at': '2026-11-20T01:00:00Z',
    });
    final a = LearningAnalytics(state, now: now);
    expect(a.goalFor(DateTime.utc(2026, 11, 16)), isNull);
    expect(a.goalFor(DateTime.utc(2026, 11, 19)), 30);
    expect(a.goalFor(DateTime.utc(2026, 11, 20)), 15);
    final s = a.summary(DateTime.utc(2026, 11, 15), DateTime.utc(2026, 11, 22));
    expect(s.targetDays, 3);
    expect(s.adherence, 0);
  });
  test('zero comparator produces an absolute delta, never infinity or fake decline', () {
    final state = fixtureState(
      sessions: [fixtureSession('s', DateTime.utc(2026, 11, 21, 1))],
    );
    final a = LearningAnalytics(state, now: now);
    expect(a.comparison(AnalyticsPeriod.daily)!.deltaMinutes, 1);
    expect(a.comparison(AnalyticsPeriod.daily)!.percent, isNull);
  });
  test('recommendation quality needs ten answers within thirty WIB days', () {
    final small = fixtureAttempt(perDomain: 9, option: 'A');
    var a = LearningAnalytics(fixtureState(attempts: [small]), now: now);
    expect(a.topics().every((t) => !t.sufficient), isTrue);
    final enough = fixtureAttempt(perDomain: 10, option: 'A');
    a = LearningAnalytics(
      fixtureState(
        attempts: [
          enough,
          fixtureAttempt(
            id: 'old',
            at: now.subtract(const Duration(days: 31)),
            perDomain: 20,
          ),
        ],
      ),
      now: now,
    );
    expect(a.topics().every((t) => t.count == 10 && t.sufficient), isTrue);
    expect(a.topics(category: 'TKP').single.quality, 20);
  });
  test('only comparable CAT blueprints share a score cohort; active attempts stay separate', () {
    final a = LearningAnalytics(
      fixtureState(
        attempts: [
          fixtureAttempt(id: '1', cat: true),
          fixtureAttempt(id: '2', cat: true),
          fixtureAttempt(id: '3', cat: true, blueprint: 'future-v2'),
          fixtureAttempt(id: '4', cat: true, perDomain: 3),
          fixtureAttempt(id: '5'),
          fixtureAttempt(id: '6', submitted: false),
        ],
      ),
      now: now,
    );
    expect(a.cohorts().map((c) => c.attempts.length).toList()..sort(), [
      1,
      1,
      2,
    ]);
    expect(a.attempts.length, 5);
    expect(a.answers.length, 33);
  });
  test('weekly category stacks, unknown category and mode filters conserve durations', () {
    final a = LearningAnalytics(
      fixtureState(
        sessions: [
          fixtureSession('1', DateTime.utc(2026, 11, 20), category: 'TWK'),
          fixtureSession(
            '2',
            DateTime.utc(2026, 11, 20),
            category: 'TIU',
            kind: 'cat',
          ),
          fixtureSession('3', DateTime.utc(2026, 11, 20), category: null),
        ],
      ),
      now: now,
    );
    final week = a.buckets(AnalyticsPeriod.weekly, 8).last;
    expect(week.secondsByCategory, {
      'TWK': 60,
      'TIU': 60,
      'Tidak diketahui': 60,
    });
    expect(
      a
          .buckets(
            AnalyticsPeriod.weekly,
            8,
            category: 'TIU',
            mode: StudyMode.tryout,
          )
          .last
          .seconds,
      60,
    );
    expect(
      a.buckets(AnalyticsPeriod.weekly, 8, mode: StudyMode.learn).last.seconds,
      120,
    );
  });
}
