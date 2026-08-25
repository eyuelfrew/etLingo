import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../lesson/lesson_screen.dart';

class LearnPathScreen extends StatelessWidget {
  final AppState state;
  const LearnPathScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final lang = state.language;
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: _WordOfDay(state: state),
              ),
            ),
            ...lang.units.map((unit) => SliverToBoxAdapter(
                  child: _UnitSection(state: state, unit: unit),
                )),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    TibebBand(height: 16, opacity: 0.7),
                    const SizedBox(height: 10),
                    Text(
                      'ቀስ በቀስ · Slowly by slowly',
                      style: TextStyle(
                        color: EtColors.muted.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final lang = state.language;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lang.color, lang.dark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: lang.dark.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.nativeName,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text('${lang.name} course',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ],
                ),
              ),
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                value: '${state.streak}',
                iconColor: const Color(0xFFFFB74D),
              ),
              const SizedBox(width: 7),
              _StatChip(
                icon: Icons.bolt_rounded,
                value: '${state.xp}',
                iconColor: EtColors.yellow,
              ),
              const SizedBox(width: 7),
              _StatChip(
                icon: Icons.favorite_rounded,
                value: '${state.hearts}',
                iconColor: const Color(0xFFFF8A93),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              color: Colors.white.withValues(alpha: 0.22),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                widthFactor: state.goalProgress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      EtColors.yellow,
                      Color(0xFFFFE97A),
                    ]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Daily goal ${state.xpToday}/${AppState.dailyGoal} XP',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color iconColor;
  const _StatChip({
    required this.icon,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _WordOfDay extends StatefulWidget {
  final AppState state;
  const _WordOfDay({required this.state});

  @override
  State<_WordOfDay> createState() => _WordOfDayState();
}

class _WordOfDayState extends State<_WordOfDay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.state.language;
    return GestureDetector(
      onTapDown: (_) {},
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (context, child) => Transform.rotate(
          angle: math.sin(_wobble.value * math.pi) * 0.006,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lang.color, lang.dark],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: lang.dark.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                child: const Icon(Icons.record_voice_over_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WORD OF THE DAY',
                        style: TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6)),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(lang.helloTarget,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                        ),
                        if (lang.helloTarget.length < 12) ...[
                          const SizedBox(width: 8),
                          Text(lang.helloMeaning.split('·').first.trim(),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(lang.helloMeaning,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitSection extends StatelessWidget {
  final AppState state;
  final Unit unit;
  const _UnitSection({required this.state, required this.unit});

  @override
  Widget build(BuildContext context) {
    final done = state.completedInUnit(unit);
    final total = unit.lessons.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [unit.color, unit.dark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: unit.dark.withValues(alpha: 0.30), blurRadius: 14, offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(unit.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(unit.subtitle,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      strokeWidth: 4.5,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  Text('$done/$total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ]),
              ],
            ),
          ),
          ZigzagNodes(
            state: state,
            unit: unit,
          ),
        ],
      ),
    );
  }
}

class ZigzagNodes extends StatefulWidget {
  final AppState state;
  final Unit unit;
  const ZigzagNodes({super.key, required this.state, required this.unit});

  @override
  State<ZigzagNodes> createState() => _ZigzagNodesState();
}

class _ZigzagNodesState extends State<ZigzagNodes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  static const spacing = 96.0;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.unit.lessons;

    final flatLessons = <Lesson>[];
    for (final u in widget.state.language.units) {
      flatLessons.addAll(u.lessons);
    }
    bool isUnlocked(Lesson lesson) {
      final idx = flatLessons.indexWhere((l) => l.id == lesson.id);
      if (idx <= 0) return true;
      return widget.state.completedLessons.contains(flatLessons[idx - 1].id);
    }

    int? currentIdx;
    for (var i = 0; i < lessons.length; i++) {
      if (!widget.state.completedLessons.contains(lessons[i].id)) {
        currentIdx = i;
        break;
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final maxDx = (w / 2 - 58).clamp(0.0, w / 2 - 58).toDouble();
      const pattern = [-0.85, -0.45, 0.0, 0.45, 0.85, 0.45, 0.0, -0.45];
      final centers = <Offset>[
        for (var i = 0; i < lessons.length; i++)
          Offset(w / 2 + pattern[i % pattern.length] * maxDx,
              i * spacing + spacing / 2)
      ];

      return SizedBox(
        height: lessons.length * spacing,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ConnectorPainter(
                  centers: centers,
                  activeColor: widget.unit.dark,
                  completedUpTo: currentIdx ?? lessons.length,
                ),
              ),
            ),
            for (var i = 0; i < lessons.length; i++)
              Positioned(
                top: centers[i].dy - 30,
                left: centers[i].dx - 33,
                child: _Node(
                  state: widget.state,
                  lesson: lessons[i],
                  unit: widget.unit,
                  isCurrent: i == currentIdx,
                  unlocked: isUnlocked(lessons[i]),
                  pulse: _pulse,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LessonScreen(
                        state: widget.state,
                        lesson: lessons[i],
                        unit: widget.unit,
                      ),
                    ));
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _ConnectorPainter extends CustomPainter {
  final List<Offset> centers;
  final Color activeColor;
  final int completedUpTo;

  _ConnectorPainter({
    required this.centers,
    required this.activeColor,
    required this.completedUpTo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < centers.length - 1; i++) {
      canvas.drawLine(
        centers[i],
        centers[i + 1],
        Paint()
          ..color = i < completedUpTo ? activeColor : EtColors.locked.withValues(alpha: 0.35)
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.completedUpTo != completedUpTo || old.centers != centers;
}

class _Node extends StatelessWidget {
  final AppState state;
  final Lesson lesson;
  final Unit unit;
  final bool isCurrent;
  final bool unlocked;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const _Node({
    required this.state,
    required this.lesson,
    required this.unit,
    required this.isCurrent,
    required this.unlocked,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = state.completedLessons.contains(lesson.id);

    final baseColor = completed
        ? unit.dark
        : isCurrent && unlocked
            ? Colors.white
            : const Color(0xFFEDE8DA);
    final borderColor =
        isCurrent && unlocked && !completed ? unit.dark : Colors.transparent;

    Widget core = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: lesson.isBoss ? 68 : 62,
      height: lesson.isBoss ? 62 : 56,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: completed
                ? unit.dark.withValues(alpha: 0.55)
                : isCurrent && unlocked
                    ? unit.dark.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.10),
            offset: Offset(0, completed || (isCurrent && unlocked) ? 5 : 3),
            blurRadius: 0,
          )
        ],
      ),
      child: Center(
        child: Icon(
          completed
              ? Icons.check_rounded
              : lesson.isBoss
                  ? Icons.workspace_premium_rounded
                  : isCurrent && unlocked
                      ? Icons.star_rounded
                      : Icons.lock_rounded,
          size: lesson.isBoss ? 30 : 26,
          color: completed
              ? Colors.white
              : isCurrent && unlocked
                  ? unit.color
                  : EtColors.locked,
        ),
      ),
    );

    if (!unlocked) core = Opacity(opacity: 0.75, child: core);

    Widget node = GestureDetector(
      onTap: unlocked ? onTap : null,
      child: core,
    );

    if (isCurrent && unlocked && !completed) {
      node = ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.07).animate(
          CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            node,
            Positioned(
              bottom: -26,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: EtColors.yellow,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: EtColors.yellowDark, offset: Offset(0, 3))
                    ],
                  ),
                  child: const Text('START',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: EtColors.ink)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 90,
      height: 100,
      child: Center(child: node),
    );
  }
}
