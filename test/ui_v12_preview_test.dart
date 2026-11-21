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
import 'package:cpns_journey/core/models.dart';
import 'package:cpns_journey/app/paper.dart';

import 'analytics_preview_test.dart' show previewState;
import 'support/memory_store.dart';

// Real UI engine renders, test data only; never opens a user's local/cloud DB.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('CAPTURE_PREVIEWS');
  const scenario = String.fromEnvironment(
    'PREVIEW_SCENARIO',
    defaultValue: 'profile-icons',
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
  testWidgets('capture v1.2 $scenario', (tester) async {
    final large = scenario == 'light-large';
    tester.view.physicalSize = Size(large ? 430 : 390, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = large ? 1.3 : 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    final content = ContentRepository();
    await tester.runAsync(content.load);
    final store = MemoryStore();
    final app = AppController(store, content);
    final now = DateTime.now().toUtc();
    app.data = previewState(now);
    app.data['downloaded_version'] = content.data['version'];
    if (large) app.data['theme'] = 'light';
    final pack = content.packs.first;
    final questions = (pack['question_ids'] as List)
        .map((id) => content.questions.firstWhere((q) => q.id == id))
        .toList();
    Json attempt(String id, {bool active = false, bool practice = false}) {
      final qs = practice
          ? [
              for (final d in domains)
                ...content.questions.where((q) => q.domain == d).take(5),
            ]
          : questions;
      final a = Attempt({
        'id': id,
        'title': practice ? 'Latihan cepat' : pack['name'],
        'pack_id': practice ? null : pack['id'],
        'seed': 1,
        'content_version': content.data['version'],
        'started_at': now
            .subtract(const Duration(minutes: 45))
            .toIso8601String(),
        'deadline_at': now.add(const Duration(minutes: 55)).toIso8601String(),
        'duration_seconds': 6000,
        'submitted_at': active
            ? null
            : now
                  .subtract(Duration(minutes: practice ? 8 : 12))
                  .toIso8601String(),
        'questions': qs.map((q) => deepCopy(q.json)).toList(),
        'answers': {
          for (var i = 0; i < qs.length; i++)
            if (!active || i < 15)
              qs[i].id: i % 3 == 0 ? qs[i].best : qs[i].options.first['id'],
        },
        'flagged': active ? [qs[2].id, qs[18].id] : <String>[],
        'index': 0,
        'blueprint': practice
            ? {'id': 'practice-v1', 'status': 'practice', 'year': 2024}
            : deepCopy(ContentRepository.blueprintFor(pack)),
      });
      if (!active) a.json['scores'] = a.scores;
      return a.json;
    }

    const activeId = '33333333-3333-4333-8333-333333333333';
    app.data['attempts'] = [
      attempt('11111111-1111-4111-8111-111111111111'),
      attempt('22222222-2222-4222-8222-222222222222', practice: true),
      if (scenario == 'navigator') attempt(activeId, active: true),
    ];
    final route = switch (scenario) {
      'home' || 'priorities' || 'light-large' => '/home',
      'profile' || 'profile-icons' => '/profile',
      'preparation' => '/journey',
      'tryouts' || 'history' => '/tryouts',
      'navigator' => '/exam/$activeId',
      'category' => '/analytics?category=TKP',
      _ => '/analytics',
    };
    final screen = JourneyApp(controller: app);
    screen.router.go(route);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [appProvider.overrideWith((ref) => app)],
          child: Stack(
            textDirection: TextDirection.ltr,
            children: [
              Positioned.fill(bottom: 16, child: screen),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 16,
                child: Material(
                  color: Color(0xFFEAC16C),
                  child: Text(
                    'DATA UJI • bukan riwayat pengguna',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PlusJakarta',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF142641),
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
    final ctx = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => Future.wait([
        ...PaperAsset.values.map(
          (a) => precacheImage(AssetImage(PaperArt.path(a)), ctx),
        ),
        ...['welcome', 'focus'].map(
          (n) => precacheImage(AssetImage('assets/papercut_home/$n.png'), ctx),
        ),
        precacheImage(const AssetImage('assets/brand/logo.png'), ctx),
      ]),
    );
    if (scenario == 'history') {
      await tester.tap(find.widgetWithText(Tab, 'Riwayat'));
      await tester.pumpAndSettle();
    }
    if (scenario == 'weekly') {
      await tester.tap(find.text('Mingguan'));
      await tester.pumpAndSettle();
    }
    if (scenario == 'monthly') {
      await tester.tap(find.text('Bulanan'));
      await tester.pumpAndSettle();
    }
    if (scenario == 'navigator') {
      await tester.tap(find.byTooltip('Navigator soal'));
      await tester.pumpAndSettle();
    }
    final scrollTitle = switch (scenario) {
      'profile-icons' => 'Akun & penyimpanan',
      'preparation' => 'Pusat persiapan',
      'priorities' => 'Prioritas belajarmu',
      'category' => 'Tren TKP · 4 minggu',
      _ => null,
    };
    if (scrollTitle != null) {
      await tester.scrollUntilVisible(find.text(scrollTitle), 350);
      await tester.ensureVisible(find.text(scrollTitle));
      await tester.pumpAndSettle();
      if (scenario == 'category') {
        await tester.tap(find.text(scrollTitle));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
        await tester.pumpAndSettle();
      }
    }
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('docs/design/screenshots/v1.2.3');
      await dir.create(recursive: true);
      await File('${dir.path}/$scenario.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      img.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    screen.router.dispose();
    await store.close();
  }, skip: !capture);
}
