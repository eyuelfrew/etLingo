import 'package:flutter/material.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/et_bottom_nav.dart';
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

    // Rebuild when learner progress or app language (EN/AM) changes.
    return ListenableBuilder(
      listenable: Listenable.merge([widget.state, EtStrings.langNotifier]),
      builder: (context, _) => Scaffold(
        body: IndexedStack(index: _tab, children: pages),
        bottomNavigationBar: EtBottomNav(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}
