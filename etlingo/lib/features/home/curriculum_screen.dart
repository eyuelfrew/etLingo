import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/et_card.dart';
import '../../core/widgets/et_icons.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../lesson/lesson_screen.dart';
import '../lesson/teaching_screen.dart';

/// Chapter / lesson catalog — pick what to study.
/// Future paid lessons can set `isPremium` and show a lock + pay CTA.
class CurriculumScreen extends StatelessWidget {
  final AppState state;

  /// When true, show a primary CTA to continue the guided path.
  final bool showPathCta;

  const CurriculumScreen({
    super.key,
    required this.state,
    this.showPathCta = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = state.language;

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([state, EtStrings.langNotifier]),
        builder: (context, _) {
          final units = lang.units;
          return RefreshIndicator(
            onRefresh: () => state.refreshLanguage(),
            color: lang.id.isEmpty ? EtColors.green : lang.color,
            backgroundColor: EtColors.card,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _Header(lang: lang, state: state, showPathCta: showPathCta),
                const SizedBox(height: 14),
                if (units.isEmpty)
                  _Empty(lang: lang)
                else
                  ...units.asMap().entries.map((entry) {
                    final i = entry.key;
                    final unit = entry.value;
                    return _UnitBlock(
                      index: i,
                      unit: unit,
                      state: state,
                      lang: lang,
                    );
                  }),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    EtStrings.pullToRefresh,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: EtColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Language lang;
  final AppState state;
  final bool showPathCta;

  const _Header({
    required this.lang,
    required this.state,
    required this.showPathCta,
  });

  @override
  Widget build(BuildContext context) {
    final total = lang.totalLessons;
    final done = state.totalLessonsDone;
    final colors = lang.id.isEmpty
        ? const [EtColors.greenMid, EtColors.greenDeep]
        : [lang.color, lang.dark];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            EtStrings.chooseLesson,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${lang.nativeName} · ${lang.name}\n${EtStrings.chooseLessonSub}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      FractionallySizedBox(
                        widthFactor: total == 0 ? 0 : (done / total).clamp(0, 1),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [EtColors.yellow, EtColors.yellowSoft],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$done/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (showPathCta) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final next = state.nextLesson();
                    final unit = next != null ? state.unitOf(next) : null;
                    if (next == null || unit == null) {
                      Navigator.of(context).pop();
                      return;
                    }
                    _openLesson(context, state, next, unit);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: colors.last),
                        const SizedBox(width: 6),
                        Text(
                          EtStrings.continuePath,
                          style: TextStyle(
                            color: colors.last,
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
    );
  }
}

class _Empty extends StatelessWidget {
  final Language lang;
  const _Empty({required this.lang});

  @override
  Widget build(BuildContext context) {
    return EtCard(
      child: Column(
        children: [
          EtIcons.tile(icon: Icons.menu_book_rounded, color: lang.color, size: 56),
          const SizedBox(height: 12),
          Text(
            EtStrings.noLessonsYet,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            EtStrings.noLessonsYetSub,
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

class _UnitBlock extends StatelessWidget {
  final int index;
  final Unit unit;
  final AppState state;
  final Language lang;

  const _UnitBlock({
    required this.index,
    required this.unit,
    required this.state,
    required this.lang,
  });

  /// Future paid gate — keep false until payment lands.
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chapter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [unit.color, unit.dark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: unit.dark.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(unit.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Admin-authored title only — no auto "Chapter N".
                      Text(
                        unit.title.isEmpty
                            ? EtStrings.unit
                            : unit.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
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
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$done/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      EtStrings.lessonsDone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Lessons list
          if (unit.teachItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
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
          ...unit.lessons.map((lesson) {
            final completed = state.completedLessons.contains(lesson.id);
            final unlocked = isUnlocked(lesson);
            final premium = isPremiumLesson(lesson);
            final canOpen = unlocked && !premium;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: canOpen
                      ? () => _openLesson(context, state, lesson, unit)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: completed
                          ? unit.color.withValues(alpha: 0.08)
                          : EtColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: completed
                            ? unit.color.withValues(alpha: 0.35)
                            : canOpen
                                ? EtColors.line
                                : EtColors.locked.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: completed
                                ? unit.color
                                : canOpen
                                    ? unit.color.withValues(alpha: 0.12)
                                    : EtColors.locked.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
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
                                    ? unit.color
                                    : EtColors.locked,
                            size: completed || !canOpen ? 20 : 24,
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
                                        fontSize: 14.5,
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
                                        color:
                                            EtColors.yellow.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(8),
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
                                        ? '${lesson.teachItems.length + unit.teachItems.length} ${EtStrings.vocabWords} · ${lesson.questions.length} ${EtStrings.quizQuestions} · ${lesson.xpReward} XP'
                                        : EtStrings.lockedHint,
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
                              color: EtColors.yellow.withValues(alpha: 0.25),
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
                            color: canOpen ? unit.color : EtColors.locked,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

void _openLesson(
  BuildContext context,
  AppState state,
  Lesson lesson,
  Unit unit,
) {
  if (lesson.questions.isEmpty && unit.teachItemsFor(lesson).isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${lesson.title}" — ${EtStrings.noContentYet}')),
    );
    return;
  }
  final teach = unit.teachItemsFor(lesson);
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
