import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

class LeaderboardScreen extends StatelessWidget {
  final AppState state;
  const LeaderboardScreen({super.key, required this.state});

  static const _mock = <(String, int)>[
    ('Abebe T.', 482),
    ('Tigist A.', 431),
    ('Dawit K.', 377),
    ('Hanna M.', 312),
    ('Chala B.', 254),
    ('Meron G.', 198),
    ('Yonas F.', 141),
    ('Bontu S.', 96),
    ('Selam W.', 52),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = [..._mock.map((e) => (e.$1, e.$2, false))];
    final all = [...rows, ('You', state.xp, true)];
    all.sort((a, b) => b.$2.compareTo(a.$2));

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final sorted = [
            ..._mock.map((e) => (e.$1, e.$2, false)),
            ('እርስዎ · You', state.xp, true),
          ]..sort((a, b) => b.$2.compareTo(a.$2));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [EtColors.yellow, Color(0xFFE8A800)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: EtShadows.glow(EtColors.yellowDark, blur: 16, y: 6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ወርቅ ሊግ · Gold League',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(
                              'ሪስ ይቀላቀሉ · ${state.xpToday}/${AppState.dailyGoal} XP ዛሬ',
                              style: TextStyle(
                                color: EtColors.ink.withValues(alpha: 0.65),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) => _Row(
                    rank: i + 1,
                    name: sorted[i].$1,
                    xp: sorted[i].$2,
                    isYou: sorted[i].$3,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final int rank;
  final String name;
  final int xp;
  final bool isYou;

  const _Row({
    required this.rank,
    required this.name,
    required this.xp,
    required this.isYou,
  });

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (rank) {
      1 => const Color(0xFFFFC400),
      2 => const Color(0xFFB9C0CC),
      3 => const Color(0xFFCD7F32),
      _ => EtColors.locked.withValues(alpha: 0.4),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isYou ? EtColors.green.withValues(alpha: 0.08) : EtColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isYou ? EtColors.green : EtColors.line,
          width: isYou ? 2 : 1.3,
        ),
      ),
      child: Row(
        children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: medalColor),
              alignment: Alignment.center,
              child: rank <= 3
                  ? Icon(
                      rank == 1
                          ? Icons.looks_one_rounded
                          : rank == 2
                              ? Icons.looks_two_rounded
                              : Icons.looks_3_rounded,
                      color: Colors.white,
                      size: 22,
                    )
                  : Text('$rank',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: EtColors.muted)),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isYou ? EtColors.greenDark : EtColors.ink,
              ),
            ),
          ),
          const Icon(Icons.bolt_rounded, color: EtColors.yellowDark, size: 17),
          const SizedBox(width: 3),
          Text('$xp',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isYou ? EtColors.greenDark : EtColors.muted,
              )),
        ],
      ),
    );
  }
}
