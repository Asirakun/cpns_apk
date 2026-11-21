import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'theme.dart';

enum PaperAsset {
  book,
  checklist,
  route,
  home,
  target,
  graduation,
  documents,
  calendar,
  bell,
  medal,
  sprout,
  flashcards,
  avatar,
  shield,
  clock,
  balloon,
  cloudSync,
  backup,
  privacy,
  sources,
  settings,
  formation,
  announcements,
  results,
  briefcase,
  wallet,
  analytics,
  review,
  logout,
  search,
  download,
  device,
  moon,
  help,
  plan,
  verified,
}

class PaperArt extends StatelessWidget {
  const PaperArt(this.asset, {super.key, this.size = 56});
  final PaperAsset asset;
  final double size;
  static PaperAsset? forIcon(IconData icon) {
    if (icon == Icons.cloud_sync_outlined) return PaperAsset.cloudSync;
    if (icon == Icons.ios_share_rounded) return PaperAsset.backup;
    if (icon == Icons.verified_user_outlined) return PaperAsset.privacy;
    if (icon == Icons.link_rounded) return PaperAsset.sources;
    if (icon == Icons.tune_rounded) return PaperAsset.settings;
    if (icon == Icons.location_city_outlined) return PaperAsset.formation;
    if (icon == Icons.campaign_outlined) return PaperAsset.announcements;
    if (icon == Icons.assignment_outlined) return PaperAsset.results;
    if (icon == Icons.work_outline_rounded) return PaperAsset.briefcase;
    if (icon == Icons.account_balance_wallet_outlined) return PaperAsset.wallet;
    if (icon == Icons.logout_rounded) return PaperAsset.logout;
    if (icon == Icons.psychology_outlined) return PaperAsset.review;
    if (icon == Icons.style_outlined) return PaperAsset.flashcards;
    if (icon == Icons.search_rounded) return PaperAsset.search;
    if (icon == Icons.info_outline_rounded) return PaperAsset.help;
    if ([
      Icons.route_rounded,
      Icons.location_city_outlined,
      Icons.work_outline_rounded,
    ].contains(icon)) {
      return PaperAsset.route;
    }
    if ([Icons.school_outlined, Icons.school_rounded].contains(icon)) {
      return PaperAsset.graduation;
    }
    if ([Icons.calendar_month_outlined, Icons.event_outlined].contains(icon)) {
      return PaperAsset.calendar;
    }
    if ([Icons.person_outline_rounded, Icons.person_rounded].contains(icon)) {
      return PaperAsset.avatar;
    }
    if ([Icons.menu_book_outlined, Icons.menu_book_rounded].contains(icon)) {
      return PaperAsset.book;
    }
    if ([
      Icons.folder_open_rounded,
      Icons.download_for_offline_outlined,
      Icons.description_outlined,
    ].contains(icon)) {
      return PaperAsset.documents;
    }
    if ([Icons.fact_check_outlined, Icons.task_alt_rounded].contains(icon)) {
      return PaperAsset.checklist;
    }
    if ([
      Icons.verified_outlined,
      Icons.offline_pin_outlined,
      Icons.cloud_done_outlined,
    ].contains(icon)) {
      return PaperAsset.shield;
    }
    if ([Icons.history_rounded, Icons.timer_outlined].contains(icon)) {
      return PaperAsset.clock;
    }
    if ([Icons.show_chart_rounded, Icons.analytics_outlined].contains(icon)) {
      return PaperAsset.analytics;
    }
    if ([
      Icons.bolt_rounded,
      Icons.edit_note_rounded,
      Icons.play_circle_outline_rounded,
    ].contains(icon)) {
      return PaperAsset.target;
    }
    return null;
  }

  static String path(PaperAsset asset) =>
      '${asset.index < 16 ? 'assets/papercut' : 'assets/papercut_functions'}/${asset.name}.png';

  @override
  Widget build(BuildContext context) => Image.asset(
    path(asset),
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
}

class HomeIllustration extends StatelessWidget {
  const HomeIllustration(
    this.name, {
    super.key,
    this.width = 150,
    this.height = 135,
  });
  final String name;
  final double width, height;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/papercut_home/$name.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
}

class BluePaperPanel extends StatelessWidget {
  const BluePaperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.deep = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool deep;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      boxShadow: const [
        BoxShadow(
          color: Color(0x50020D19),
          blurRadius: 12,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: deep
                ? const [Color(0xFF103D63), Color(0xFF0B2D4E)]
                : const [Color(0xFF246FA7), Color(0xFF10416F)],
          ),
        ),
        child: CustomPaint(
          painter: const _BlueWavesPainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    ),
  );
}

class _BlueWavesPainter extends CustomPainter {
  const _BlueWavesPainter();
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final y = size.height - 20 + i * 6;
      final path = Path()
        ..moveTo(0, y + 8)
        ..cubicTo(
          size.width * .21,
          y - 25,
          size.width * .42,
          y + 24,
          size.width * .63,
          y - 4,
        )
        ..cubicTo(
          size.width * .79,
          y - 25,
          size.width * .91,
          y - 4,
          size.width,
          y - 11,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawShadow(path, const Color(0x55051D35), 3, false);
      canvas.drawPath(
        path,
        Paint()
          ..color = const [
            Color(0xFF174F7B),
            Color(0xFF286F9C),
            Color(0xFF438DB9),
          ][i].withValues(alpha: .75),
      );
    }
    final corner = Path()
      ..moveTo(size.width * .58, 0)
      ..quadraticBezierTo(size.width * .75, 45, size.width, 20)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      corner,
      Paint()..color = const Color(0xFF0B365E).withValues(alpha: .4),
    );
  }

  @override
  bool shouldRepaint(covariant _BlueWavesPainter oldDelegate) => false;
}

class PaperPanel extends StatelessWidget {
  const PaperPanel({
    super.key,
    required this.child,
    this.color,
    this.backing,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color? color, backing;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Stack(
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(2, 6),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: backing ?? const Color(0xFF375B7D),
                shape: const PapercutShape(),
                shadows: const [
                  BoxShadow(
                    color: Color(0x55040813),
                    blurRadius: 15,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
            ),
          ),
        ),
        Material(
          color: color ?? Theme.of(context).colorScheme.surface,
          shape: PapercutShape(
            side: BorderSide(
              color: (color ?? Theme.of(context).colorScheme.surface)
                  .withValues(alpha: .8),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      ],
    ),
  );
}

class PaperBackdrop extends StatelessWidget {
  const PaperBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PaperBackdropPainter(
      Theme.of(context).brightness == Brightness.dark,
    ),
    child: child,
  );
}

class _PaperBackdropPainter extends CustomPainter {
  const _PaperBackdropPainter(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = (dark ? paperBlue : paperInk).withValues(
        alpha: dark ? .045 : .035,
      );
    for (double y = 9; y < size.height; y += 29) {
      for (double x = 9; x < size.width; x += 29) {
        canvas.drawCircle(Offset(x + math.sin(y * .13) * 4, y), .7, dot);
      }
    }
    final edge = Paint()
      ..color = (dark ? paperBlue : paperInk).withValues(alpha: .035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width + 18, size.height * .53),
          radius: 105 + i * 15,
        ),
        1.8,
        3.9,
        false,
        edge,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperBackdropPainter oldDelegate) =>
      dark != oldDelegate.dark;
}

class PaperPageHeading extends StatelessWidget {
  const PaperPageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    this.eyebrow = 'CPNS JOURNEY',
  });
  final String title, subtitle, eyebrow;
  final PaperAsset asset;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 9),
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 9),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Transform.rotate(angle: -.07, child: PaperArt(asset, size: 78)),
      ],
    ),
  );
}
