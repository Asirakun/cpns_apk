import 'dart:convert';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cpns_journey/main.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/services.dart';
import 'package:cpns_journey/app/paper.dart';
import 'package:cpns_journey/app/intro.dart';

import 'support/memory_store.dart';
import 'support/analytics_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakarta',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  Future<(AppController, JourneyApp)> mount(
    WidgetTester tester,
    String route,
  ) async {
    final repo = ContentRepository();
    await tester.runAsync(repo.load);
    final app = AppController(MemoryStore(), repo);
    app.data['onboarded'] = true;
    app.data['theme'] = 'dark';
    app.data['downloaded_version'] = repo.data['version'];
    final uiApp = JourneyApp(controller: app);
    uiApp.router.go(route);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => app)],
        child: uiApp,
      ),
    );
    await tester.pumpAndSettle();
    return (app, uiApp);
  }

  Future<void> close(WidgetTester tester, JourneyApp app) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    app.router.dispose();
  }

  test('profile icons match their purpose and unrelated controls never fall back to a sprout', () {
    final icons = [
      Icons.cloud_sync_outlined,
      Icons.ios_share_rounded,
      Icons.verified_user_outlined,
      Icons.link_rounded,
    ];
    expect(icons.map(PaperArt.forIcon).toList(), [
      PaperAsset.cloudSync,
      PaperAsset.backup,
      PaperAsset.privacy,
      PaperAsset.sources,
    ]);
    expect(icons.map(PaperArt.forIcon).toSet().length, 4);
    expect(PaperArt.forIcon(Icons.delete_forever_outlined), isNull);
    expect(
      PaperArt.forIcon(Icons.account_balance_wallet_outlined),
      PaperAsset.wallet,
    );
  });
  test(
    'provided intro has original 200-frame motion and audible WAV',
    () async {
      final timing = jsonDecode(
        await rootBundle.loadString(
          'assets/intro/provided-motion.json',
          cache: false,
        ),
      ) as Map<String, dynamic>;
      expect(timing['frames'], 200);
      expect(timing['durationMs'], 6667);
      expect((timing['samples'] as List).length, 200);
      final wav = await rootBundle.load('assets/intro/intro-sfx.wav');
      expect(wav.lengthInBytes, greaterThan(500000));
      for (final name in ['book-open', 'book-closed', 'road-rot', 'flag']) {
        final bytes = await rootBundle.load('assets/intro/$name.png');
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(50));
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
  for (final width in [360.0, 430.0]) {
    testWidgets('preparation cards are 3+3+1 centered at ${width}dp and 1.3x', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (_, app) = await mount(tester, '/journey');
      Rect box(String key) =>
          tester.getRect(find.byKey(ValueKey('preparation-$key')));
      expect(
        box('formations').center.dy,
        closeTo(box('sources').center.dy, .1),
      );
      expect(box('sources').center.dy, closeTo(box('documents').center.dy, .1));
      expect(box('calendar').center.dy, closeTo(box('results').center.dy, .1));
      expect(box('results').center.dy, closeTo(box('skb').center.dy, .1));
      expect(box('budget').center.dx, closeTo(width / 2, .1));
      expect(box('formations').size, box('budget').size);
      expect(tester.takeException(), isNull);
      await close(tester, app);
    });
  }
  testWidgets(
    'history tabs/search/kind filters preserve raw attempts and separate Tryout from Latihan',
    (tester) async {
      final (app, screen) = await mount(tester, '/tryouts');
      final now = DateTime.now().toUtc();
      final cat = fixtureAttempt(
        cat: true,
        at: now.subtract(const Duration(hours: 1)),
      )..['title'] = 'CAT Konstitusi';
      final practice = fixtureAttempt(
        id: '22222222-2222-4222-8222-222222222222',
        at: now.subtract(const Duration(days: 1)),
      )..['title'] = 'Latihan Pancasila';
      practice.remove('blueprint'); // Older snapshots can lack this metadata.
      app.data['attempts'] = [cat, practice];
      await app.save();
      await tester.pumpAndSettle();
      final before = jsonEncode(app.data['attempts']);
      await tester.tap(find.widgetWithText(Tab, 'Riwayat'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('history-${cat['id']}')), findsOneWidget);
      expect(find.byKey(ValueKey('history-${practice['id']}')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(ValueKey('history-${cat['id']}'))).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(ValueKey('history-${practice['id']}')))
              .dy,
        ),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tryout'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('history-${cat['id']}')), findsOneWidget);
      expect(find.byKey(ValueKey('history-${practice['id']}')), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Latihan'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('history-${cat['id']}')), findsNothing);
      expect(find.byKey(ValueKey('history-${practice['id']}')), findsOneWidget);
      final search = find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.hintText == 'Cari riwayat latihan',
      );
      await tester.enterText(search, 'tidak-ada');
      await tester.pumpAndSettle();
      expect(find.text('Riwayat tidak ditemukan'), findsOneWidget);
      expect(jsonEncode(app.data['attempts']), before);
      expect(tester.takeException(), isNull);
      await close(tester, screen);
    },
  );
  testWidgets(
    'Soal search finds actual topics and keeps history on its own tab',
    (tester) async {
      final (app, screen) = await mount(tester, '/tryouts');
      final topic = app.content.questions.first.topic;
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Cari paket atau topik',
        ),
        topic,
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, topic), findsOneWidget);
      expect(find.text('Riwayat latihan'), findsNothing);
      expect(tester.takeException(), isNull);
      await close(tester, screen);
    },
  );
  testWidgets('answered navigator buttons remain green even when flagged', (
    tester,
  ) async {
    final (app, screen) = await mount(tester, '/home');
    final attempt = fixtureAttempt(
      submitted: false,
      at: DateTime.now().toUtc(),
    );
    attempt['answers'] = <String, dynamic>{'TWK-0': 'E'};
    attempt['flagged'] = ['TWK-0', 'TWK-1'];
    app.data['attempts'] = [attempt];
    await app.save();
    screen.router.go('/exam/${attempt['id']}');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Navigator soal'));
    await tester.pumpAndSettle();
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '1 ?'),
    );
    expect(button.style!.foregroundColor!.resolve({}), const Color(0xFF74DDA2));
    final unanswered = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '2 ?'),
    );
    expect(
      unanswered.style!.foregroundColor!.resolve({}),
      isNot(const Color(0xFF74DDA2)),
    );
    expect(app.attempts.single.answers, {'TWK-0': 'E'});
    expect(tester.takeException(), isNull);
    await close(tester, screen);
  });
  testWidgets(
    'reduced motion uses a static logo and advances without an animation',
    (tester) async {
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: IntroScreen(onDone: () => finished++),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 301));
      expect(finished, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
