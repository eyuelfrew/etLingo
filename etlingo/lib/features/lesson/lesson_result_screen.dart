import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confetti.dart';
import '../../core/widgets/et_button.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';

class LessonResultScreen extends StatefulWidget {
  final AppState state;
  final Lesson lesson;
  final Unit unit;
  final int mistakes;

  const LessonResultScreen({
    super.key,
    required this.state,
    required this.lesson,
    required this.unit,
    required this.mistakes,
  });

  @override
  State<LessonResultScreen> createState() => _LessonResultScreenState();
}

class _LessonResultScreenState extends State<LessonResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfect = widget.mistakes == 0;
    final earned = widget.state.lessonReward(mistakes: widget.mistakes);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.unit.color.withValues(alpha: 0.16),
                  EtColors.paper,
                ],
              ),
            ),
          ),
          const ConfettiRain(active: true),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ScaleTransition(
                scale: CurvedAnimation(
                    parent: _pop, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [widget.unit.color, widget.unit.dark]),
                          boxShadow: [
                            BoxShadow(
                              color: widget.unit.dark.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          perfect
                              ? Icons.workspace_premium_rounded
                              : Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      perfect ? 'ጎበዝ! Flawless!' : 'Lesson complete!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      perfect
                          ? 'Zero mistakes — you are gobez!'
                          : '${widget.mistakes} slip${widget.mistakes == 1 ? '' : 's'} — practice makes perfect',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: EtColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultCard(
                            icon: Icons.bolt_rounded,
                            value: '+$earned',
                            label: 'XP earned',
                            color: EtColors.yellowDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultCard(
                            icon: Icons.local_fire_department_rounded,
                            value: '${widget.state.streak}',
                            label: 'Day streak',
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultCard(
                            icon: Icons.favorite_rounded,
                            value: '${widget.state.hearts}',
                            label: 'Hearts',
                            color: EtColors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewPadding.bottom + 20,
                ),
                child: EtButton(
                  'Keep going!',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ResultCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: EtColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: EtColors.line, width: 1.4),
        boxShadow: EtShadows.soft,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: EtColors.muted,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
