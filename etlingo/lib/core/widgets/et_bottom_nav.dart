import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../ui/et_strings.dart';

/// Distinctive Ethio-inspired bottom navigation.
/// Flag-colored active pill, gold pulse on selected, tibeb dots on inactive.
class EtBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const EtBottomNav({super.key, required this.index, required this.onChanged});

  static const _icons = [
    Icons.school_rounded,
    Icons.menu_book_rounded,
    Icons.person_rounded,
  ];

  static const _accent = [
    EtColors.green,
    EtColors.yellowDark,
    EtColors.blue,
  ];

  List<String> get _labels => [
        EtStrings.tabLearn,
        EtStrings.tabWords,
        EtStrings.tabYou,
      ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EtStrings.langNotifier,
      builder: (context, _) {
        final labels = _labels;
        final bottom = MediaQuery.of(context).padding.bottom;

        return Container(
          decoration: BoxDecoration(
            color: EtColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
                color: EtColors.line.withValues(alpha: 0.7), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == 0
                              ? EtColors.green
                              : EtColors.green.withValues(alpha: 0.35),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == 1
                              ? EtColors.yellow
                              : EtColors.yellow.withValues(alpha: 0.4),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == 2
                              ? EtColors.red
                              : EtColors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == 3
                              ? EtColors.blue
                              : EtColors.blue.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 12, 10, 8 + bottom),
                  child: Row(
                    children: List.generate(_icons.length, (i) {
                      final selected = index == i;
                      final accent = _accent[i];
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? accent.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? accent.withValues(alpha: 0.35)
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding:
                                      EdgeInsets.all(selected ? 7 : 5),
                                  decoration: BoxDecoration(
                                    color:
                                        selected ? accent : Colors.transparent,
                                    shape: BoxShape.circle,
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: accent
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    _icons[i],
                                    size: selected ? 22 : 21,
                                    color: selected
                                        ? Colors.white
                                        : EtColors.locked,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  labels[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: selected
                                        ? accent
                                        : EtColors.locked,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: List.generate(3, (d) {
                                    final on = selected && d <= (index % 3);
                                    return Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        color:
                                            on ? accent : EtColors.line,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
