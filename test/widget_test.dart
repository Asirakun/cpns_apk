import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/memory_store.dart';

import 'package:cpns_journey/main.dart';
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
    testWidgets('five tabs at ${width}dp with 1.3x text and dark theme', (
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
      app.data['theme'] = 'dark';
      app.data['downloaded_version'] = '1.0.0';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appProvider.overrideWith((ref) => app)],
          child: JourneyApp(controller: app),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Siap melangkah\nlebih dekat?'), findsOneWidget);
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
            of: find.byType(NavigationBar),
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
