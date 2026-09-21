import 'package:flutter/material.dart';
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

    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) => IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: EtBottomNav(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}
