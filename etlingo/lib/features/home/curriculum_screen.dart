import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/et_icons.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../lesson/lesson_screen.dart';
import '../lesson/teaching_screen.dart';

/// Full-screen chapter / lesson catalog (light parchment theme).
class CurriculumScreen extends StatelessWidget {
  final AppState state;
  final bool showPathCta;

  const CurriculumScreen({
    super.key,
    required this.state,
    this.showPathCta = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = state.language;
    final accent = lang.id.isEmpty ? EtColors.green : lang.color;

    return Scaffold(
      backgroundColor: EtColors.paper,
      appBar: AppBar(
        backgroundColor: EtColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: EtColors.ink),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: EtColors.ink),
                tooltip: EtStrings.tabLearn,
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/home'),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              EtStrings.chooseLesson,
              style: const TextStyle(
                color: EtColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              lang.id.isEmpty
                  ? EtStrings.brand
                  : '${lang.nativeName} · ${lang.name}',
              style: const TextStyle(
                color: EtColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (showPathCta)
            TextButton.icon(
              onPressed: () {
                final next = state.nextLesson();
                final unit = next != null ? state.unitOf(next) : null;
                if (next == null || unit == null) {
                  Navigator.of(context).pop();
                  return;
                }
                openLesson(context, state, next, unit);
              },
              icon: Icon(Icons.play_arrow_rounded, color: accent, size: 22),
              label: Text(
                EtStrings.tabLearn,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([state, EtStrings.langNotifier]),
          builder: (context, _) {
            final units = lang.units;
            final done = state.totalLessonsDone;
            final total = lang.totalLessons;

            return RefreshIndicator(
              onRefresh: () => state.refreshLanguage(),
              color: accent,
              backgroundColor: EtColors.card,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  // Light progress card (not a dark hero)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EtColors.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: EtColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            EtIcons.tile(
                              icon: Icons.auto_stories_rounded,
                              color: accent,
                              size: 44,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    EtStrings.chooseLesson,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: EtColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    EtStrings.chooseLessonSub,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: EtColors.muted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$done/$total',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                                Text(
                                  EtStrings.lessonsDone,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: EtColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Container(height: 8, color: EtColors.line),
                              FractionallySizedBox(
                                widthFactor: total == 0
                                    ? 0
                                    : (done / total).clamp(0.0, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showPathCta) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: accent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  final next = state.nextLesson();
                                  final unit =
                                      next != null ? state.unitOf(next) : null;
                                  if (next == null || unit == null) {
                                    Navigator.of(context).pop();
                                    return;
                                  }
                                  openLesson(context, state, next, unit);
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_arrow_rounded,
                                          color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        EtStrings.continuePath,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (units.isEmpty)
                    _Empty(lang: lang, accent: accent)
                  else
                    ...units.asMap().entries.map((entry) {
                      return _UnitBlock(
                        index: entry.key,
                        unit: entry.value,
                        state: state,
                        accent: accent,
                      );
                    }),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      EtStrings.pullToRefresh,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EtColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final Language lang;
  final Color accent;
  const _Empty({required this.lang, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: EtColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: EtColors.line),
      ),
      child: Column(
        children: [
          EtIcons.tile(icon: Icons.menu_book_rounded, color: accent, size: 56),
          const SizedBox(height: 14),
          Text(
            EtStrings.noLessonsYet,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            EtStrings.noLessonsYetSub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EtColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.4,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitBlock extends StatelessWidget {
  final int index;
  final Unit unit;
  final AppState state;
  final Color accent;

  const _UnitBlock({
    required this.index,
    required this.unit,
    required this.state,
    required this.accent,
  });

  static bool isPremiumLesson(Lesson lesson) => false;

  bool isUnlocked(Lesson lesson) {
    final flat = <Lesson>[];
    for (final u in state.language.units) {
      flat.addAll(u.lessons);
    }
    final idx = flat.indexWhere((l) => l.id == lesson.id);
    if (idx <= 0) return true;
    return state.completedLessons.contains(flat[idx - 1].id);
  }

  @override
  Widget build(BuildContext context) {
    final done = state.completedInUnit(unit);
    final total = unit.lessons.length;
    final unitAccent = unit.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Light chapter card — colored accent strip, not a dark slab
          Container(
            decoration: BoxDecoration(
              color: EtColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EtColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 4, color: unitAccent),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: unitAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(unit.icon, color: unitAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unit.title.isEmpty
                                  ? EtStrings.unit
                                  : unit.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: EtColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            if (unit.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                unit.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EtColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: unitAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$done/$total',
                          style: TextStyle(
                            color: unitAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (unit.teachItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Text(
                      '${unit.teachItems.length} ${EtStrings.vocabWords} · ${unit.teachItems.map((t) => t.target).take(3).join(' · ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: EtColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Divider(height: 1, color: EtColors.line),
                ...unit.lessons.asMap().entries.map((e) {
                  final lesson = e.value;
                  final isLast = e.key == unit.lessons.length - 1;
                  final completed =
                      state.completedLessons.contains(lesson.id);
                  final unlocked = isUnlocked(lesson);
                  final premium = isPremiumLesson(lesson);
                  final canOpen = unlocked && !premium;

                  return InkWell(
                    onTap: canOpen
                        ? () => openLesson(context, state, lesson, unit)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      decoration: BoxDecoration(
                        color: completed
                            ? unitAccent.withValues(alpha: 0.06)
                            : Colors.transparent,
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: EtColors.line.withValues(alpha: 0.7),
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: completed
                                  ? unitAccent
                                  : canOpen
                                      ? EtColors.cream
                                      : EtColors.line.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: completed
                                    ? unitAccent
                                    : canOpen
                                        ? unitAccent.withValues(alpha: 0.25)
                                        : EtColors.locked
                                            .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              completed
                                  ? Icons.check_rounded
                                  : premium
                                      ? Icons.lock_rounded
                                      : unlocked
                                          ? (lesson.isBoss
                                              ? Icons.workspace_premium_rounded
                                              : Icons.play_arrow_rounded)
                                          : Icons.lock_outline_rounded,
                              color: completed
                                  ? Colors.white
                                  : canOpen
                                      ? unitAccent
                                      : EtColors.locked,
                              size: completed || !canOpen ? 18 : 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        lesson.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: canOpen || completed
                                              ? EtColors.ink
                                              : EtColors.locked,
                                        ),
                                      ),
                                    ),
                                    if (lesson.isBoss) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: EtColors.yellow
                                              .withValues(alpha: 0.35),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'BOSS',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: EtColors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  premium
                                      ? EtStrings.premiumSoon
                                      : unlocked
                                          ? metaLine(lesson)
                                          : EtStrings.lockedHint,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: premium
                                        ? EtColors.yellowDark
                                        : EtColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (premium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    EtColors.yellow.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: EtColors.yellowDark,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right_rounded,
                              color: canOpen
                                  ? unitAccent
                                  : EtColors.locked.withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String metaLine(Lesson lesson) {
    final words = lesson.teachItems.length + unit.teachItems.length;
    final qs = lesson.questions.length;
    final files = lesson.resources.length;
    final parts = <String>[
      '$words ${EtStrings.vocabWords}',
      '$qs ${EtStrings.quizQuestions}',
      if (files > 0) '$files files',
      '${lesson.xpReward} XP',
    ];
    return parts.join(' · ');
  }
}

void openLesson(
  BuildContext context,
  AppState state,
  Lesson lesson,
  Unit unit,
) {
  final teach = unit.teachItemsFor(lesson);
  if (lesson.questions.isEmpty && teach.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: EtColors.ink,
        content: Text('"${lesson.title}" — ${EtStrings.noContentYet}'),
      ),
    );
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => teach.isNotEmpty
        ? TeachingScreen(
            state: state,
            lesson: lesson,
            unit: unit,
            teachItemsOverride: teach,
          )
        : LessonScreen(state: state, lesson: lesson, unit: unit),
  ));
}
