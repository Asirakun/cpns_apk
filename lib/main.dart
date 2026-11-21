import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/controller.dart';
import 'core/services.dart';
import 'app/theme.dart';
import 'app/widgets.dart';
import 'app/paper.dart';
import 'app/study_activity.dart';
import 'app/intro.dart';
import 'app/floating_nav.dart';
import 'features/analytics.dart';
import 'features/home.dart';
import 'features/learn.dart';
import 'features/tryout.dart';
import 'features/journey.dart';
import 'features/profile.dart';
import 'features/auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  String? error;
  try {
    await controller.content.load();
    try {
      await CloudConfig.initialize();
    } catch (_) {
      error = 'Konfigurasi cloud belum tersedia. Gunakan mode perangkat.';
    }
    await controller.initialize();
  } catch (_) {
    runApp(const StartupFailure());
    return;
  }
  controller.error ??= error;
  runApp(
    ProviderScope(
      overrides: [appProvider.overrideWith((ref) => controller)],
      child: JourneyApp(controller: controller, showIntro: true),
    ),
  );
}

class JourneyApp extends StatelessWidget {
  JourneyApp({super.key, required this.controller, this.showIntro = false})
    : router = GoRouter(
        observers: [studyRouteObserver],
        initialLocation: '/home',
        refreshListenable: controller,
        redirect: (ctx, state) {
          if (controller.switchingAccount) return null;
          if (controller.data['onboarded'] == true &&
              state.uri.path == '/onboarding') {
            return '/home';
          }
          if (state.uri.path == '/auth' &&
              controller.namespace != 'guest' &&
              !controller.passwordRecovery) {
            return controller.data['onboarded'] == true
                ? '/home'
                : '/onboarding';
          }
          if (!controller.data['onboarded'] &&
              state.uri.path != '/onboarding' &&
              state.uri.path != '/auth') {
            return '/onboarding';
          }
          if (controller.passwordRecovery && state.uri.path != '/auth') {
            return '/auth';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (c, s) => const OnboardingScreen(),
          ),
          GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
          GoRoute(
            path: '/intro',
            builder: (c, s) => IntroScreen(
              onDone: () {
                if (GoRouter.of(c).canPop()) {
                  c.pop();
                } else {
                  c.go('/home');
                }
              },
            ),
          ),
          ShellRoute(
            builder: (c, s, child) =>
                NavigationShell(location: s.uri.path, child: child),
            routes: [
              GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
              GoRoute(path: '/learn', builder: (c, s) => const LearnScreen()),
              GoRoute(
                path: '/tryouts',
                builder: (c, s) => const TryoutScreen(),
              ),
              GoRoute(
                path: '/journey',
                builder: (c, s) => const JourneyScreen(),
              ),
              GoRoute(
                path: '/profile',
                builder: (c, s) => const ProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/lesson/:id',
            builder: (c, s) => LessonScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/analytics',
            builder: (c, s) => AnalyticsScreen(
              initialCategory: s.uri.queryParameters['category'] ?? 'Semua',
            ),
          ),
          GoRoute(
            path: '/exam/:id',
            builder: (c, s) => ExamScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/result/:id',
            builder: (c, s) => ResultScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/journey/:section',
            builder: (c, s) =>
                JourneyDetailScreen(section: s.pathParameters['section']!),
          ),
        ],
      );
  final AppController controller;
  final bool showIntro;
  final GoRouter router;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp.router(
      key: ValueKey(controller.namespace),
      title: 'CPNS Journey',
      debugShowCheckedModeBanner: false,
      theme: journeyTheme(Brightness.light),
      darkTheme: journeyTheme(Brightness.dark),
      themeMode: switch (controller.data['theme']) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      },
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) => IntroGate(
        enabled: showIntro,
        child: controller.switchingAccount
            ? const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memuat progres akun…'),
                    ],
                  ),
                ),
              )
            : child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

class NavigationShell extends ConsumerWidget {
  const NavigationShell({
    super.key,
    required this.location,
    required this.child,
  });
  final String location;
  final Widget child;
  static const paths = ['/home', '/learn', '/tryouts', '/journey', '/profile'];
  static const labels = ['Beranda', 'Belajar', 'Tryout', 'Journey', 'Profil'];
  static const icons = [
    Icons.grid_view_rounded,
    Icons.menu_book_outlined,
    Icons.fact_check_outlined,
    Icons.route_outlined,
    Icons.person_outline_rounded,
  ];
  static const paperIcons = [
    PaperAsset.home,
    PaperAsset.book,
    PaperAsset.checklist,
    PaperAsset.route,
    PaperAsset.avatar,
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final index = paths.indexOf(location);
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(size: 38),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'CPNS Journey',
                maxLines: 2,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Agenda & pengingat',
            onPressed: () => context.push('/journey/calendar'),
            icon: const PaperArt(PaperAsset.bell, size: 29),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PaperBackdrop(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: index < 0 ? 0 : index,
                onDestinationSelected: (i) => context.go(paths[i]),
                labelType: NavigationRailLabelType.all,
                destinations: List.generate(
                  5,
                  (i) => NavigationRailDestination(
                    icon: PaperArt(paperIcons[i], size: 32),
                    label: Text(labels[i]),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  if (app.conflict || app.error != null)
                    Material(
                      color: app.conflict
                          ? amber.withValues(alpha: .12)
                          : Theme.of(context).colorScheme.surface,
                      child: InkWell(
                        onTap: () => context.go('/profile'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                app.conflict
                                    ? Icons.sync_problem_rounded
                                    : Icons.cloud_off_outlined,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  app.error ?? app.syncLabel,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : FloatingPaperNavBar(
              selectedIndex: index < 0 ? 0 : index,
              onSelected: (i) => context.go(paths[i]),
              labels: labels,
              icons: paperIcons,
            ),
    );
  }
}

class StartupFailure extends StatelessWidget {
  const StartupFailure({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: journeyTheme(Brightness.light),
    home: const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: EmptyCard(
              icon: Icons.error_outline,
              title: 'Aplikasi belum dapat dibuka',
              body: 'Penyimpanan atau paket konten tidak tersedia. Pastikan ruang penyimpanan cukup lalu buka kembali. Jangan hapus data jika belum diekspor.',
            ),
          ),
        ),
      ),
    ),
  );
}
