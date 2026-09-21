import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/confetti.dart';
import '../../core/widgets/et_button.dart';
import '../../core/widgets/tibeb_band.dart';
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
    final earned = widget.state.lessonReward(
      mistakes: widget.mistakes,
      xpReward: widget.lesson.xpReward,
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.unit.color.withValues(alpha: 0.22),
                  widget.unit.dark.withValues(alpha: 0.08),
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
                    parent: _pop,
                    curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [widget.unit.color, widget.unit.dark]),
                          boxShadow: [
                            BoxShadow(
                              color: widget.unit.dark.withValues(alpha: 0.45),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          perfect
                              ? Icons.workspace_premium_rounded
                              : Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      perfect ? EtStrings.perfect : EtStrings.lessonDone,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      perfect
                          ? EtStrings.perfectSub
                          : '${widget.mistakes} ስህተት · ${EtStrings.slowMotto}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: EtColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    const Center(child: TibebBand(height: 14, opacity: 0.85)),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _ResultCard(
                            icon: Icons.bolt_rounded,
                            value: '+$earned',
                            label: EtStrings.xpEarned,
                            color: EtColors.yellowDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultCard(
                            icon: Icons.local_fire_department_rounded,
                            value: '${widget.state.streak}',
                            label: EtStrings.dayStreak,
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultCard(
                            icon: Icons.favorite_rounded,
                            value: '${widget.state.hearts}',
                            label: EtStrings.hearts,
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: EtButton(
                  EtStrings.keepGoing,
                  icon: Icons.play_arrow_rounded,
                  style: EtStyle.primary,
                  onPressed: () => Navigator.of(context).pop(),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EtColors.line),
        boxShadow: EtShadows.soft,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: EtColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
