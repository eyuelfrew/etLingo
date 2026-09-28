import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/engagement_bar.dart';
import '../../core/widgets/et_card.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../data/models.dart';
import '../../services/engagement_service.dart';
import '../../services/api_client.dart';
import '../../state/app_state.dart';
import '../lesson/lesson_screen.dart';
import '../lesson/teaching_screen.dart';
import 'curriculum_screen.dart';
import '../culture/culture_phase4_screens.dart';
import '../culture/culture_screen.dart';
import '../culture/culture_widgets.dart';
import '../calendar/ethiopian_calendar_screen.dart';
import '../../widgets/ad_slot.dart';
import '../../core/calendar/ethiopian_calendar.dart';

class LearnPathScreen extends StatefulWidget {
  final AppState state;
  const LearnPathScreen({super.key, required this.state});

  @override
  State<LearnPathScreen> createState() => _LearnPathScreenState();
}

class _LearnPathScreenState extends State<LearnPathScreen> {
  int _track = 0; // 0 = language, 1 = culture

  AppState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final lang = state.language;
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => RefreshIndicator(
          onRefresh: () => _track == 0
              ? state.refreshLanguage()
              : state.loadCulture().then((_) {}),
          color: EtColors.green,
          backgroundColor: EtColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (state.loadingContent)
                const SliverToBoxAdapter(
                  child:
                      LinearProgressIndicator(minHeight: 2, color: EtColors.green),
                ),
              SliverToBoxAdapter(child: _CourseHero(state: state, lang: lang)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AdSlot(state: state, position: 'home_top', compact: true),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _TrackSwitch(
                    index: _track,
                    accent: lang.id.isEmpty ? EtColors.green : lang.color,
                    onChanged: (i) => setState(() => _track = i),
                  ),
                ),
              ),
              if (_track == 0) ...[
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: _ProverbAndCalendar(state: state),
                  ),
                ),
                if (lang.units.isEmpty)
                  SliverToBoxAdapter(child: _EmptyCourse(state: state))
                else
                  ...lang.units.map((unit) => SliverToBoxAdapter(
                        child: _UnitSection(
                          key: ValueKey('unit-${unit.dbId ?? unit.title}'),
                          state: state,
                          unit: unit,
                        ),
                      )),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: AdSlot(state: state, position: 'home_mid'),
                  ),
                ),
              ] else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                    child: CultureScreen(state: state),
                  ),
                ),
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

class _TrackSwitch extends StatelessWidget {
  final int index;
  final Color accent;
  final ValueChanged<int> onChanged;
  const _TrackSwitch({
    required this.index,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EtColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EtColors.line),
      ),
      child: Row(
        children: [
          _seg(0, EtStrings.tabLearn, Icons.school_rounded),
          _seg(1, EtStrings.cultureTab, Icons.auto_stories_rounded),
        ],
      ),
    );
  }

  Widget _seg(int i, String label, IconData icon) {
    final on = index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: on ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: on ? Colors.white : EtColors.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: on ? Colors.white : EtColors.muted,
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
          const SizedBox(height: 12),
          if (lang.dbId != null)
            Align(
              alignment: Alignment.centerLeft,
              child: _LanguageEngagementBar(state: state),
            ),
          const SizedBox(height: 12),
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

/// Proverb of the Day + Ethiopian calendar strip on the language track home.
class _ProverbAndCalendar extends StatefulWidget {
  final AppState state;
  const _ProverbAndCalendar({required this.state});

  @override
  State<_ProverbAndCalendar> createState() => _ProverbAndCalendarState();
}

class _ProverbAndCalendarState extends State<_ProverbAndCalendar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.loadProverbOfDay();
      widget.state.loadCultureCalendar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final proverb = state.proverbOfDay;
    final cal = state.cultureCalendar;
    final holiday = cal?['holiday'] is Map
        ? (cal!['holiday'] as Map)['nameAm'] ?? (cal['holiday'] as Map)['name']
        : EthiopianCalendar.holidayLabel(DateTime.now());
    final upcoming = cal?['upcoming'] is Map ? cal!['upcoming'] as Map : null;
    final live = cal?['holiday'] is Map || EthiopianCalendar.holidayXpActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EthiopianCalendarCard(
          holidayLabel: holiday?.toString(),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const EthiopianCalendarScreen(),
            ));
          },
        ),
        if (live || upcoming != null) ...[
          const SizedBox(height: 10),
          HolidayChallengeBanner(
            label: EtStrings.holidayChallenge,
            detail: live
                ? '${holiday ?? 'Holiday'} · ${cal?['xpMultiplier'] ?? 2}× culture XP'
                : '${upcoming?['name']} in ${upcoming?['inDays']} days',
            accent: live ? EtColors.red : EtColors.gold,
            onOpen: live
                ? () {
                    // Jump user to culture track via parent switch is not
                    // available here — open share/proverb instead.
                    if (proverb == null) return;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ArShareCardScreen(
                        title: EtStrings.proverbOfDay,
                        target: proverb.title,
                        body: proverb.bodyFor(state.baseLanguage),
                        translit: proverb.translit.isEmpty
                            ? null
                            : proverb.translit,
                      ),
                    ));
                  }
                : null,
          ),
        ],
        if (proverb != null) ...[
          const SizedBox(height: 12),
          ProverbOfDayCard(
            title: EtStrings.proverbOfDay,
            target: proverb.title,
            translit: proverb.translit,
            body: proverb.bodyFor(state.baseLanguage),
            accent: EtColors.gold,
            audioUrl:
                proverb.audioUrl.isEmpty ? null : proverb.audioUrl,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ArShareCardScreen(
                  title: EtStrings.proverbOfDay,
                  target: proverb.title,
                  body: proverb.bodyFor(state.baseLanguage),
                  translit:
                      proverb.translit.isEmpty ? null : proverb.translit,
                ),
              ));
            },
          ),
        ],
      ],
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

class _UnitSection extends StatefulWidget {
  final AppState state;
  final Unit unit;
  const _UnitSection({super.key, required this.state, required this.unit});

  @override
  State<_UnitSection> createState() => _UnitSectionState();
}

class _UnitSectionState extends State<_UnitSection> {
  late bool _expanded;

  AppState get state => widget.state;
  Unit get unit => widget.unit;

  bool get _isDone {
    final total = unit.lessons.length;
    return total > 0 && state.completedInUnit(unit) >= total;
  }

  bool get _hasCurrentLesson {
    final next = state.nextLesson();
    return next != null && unit.lessons.any((l) => l.id == next.id);
  }

  @override
  void initState() {
    super.initState();
    // Finished chapters start folded; the chapter you're in stays open.
    _expanded = _hasCurrentLesson || !_isDone;
  }

  @override
  void didUpdateWidget(covariant _UnitSection old) {
    super.didUpdateWidget(old);
    // When this chapter is fully done and the next one is active, fold it away.
    if (_isDone && !_hasCurrentLesson && _expanded) {
      _expanded = false;
    }
    // If progress lands here (e.g. after finishing previous unit), open it.
    if (_hasCurrentLesson && !_expanded) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = state.completedInUnit(unit);
    final total = unit.lessons.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        children: [
          // Chapter header — tap to collapse / expand lessons
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
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
                      child: _isDone
                          ? const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 24)
                          : Icon(unit.icon, color: Colors.white, size: 24),
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
                            _isDone
                                ? EtStrings.chapterDone
                                : unit.subtitle.isEmpty
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
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                ZigzagNodes(state: state, unit: unit),
                if (unit.dbId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _UnitEngagementBar(
                      unitId: unit.dbId!,
                      unitTitle: unit.title,
                      accent: unit.color,
                      state: state,
                    ),
                  ),
              ],
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
          ),
          if (!_expanded && unit.dbId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _UnitEngagementBar(
                unitId: unit.dbId!,
                unitTitle: unit.title,
                accent: unit.color,
                state: state,
              ),
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

  static const spacing = 132.0;

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
                top: centers[i].dy - 36,
                left: centers[i].dx - 60,
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

  /// Circle radius used on the path (must match _Node).
  static const double nodeR = 30;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < centers.length - 1; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      // Only connect circle edge → next circle top (skip title zone).
      final start = Offset(a.dx, a.dy + nodeR + 2);
      final end = Offset(b.dx, b.dy - nodeR - 2);
      final done = i < completedUpTo;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          (start.dx + end.dx) / 2 + (b.dx - a.dx) * 0.08,
          (start.dy + end.dy) / 2,
          end.dx,
          end.dy,
        );

      if (done) {
        // Completed: soft glow + gradient stroke
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..strokeCap = StrokeCap.round
            ..color = activeColor.withValues(alpha: 0.18),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [activeColor, activeColor.withValues(alpha: 0.75)],
            ).createShader(Rect.fromPoints(start, end)),
        );
        // Tibeb-style gold bead mid-segment
        final t = 0.5;
        final mid = Offset(
          (1 - t) * (1 - t) * start.dx +
              2 * (1 - t) * t * ((start.dx + end.dx) / 2) +
              t * t * end.dx,
          (1 - t) * (1 - t) * start.dy +
              2 * (1 - t) * t * ((start.dy + end.dy) / 2) +
              t * t * end.dy,
        );
        canvas.drawCircle(mid, 4.5, Paint()..color = EtColors.yellow);
        canvas.drawCircle(
          mid,
          4.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.85),
        );
      } else {
        // Locked: light dotted trail
        final dash = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = EtColors.locked.withValues(alpha: 0.35);
        const dashLen = 8.0;
        const gap = 7.0;
        final total = (end - start).distance;
        var drawn = 0.0;
        while (drawn < total) {
          final t0 = drawn / total;
          final t1 = ((drawn + dashLen) / total).clamp(0.0, 1.0);
          final p0 = Offset.lerp(start, end, t0)!;
          final p1 = Offset.lerp(start, end, t1)!;
          canvas.drawLine(p0, p1, dash);
          drawn += dashLen + gap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.completedUpTo != completedUpTo ||
      old.centers != centers ||
      old.activeColor != activeColor;
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

    final icon = completed
        ? const Icon(Icons.check_rounded, size: 28, color: Colors.white)
        : lesson.isBoss
            ? Icon(
                Icons.workspace_premium_rounded,
                size: 28,
                color: activeNow ? unit.color : EtColors.locked,
              )
            : activeNow
                ? Icon(Icons.play_arrow_rounded, size: 30, color: unit.color)
                : const Icon(Icons.lock_rounded,
                    size: 22, color: EtColors.locked);

    Widget circle = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: lesson.isBoss ? 64 : 58,
      height: lesson.isBoss ? 64 : 58,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: activeNow
              ? unit.dark
              : completed
                  ? unit.color.withValues(alpha: 0.4)
                  : Colors.transparent,
          width: activeNow ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: completed
                ? unit.dark.withValues(alpha: 0.45)
                : activeNow
                    ? EtColors.yellow.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.06),
            offset: Offset(0, completed || activeNow ? 4 : 2),
            blurRadius: activeNow ? 8 : 0,
          )
        ],
      ),
      child: Center(child: icon),
    );

    if (activeNow) {
      circle = ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.05).animate(
          CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
        ),
        child: circle,
      );
    }

    // Title under the node — always for unlocked/completed, dimmed when locked
    final titleColor = completed
        ? unit.dark
        : activeNow
            ? EtColors.ink
            : unlocked
                ? EtColors.ink
                : EtColors.locked;

    return SizedBox(
      width: 120,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: unlocked ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circle,
            // Title under the node — chip background so the path never covers text
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (activeNow)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [EtColors.yellow, EtColors.gold],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: EtColors.yellowDark,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        lesson.teachItems.isNotEmpty ||
                                unit.teachItems.isNotEmpty
                            ? EtStrings.learn
                            : EtStrings.start,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: EtColors.ink,
                        ),
                      ),
                    ),
                  Text(
                    lesson.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: completed || activeNow
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: titleColor,
                      height: 1.2,
                    ),
                  ),
                  if (completed)
                    Text(
                      EtStrings.lessonsDone,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: unit.color,
                      ),
                    ),
                  if (!unlocked && !completed)
                    Text(
                      EtStrings.lockedHint,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: EtColors.locked,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _UnitEngagementBar extends StatefulWidget {
  final int unitId;
  final String unitTitle;
  final Color accent;
  final AppState state;

  const _UnitEngagementBar({
    required this.unitId,
    required this.unitTitle,
    required this.accent,
    required this.state,
  });

  @override
  State<_UnitEngagementBar> createState() => _UnitEngagementBarState();
}

class _UnitEngagementBarState extends State<_UnitEngagementBar> {
  Engagement? _data;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final e = await widget.state.engagement.unit(widget.unitId);
      if (mounted) setState(() => _data = e);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _UnitEngagementBar old) {
    super.didUpdateWidget(old);
    // After login, re-fetch so likedByMe comes from the server.
    if (widget.state.canEngage && _data?.likedByMe != true) {
      _load();
    }
  }

  Future<void> _like() async {
    if (!widget.state.canEngage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(EtStrings.signInToEngage)),
      );
      return;
    }
    if (_data?.likedByMe == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(EtStrings.alreadyLiked)),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await widget.state.engagement.likeUnit(widget.unitId);
      setState(() {
        _data = Engagement(
          target: 'unit',
          id: widget.unitId,
          likes: r.likes,
          likedByMe: true,
          commentCount: _data?.commentCount ?? 0,
          comments: _data?.comments ?? const [],
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.describeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openComments(BuildContext context) async {
    _data ??= await widget.state.engagement.unit(widget.unitId);
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CommentsSheet(
        title: '${widget.unitTitle} · ${EtStrings.comments}',
        engagement: _data!,
        accent: widget.accent,
        canComment: widget.state.canEngage,
        onSubmit: (body) =>
            widget.state.engagement.commentUnit(widget.unitId, body),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    // Reload when sign-in state changes so likedByMe is correct after login.
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_data == null || mounted) {
            // silent refresh — keeps heart filled after logout/login
          }
        });
        final d = _data;
        return Align(
          alignment: Alignment.centerRight,
          child: EngagementBar(
            targetLabel: widget.unitTitle,
            likes: d?.likes ?? 0,
            likedByMe: d?.likedByMe ?? false,
            commentCount: d?.commentCount ?? 0,
            accent: widget.accent,
            compact: true,
            onToggleLike: _like,
            onOpenComments: _openComments,
          ),
        );
      },
    );
  }
}

class _LanguageEngagementBar extends StatefulWidget {
  final AppState state;
  const _LanguageEngagementBar({required this.state});

  @override
  State<_LanguageEngagementBar> createState() => _LanguageEngagementBarState();
}

class _LanguageEngagementBarState extends State<_LanguageEngagementBar> {
  Engagement? _data;
  bool _busy = false;

  int? get _dbId => widget.state.language.dbId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _dbId;
    if (id == null) return;
    try {
      final e = await widget.state.engagement.language(id);
      if (mounted) setState(() => _data = e);
    } catch (_) {}
  }

  Future<void> _like() async {
    final id = _dbId;
    if (id == null) return;
    if (!widget.state.canEngage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(EtStrings.signInToEngage)),
      );
      return;
    }
    if (_data?.likedByMe == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(EtStrings.alreadyLiked)),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await widget.state.engagement.likeLanguage(id);
      setState(() {
        _data = Engagement(
          target: 'language',
          id: id,
          likes: r.likes,
          likedByMe: true,
          commentCount: _data?.commentCount ?? 0,
          comments: _data?.comments ?? const [],
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.describeError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openComments(BuildContext context) async {
    final id = _dbId;
    if (id == null) return;
    _data ??= await widget.state.engagement.language(id);
    if (!context.mounted) return;
    final lang = widget.state.language;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CommentsSheet(
        title: '${lang.nativeName} · ${EtStrings.comments}',
        engagement: _data!,
        accent: lang.color,
        canComment: widget.state.canEngage,
        onSubmit: (body) => widget.state.engagement.commentLanguage(id, body),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.state.language;
    final d = _data;
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        return EngagementBar(
          targetLabel: lang.name,
          likes: d?.likes ?? 0,
          likedByMe: d?.likedByMe ?? false,
          commentCount: d?.commentCount ?? 0,
          accent: Colors.white,
          compact: true,
          onToggleLike: _like,
          onOpenComments: _openComments,
        );
      },
    );
  }
}
