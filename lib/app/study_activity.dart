import 'dart:async';

import 'package:flutter/scheduler.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/controller.dart';
import '../core/study_clock.dart';

final studyRouteObserver = RouteObserver<ModalRoute<dynamic>>();

/// Only content readers/players are instrumented. Routing, lifecycle and idle
/// checks pause this clock independently of the persistent CAT deadline.
class StudyActivity extends ConsumerStatefulWidget {
  const StudyActivity({
    super.key,
    required this.child,
    required this.kind,
    this.category,
    this.topic,
    this.attemptId,
    this.enabled = true,
  });
  final Widget child;
  final String kind;
  final String? category, topic, attemptId;
  final bool enabled;
  @override
  ConsumerState<StudyActivity> createState() => _StudyActivityState();
}

class _StudyActivityState extends ConsumerState<StudyActivity>
    with WidgetsBindingObserver, RouteAware {
  final stopwatch = Stopwatch();
  late StudyClock clock;
  late AppController app;
  late String owner;
  late int generation;
  Timer? timer;
  bool resumed = true;
  bool visible = true;
  ModalRoute<dynamic>? route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context);
    if (next != route) {
      studyRouteObserver.unsubscribe(this);
      route = next;
      if (next != null) studyRouteObserver.subscribe(this, next);
    }
  }

  @override
  void didPushNext() {
    flush();
    visible = false;
    clock.setForeground(false);
  }

  @override
  void didPopNext() {
    visible = true;
    clock.setForeground(resumed && widget.enabled);
  }

  @override
  void initState() {
    super.initState();
    app = ref.read(appProvider);
    owner = app.namespace;
    generation = app.namespaceGeneration;
    stopwatch.start();
    clock = StudyClock(
      utcNow: () => DateTime.now().toUtc(),
      monotonicNow: () => stopwatch.elapsed,
    );
    resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    clock.setForeground(resumed && widget.enabled);
    app.studyFlushers.add(flush);
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      updateVisibility();
      flush();
    });
  }

  void updateVisibility() {
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (visible != current) {
      flush();
      visible = current;
      clock.setForeground(visible && resumed && widget.enabled);
    }
  }

  void flush() {
    final span = clock.take();
    if (span != null) {
      record(
        span,
        widget.kind,
        widget.category,
        widget.topic,
        widget.attemptId,
      );
    }
  }

  void record(
    ActiveSpan span,
    String kind,
    String? category,
    String? topic,
    String? attemptId,
  ) {
    void write() {
      unawaited(
        app
            .recordStudySpan(
              span,
              owner: owner,
              generation: generation,
              kind: kind,
              category: category,
              topic: topic,
              attemptId: attemptId,
            )
            .catchError((Object _) {
              /* Controller already exposes storage errors. */
            }),
      );
    }

    // Category changes and disposal can happen during a widget rebuild.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => write());
    } else {
      write();
    }
  }

  void input() {
    updateVisibility();
    if (clock.idle) flush();
    clock.interact();
  }

  @override
  void didUpdateWidget(covariant StudyActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.topic != widget.topic ||
        oldWidget.attemptId != widget.attemptId) {
      final span = clock.take();
      if (span != null) {
        record(
          span,
          oldWidget.kind,
          oldWidget.category,
          oldWidget.topic,
          oldWidget.attemptId,
        );
      }
    }
    if (oldWidget.enabled != widget.enabled) {
      flush();
      clock.setForeground(resumed && visible && widget.enabled);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    flush();
    resumed = state == AppLifecycleState.resumed;
    clock.setForeground(resumed && visible && widget.enabled);
  }

  @override
  void dispose() {
    flush();
    timer?.cancel();
    stopwatch.stop();
    app.studyFlushers.remove(flush);
    WidgetsBinding.instance.removeObserver(this);
    studyRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => input(),
    onPointerMove: (_) => input(),
    onPointerSignal: (_) => input(),
    child: Focus(
      onKeyEvent: (_, _) {
        input();
        return KeyEventResult.ignored;
      },
      child: widget.child,
    ),
  );
}
