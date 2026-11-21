import 'dart:convert';
import 'dart:math' as math;

import 'models.dart';

// Calendar arithmetic is done in UTC-shaped WIB wall dates, never host time.
DateTime wibWall(DateTime utc) => utc.toUtc().add(const Duration(hours: 7));
DateTime calendarDay(DateTime wall) =>
    DateTime.utc(wall.year, wall.month, wall.day);
DateTime wibDay(DateTime utc) => calendarDay(wibWall(utc));
String calendarKey(DateTime day) => day.toIso8601String().substring(0, 10);
DateTime dayUtc(DateTime day) => day.subtract(const Duration(hours: 7));
DateTime monday(DateTime day) => day.subtract(Duration(days: day.weekday - 1));
DateTime monthStart(DateTime day) => DateTime.utc(day.year, day.month);
DateTime? timestamp(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

Json? analyticsOf(Json state) => state['analytics'] is Map
    ? Map<String, dynamic>.from(state['analytics'] as Map)
    : null;

/// Add-only payload migration. schema_version, IDs, raw answers and all existing
/// keys stay unchanged. The original start timestamp is never reset on restart.
bool ensureAnalytics(Json state, DateTime now, String goalId) {
  if (state['analytics'] != null) {
    if (analyticsOf(state)?['version'] != 1) {
      throw const FormatException(
        'Versi analisis belum didukung. Data lama tetap disimpan.',
      );
    }
    return false;
  }
  state['analytics'] = {
    'version': 1,
    'tracking_started_at': now.toUtc().toIso8601String(),
    'sessions': <Json>[],
    'goals': <Json>[
      {
        'id': goalId,
        'effective_day': calendarKey(wibDay(now)),
        'minutes': state['minutes'] ?? 45,
        'created_at': now.toUtc().toIso8601String(),
      },
    ],
  };
  return true;
}

/// Merge immutable UUID records only. A collision is an error, not last-write-
/// wins. Used for cloud reconciliation without discarding new local intervals.
Json? mergeAnalytics(Json? local, Json? remote) {
  if (local == null) return remote == null ? null : deepCopy(remote);
  if (remote == null) return deepCopy(local);
  if (local['version'] != 1 || remote['version'] != 1) {
    throw const FormatException('Versi analisis tidak kompatibel.');
  }
  final merged = <String, dynamic>{...remote, ...local, 'version': 1};
  for (final field in ['sessions', 'goals']) {
    final byId = <String, Json>{};
    for (final raw in [
      ...(remote[field] as List? ?? []),
      ...(local[field] as List? ?? []),
    ]) {
      final item = Map<String, dynamic>.from(raw as Map);
      final id = item['id'] as String;
      if (byId.containsKey(id) &&
          canonicalJson(byId[id]) != canonicalJson(item)) {
        throw StateError(
          'Identitas catatan analisis bertabrakan. Salinan tetap dipertahankan.',
        );
      }
      byId[id] = item;
    }
    merged[field] = byId.values.toList()
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  }
  final starts = [
    timestamp(local['tracking_started_at']),
    timestamp(remote['tracking_started_at']),
  ].whereType<DateTime>().toList()..sort();
  if (starts.isNotEmpty) {
    merged['tracking_started_at'] = starts.first.toIso8601String();
  }
  return merged;
}

String canonicalJson(dynamic value) {
  dynamic sorted(dynamic v) {
    if (v is Map) {
      final keys = v.keys.cast<String>().toList()..sort();
      return {for (final k in keys) k: sorted(v[k])};
    }
    if (v is List) return v.map(sorted).toList();
    return v;
  }

  return jsonEncode(sorted(value));
}

enum AnalyticsPeriod { daily, weekly, monthly }

enum StudyMode { all, learn, tryout }

class StudySession {
  StudySession(this.json);
  final Json json;
  String get id => json['id'] as String;
  DateTime get start => timestamp(json['started_at'])!;
  DateTime get end => timestamp(json['ended_at'])!;
  String? get category => json['category'] as String?;
  String get kind => json['kind'] as String;
  double get seconds => (json['active_seconds'] as num).toDouble();
  bool get valid =>
      json['id'] is String &&
      json['kind'] is String &&
      (json['category'] == null || json['category'] is String) &&
      timestamp(json['started_at']) != null &&
      timestamp(json['ended_at']) != null &&
      end.isAfter(start) &&
      json['active_seconds'] is num &&
      seconds.isFinite &&
      seconds > 0 &&
      seconds <= 120 &&
      seconds <= end.difference(start).inMilliseconds / 1000 + .002 &&
      ['lesson', 'practice', 'cat', 'review'].contains(kind) &&
      (category == null || domains.contains(category));
  bool matches(String category, StudyMode mode) =>
      (category == 'Semua' || this.category == category) &&
      (mode == StudyMode.all ||
          (mode == StudyMode.tryout ? kind == 'cat' : kind != 'cat'));
}

class FinalAnswer {
  FinalAnswer({
    required this.attempt,
    required this.question,
    required this.option,
    required this.at,
  });
  final Json attempt, question, option;
  final DateTime at;
  String get domain => question['domain'] as String;
  String get topic => question['topic'] as String? ?? 'Topik belum tercatat';
  double get score => (option['score'] as num).toDouble();
  double get maximum => (question['options'] as List)
      .cast<Map>()
      .map((o) => (o['score'] as num).toDouble())
      .reduce(math.max);
  bool get correct => score == maximum;
  bool get cat => isCat(attempt);
  bool matches(String category, StudyMode mode) =>
      (category == 'Semua' || domain == category) &&
      (mode == StudyMode.all || (mode == StudyMode.tryout ? cat : !cat));
}

bool isCat(Json attempt) =>
    (attempt['blueprint'] as Map?)?['status'] != 'practice' &&
    (attempt['pack_id'] != null ||
        (attempt['blueprint'] as Map?)?['status'] == 'historical');

class TopicQuality {
  TopicQuality(this.domain, this.topic, this.answers);
  final String domain, topic;
  final List<FinalAnswer> answers;
  int get count => answers.length;
  bool get sufficient => count >= 10;
  double get quality => domain == 'TKP'
      ? 100 *
            answers.fold<double>(0, (n, a) => n + a.score) /
            answers.fold<double>(0, (n, a) => n + a.maximum)
      : 100 * answers.where((a) => a.correct).length / count;
  DateTime get latest =>
      answers.map((a) => a.at).reduce((a, b) => a.isAfter(b) ? a : b);
}

class AnalyticsBucket {
  AnalyticsBucket(
    this.start,
    this.end,
    this.secondsByCategory,
    this.complete,
    this.samples,
  );
  final DateTime start, end; // WIB wall calendar boundaries
  final Map<String, double> secondsByCategory;
  final bool complete;
  final int samples;
  double get seconds => secondsByCategory.values.fold(0, (a, b) => a + b);
  double? get minutes => complete || seconds > 0 ? seconds / 60 : null;
}

class AnalyticsSummary {
  AnalyticsSummary(
    this.seconds,
    this.finalCount,
    this.accuracy,
    this.tkpQuality,
    this.activeDays,
    this.targetDays,
    this.achievedDays,
  );
  final double seconds;
  final int finalCount, activeDays, targetDays, achievedDays;
  final double? accuracy, tkpQuality;
  double? get adherence =>
      targetDays == 0 ? null : achievedDays / targetDays * 100;
  double? get averageActiveMinutes =>
      activeDays == 0 ? null : seconds / 60 / activeDays;
}

class PeriodComparison {
  const PeriodComparison(this.deltaMinutes, this.percent);
  final double deltaMinutes;
  final double? percent;
}

class CatCohort {
  CatCohort(this.key, this.attempts);
  final String key;
  final List<Json> attempts;
  String get label {
    final a = attempts.first;
    final bp = a['blueprint'] as Map? ?? {};
    final maximum = a['maximum'] as num? ?? _maximum(a);
    return '${bp['id'] ?? 'Blueprint lama'} · ${maximum > 0 ? '$maximum maks.' : 'maks. belum tercatat'} · n=${attempts.length}';
  }

  double get average =>
      attempts.fold<double>(0, (n, a) => n + catScore(a)) / attempts.length;
}

double _maximum(Json a) =>
    (a['questions'] as List? ?? []).cast<Map>().fold<double>(
      0,
      (n, q) =>
          n +
          (q['options'] as List)
              .cast<Map>()
              .map((o) => (o['score'] as num).toDouble())
              .reduce(math.max),
    );
double catScore(Json a) => a['scores'] is Map
    ? (a['scores'] as Map).values.whereType<num>().fold<double>(
        0,
        (n, v) => n + v,
      )
    : 0;

/// One read model for charts and cards. No I/O and no writes to raw history.
class LearningAnalytics {
  LearningAnalytics(this.state, {required DateTime now}) : now = now.toUtc() {
    final ids = <String>{};
    for (final raw in (analyticsOf(state)?['sessions'] as List? ?? [])) {
      final s = StudySession(Map<String, dynamic>.from(raw as Map));
      if (s.valid && ids.add(s.id) && !s.end.isAfter(this.now)) sessions.add(s);
    }
    sessions.sort((a, b) => a.start.compareTo(b.start));
    final submitted = <String, Json>{};
    for (final raw in (state['attempts'] as List? ?? [])) {
      final a = Map<String, dynamic>.from(raw as Map);
      final at = timestamp(a['submitted_at']);
      if (at != null && !at.isAfter(this.now) && a['id'] is String) {
        submitted.putIfAbsent(a['id'] as String, () => a);
      }
    }
    attempts.addAll(submitted.values);
    attempts.sort(
      (a, b) =>
          timestamp(a['submitted_at'])!
              .compareTo(timestamp(b['submitted_at'])!),
    );
    for (final a in attempts) {
      final seen = <String>{};
      final selections = a['answers'] as Map? ?? {};
      for (final raw in (a['questions'] as List? ?? [])) {
        final q = Map<String, dynamic>.from(raw as Map);
        if (!domains.contains(q['domain']) || !seen.add(q['id'] as String)) {
          continue;
        }
        final opts = (q['options'] as List? ?? []).cast<Map>();
        final selected = opts
            .where((o) => o['id'] == selections[q['id']] && o['score'] is num)
            .firstOrNull;
        if (selected == null ||
            opts.isEmpty ||
            opts.any((o) => o['score'] is! num) ||
            opts.map((o) => (o['score'] as num).toDouble()).reduce(math.max) <=
                0) {
          continue;
        }
        answers.add(
          FinalAnswer(
            attempt: a,
            question: q,
            option: Map<String, dynamic>.from(selected),
            at: timestamp(a['submitted_at'])!,
          ),
        );
      }
    }
  }
  final Json state;
  final DateTime now;
  final sessions = <StudySession>[];
  final attempts = <Json>[];
  final answers = <FinalAnswer>[];
  DateTime get today => wibDay(now);
  DateTime? get trackingStart =>
      timestamp(analyticsOf(state)?['tracking_started_at']);
  bool knownDay(DateTime day) =>
      trackingStart != null && !dayUtc(day).isBefore(trackingStart!);

  double secondsBetween(
    DateTime startUtc,
    DateTime endUtc, {
    String category = 'Semua',
    StudyMode mode = StudyMode.all,
  }) {
    double total = 0;
    for (final s in sessions.where((s) => s.matches(category, mode))) {
      final start = s.start.isAfter(startUtc) ? s.start : startUtc;
      final end = s.end.isBefore(endUtc) ? s.end : endUtc;
      if (end.isAfter(start)) {
        total +=
            s.seconds *
            end.difference(start).inMicroseconds /
            s.end.difference(s.start).inMicroseconds;
      }
    }
    return total;
  }

  int? goalFor(DateTime day) {
    final candidates =
        (analyticsOf(state)?['goals'] as List? ?? [])
            .cast<Map>()
            .where(
              (g) =>
                  g['effective_day'] is String &&
                  (g['effective_day'] as String).compareTo(calendarKey(day)) <=
                      0,
            )
            .toList()
          ..sort((a, b) {
            final d = (a['effective_day'] as String).compareTo(
              b['effective_day'] as String,
            );
            if (d != 0) return d;
            final stamp = (a['created_at'] as String).compareTo(
              b['created_at'] as String,
            );
            return stamp == 0
                ? (a['id'] as String).compareTo(b['id'] as String)
                : stamp;
          });
    return candidates.isEmpty
        ? null
        : (candidates.last['minutes'] as num?)?.toInt();
  }

  List<AnalyticsBucket> buckets(
    AnalyticsPeriod period,
    int count, {
    String category = 'Semua',
    StudyMode mode = StudyMode.all,
  }) {
    DateTime boundary(int offset) => switch (period) {
      AnalyticsPeriod.daily => today.add(Duration(days: offset)),
      AnalyticsPeriod.weekly => monday(today).add(Duration(days: offset * 7)),
      AnalyticsPeriod.monthly => DateTime.utc(today.year, today.month + offset),
    };
    return List.generate(count, (i) {
      final start = boundary(i - count + 1), end = boundary(i - count + 2);
      final byCategory = <String, double>{};
      for (final d in [...domains, 'Tidak diketahui']) {
        if (category != 'Semua' && d != category) continue;
        final actual = d == 'Tidak diketahui' ? null : d;
        for (final s in sessions.where(
          (s) => s.category == actual && s.matches(category, mode),
        )) {
          final l = s.start.isAfter(dayUtc(start)) ? s.start : dayUtc(start);
          final r = s.end.isBefore(dayUtc(end)) ? s.end : dayUtc(end);
          if (r.isAfter(l)) {
            byCategory[d] =
                (byCategory[d] ?? 0) +
                s.seconds *
                    r.difference(l).inMicroseconds /
                    s.end.difference(s.start).inMicroseconds;
          }
        }
      }
      final n = answers
          .where(
            (a) =>
                !wibDay(a.at).isBefore(start) &&
                wibDay(a.at).isBefore(end) &&
                a.matches(category, mode),
          )
          .length;
      return AnalyticsBucket(start, end, byCategory, knownDay(start), n);
    });
  }

  AnalyticsSummary summary(
    DateTime start,
    DateTime end, {
    String category = 'Semua',
    StudyMode mode = StudyMode.all,
  }) {
    final finalAnswers = answers
        .where(
          (a) =>
              !wibDay(a.at).isBefore(start) &&
              wibDay(a.at).isBefore(end) &&
              a.matches(category, mode),
        )
        .toList();
    final single = finalAnswers.where((a) => a.domain != 'TKP').toList();
    final tkp = finalAnswers.where((a) => a.domain == 'TKP').toList();
    int active = 0, target = 0, achieved = 0;
    for (
      var day = start;
      day.isBefore(end) && !day.isAfter(today);
      day = day.add(const Duration(days: 1))
    ) {
      final seconds = secondsBetween(
        dayUtc(day),
        dayUtc(day.add(const Duration(days: 1))),
        category: category,
        mode: mode,
      );
      if (seconds > 0) active++;
      final goal = goalFor(day);
      // Targets are global, never divided between categories or counted early.
      if (day.isBefore(today) && knownDay(day) && goal != null && goal > 0) {
        target++;
        if (secondsBetween(
              dayUtc(day),
              dayUtc(day.add(const Duration(days: 1))),
            ) >=
            goal * 60) {
          achieved++;
        }
      }
    }
    return AnalyticsSummary(
      secondsBetween(
        dayUtc(start),
        dayUtc(end),
        category: category,
        mode: mode,
      ),
      finalAnswers.length,
      single.isEmpty
          ? null
          : single.where((a) => a.correct).length / single.length * 100,
      tkp.isEmpty
          ? null
          : 100 *
                tkp.fold<double>(0, (n, a) => n + a.score) /
                tkp.fold<double>(0, (n, a) => n + a.maximum),
      active,
      target,
      achieved,
    );
  }

  List<TopicQuality> topics({
    String category = 'Semua',
    StudyMode mode = StudyMode.all,
  }) {
    final map = <String, List<FinalAnswer>>{};
    final cutoff = dayUtc(today.subtract(const Duration(days: 29)));
    for (final a in answers.where(
      (a) => !a.at.isBefore(cutoff) && a.matches(category, mode),
    )) {
      (map['${a.domain}\u0000${a.topic}'] ??= []).add(a);
    }
    final result = map.values
        .map((a) => TopicQuality(a.first.domain, a.first.topic, a))
        .toList();
    result.sort((a, b) {
      if (a.sufficient != b.sufficient) return a.sufficient ? -1 : 1;
      final quality = a.quality.compareTo(b.quality);
      if (quality != 0) return quality;
      final last = a.latest.compareTo(b.latest);
      return last != 0 ? last : a.topic.compareTo(b.topic);
    });
    return result;
  }

  List<CatCohort> cohorts() {
    final map = <String, List<Json>>{};
    for (final a in attempts.where(isCat)) {
      final rubric = <String, dynamic>{};
      for (final d in domains) {
        final qs = (a['questions'] as List? ?? [])
            .cast<Map>()
            .where((q) => q['domain'] == d)
            .toList();
        final patterns =
            qs
                .map(
                  (q) =>
                      ((q['options'] as List)
                              .cast<Map>()
                              .map((o) => o['score'] as num)
                              .toList()
                            ..sort())
                          .join(','),
                )
                .toSet()
                .toList()
              ..sort();
        rubric[d] = {'count': qs.length, 'rubrics': patterns};
      }
      // Unknown historical blueprint IDs cannot establish comparability.
      final bp = a['blueprint'] as Map? ?? {};
      final key = bp['id'] == null
          ? 'unknown:${a['id']}'
          : canonicalJson({
              'blueprint': bp,
              'rubric': rubric,
              'duration': a['duration_seconds'],
            });
      (map[key] ??= []).add(a);
    }
    return map.entries.map((e) => CatCohort(e.key, e.value)).toList();
  }

  PeriodComparison? comparison(
    AnalyticsPeriod period, {
    String category = 'Semua',
    StudyMode mode = StudyMode.all,
  }) {
    final current = switch (period) {
      AnalyticsPeriod.daily => today,
      AnalyticsPeriod.weekly => monday(today),
      AnalyticsPeriod.monthly => monthStart(today),
    };
    final previous = switch (period) {
      AnalyticsPeriod.daily => current.subtract(const Duration(days: 1)),
      AnalyticsPeriod.weekly => current.subtract(const Duration(days: 7)),
      AnalyticsPeriod.monthly => DateTime.utc(current.year, current.month - 1),
    };
    final elapsed = now.difference(dayUtc(current));
    final previousEnd = dayUtc(previous).add(elapsed);
    if (trackingStart == null ||
        dayUtc(previous).isBefore(trackingStart!) ||
        previousEnd.isAfter(dayUtc(current))) {
      return null;
    }
    final a =
        secondsBetween(dayUtc(current), now, category: category, mode: mode) /
        60;
    final b =
        secondsBetween(
          dayUtc(previous),
          previousEnd,
          category: category,
          mode: mode,
        ) /
        60;
    return PeriodComparison(a - b, b > 0 ? (a - b) / b * 100 : null);
  }
}
