import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/calendar/ethiopian_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/engagement_bar.dart';
import '../../data/fidel_chart.dart';
import '../../data/models.dart';
import '../../services/engagement_service.dart';
import '../../services/audio_service.dart';
import '../../services/script_service.dart';
import '../../state/app_state.dart';
import 'culture_phase4_screens.dart';
import 'culture_reader.dart';
import 'culture_widgets.dart';
import '../topics/topics_screen.dart';
import '../calendar/ethiopian_calendar_screen.dart';
import '../../widgets/ad_slot.dart';

class CultureChapter {
  final int id;
  final String title;
  final String subtitle;
  final String theme;
  final Color color;
  final Color dark;
  final IconData icon;
  final List<CultureCardModel> cards;
  final int doneCount;

  CultureChapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.color,
    required this.dark,
    required this.icon,
    required this.cards,
    this.doneCount = 0,
  });

  double get progress =>
      cards.isEmpty ? 0 : (doneCount / cards.length).clamp(0.0, 1.0);

  Color get accent => color;

  bool get isHoliday => theme == 'holiday';
}

class CultureCardModel {
  final String id;
  final String kind;
  final String title;
  final String body;
  final String translit;
  final String audioUrl;
  final String pdfUrl;
  final List<TeachItem> vocab;
  final int xpReward;
  final Map<String, Map<String, String>> content;
  final Map<String, dynamic> meta;

  CultureCardModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.translit = '',
    this.audioUrl = '',
    this.pdfUrl = '',
    this.vocab = const [],
    this.xpReward = 5,
    this.content = const {},
    this.meta = const {},
  });

  String titleFor(String base) =>
      content[base]?['title'] ?? content['en']?['title'] ?? title;
  String bodyFor(String base) =>
      content[base]?['body'] ?? content['en']?['body'] ?? body;

  List<({String title, String body})> stepsFor(String base) {
    final raw = meta['steps'];
    if (raw is! List) return const [];
    final out = <({String title, String body})>[];
    for (final s in raw) {
      if (s is! Map) continue;
      String pick(String key) {
        final node = s[key];
        if (node is Map) {
          return (node[base] ?? node['en'] ?? '').toString();
        }
        return (s[key] ?? '').toString();
      }

      out.add((title: pick('title'), body: pick('body')));
    }
    return out;
  }

  List<({String line, String translit, String note})> lyricsFor(String base) {
    final raw = meta['lyrics'];
    if (raw is! List) return const [];
    final out = <({String line, String translit, String note})>[];
    for (final s in raw) {
      if (s is! Map) continue;
      String pick(String key) {
        final node = s[key];
        if (node is Map) {
          return (node[base] ?? node['en'] ?? '').toString();
        }
        return (s[key] ?? '').toString();
      }

      out.add((
        line: pick('line'),
        translit: (s['translit'] ?? '').toString(),
        note: pick('note'),
      ));
    }
    return out;
  }

  String get kindLabel => switch (kind) {
        'proverb' => 'PROVERB · ምሳሌ',
        'vocab' => 'WORDS · ቃላት',
        'steps' => 'STEPS · እርምጃ',
        'calendar' => 'CALENDAR',
        'fact' => 'FACT',
        'media' => 'MEDIA',
        'music' => 'MUSIC · ዘፈን',
        _ => 'CULTURE',
      };

  factory CultureCardModel.fromJson(Map<String, dynamic> j) {
    final rawVocab = j['vocab'];
    final rawContent = j['content'];
    final content = <String, Map<String, String>>{};
    if (rawContent is Map) {
      rawContent.forEach((k, v) {
        if (v is Map) {
          content[k.toString()] = {
            'title': (v['title'] ?? '').toString(),
            'body': (v['body'] ?? '').toString(),
          };
        }
      });
    }
    return CultureCardModel(
      id: (j['id'] ?? '').toString(),
      kind: (j['kind'] ?? 'text').toString(),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      translit: (j['translit'] ?? '').toString(),
      audioUrl: (j['audioUrl'] ?? '').toString(),
      pdfUrl: (j['pdfUrl'] ?? '').toString(),
      vocab: rawVocab is List
          ? rawVocab
              .whereType<Map>()
              .map((e) => TeachItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      xpReward: (j['xpReward'] as num?)?.toInt() ?? 5,
      content: content,
      meta: j['meta'] is Map
          ? Map<String, dynamic>.from(j['meta'] as Map)
          : const {},
    );
  }
}

/// Culture Path — second track under Learn.
class CultureScreen extends StatefulWidget {
  final AppState state;
  const CultureScreen({super.key, required this.state});

  @override
  State<CultureScreen> createState() => _CultureScreenState();
}

class _CultureScreenState extends State<CultureScreen> {
  List<CultureChapter>? _chapters;
  bool _loading = true;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final chapters = await state.loadCulture();
    await state.loadProverbOfDay();
    await state.loadCultureCalendar();
    await state.loadLanguageScripts();
    if (!mounted) return;
    setState(() {
      _chapters = chapters;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = state.language;
    final accent = lang.id.isEmpty ? EtColors.green : lang.color;
    final code = lang.id;
    final cached = code.isNotEmpty && state.isCultureCached(code);
    final cal = state.cultureCalendar;
    final holidayName = (cal?['holiday'] is Map)
        ? ((cal!['holiday'] as Map)['nameAm'] ?? (cal['holiday'] as Map)['name'])
            .toString()
        : EthiopianCalendar.holidayLabel(DateTime.now());
    final upcoming = (cal?['upcoming'] is Map) ? cal!['upcoming'] as Map : null;
    final holidayLive = cal?['holiday'] is Map ||
        EthiopianCalendar.holidayXpActive;

    if (_loading && _chapters == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final chapters = _chapters ?? const <CultureChapter>[];

    return RefreshIndicator(
      onRefresh: _load,
      color: accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AdSlot(state: state, position: 'culture_top', compact: true),
          Row(
            children: [
              Expanded(
                child: Text(
                  EtStrings.cultureTab,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              if (code.isNotEmpty)
                OfflineCacheChip(
                  cached: cached,
                  accent: accent,
                  onDownload: cached
                      ? null
                      : () async {
                          await state.downloadCulturePack(code);
                          if (mounted) setState(() {});
                        },
                ),
            ],
          ),
          const SizedBox(height: 12),
          EthiopianCalendarCard(
            holidayLabel: holidayName,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EthiopianCalendarScreen(),
              ));
            },
          ),
          if (holidayLive) ...[
            const SizedBox(height: 12),
            HolidayChallengeBanner(
              label: EtStrings.holidayChallenge,
              detail: (cal != null && cal['holiday'] is Map)
                  ? '${(cal['holiday'] as Map)['name']} · ${cal['xpMultiplier'] ?? 2}× XP'
                  : 'Culture XP boosted today',
              onOpen: () {
                final holidayUnits =
                    chapters.where((c) => c.isHoliday).toList();
                if (holidayUnits.isEmpty) return;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CultureCardReader(
                    state: state,
                    chapter: holidayUnits.first,
                    cards: holidayUnits.first.cards,
                  ),
                ));
              },
            ),
          ] else if (upcoming != null) ...[
            const SizedBox(height: 12),
            HolidayChallengeBanner(
              label: EtStrings.holidayChallenge,
              detail:
                  '${upcoming['name']} in ${upcoming['inDays']} days · ${upcoming['xpMultiplier'] ?? 2}× XP',
              accent: EtColors.gold,
            ),
          ],
          if (state.proverbOfDay != null) ...[
            const SizedBox(height: 14),
            ProverbOfDayCard(
              title: EtStrings.proverbOfDay,
              target: state.proverbOfDay!.title,
              translit: state.proverbOfDay!.translit,
              body: state.proverbOfDay!.bodyFor(state.baseLanguage),
              accent: EtColors.gold,
              audioUrl: state.proverbOfDay!.audioUrl.isEmpty
                  ? null
                  : state.proverbOfDay!.audioUrl,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ArShareCardScreen(
                    title: EtStrings.proverbOfDay,
                    target: state.proverbOfDay!.title,
                    body: state.proverbOfDay!.bodyFor(state.baseLanguage),
                    translit: state.proverbOfDay!.translit.isEmpty
                        ? null
                        : state.proverbOfDay!.translit,
                  ),
                ));
              },
            ),
          ],
          const SizedBox(height: 16),
          if (chapters.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  EtStrings.readEmptySub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: EtColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ...chapters.map((ch) => _ChapterCard(
                  chapter: ch,
                  state: state,
                  highlight: ch.isHoliday && holidayLive,
                  onOpen: () async {
                    final done = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => CultureCardReader(
                          state: state,
                          chapter: ch,
                          cards: ch.cards,
                        ),
                      ),
                    );
                    if (done == true && mounted) {
                      await _load();
                    }
                  },
                )),
          const SizedBox(height: 8),
          Text(
            EtStrings.letterFamily,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: accent, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final script = state.primaryScript;
            if (script == null) {
              return FidelTrainerCard(
                accent: EtColors.blue,
                onOpen: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FidelTrainerScreen(state: state),
                  ));
                },
              );
            }
            final families = FidelChart.groupFamilies(script.letters);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScriptBadge(
                  script: script,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ScriptBrowserScreen(state: state),
                    ));
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: families.length.clamp(0, 12),
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final fam = families[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => LetterFamilyScreen(
                              family: fam,
                              scriptName: script.name,
                            ),
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: EtColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EtColors.line),
                          ),
                          child: Center(
                            child: Text(
                              fam.sample,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 10),
          FidelTrainerCard(
            accent: EtColors.blue,
            onOpen: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FidelTrainerScreen(state: state),
              ));
            },
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ScriptBrowserScreen(state: state),
                ));
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EtColors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: EtColors.blue.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.abc_rounded, color: EtColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        EtStrings.fidelTrainerSub,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: EtColors.locked),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Topic packs (Animals, Food…)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TopicsScreen(state: state),
                ));
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EtColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: EtColors.gold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets_rounded, color: EtColors.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            EtStrings.topicPacks,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          Text(
                            EtStrings.topicPacksSub,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: EtColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: EtColors.locked),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LanguageExchangeCard(
            accent: EtColors.blue,
            onOpen: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LanguageExchangeScreen(state: state),
              ));
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CommunityStoriesScreen(state: state),
                ));
              },
              child: CommunityStoryCard(
                author: EtStrings.communityStories,
                snippet: 'Read and share family stories (moderated)',
                accent: EtColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final CultureChapter chapter;
  final AppState state;
  final VoidCallback onOpen;
  final bool highlight;

  const _ChapterCard({
    required this.chapter,
    required this.state,
    required this.onOpen,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final ch = chapter;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlight ? EtColors.red : EtColors.line,
          width: highlight ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 4, color: highlight ? EtColors.red : ch.color),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ch.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(ch.icon, color: ch.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ch.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            ch.subtitle.isEmpty
                                ? '${ch.cards.length} ${EtStrings.vocabWords}'
                                : ch.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: EtColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${ch.doneCount}/${ch.cards.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ch.color,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: EtColors.locked),
                  ],
                ),
              ),
            ),
          ),
          if (ch.id > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _CultureUnitEngagementBar(
                state: state,
                unitId: ch.id,
                unitTitle: ch.title,
              ),
            ),
        ],
      ),
    );
  }
}

class _CultureUnitEngagementBar extends StatefulWidget {
  final AppState state;
  final int unitId;
  final String unitTitle;
  const _CultureUnitEngagementBar({
    required this.state,
    required this.unitId,
    required this.unitTitle,
  });

  @override
  State<_CultureUnitEngagementBar> createState() =>
      _CultureUnitEngagementBarState();
}

class _CultureUnitEngagementBarState extends State<_CultureUnitEngagementBar> {
  Engagement? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await widget.state.engagement.cultureUnit(widget.unitId);
      if (mounted) setState(() => _data = d);
    } catch (_) {}
  }

  Future<void> _like() async {
    if (!widget.state.canEngage) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(EtStrings.signInToEngage)));
      return;
    }
    final r = await widget.state.engagement.likeCultureUnit(widget.unitId);
    if (!mounted) return;
    setState(() {
      _data = Engagement(
        target: 'cultureUnit',
        id: widget.unitId,
        likes: r.likes,
        likedByMe: true,
        commentCount: _data?.commentCount ?? 0,
        comments: _data?.comments ?? const [],
      );
    });
    if (r.alreadyLiked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(EtStrings.alreadyLiked)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final accent = widget.state.language.color;
    return EngagementBar(
      targetLabel: 'cultureUnit',
      likes: d?.likes ?? 0,
      likedByMe: d?.likedByMe ?? false,
      commentCount: d?.commentCount ?? 0,
      accent: accent,
      compact: true,
      onToggleLike: _like,
      onOpenComments: (ctx) async {
        await showModalBottomSheet(
          context: ctx,
          isScrollControlled: true,
          builder: (_) => CommentsSheet(
            title: '${widget.unitTitle} · ${EtStrings.comments}',
            engagement:
                _data ?? Engagement(target: 'cultureUnit', id: widget.unitId),
            accent: accent,
            canComment: widget.state.canEngage,
            onSubmit: (body) =>
                widget.state.engagement.commentCultureUnit(widget.unitId, body),
          ),
        );
        await _load();
      },
    );
  }
}

Future<void> openPdfUrl(String url) async {
  final uri = Uri.parse(AudioService.resolve(url));
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
