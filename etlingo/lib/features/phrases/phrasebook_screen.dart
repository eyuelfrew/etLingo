import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';

/// Phrasebook for the current course language (with audio when available).
class PhrasebookScreen extends StatefulWidget {
  final AppState state;
  const PhrasebookScreen({super.key, required this.state});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  List<Phrase> _phrases = const [];
  bool _loading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await widget.state.loadPhrases();
    if (!mounted) return;
    setState(() {
      _phrases = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _filter.trim().toLowerCase();
    final list = q.isEmpty
        ? _phrases
        : _phrases
            .where((p) =>
                p.target.toLowerCase().contains(q) ||
                p.meaning.toLowerCase().contains(q) ||
                p.translit.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.phrasebook),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: EtStrings.phrasebook,
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (list.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  EtStrings.emptyPhrasebook,
                  style: const TextStyle(color: EtColors.muted),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final p = list[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: EtColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EtColors.line),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        p.target,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        [
                          if (p.translit.isNotEmpty) p.translit,
                          p.meaning,
                          if (p.category.isNotEmpty) p.category,
                        ].join(' · '),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: EtColors.muted),
                      ),
                      trailing: p.audioUrl.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.volume_up_rounded,
                                  color: EtColors.blue),
                              onPressed: () =>
                                  AudioService.instance.play(p.audioUrl),
                            )
                          : null,
                      onTap: p.audioUrl.isNotEmpty
                          ? () => AudioService.instance.play(p.audioUrl)
                          : null,
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
