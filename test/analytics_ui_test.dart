import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cpns_journey/main.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/services.dart';
import 'package:cpns_journey/core/models.dart';

import 'support/analytics_fixture.dart';
import 'support/memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakarta',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  Future<(AppController, JourneyApp, MemoryStore)> mount(
    WidgetTester tester, {
    String route = '/analytics',
    bool history = false,
  }) async {
    final store = MemoryStore();
    final repo = ContentRepository();
    await tester.runAsync(repo.load);
    final app = AppController(store, repo);
    final now = DateTime.now().toUtc();
    app.data = fixtureState(
      start: now.subtract(const Duration(days: 200)),
      attempts: history
          ? [
              fixtureAttempt(
                at: now.subtract(const Duration(hours: 1)),
                cat: true,
                perDomain: 10,
                option: 'C',
              ),
              fixtureAttempt(
                id: '22222222-2222-4222-8222-222222222222',
                at: now.subtract(const Duration(days: 1)),
                option: 'A',
              ),
            ]
          : [],
      sessions: history
          ? [
              fixtureSession(
                'ui-session',
                now.subtract(const Duration(hours: 2)),
              ),
            ]
          : [],
    );
    app.data['onboarded'] = true;
    app.data['theme'] = 'dark';
    app.data['downloaded_version'] = repo.data['version'];
    final ui = JourneyApp(controller: app);
    ui.router.go(route);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => app)],
        child: ui,
      ),
    );
    await tester.pumpAndSettle();
    return (app, ui, store);
  }

  Future<void> close(
    WidgetTester tester,
    JourneyApp ui,
    MemoryStore store,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    ui.router.dispose();
    await store.close();
  }

  for (final theme in ['dark', 'light']) {
    testWidgets(
      'charts: daily/weekly/monthly ranges and category at 360x800 1.3x $theme',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final (app, ui, store) = await mount(tester, history: true);
        app.data['theme'] = theme;
        await app.save();
        await tester.pumpAndSettle();
        final raw = deepCopy({'attempts': app.data['attempts']});
        for (final name in ['Mingguan', 'Bulanan', 'Harian']) {
          await tester.tap(find.text(name));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byType(DropdownButton<int>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('14 hari').last);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'TKP'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mingguan'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButton<int>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('12 minggu').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bulanan'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButton<int>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('12 bulan').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Nilai CAT'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nilai CAT'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Tabel nilai bulanan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tabel nilai bulanan'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(app.data['attempts'], raw['attempts']);
        await close(tester, ui, store);
      },
    );
  }
  testWidgets('empty chart has a working first-practice action', (
    tester,
  ) async {
    final (_, ui, store) = await mount(tester);
    await tester.scrollUntilVisible(find.text('Buka latihan'), 300);
    await tester.ensureVisible(find.text('Buka latihan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka latihan'));
    await tester.pumpAndSettle();
    expect(find.text('Simulasi CAT penuh'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester, ui, store);
  });
  testWidgets(
    'previous illustrated home remains and its analytics shortcut opens charts',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (_, ui, store) = await mount(tester, route: '/home');
      expect(find.text('Siap melangkah\nlebih dekat?'), findsOneWidget);
      final shortcut = find.text('Analisis\nperforma');
      await tester.ensureVisible(shortcut);
      await tester.pumpAndSettle();
      await tester.tap(shortcut);
      await tester.pumpAndSettle();
      expect(find.text('Analisis belajar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester, ui, store);
    },
  );
}
