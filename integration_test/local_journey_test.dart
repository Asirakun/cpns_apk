import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:cpns_journey/main.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/services.dart';
import 'package:cpns_journey/core/local_store_native.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('complete a 110-question local CAT without cloud access', (
    tester,
  ) async {
    final store = DriftStore(JourneyDatabase(NativeDatabase.memory()));
    final content = ContentRepository();
    await content.load();
    final app = AppController(store, content);
    app.data['onboarded'] = true;
    app.data['downloaded_version'] = content.data['version'];
    final ui = JourneyApp(controller: app);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => app)],
        child: ui,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Tryout'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai simulasi').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saya siap, mulai CAT'));
    await tester.pumpAndSettle();
    final a = app.activeAttempt!;
    expect(a.questions.length, 110);
    for (var i = 0; i < a.questions.length; i++) {
      final q = a.questions[i];
      final text =
          q.options.firstWhere((o) => o['id'] == q.best)['text'] as String;
      final option = find.text(text).last;
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      if (i < 109) {
        await tester.tap(find.text('Berikutnya'));
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(find.text('Kumpulkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kumpulkan').last);
    await tester.pumpAndSettle();
    expect(app.results.single.total, 550);
    expect(app.results.single.scores, {'TWK': 150, 'TIU': 175, 'TKP': 225});
    expect(find.text('Hasil latihan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    ui.router.dispose();
    await store.close();
  });
}
