import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/memory_store.dart';

import 'package:cpns_journey/main.dart';
import 'package:cpns_journey/app/floating_nav.dart';
import 'package:cpns_journey/app/paper.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('PlusJakarta')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await loader.load();
  });
  for (final width in [360.0, 430.0]) {
    for (final theme in ['dark', 'light']) {
      testWidgets('five tabs at ${width}dp with 1.3x text and $theme theme', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryStore();
        final repo = ContentRepository();
        await tester.runAsync(() => repo.load());
        final app = AppController(store, repo);
        app.data['onboarded'] = true;
        app.data['theme'] = theme;
        app.data['downloaded_version'] = '1.0.0';
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appProvider.overrideWith((ref) => app)],
            child: JourneyApp(controller: app),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Siap melangkah\nlebih dekat?'), findsOneWidget);
        final dock = find.byType(FloatingPaperNavBar);
        final material = find
            .descendant(of: dock, matching: find.byType(Material))
            .first;
        expect(tester.widget<Material>(material).shape, isA<StadiumBorder>());
        expect(tester.getRect(material).left, closeTo(12, .01));
        expect(tester.getRect(material).right, closeTo(width - 12, .01));
        expect(
          tester
              .widgetList<PaperArt>(
                find.descendant(of: dock, matching: find.byType(PaperArt)),
              )
              .map((art) => art.asset),
          [
            PaperAsset.home,
            PaperAsset.book,
            PaperAsset.checklist,
            PaperAsset.route,
            PaperAsset.avatar,
          ],
        );
        expect(tester.takeException(), isNull);
        for (final name in [
          'Belajar',
          'Tryout',
          'Journey',
          'Profil',
          'Beranda',
        ]) {
          await tester.tap(
            find.descendant(
              of: find.byType(FloatingPaperNavBar),
              matching: find.text(name),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$name at $width');
        }
        await tester.pumpWidget(const SizedBox());
        await store.close();
      });
    }
  }
  testWidgets(
    'onboarding provides local start and historical/Medan disclosure',
    (tester) async {
      final store = MemoryStore();
      final repo = ContentRepository();
      await tester.runAsync(() => repo.load());
      final app = AppController(store, repo);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => app)],
          child: JourneyApp(controller: app),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mulai di perangkat'), findsOneWidget);
      expect(find.textContaining('Medan belum'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await store.close();
    },
  );
}
