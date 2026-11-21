import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpns_journey/main.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/services.dart';

import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'AC14 complete 110-question CAT through real widgets, reload result and analytics',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await (FontLoader(
        'PlusJakarta',
      )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
      final repo = ContentRepository();
      await tester.runAsync(repo.load);
      final store = MemoryStore();
      final app = AppController(store, repo);
      app.data['onboarded'] = true;
      app.data['downloaded_version'] = repo.data['version'];
      final ui = JourneyApp(controller: app);
      ui.router.go('/tryouts');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => app)],
          child: ui,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mulai simulasi').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai simulasi').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Saya siap, mulai CAT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saya siap, mulai CAT'));
      await tester.pumpAndSettle();
      final attempt = app.activeAttempt!;
      final deadline = attempt.deadline;
      for (var i = 0; i < attempt.questions.length; i++) {
        final q = attempt.questions[i];
        final answer =
            q.options.firstWhere((o) => o['id'] == q.best)['text'] as String;
        await tester.ensureVisible(find.text(answer).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(answer).last);
        await tester.pumpAndSettle();
        final next = find.text(i == 109 ? 'Kumpulkan' : 'Berikutnya');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Kumpulkan').last);
      await tester.pumpAndSettle();
      expect(app.results.single.total, 550);
      expect(app.results.single.scores, {'TWK': 150, 'TIU': 175, 'TKP': 225});
      expect(app.results.single.deadline, deadline);
      expect(find.text('Hasil latihan'), findsOneWidget);
      final before = app.results.single.json.toString();
      ui.router.go('/analytics');
      await tester.pumpAndSettle();
      expect(app.analytics.answers.length, 110);
      expect(app.analytics.cohorts().single.average, 550);
      expect(app.results.single.json.toString(), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      ui.router.dispose();
      await store.close();
    },
  );
}
