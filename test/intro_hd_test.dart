import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cpns_journey/app/intro.dart';
import 'package:cpns_journey/app/paper.dart';
import 'package:cpns_journey/app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakarta',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  for (final scenario in [
    ('dark-20x9', const Size(360, 800), 3.0, Brightness.dark, 1.0),
    ('light-20x9', const Size(360, 800), 3.0, Brightness.light, 1.0),
    ('dark-16x9-large-text', const Size(360, 640), 2.0, Brightness.dark, 1.3),
  ]) {
    testWidgets(
      'HD intro has native text and seamless background: ${scenario.$1}',
      (tester) async {
        final size = scenario.$2, dpr = scenario.$3;
        tester.view.physicalSize = Size(size.width * dpr, size.height * dpr);
        tester.view.devicePixelRatio = dpr;
        tester.platformDispatcher.textScaleFactorTestValue = scenario.$5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final theme = journeyTheme(scenario.$4);
        final key = GlobalKey();
        Widget root(Widget child) => RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: child,
          ),
        );
        Future<ui.Image> capture() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          boundary.markNeedsPaint();
          await tester.pump();
          return tester
              .runAsync(() => boundary.toImage(pixelRatio: dpr))
              .then((value) => value!);
        }

        await tester.pumpWidget(
          root(const Scaffold(body: PaperBackdrop(child: SizedBox.expand()))),
        );
        await tester.pumpAndSettle();
        final baseline = await capture();
        final expected = (await tester.runAsync(
          () => baseline.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        baseline.dispose();
        await tester.pumpWidget(root(IntroScreen(onDone: () {})));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pump();
        for (var frame = 0; frame < 180; frame++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 12)),
          );
          await tester.pump(const Duration(milliseconds: 34));
        }
        expect(find.text('CPNS Journey'), findsOneWidget);
        expect(find.text('Persiapan yang terarah'), findsOneWidget);
        final image = find.byWidgetPredicate(
          (w) => w.key == const ValueKey('intro-artwork'),
        );
        expect(image, findsOneWidget);
        final imageBox = tester.getRect(image);
        expect(imageBox.width / imageBox.height, closeTo(585 / 440, .01));
        expect(imageBox.left, greaterThan(0));
        final actual = await capture();
        final pixels = (await tester.runAsync(
          () => actual.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        // The mark's transparent corners must reproduce the exact native
        // background pixels, including its dots/arcs, with no video rectangle.
        final points = [
          const Offset(1, 1),
          Offset(size.width - 2, size.height - 2),
          imageBox.topLeft + const Offset(2, 2),
          imageBox.topRight + const Offset(-2, 2),
          imageBox.bottomLeft + const Offset(2, -2),
          imageBox.bottomRight + const Offset(-2, -2),
        ];
        for (final point in points) {
          final offset =
              ((point.dy * dpr).floor() * actual.width +
                  (point.dx * dpr).floor()) *
              4;
          expect(
            pixels.getUint32(offset),
            expected.getUint32(offset),
            reason: 'Background seam at $point',
          );
        }
        if (const bool.fromEnvironment('CAPTURE_INTRO_PREVIEWS')) {
          final png = (await tester.runAsync(
            () => actual.toByteData(format: ui.ImageByteFormat.png),
          ))!;
          await tester.runAsync(() async {
            final directory = Directory('docs/design/v1.2.2/intro');
            await directory.create(recursive: true);
            await File('${directory.path}/flutter-${scenario.$1}.png')
                .writeAsBytes(png.buffer.asUint8List());
          });
        }
        actual.dispose();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
