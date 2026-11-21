import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cpns_journey/app/intro.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'provided intro plays SFX, has no skip, completes once and stops on dispose',
    (tester) async {
      final calls = <String>[];
      final positions = <int>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('cpnsjourney/intro_audio'),
            (call) async {
              calls.add(call.method);
              if (call.method == 'play') {
                final args = call.arguments as Map;
                expect(args['owner'], isNotEmpty);
                positions.add(args['positionMs'] as int);
              }
              return true;
            },
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('cpnsjourney/intro_audio'),
              null,
            ),
      );
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(home: IntroScreen(onDone: () => finished++)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      expect(find.text('Lewati'), findsNothing);
      expect(calls, contains('play'));
      await tester.pump(const Duration(seconds: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(calls.last, 'stop');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
      expect(calls.where((v) => v == 'play').length, 2);
      expect(positions.last, greaterThanOrEqualTo(1900));
      await tester.pump(const Duration(milliseconds: 6668));
      await tester.pump();
      expect(finished, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(finished, 1);
      await tester.pumpWidget(const SizedBox());
      expect(calls.last, 'stop');
    },
  );
  testWidgets('first-launch gate automatically remembers completed intro', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    Widget app(Key key) => MaterialApp(
      key: key,
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: IntroGate(child: Scaffold(body: Text('Ready'))),
      ),
    );
    await tester.pumpWidget(app(const ValueKey('first')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    expect(find.byType(IntroScreen), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getBool(IntroGate.seenKey),
      true,
    );
    await tester.pumpWidget(app(const ValueKey('second')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
