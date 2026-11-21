import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'paper.dart';

/// Local launch preference, independent of user snapshots and account data.
class IntroGate extends StatefulWidget {
  const IntroGate({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  static const seenKey = 'cpns.papercut-intro.v1';
  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  bool checking = true, visible = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.enabled) {
      checking = false;
      return;
    }
    bool seen = false;
    try {
      seen =
          (await SharedPreferences.getInstance()).getBool(IntroGate.seenKey) ??
          false;
    } catch (_) {
      /* A preference error must never block the app. */
    }
    if (mounted) {
      setState(() {
        checking = false;
        visible = !seen;
      });
    }
  }

  void finish() {
    if (!visible) return;
    setState(() => visible = false);
    unawaited(_remember());
  }

  Future<void> _remember() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(
        IntroGate.seenKey,
        true,
      );
    } catch (_) {
      /* App data stays available. */
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    if (checking) {
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const PaperBackdrop(
          child: Center(
            child: Image(
              image: AssetImage('assets/brand/logo.png'),
              width: 140,
            ),
          ),
        ),
      );
    }
    if (!visible) return widget.child;
    return Stack(
      children: [
        ExcludeSemantics(child: widget.child),
        Positioned.fill(
          child: BlockSemantics(child: IntroScreen(onDone: finish)),
        ),
      ],
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const audio = MethodChannel('cpnsjourney/intro_audio');
  static int nextAudioOwner = 0;
  final String audioOwner = '${++nextAudioOwner}';
  late final AnimationController motion;
  List<Map<String, dynamic>> frames = [];
  Timer? reducedTimer;
  bool started = false, done = false, paused = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    motion =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 6667),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) finish();
        });
  }

  Future<void> sound(String method, {int position = 0}) async {
    try {
      await audio.invokeMethod<Object?>(method, {
        'positionMs': position,
        'owner': audioOwner,
      });
    } catch (_) {
      /* Silent fallback never blocks app startup. */
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      reducedTimer = Timer(const Duration(milliseconds: 300), finish);
    } else {
      unawaited(load());
    }
  }

  Future<void> load() async {
    try {
      final data = jsonDecode(
        await rootBundle.loadString(
          'assets/intro/provided-motion.json',
          cache: false,
        ),
      ) as Map<String, dynamic>;
      final values = (data['samples'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      if (data['frames'] != 200 ||
          data['durationMs'] != 6667 ||
          values.length != 200) {
        throw const FormatException('Invalid intro');
      }
      if (!mounted || done) return;
      setState(() => frames = values);
      await sound('play');
      if (!mounted || done) {
        await sound('stop');
        return;
      }
      if (!paused) motion.forward();
    } catch (_) {
      if (mounted && !done) finish();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (done) return;
    if (state == AppLifecycleState.resumed) {
      if (paused && frames.isNotEmpty) {
        paused = false;
        unawaited(resume());
      }
    } else {
      paused = true;
      motion.stop();
      unawaited(sound('stop'));
    }
  }

  Future<void> resume() async {
    await sound('play', position: (motion.value * 6667).round());
    if (mounted && !done && !paused) motion.forward();
  }

  void finish() {
    if (!mounted || done) return;
    done = true;
    reducedTimer?.cancel();
    motion.stop();
    unawaited(sound('stop'));
    widget.onDone();
  }

  @override
  void dispose() {
    done = true;
    reducedTimer?.cancel();
    motion.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(sound('stop'));
    super.dispose();
  }

  double value(String key) {
    if (frames.isEmpty) return key == 'scale' ? 1 : 0;
    final at = (motion.value * 200).clamp(0.0, 199.0);
    final first = at.floor();
    final last = math.min(first + 1, 199);
    return (frames[first][key] as num).toDouble() +
        ((frames[last][key] as num) - (frames[first][key] as num)) *
            (at - first);
  }

  Widget _image(String name, double width, double height) => Image.asset(
    'assets/intro/$name.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
  Widget _book() {
    final open = value('open').clamp(0.0, 1.0);
    final raw = ((open - .15) / .7).clamp(0.0, 1.0);
    final rev = 1 - math.pow(1 - raw, 3).toDouble();
    final road = value('road').clamp(0.0, 1.0);
    final flag = value('flag');
    final layers = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Center(
            child: ClipRect(
              child: Align(
                widthFactor: rev,
                child: Transform.scale(
                  scaleX: .8 + .2 * rev,
                  child: _image('book-open', 585, 334),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 115.5,
          top: 15,
          child: Opacity(
            opacity: 1 - ((open - .2) / .45).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 1 + .08 * open,
              alignment: const Alignment(0, .8),
              child: _image('book-closed', 354, 313),
            ),
          ),
        ),
        Positioned(
          left: 187,
          top: 3,
          child: Opacity(
            opacity: road > 0 ? 1 : 0,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: const [Colors.white, Colors.transparent],
                stops: [road, math.min(1.0, road + .10)],
              ).createShader(r),
              child: _image('road-rot', 223, 239),
            ),
          ),
        ),
        Positioned(
          left: 289,
          top: -84,
          child: Opacity(
            opacity: (flag * 3).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: value('wave') * .6 * math.pi / 180,
              alignment: const Alignment(-.76, 1),
              child: Transform.scale(
                scale: flag,
                alignment: const Alignment(-.76, 1),
                child: _image('flag', 76, 101),
              ),
            ),
          ),
        ),
      ],
    );
    final animated = Opacity(
      opacity: value('appear').clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, value('y')),
        child: Transform.scale(
          scale: value('scale'),
          child: SizedBox(width: 585, height: 334, child: layers),
        ),
      ),
    );
    return FittedBox(
      child: SizedBox(
        width: 585,
        height: 440,
        child: Stack(
          clipBehavior: Clip.none,
          children: [Positioned(top: 84, left: 0, child: animated)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) finish();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: PaperBackdrop(
            child: LayoutBuilder(
              builder: (context, box) {
                final width = math.min(
                  300.0,
                  math.min(box.maxWidth * .72, box.maxHeight * .60),
                );
                if (reduced || frames.isEmpty) {
                  return Center(
                    child: Image.asset('assets/brand/logo.png', width: 160),
                  );
                }
                return AnimatedBuilder(
                  animation: motion,
                  builder: (context, _) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              key: const ValueKey('intro-artwork'),
                              width: width,
                              height: width * 440 / 585,
                              child: _book(),
                            ),
                            SizedBox(height: width * .05),
                            Opacity(
                              opacity: value('title'),
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  (1 - value('title')) * 30 * width / 585,
                                ),
                                child: Text(
                                  'CPNS Journey',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: width * .115,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: width * .02),
                            Opacity(
                              opacity: value('tag'),
                              child: Text(
                                'Persiapan yang terarah',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: width * .048,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: .5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            SizedBox(height: width * .045),
                            Transform.scale(
                              scaleX: value('line'),
                              child: Container(
                                width: width * .12,
                                height: math.max(1.5, width * .006),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf6b92b),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
