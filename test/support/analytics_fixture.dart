import 'package:cpns_journey/core/analytics.dart';
import 'package:cpns_journey/core/models.dart';

Json fixtureAttempt({
  String id = '11111111-1111-4111-8111-111111111111',
  DateTime? at,
  bool submitted = true,
  bool cat = false,
  int perDomain = 2,
  String blueprint = 'historical-2024-v1',
  String option = 'E',
}) {
  final end = at ?? DateTime.utc(2026, 11, 21, 10);
  final questions = [
    for (final d in domains)
      for (var i = 0; i < perDomain; i++)
        {
          'id': '$d-$i',
          'domain': d,
          'topic': '$d topik',
          'version': 1,
          'text': 'Pertanyaan latihan $d $i',
          'explanation': 'Pembahasan untuk latihan.',
          'options': [
            for (var n = 0; n < 5; n++)
              {
                'id': String.fromCharCode(65 + n),
                'text': 'Pilihan ${String.fromCharCode(65 + n)}',
                'score': d == 'TKP'
                    ? n + 1
                    : n == 4
                    ? 5
                    : 0,
              },
          ],
        },
  ];
  final a = Attempt({
    'id': id,
    'title': cat ? 'CAT fixture' : 'Latihan fixture',
    'pack_id': cat ? 'pack-fixture' : null,
    'started_at': end.subtract(const Duration(minutes: 20)).toIso8601String(),
    'deadline_at': end.add(const Duration(minutes: 80)).toIso8601String(),
    'duration_seconds': 6000,
    'submitted_at': submitted ? end.toIso8601String() : null,
    'questions': questions,
    'answers': {for (final q in questions) q['id'] as String: option},
    'flagged': <String>[],
    'index': 0,
    'blueprint': {
      'id': cat ? blueprint : 'practice-v1',
      'status': cat ? 'historical' : 'practice',
      'year': 2024,
    },
  });
  if (submitted) a.json['scores'] = a.scores;
  return a.json;
}

Json fixtureSession(
  String id,
  DateTime start, {
  int seconds = 60,
  String? category = 'TIU',
  String kind = 'lesson',
}) => {
  'id': id,
  'started_at': start.toUtc().toIso8601String(),
  'ended_at': start.toUtc().add(Duration(seconds: seconds)).toIso8601String(),
  'local_day': calendarKey(wibDay(start)),
  'active_seconds': seconds,
  'category': category,
  'kind': kind,
  'source': 'foreground-v1',
  'source_attempt_id': null,
  'created_at': start.toUtc().toIso8601String(),
};

Json fixtureState({
  DateTime? start,
  List<Json> sessions = const [],
  List<Json> attempts = const [],
  int goal = 30,
}) {
  final state = initialData()..['minutes'] = goal;
  ensureAnalytics(
    state,
    start ?? DateTime.utc(2026, 11, 1),
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  );
  (state['analytics'] as Json)['sessions'] = List<Json>.from(sessions);
  state['attempts'] = List<Json>.from(attempts);
  return state;
}
