import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpns_journey/main.dart';
import 'package:cpns_journey/core/controller.dart';
import 'package:cpns_journey/core/services.dart';
import 'package:cpns_journey/app/paper.dart';

import 'support/memory_store.dart';

// Opt-in real Flutter renders, without a device, browser, or production data:
// flutter test test/papercut_preview_test.dart --dart-define=CAPTURE_PREVIEWS=true
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('CAPTURE_PREVIEWS');
  const selectedRoute = String.fromEnvironment('PREVIEW_ROUTE');
  setUpAll(() async {
    final font = FontLoader('PlusJakarta')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await font.load();
    if (capture) {
      final flutterRoot = Platform.environment['FLUTTER_ROOT'];
      if (flutterRoot != null) {
        final iconFile = File(
          '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        );
        if (await iconFile.exists()) {
          await (FontLoader('MaterialIcons')..addFont(
                iconFile.readAsBytes().then((b) => ByteData.sublistView(b)),
              ))
              .load();
        }
      }
    }
  });

  test('all papercut icons are packaged as PNG assets', () async {
    for (final asset in PaperAsset.values) {
      final data = await rootBundle.load(PaperArt.path(asset));
      expect(data.lengthInBytes, greaterThan(1000));
    }
    for (final name in ['welcome', 'focus']) {
      final data = await rootBundle.load('assets/papercut_home/$name.png');
      expect(data.lengthInBytes, greaterThan(1000));
    }
  });

  testWidgets('capture real Flutter papercut screens at phone size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = ContentRepository();
    await tester.runAsync(repo.load);
    debugDisableShadows = false;
    addTearDown(() {
      debugDisableShadows = true;
    });
    for (final screen in [
      ('/home', '01-beranda'),
      ('/learn', '02-belajar'),
      ('/tryouts', '03-tryout'),
      ('/journey', '04-journey'),
      ('/profile', '05-profil'),
      ('/onboarding', '06-onboarding'),
    ]) {
      if (selectedRoute.isNotEmpty && screen.$1 != selectedRoute) continue;
      final store = MemoryStore();
      final app = AppController(store, repo);
      app.data['onboarded'] = screen.$1 != '/onboarding';
      app.data['theme'] = 'dark';
      app.data['downloaded_version'] = repo.data['version'];
      final uiApp = JourneyApp(controller: app);
      uiApp.router.go(screen.$1);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: ProviderScope(
            overrides: [appProvider.overrideWith((ref) => app)],
            child: uiApp,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final imageContext = tester.element(find.byType(Scaffold));
      await tester.runAsync(
        () => Future.wait(
          PaperAsset.values.map(
            (asset) =>
                precacheImage(AssetImage(PaperArt.path(asset)), imageContext),
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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: screen.$2);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      boundary.markNeedsPaint();
      await tester.pump();
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('docs/design/screenshots/v1.0.2');
        await directory.create(recursive: true);
        await File('${directory.path}/${screen.$2}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      uiApp.router.dispose();
      await store.close();
    }
  }, skip: !capture);
}
