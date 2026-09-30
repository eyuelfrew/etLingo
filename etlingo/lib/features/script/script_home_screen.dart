import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../data/fidel_chart.dart';
import '../../services/audio_service.dart';
import '../../services/script_service.dart';
import '../../state/app_state.dart';
import '../culture/culture_phase4_screens.dart';
import '../phrases/phrasebook_screen.dart';
import '../topics/topics_screen.dart';

/// Bottom-nav home for writing systems: pick a script, browse families,
/// open trainer / full alphabet.
class ScriptHomeScreen extends StatefulWidget {
  final AppState state;
  const ScriptHomeScreen({super.key, required this.state});

  @override
  State<ScriptHomeScreen> createState() => _ScriptHomeScreenState();
}

class _ScriptHomeScreenState extends State<ScriptHomeScreen> {
  List<ScriptInfo> _scripts = const [];
  int _index = 0;
  bool _loading = true;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pack = await state.loadLanguageScripts();
      var list =
          pack?.scripts.where((s) => s.letters.isNotEmpty).toList() ??
              const <ScriptInfo>[];
      if (list.isEmpty) {
        final all = await ScriptService(state.apiGet).all();
        list = all
            .where((s) => s.letters.isNotEmpty || s.sample.isNotEmpty)
            .toList();
      }
      if (mounted) {
        setState(() {
          _scripts = list;
          _index = 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final script = _scripts.isEmpty
        ? null
        : _scripts[_index.clamp(0, _scripts.length - 1)];
    final families = script == null
        ? const <LetterFamily>[]
        : FidelChart.groupFamilies(script.letters);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: EtColors.gold,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'ፊደል · Script',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: EtColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              EtStrings.fidelTrainerSub,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EtColors.muted,
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (script == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  EtStrings.noContentYet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: EtColors.muted),
                ),
              )
            else ...[
              if (_scripts.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _scripts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final s = _scripts[i];
                      final on = i == _index;
                      return ChoiceChip(
                        selected: on,
                        label: Text(s.name),
                        selectedColor: EtColors.gold.withValues(alpha: 0.25),
                        onSelected: (_) => setState(() => _index = i),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EtColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: EtColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      script.sample.isEmpty ? 'ሀ' : script.sample.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: EtColors.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            script.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${script.letters.length} letters · '
                            '${families.length} families',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: EtColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: EtColors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => FidelTrainerScreen(
                            state: state,
                            scriptCode: script.code,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.school_rounded),
                      label: Text(EtStrings.fidelTrainer),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ScriptBrowserScreen(
                            state: state,
                            scriptCode: script.code,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.grid_view_rounded),
                      label: Text(EtStrings.letterFamily),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                EtStrings.letterFamily,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                itemCount: families.length,
                itemBuilder: (ctx, i) {
                  final fam = families[i];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: EtColors.line),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              fam.head.glyph,
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fam.sample.length > 6
                                  ? fam.sample.substring(0, 6)
                                  : fam.sample,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: EtColors.muted,
                              ),
                            ),
                            Text(
                              '${fam.letters.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: EtColors.locked,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
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
                      color: EtColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: EtColors.green.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pets_rounded, color: EtColors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            EtStrings.topicPacks,
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PhrasebookScreen(state: state),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: EtColors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: EtColors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            color: EtColors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            EtStrings.phrasebook,
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
              const SizedBox(height: 8),
              if (families.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    final l = families.first.head;
                    if (l.hasAudio) {
                      AudioService.instance.play(l.audioUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(EtStrings.noAudioYet)));
                    }
                  },
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(EtStrings.playSound),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
