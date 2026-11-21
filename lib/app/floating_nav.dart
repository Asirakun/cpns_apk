import 'package:material_ui/material_ui.dart';

import 'paper.dart';

/// Floating capsule dock. Existing destinations and paper assets are supplied
/// by the shell so route selection and icon identity stay in one place.
class FloatingPaperNavBar extends StatelessWidget {
  const FloatingPaperNavBar({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> labels;
  final List<PaperAsset> icons;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final height = 60.0 + (scale - 1).clamp(0.0, 2.0) * 14;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .28 : .12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: dark ? const Color(0xFF152B46) : const Color(0xFFFFF8EB),
            shape: StadiumBorder(
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .65),
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: List.generate(labels.length, (i) {
                  final selected = selectedIndex == i;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: labels[i],
                      onTap: () => onSelected(i),
                      child: ExcludeSemantics(
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          height: height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: selected
                                ? (dark
                                      ? const Color(0xFF355777)
                                      : const Color(0xFFFFFEF8))
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? colors.primary.withValues(alpha: .22)
                                  : Colors.transparent,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: .12,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: () => onSelected(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 33,
                                    child: Center(
                                      child: PaperArt(
                                        icons[i],
                                        size: selected ? 33 : 29,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    labels[i],
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.3,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: selected
                                          ? colors.onSurface
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
