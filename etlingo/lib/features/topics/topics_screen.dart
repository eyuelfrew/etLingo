import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../services/audio_service.dart';
import '../../services/topic_service.dart';
import '../../state/app_state.dart';
import '../../widgets/ad_slot.dart';

/// Theme packs: Animals · Food · Colors — words with audio + meaning.
class TopicsScreen extends StatefulWidget {
  final AppState state;
  const TopicsScreen({super.key, required this.state});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  List<TopicCategory> _cats = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pack = await widget.state.loadTopics();
    if (!mounted) return;
    setState(() {
      _cats = pack?.categories ?? const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.topicPacks),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AdSlot(
                      state: widget.state,
                      position: 'after_topics',
                      compact: true),
                  Text(
                    EtStrings.topicPacksSub,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: EtColors.muted),
                  ),
                  const SizedBox(height: 14),
                  if (_cats.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        EtStrings.noContentYet,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: EtColors.muted),
                      ),
                    )
                  else
                    ..._cats.map((c) => _TopicTile(
                          cat: c,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => TopicWordsScreen(
                                state: widget.state,
                                category: c,
                              ),
                            ));
                          },
                        )),
                ],
              ),
            ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final TopicCategory cat;
  final VoidCallback onTap;
  const _TopicTile({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = cat.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(cat.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        cat.nativeTitle.isNotEmpty
                            ? cat.nativeTitle
                            : cat.description,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: EtColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${cat.words.length}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: color, fontSize: 16),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: EtColors.locked),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Word list for one theme — tap to hear audio; check to mark known.
class TopicWordsScreen extends StatefulWidget {
  final AppState state;
  final TopicCategory category;
  const TopicWordsScreen({
    super.key,
    required this.state,
    required this.category,
  });

  @override
  State<TopicWordsScreen> createState() => _TopicWordsScreenState();
}

class _TopicWordsScreenState extends State<TopicWordsScreen> {
  final Set<int> _known = {};

  Future<void> _toggleKnown(TopicWord w) async {
    if (!widget.state.canEngage) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(EtStrings.signInToEngage)));
      return;
    }
    final was = _known.contains(w.id);
    setState(() {
      if (was) {
        _known.remove(w.id);
      } else {
        _known.add(w.id);
      }
    });
    if (was) {
      await widget.state.unmarkWordKnown(w.id);
    } else {
      await widget.state.markWordKnown(w.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.category.words;
    final base = widget.state.baseLanguage;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text('${widget.category.emoji} ${widget.category.title}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${_known.length}/${words.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: EtColors.muted),
              ),
            ),
          ),
          IconButton(
            tooltip: EtStrings.quizMe,
            icon: const Icon(Icons.quiz_rounded),
            onPressed: words.length < 2
                ? null
                : () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TopicQuizScreen(
                        state: widget.state,
                        category: widget.category,
                      ),
                    ));
                  },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: words.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final w = words[i];
          final meaning = w.meaningFor(base);
          final known = _known.contains(w.id);
          return Container(
            decoration: BoxDecoration(
              color: known
                  ? EtColors.green.withValues(alpha: 0.06)
                  : EtColors.card,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: known ? EtColors.green : EtColors.line),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(
                w.target,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                w.translit.isNotEmpty ? '${w.translit} · $meaning' : meaning,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: EtColors.muted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: known ? 'Known' : 'Mark known',
                    icon: Icon(
                      known
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      color: known ? EtColors.green : EtColors.locked,
                    ),
                    onPressed: () => _toggleKnown(w),
                  ),
                  IconButton(
                    icon: Icon(
                      w.hasAudio
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_outlined,
                      color: w.hasAudio ? EtColors.blue : EtColors.locked,
                      size: 28,
                    ),
                    onPressed: () {
                      if (w.hasAudio) {
                        AudioService.instance.play(w.audioUrl);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(EtStrings.noAudioYet)));
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                if (w.hasAudio) AudioService.instance.play(w.audioUrl);
              },
            ),
          );
        },
      ),
    );
  }
}

/// Simple listen/see quiz over a topic pack.
class TopicQuizScreen extends StatefulWidget {
  final AppState state;
  final TopicCategory category;
  const TopicQuizScreen({
    super.key,
    required this.state,
    required this.category,
  });

  @override
  State<TopicQuizScreen> createState() => _TopicQuizScreenState();
}

class _TopicQuizScreenState extends State<TopicQuizScreen> {
  int _i = 0;
  int _score = 0;
  String? _feedback;
  late List<TopicWord> _shuffled;
  late TopicWord _correct;
  late List<TopicWord> _options;

  @override
  void initState() {
    super.initState();
    _shuffled = [...widget.category.words]..shuffle();
    _correct = _shuffled.first;
    _options = _makeOptions();
  }

  List<TopicWord> _makeOptions() {
    final others = List<TopicWord>.of(widget.category.words)
      ..removeWhere((w) => w.id == _correct.id)
      ..shuffle();
    final picks = others.take(3).toList();
    return ([_correct, ...picks]..shuffle());
  }

  void _next() {
    setState(() {
      _i += 1;
      if (_i >= _shuffled.length) {
        _feedback = '${EtStrings.quizMe}: $_score / ${_shuffled.length}';
        return;
      }
      _correct = _shuffled[_i];
      _options = _makeOptions();
      _feedback = null;
    });
  }

  void _answer(TopicWord pick) {
    final ok = pick.id == _correct.id;
    setState(() {
      if (ok) _score += 1;
      _feedback = ok
          ? '✓ ${_correct.target} = ${_correct.meaning}'
          : '✗ ${_correct.target} = ${_correct.meaning}';
    });
    if (_correct.hasAudio) AudioService.instance.play(_correct.audioUrl);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _i >= _shuffled.length;
    final base = widget.state.baseLanguage;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.quizMe),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$_score / ${_shuffled.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: EtColors.muted),
              ),
            ),
          ),
        ],
      ),
      body: done
          ? Center(
              child: Text(
                '${EtStrings.quizMe}: $_score / ${_shuffled.length}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _correct.target,
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w800),
                  ),
                  if (_correct.translit.isNotEmpty)
                    Text(
                      _correct.translit,
                      style: const TextStyle(
                          color: EtColors.muted, fontWeight: FontWeight.w700),
                    ),
                  const SizedBox(height: 8),
                  Text(_feedback ?? ' ', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: _options
                          .map(
                            (o) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: EtColors.card,
                                  foregroundColor: EtColors.ink,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: EtColors.line),
                                ),
                                onPressed:
                                    _feedback == null ? () => _answer(o) : null,
                                child: Text(
                                  o.meaningFor(base),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
