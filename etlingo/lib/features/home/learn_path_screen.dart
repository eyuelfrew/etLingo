import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/et_card.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../lesson/lesson_screen.dart';
import '../lesson/teaching_screen.dart';
import 'curriculum_screen.dart';

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
        builder: (context, _) => RefreshIndicator(
          onRefresh: () => state.refreshLanguage(),
          color: EtColors.green,
          backgroundColor: EtColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (state.loadingContent)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2, color: EtColors.green),
                ),
              SliverToBoxAdapter(child: _CourseHero(state: state, lang: lang)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _BrowseLessonsButton(state: state),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _WordOfDay(state: state),
                ),
              ),
              if (lang.units.isEmpty)
                SliverToBoxAdapter(child: _EmptyCourse(state: state))
              else
                ...lang.units.map((unit) => SliverToBoxAdapter(
                      child: _UnitSection(state: state, unit: unit),
                    )),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                  child: Column(
                    children: [
                      const TibebBand(height: 16, opacity: 0.75),
                      const SizedBox(height: 12),
                      Text(
                        EtStrings.slowMotto,
                        style: TextStyle(
                          color: EtColors.muted.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseLessonsButton extends StatelessWidget {
  final AppState state;
  const _BrowseLessonsButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CurriculumScreen(state: state, showPathCta: true),
          ));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: EtColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EtColors.line),
            boxShadow: EtShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EtColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: EtColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      EtStrings.browseLessons,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: EtColors.ink,
                      ),
                    ),
                    Text(
                      EtStrings.chooseLessonSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: EtColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: EtColors.blue),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  final AppState state;
  final Language lang;
  const _CourseHero({required this.state, required this.lang});

  @override
  Widget build(BuildContext context) {
    final done = state.totalLessonsDone;
    final total = lang.totalLessons;
    final next = state.nextLesson();
    final greeting = _greeting();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lang.id.isEmpty ? EtColors.greenMid : lang.color,
            lang.id.isEmpty ? EtColors.greenDeep : lang.dark,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: EtShadows.glow(
          lang.id.isEmpty ? EtColors.greenDark : lang.dark,
          blur: 22,
          y: 10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.nativeName.isEmpty ? EtStrings.brand : lang.nativeName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.id.isEmpty
                          ? EtStrings.brandTagline
                          : '${EtStrings.course} · ${lang.name}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              EtProgressRing(
                progress: total == 0 ? 0 : done / total,
                size: 56,
                stroke: 5,
                color: EtColors.yellow,
                track: Colors.white24,
                label: '$done/$total',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              EtStatChip(
                icon: Icons.local_fire_department_rounded,
                value: '${state.streak}',
                iconColor: const Color(0xFFFFB74D),
                label: EtStrings.streak,
              ),
              const SizedBox(width: 8),
              EtStatChip(
                icon: Icons.bolt_rounded,
                value: '${state.xp}',
                iconColor: EtColors.yellow,
                label: EtStrings.xp,
              ),
              const SizedBox(width: 8),
              EtStatChip(
                icon: Icons.favorite_rounded,
                value: '${state.hearts}',
                iconColor: EtColors.heart,
                label: EtStrings.hearts,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(height: 10, color: Colors.white.withValues(alpha: 0.2)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    widthFactor: state.goalProgress,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [EtColors.yellow, EtColors.yellowSoft],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.goalProgress >= 1
                      ? EtStrings.goalComplete
                      : '${EtStrings.dailyGoal} ${state.xpToday}/${AppState.dailyGoal} XP',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (next != null)
                Flexible(
                  child: Text(
                    next.title,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'እንደምን አደሩ 👋';
    if (h < 18) return 'እንደምን አደሩ';
    return 'እንደምን ደናგ госуд';
  }
}

class _EmptyCourse extends StatelessWidget {
  final AppState state;
  const _EmptyCourse({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: EtColors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded,
                size: 34, color: EtColors.green),
          ),
          const SizedBox(height: 16),
          const Text(
            'ትምህርት አልተገኘም',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            state.error ?? EtStrings.noContentYet,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EtColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
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
    if (lang.helloTarget.isEmpty && lang.helloMeaning.isEmpty) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _wobble,
      builder: (context, child) => Transform.rotate(
        angle: math.sin(_wobble.value * math.pi) * 0.005,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EtColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: EtColors.line, width: 1.2),
          boxShadow: EtShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    lang.color.withValues(alpha: 0.18),
                    lang.dark.withValues(alpha: 0.12),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: lang.color.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(Icons.record_voice_over_rounded,
                  color: lang.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: EtColors.yellow.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          EtStrings.wordOfDay,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: EtColors.ink,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang.helloTarget,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  if (lang.helloMeaning.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lang.helloMeaning,
                      style: const TextStyle(
                        color: EtColors.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
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
              boxShadow: EtShadows.glow(unit.dark, blur: 16, y: 6),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(unit.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unit.subtitle.isEmpty
                            ? '${EtStrings.unit} · $done/$total'
                            : unit.subtitle,
                        maxLines: 2,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                EtProgressRing(
                  progress: total == 0 ? 0 : done / total,
                  size: 42,
                  stroke: 4,
                  label: '$done/$total',
                ),
              ],
            ),
          ),
          ZigzagNodes(state: state, unit: unit),
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

  static const spacing = 100.0;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _openLesson(Lesson lesson) {
    final unit = widget.unit;
    final teachItems = unit.teachItemsFor(lesson);
    final hasQuestions = lesson.questions.isNotEmpty;
    final hasTeach = teachItems.isNotEmpty;

    if (!hasQuestions && !hasTeach) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${lesson.title}" — ${EtStrings.noContentYet}')),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => hasTeach
          ? TeachingScreen(
              state: widget.state,
              lesson: lesson,
              unit: unit,
              teachItemsOverride: teachItems,
            )
          : LessonScreen(
              state: widget.state,
              lesson: lesson,
              unit: unit,
            ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.unit.lessons;
    if (lessons.isEmpty) return const SizedBox.shrink();

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
      final maxDx = (w / 2 - 60).clamp(0.0, w / 2 - 60).toDouble();
      const pattern = [-0.85, -0.45, 0.0, 0.45, 0.85, 0.45, 0.0, -0.45];
      final centers = <Offset>[
        for (var i = 0; i < lessons.length; i++)
          Offset(w / 2 + pattern[i % pattern.length] * maxDx,
              i * spacing + spacing / 2)
      ];

      return SizedBox(
        height: lessons.length * spacing + 8,
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
                top: centers[i].dy - 32,
                left: centers[i].dx - 36,
                child: _Node(
                  state: widget.state,
                  lesson: lessons[i],
                  unit: widget.unit,
                  isCurrent: i == currentIdx,
                  unlocked: isUnlocked(lessons[i]),
                  pulse: _pulse,
                  onTap: () => _openLesson(lessons[i]),
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
      final active = i < completedUpTo;
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 10;
      if (active) {
        paint.color = activeColor;
      } else {
        paint.color = EtColors.locked.withValues(alpha: 0.3);
        // dashed feel for locked path
      }
      canvas.drawLine(centers[i], centers[i + 1], paint);
      if (!active) {
        final mid = Offset(
          (centers[i].dx + centers[i + 1].dx) / 2,
          (centers[i].dy + centers[i + 1].dy) / 2,
        );
        canvas.drawCircle(
          mid,
          3,
          Paint()..color = EtColors.locked.withValues(alpha: 0.45),
        );
      }
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
    final activeNow = isCurrent && unlocked && !completed;

    final baseColor = completed
        ? unit.dark
        : activeNow
            ? Colors.white
            : const Color(0xFFEDE8DA);

    Widget core = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: lesson.isBoss ? 72 : 66,
      height: lesson.isBoss ? 68 : 62,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: activeNow
              ? unit.dark
              : completed
                  ? unit.color.withValues(alpha: 0.4)
                  : Colors.transparent,
          width: activeNow ? 3.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: completed
                ? unit.dark.withValues(alpha: 0.5)
                : activeNow
                    ? EtColors.yellow.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.08),
            offset: Offset(0, completed || activeNow ? 5 : 3),
            blurRadius: activeNow ? 10 : 0,
          )
        ],
      ),
      child: Center(
        child: completed
            ? const Icon(Icons.check_rounded, size: 30, color: Colors.white)
            : lesson.isBoss
                ? Icon(Icons.workspace_premium_rounded,
                    size: 30,
                    color: activeNow ? unit.color : EtColors.locked)
                : activeNow
                    ? Icon(Icons.play_arrow_rounded,
                        size: 32, color: unit.color)
                    : const Icon(Icons.lock_rounded,
                        size: 24, color: EtColors.locked),
      ),
    );

    if (!unlocked) core = Opacity(opacity: 0.7, child: core);

    Widget node = GestureDetector(
      onTap: unlocked ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: core,
    );

    if (activeNow) {
      node = ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.06).animate(
          CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            node,
            Positioned(
              bottom: -28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [EtColors.yellow, EtColors.gold],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: EtColors.yellowDark,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    unit.teachItems.isNotEmpty || lesson.teachItems.isNotEmpty
                        ? EtStrings.learn
                        : EtStrings.start,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: EtColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 96,
      height: 108,
      child: Center(child: node),
    );
  }
}
