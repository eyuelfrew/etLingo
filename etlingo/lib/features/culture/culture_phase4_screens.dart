import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../data/fidel_chart.dart';
import '../../services/audio_service.dart';
import '../../services/script_service.dart';
import '../../state/app_state.dart';
import 'culture_widgets.dart';

/// Full family view: ሀ ሁ ሂ ሃ ሄ ህ ሆ with audio per form.
class LetterFamilyScreen extends StatelessWidget {
  final LetterFamily family;
  final String scriptName;
  const LetterFamilyScreen({
    super.key,
    required this.family,
    required this.scriptName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text('${EtStrings.letterFamily} · ${family.key}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            family.sample,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.w800, height: 1.3),
          ),
          Text(
            '${EtStrings.sevenOrders} · $scriptName',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: EtColors.muted),
          ),
          const SizedBox(height: 16),
          ...family.letters.map((l) {
            final label = FidelChart.formLabels[l.formIndex.clamp(0, 7)];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: EtColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EtColors.line),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Text(
                  l.glyph,
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w800),
                ),
                title: Text(
                  '${l.glyph} · $label',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  l.roman.isNotEmpty ? l.roman : l.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: EtColors.muted),
                ),
                trailing: IconButton(
                  icon: Icon(
                    l.hasAudio
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_outlined,
                    color: l.hasAudio ? EtColors.blue : EtColors.locked,
                  ),
                  onPressed: () {
                    if (l.hasAudio) {
                      AudioService.instance.play(l.audioUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(EtStrings.noAudioYet)));
                    }
                  },
                ),
                onTap: () {
                  if (l.hasAudio) AudioService.instance.play(l.audioUrl);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Phase 4 — letter practice with **audio pronunciation**.
/// Two modes: hear sound → pick glyph (listen-first) · see glyph → pick sound.
class FidelTrainerScreen extends StatefulWidget {
  final AppState state;
  final String? scriptCode;
  const FidelTrainerScreen({super.key, required this.state, this.scriptCode});

  @override
  State<FidelTrainerScreen> createState() => _FidelTrainerScreenState();
}

class _FidelTrainerScreenState extends State<FidelTrainerScreen> {
  int _score = 0;
  int _asked = 0;
  List<FidelLetter> _pool = FidelChart.bases;
  String _scriptLabel = "Ge'ez / Ethiopic";
  /// true = listen-first (hear → pick glyph); false = see glyph → pick sound
  bool _listenFirst = true;
  /// When true, distractors come from the same family (ሀ vs ሁ vs ሂ…).
  bool _familyMode = true;
  late FidelLetter _correct = FidelChart.random(_pool);
  late List<FidelLetter> _options =
      FidelChart.quizOptions(_correct, _pool, sameFamily: true);
  String? _feedback;

  void _reseed() {
    _correct = FidelChart.random(_pool);
    _options = FidelChart.quizOptions(_correct, _pool, sameFamily: _familyMode);
    _feedback = null;
  }

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    try {
      final svc = ScriptService(widget.state.apiGet);
      ScriptInfo info;
      if (widget.scriptCode != null && widget.scriptCode!.isNotEmpty) {
        info = await svc.byCode(widget.scriptCode!);
      } else {
        final code = widget.state.language.id;
        final pack = code.isEmpty ? null : await svc.forLanguage(code);
        info = pack?.primary ??
            (code == 'am' || code == 'ti'
                ? await svc.byCode('ethi')
                : await svc.byCode('latn'));
      }
      final pool = FidelChart.resolve(info.letters);
      if (!mounted) return;
      setState(() {
        _pool = pool;
        _scriptLabel = info.name.isNotEmpty ? info.name : _scriptLabel;
        _reseed();
      });
      _maybeAutoplay();
    } catch (_) {
      // Keep bundled chart offline.
    }
  }

  void _maybeAutoplay() {
    if (_listenFirst && _correct.hasAudio) {
      AudioService.instance.play(_correct.audioUrl);
    }
  }

  void _replay() {
    if (_correct.hasAudio) {
      AudioService.instance.play(_correct.audioUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(EtStrings.noAudioYet)));
    }
  }

  void _next() {
    setState(_reseed);
    _maybeAutoplay();
  }

  void _answer(FidelLetter pick) {
    final ok = pick.glyph == _correct.glyph;
    setState(() {
      _asked += 1;
      if (ok) {
        _score += 1;
        _feedback = '✓ ${_correct.glyph} = ${_correct.sound} (${_correct.roman})';
      } else {
        _feedback = '✗ ${_correct.glyph} = ${_correct.sound} (${_correct.roman})';
      }
    });
    // Speak the correct pronunciation after the reveal.
    if (_correct.hasAudio) {
      AudioService.instance.play(_correct.audioUrl);
    }
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showGlyph = !_listenFirst;
    final optionsAsGlyphs = _listenFirst;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.fidelTrainer),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$_score / $_asked · ${_pool.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: EtColors.muted),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Mode switch — listen-first helps non-readers.
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: EtColors.cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EtColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _modeChip(
                        on: _listenFirst,
                        label: EtStrings.listenMode,
                        icon: Icons.headphones_rounded,
                        onTap: () {
                          if (_listenFirst) return;
                          setState(() => _listenFirst = true);
                          _maybeAutoplay();
                        },
                      ),
                    ),
                    Expanded(
                      child: _modeChip(
                        on: !_listenFirst,
                        label: EtStrings.seeMode,
                        icon: Icons.visibility_rounded,
                        onTap: () {
                          if (!_listenFirst) return;
                          setState(() => _listenFirst = false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Family vs any-letter practice
              Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      selected: _familyMode,
                      label: Text(EtStrings.familyMode),
                      onSelected: (v) {
                        setState(() {
                          _familyMode = v;
                          _options = FidelChart.quizOptions(_correct, _pool,
                              sameFamily: _familyMode);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChip(
                      selected: !_familyMode,
                      label: Text(EtStrings.anyLetter),
                      onSelected: (v) {
                        setState(() {
                          _familyMode = !v;
                          _options = FidelChart.quizOptions(_correct, _pool,
                              sameFamily: _familyMode);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show family strip when family mode (tells learner the set)
              if (_correct.orderName.isNotEmpty && _familyMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    FidelChart.familyOf(_correct, _pool)
                        .map((l) => l.glyph)
                        .join(' '),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: EtColors.muted,
                        letterSpacing: 2),
                  ),
                ),
              Text(
                _scriptLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: EtColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                _listenFirst
                    ? EtStrings.whichLetterHear
                    : EtStrings.whichSoundSee,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: EtColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                _correct.orderName.isEmpty
                    ? ''
                    : '${EtStrings.letterFamily}: ${_correct.orderName} · '
                        '${FidelChart.formLabels[_correct.formIndex.clamp(0, 7)]}',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: EtColors.locked),
              ),
              const SizedBox(height: 8),
              // Prompt: sound button or big glyph
              if (showGlyph)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: EtColors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: EtColors.blue.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Text(
                      _correct.glyph,
                      style: const TextStyle(
                          fontSize: 72, fontWeight: FontWeight.w800),
                    ),
                  ),
                )
              else
                Material(
                  color: EtColors.blue.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                        color: EtColors.blue.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _replay,
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _correct.hasAudio
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 48,
                            color: EtColors.blue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            EtStrings.playSound,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: EtColors.blue,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (showGlyph && _correct.hasAudio)
                TextButton.icon(
                  onPressed: _replay,
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: Text(EtStrings.playSound),
                ),
              const SizedBox(height: 8),
              Text(
                _feedback ?? ' ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _feedback == null
                      ? Colors.transparent
                      : (_feedback!.startsWith('✓')
                          ? EtColors.green
                          : EtColors.red),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: optionsAsGlyphs ? 1.15 : 2.2,
                  children: _options
                      .map(
                        (o) => Material(
                          color: EtColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: EtColors.line),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _feedback == null ? () => _answer(o) : null,
                            child: Center(
                              child: optionsAsGlyphs
                                  ? Text(
                                      o.glyph,
                                      style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800),
                                    )
                                  : Text(
                                      o.sound,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800),
                                    ),
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
      ),
    );
  }

  Widget _modeChip({
    required bool on,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: on ? EtColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: on ? Colors.white : EtColors.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: on ? Colors.white : EtColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phase 4 — community stories list + submit.
class CommunityStoriesScreen extends StatefulWidget {
  final AppState state;
  const CommunityStoriesScreen({super.key, required this.state});

  @override
  State<CommunityStoriesScreen> createState() => _CommunityStoriesScreenState();
}

class _CommunityStoriesScreenState extends State<CommunityStoriesScreen> {
  List<Map<String, dynamic>> _stories = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.state.apiGet('/app/stories');
      if (data is List) {
        _stories = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(EtStrings.communityStories),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Your story'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.state.apiPost('/app/stories', {
        'title': titleCtrl.text,
        'body': bodyCtrl.text,
        'languageCode': widget.state.language.id.isEmpty
            ? 'am'
            : widget.state.language.id,
      });
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.communityStories),
        actions: [
          IconButton(onPressed: _submit, icon: const Icon(Icons.edit_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Stories are reviewed by a moderator before they appear here.',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EtColors.muted),
                  ),
                  const SizedBox(height: 12),
                  if (_stories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(EtStrings.communityStories,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: EtColors.muted)),
                    )
                  else
                    ..._stories.map(
                      (s) => CommunityStoryCard(
                        author: (s['author'] ?? '').toString(),
                        snippet: (s['body'] ?? s['title'] ?? '').toString(),
                        audioUrl: (s['audioUrl'] ?? '').toString(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Phase 4 — language exchange waitlist signup.
class LanguageExchangeScreen extends StatefulWidget {
  final AppState state;
  const LanguageExchangeScreen({super.key, required this.state});

  @override
  State<LanguageExchangeScreen> createState() => _LanguageExchangeScreenState();
}

class _LanguageExchangeScreenState extends State<LanguageExchangeScreen> {
  String _speaks = 'en';
  String _learning = 'am';
  final _note = TextEditingController();
  String? _message;
  bool _busy = false;

  static const _langs = [
    ('en', 'English'),
    ('am', 'አማርኛ'),
    ('om', 'Afaan Oromoo'),
    ('ti', 'ትግርኛ'),
    ('so', 'Soomaali'),
  ];

  Future<void> _signup() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final data = await widget.state.apiPost('/app/exchange/signup', {
        'speaks': _speaks,
        'learning': _learning,
        'note': _note.text,
      });
      setState(() {
        _message = data is Map
            ? (data['message'] ?? 'You are on the list.').toString()
            : 'You are on the list.';
      });
    } catch (e) {
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.languageExchange),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            EtStrings.languageExchangeSub,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: EtColors.muted),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _speaks,
            decoration: const InputDecoration(labelText: 'I speak'),
            items: _langs
                .map((l) => DropdownMenuItem(value: l.$1, child: Text(l.$2)))
                .toList(),
            onChanged: (v) => setState(() => _speaks = v ?? 'en'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _learning,
            decoration: const InputDecoration(labelText: 'I am learning'),
            items: _langs
                .map((l) => DropdownMenuItem(value: l.$1, child: Text(l.$2)))
                .toList(),
            onChanged: (v) => setState(() => _learning = v ?? 'am'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              helperText: 'How you like to practice — voice, text, schedule',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _signup,
            style: FilledButton.styleFrom(
                backgroundColor: EtColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(_busy ? '…' : 'Join exchange list'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: EtColors.green)),
          ],
        ],
      ),
    );
  }
}

/// Browse a writing system's alphabet (admin-managed letters).
class ScriptBrowserScreen extends StatefulWidget {
  final AppState state;
  final String? scriptCode;
  const ScriptBrowserScreen({super.key, required this.state, this.scriptCode});

  @override
  State<ScriptBrowserScreen> createState() => _ScriptBrowserScreenState();
}

class _ScriptBrowserScreenState extends State<ScriptBrowserScreen> {
  List<ScriptInfo> _scripts = const [];
  int _index = 0;
  bool _loading = true;

  List<LetterFamily> get _families {
    if (_scripts.isEmpty) return const [];
    final script = _scripts[_index.clamp(0, _scripts.length - 1)];
    return FidelChart.groupFamilies(script.letters);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final svc = ScriptService(widget.state.apiGet);
      List<ScriptInfo> list;
      if (widget.scriptCode != null && widget.scriptCode!.isNotEmpty) {
        list = [await svc.byCode(widget.scriptCode!)];
      } else {
        final code = widget.state.language.id;
        if (code.isEmpty) {
          list = await svc.all();
        } else {
          final pack = await svc.forLanguage(code);
          list = pack.scripts.where((s) => s.letters.isNotEmpty).toList();
          if (list.isEmpty) list = await svc.all();
        }
      }
      if (mounted) setState(() => _scripts = list);
    } catch (_) {
      if (mounted) setState(() => _scripts = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final script =
        _scripts.isEmpty ? null : _scripts[_index.clamp(0, _scripts.length - 1)];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(script == null
            ? EtStrings.fidelTrainerSub
            : '${script.name} · ${script.letters.length}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : script == null
              ? Center(child: Text(EtStrings.noContentYet))
              : Column(
                  children: [
                    if (_scripts.length > 1)
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _scripts.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final s = _scripts[i];
                            final on = i == _index;
                            return ChoiceChip(
                              selected: on,
                              label: Text(s.name),
                              onSelected: (_) => setState(() => _index = i),
                            );
                          },
                        ),
                      ),
                    if (script.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          script.description,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: EtColors.muted),
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _families.length,
                        itemBuilder: (ctx, i) {
                          final fam = _families[i];
                          return Material(
                            color: EtColors.card,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => LetterFamilyScreen(
                                    family: fam,
                                    scriptName: script.name,
                                  ),
                                ));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: EtColors.line),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      fam.head.glyph,
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fam.sample.length > 5
                                          ? '${fam.sample.substring(0, 5)}…'
                                          : fam.sample,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: EtColors.muted),
                                    ),
                                    Text(
                                      '${fam.letters.length} forms',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: EtColors.locked),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// Phase 4 — pretty share card (copy text / open share sheet via clipboard).
class ArShareCardScreen extends StatelessWidget {
  final String title;
  final String target;
  final String body;
  final String? translit;
  const ArShareCardScreen({
    super.key,
    required this.title,
    required this.target,
    required this.body,
    this.translit,
  });

  Future<void> _copy(BuildContext context) async {
    final text = '$target\n${translit ?? ''}\n\n$body\n— etLingo';
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Share text copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EtColors.ink,
      appBar: AppBar(
        backgroundColor: EtColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(EtStrings.arShare),
        actions: [
          IconButton(onPressed: () => _copy(context), icon: const Icon(Icons.copy_rounded)),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [EtColors.green, EtColors.yellow, EtColors.red],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                target,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              if ((translit ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  translit!,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'etLingo · ኢትLang',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
