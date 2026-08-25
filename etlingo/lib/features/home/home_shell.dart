import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import 'learn_path_screen.dart';
import 'phrasebook_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  final AppState state;
  const HomeShell({super.key, required this.state});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      LearnPathScreen(state: widget.state),
      PhrasebookScreen(state: widget.state),
      LeaderboardScreen(state: widget.state),
      ProfileScreen(state: widget.state),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) => IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: EtColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              children: List.generate(4, (i) {
                const icons = [
                  Icons.school_rounded,
                  Icons.menu_book_rounded,
                  Icons.emoji_events_rounded,
                  Icons.person_rounded,
                ];
                const labels = ['Learn', 'Words', 'Rank', 'You'];
                final selected = _tab == i;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _tab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? EtColors.green.withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[i],
                            size: 23,
                            color: selected ? EtColors.green : EtColors.locked,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? EtColors.green : EtColors.locked,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
