import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/audio_speed_button.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import '../pronounce/pronounce_screen.dart';

class PhrasebookScreen extends StatefulWidget {
  final AppState state;
  const PhrasebookScreen({super.key, required this.state});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final lang = widget.state.language;
    final filtered = lang.phrases.where((p) {
      if (_query.isEmpty) return true;
      return p.meaning.toLowerCase().contains(_query) ||
          p.translit.toLowerCase().contains(_query) ||
          p.target.contains(_query);
    }).toList();

    final rows = <Object>[];
    final seenCategories = <String>{};
    for (final p in filtered) {
      if (!seenCategories.contains(p.category)) {
        seenCategories.add(p.category);
        rows.add(p.category);
      }
      rows.add(p);
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('የቃላት መጠቈለያ',
                    style:
                        TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('ቃላት በኪስዎ ውስጥ · ${lang.nativeName}',
                    style: const TextStyle(
                        color: EtColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text('ከመምህሩ ጋር በድጋሚ ይናገሩ · 🎙',
                          style: TextStyle(
                              color: EtColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5)),
                    ),
                    const AudioSpeedButton(),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'ቃላት ፈልግ…',
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: EtColors.muted),
                    filled: true,
                    fillColor: EtColors.card,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          const BorderSide(color: EtColors.line, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: lang.color, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const TibebBand(height: 14, opacity: 0.8),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final row = rows[i];
                if (row is String) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: lang.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(row.toUpperCase(),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: lang.dark)),
                      ],
                    ),
                  );
                }
                final phrase = row as Phrase;
                return _PhraseTile(phrase: phrase, accent: lang.color);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhraseTile extends StatelessWidget {
  final Phrase phrase;
  final Color accent;
  const _PhraseTile({required this.phrase, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: EtColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EtColors.line, width: 1.3),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phrase.target,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700)),
                Text(phrase.translit,
                    style: const TextStyle(
                        fontSize: 11,
                        color: EtColors.muted,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(phrase.meaning,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: accent.computeLuminance() > 0.6
                        ? EtColors.greenDark
                        : accent)),
          ),
          if (phrase.audioUrl.isNotEmpty) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => AudioService.instance.play(phrase.audioUrl),
              icon: const Icon(Icons.volume_up_rounded,
                  size: 20, color: EtColors.green),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Practice pronouncing',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PronounceScreen(
                  phrase: phrase,
                  accent: accent,
                ),
              )),
              icon: Icon(Icons.mic_none_rounded, size: 20, color: accent.computeLuminance() > 0.6 ? EtColors.greenDark : accent),
            ),
          ],
        ],
      ),
    );
  }
}
