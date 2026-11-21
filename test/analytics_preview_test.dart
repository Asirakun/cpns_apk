import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cpns_journey/main.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/services.dart';
import 'package:cpns_journey/core/analytics.dart';
import 'package:cpns_journey/core/models.dart';
import 'package:cpns_journey/app/paper.dart';

import 'support/memory_store.dart';
import 'support/analytics_fixture.dart';

// Explicitly isolated fixture data. Never opens the actual user database/cloud.
Json previewState(DateTime now) {
  final today = wibDay(now);
  final sessions = <Json>[];
  var id = 1;
  for (var d = 1; d <= 26; d++) {
    final start = dayUtc(today.subtract(Duration(days: d)))
        .add(const Duration(hours: 10));
    final minutes = [15, 22, 0, 18, 28, 12, 25][d % 7];
    for (var m = 0; m < minutes; m++) {
      sessions.add(
        fixtureSession(
          '00000000-0000-4000-8000-${(id++).toString().padLeft(12, '0')}',
          start.add(Duration(minutes: m)),
          category: domains[d % 3],
        ),
      );
    }
  }
  for (var month = 1; month <= 5; month++) {
    final start = dayUtc(DateTime.utc(today.year, today.month - month, 12))
        .add(const Duration(hours: 10));
    for (var m = 0; m < 20 + month * 5; m++) {
      sessions.add(
        fixtureSession(
          '00000000-0000-4000-8000-${(id++).toString().padLeft(12, '0')}',
          start.add(Duration(minutes: m)),
          category: domains[month % 3],
        ),
      );
    }
  }
  final attempts = [
    for (var n = 1; n <= 6; n++)
      fixtureAttempt(
        id: '11111111-1111-4111-8111-${n.toString().padLeft(12, '0')}',
        cat: true,
        perDomain: 10,
        at: dayUtc(today.subtract(Duration(days: n <= 3 ? n * 2 : n * 22)))
            .add(const Duration(hours: 12)),
        option: ['E', 'C', 'B', 'D', 'C', 'A'][n - 1],
      ),
  ];
  return fixtureState(
      start: dayUtc(DateTime.utc(today.year, today.month - 6)),
      sessions: sessions,
      attempts: attempts,
    )
    ..['alias'] = 'Demo visual'
    ..['onboarded'] = true
    ..['theme'] = 'dark';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('CAPTURE_PREVIEWS');
  const scenario = String.fromEnvironment(
    'PREVIEW_SCENARIO',
    defaultValue: 'daily',
  );
  setUpAll(() async {
    await (FontLoader(
      'PlusJakarta',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (capture && root != null) {
      final file = File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      await (FontLoader(
        'MaterialIcons',
      )..addFont(file.readAsBytes().then(ByteData.sublistView))).load();
    }
  });
  testWidgets('capture PRD v2.1 real Flutter UI ($scenario)', (tester) async {
    final large = scenario == 'light-large';
    tester.view.physicalSize = Size(large ? 430 : 390, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = large ? 1.3 : 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    final repo = ContentRepository();
    await tester.runAsync(repo.load);
    final store = MemoryStore();
    final app = AppController(store, repo);
    final fixture = scenario != 'home-empty';
    app.data = fixture ? previewState(DateTime.now().toUtc()) : initialData()
      ..['onboarded'] = true;
    app.data['downloaded_version'] = repo.data['version'];
    if (large) app.data['theme'] = 'light';
    final route = switch (scenario) {
      'home-empty' || 'home-demo' || 'light-large' => '/home',
      'learn' => '/learn',
      'tryouts' => '/tryouts',
      'journey' => '/journey',
      'profile' => '/profile',
      'category' => '/analytics?category=TKP',
      _ => '/analytics',
    };
    final appUi = JourneyApp(controller: app);
    appUi.router.go(route);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [appProvider.overrideWith((ref) => app)],
          child: Stack(
            textDirection: TextDirection.ltr,
            children: [
              appUi,
              if (fixture)
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: Color(0xFFEAC16C),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'DATA UJI • bukan riwayat pengguna',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlusJakarta',
                          fontSize: 10,
                          color: Color(0xFF142641),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final imageContext = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => Future.wait(
        PaperAsset.values.map(
          (a) => precacheImage(AssetImage(PaperArt.path(a)), imageContext),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.wait(
        ['welcome', 'focus'].map(
          (name) => precacheImage(
            AssetImage('assets/papercut_home/$name.png'),
            imageContext,
          ),
        ),
      ),
    );
    if (scenario == 'weekly') {
      await tester.tap(find.text('Mingguan'));
      await tester.pumpAndSettle();
    }
    if (scenario == 'monthly') {
      await tester.tap(find.text('Bulanan'));
      await tester.pumpAndSettle();
    }
    if (scenario == 'category') {
      await tester.scrollUntilVisible(find.text('Tren TKP · 4 minggu'), 350);
      await tester.ensureVisible(find.text('Tren TKP · 4 minggu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tren TKP · 4 minggu'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -430));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('docs/design/screenshots/v1.1.0');
      await directory.create(recursive: true);
      await File('${directory.path}/$scenario.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    appUi.router.dispose();
    await store.close();
  }, skip: !capture);
}
