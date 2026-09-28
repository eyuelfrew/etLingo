import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import 'culture_phase4_screens.dart';
import 'culture_screen.dart';
import 'culture_widgets.dart';

/// Cards-only culture track (Phase 2). Swipe through cards, learn vocab, earn XP.
class CultureCardReader extends StatefulWidget {
  final AppState state;
  final CultureChapter chapter;
  final List<CultureCardModel> cards;

  const CultureCardReader({
    super.key,
    required this.state,
    required this.chapter,
    required this.cards,
  });

  @override
  State<CultureCardReader> createState() => _CultureCardReaderState();
}

class _CultureCardReaderState extends State<CultureCardReader> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _last => _page >= widget.cards.length - 1;

  Future<void> _completeCurrent() async {
    final card = widget.cards[_page];
    await widget.state.completeCultureCard(card);
    if (!mounted) return;
    if (_last) {
      Navigator.of(context).pop(true);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final cards = widget.cards;
    final base = widget.state.baseLanguage;
    if (cards.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(chapter.title)),
        body: Center(child: Text(EtStrings.noContentYet)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(chapter.title, style: const TextStyle(fontSize: 16)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_page + 1}/${cards.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: EtColors.muted),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_page + 1) / cards.length,
              backgroundColor: EtColors.line,
              color: chapter.accent,
              minHeight: 4,
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: cards.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _CardBody(
                  card: cards[i],
                  accent: chapter.accent,
                  baseLang: base,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: chapter.accent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _completeCurrent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _last ? EtStrings.keepGoing : EtStrings.gotIt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final CultureCardModel card;
  final Color accent;
  final String baseLang;
  const _CardBody({
    required this.card,
    required this.accent,
    this.baseLang = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final title = card.titleFor(baseLang);
    final body = card.bodyFor(baseLang);
    final steps = card.stepsFor(baseLang);
    final lyrics = card.lyricsFor(baseLang);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              card.kindLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (card.translit.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              card.translit,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.15)),
            ),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              EtStrings.stepsLabel,
              style: TextStyle(fontWeight: FontWeight.w800, color: accent),
            ),
            const SizedBox(height: 10),
            ...steps.asMap().entries.map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EtColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: accent),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5)),
                              if (e.value.body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  e.value.body,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: EtColors.muted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (card.kind == 'music')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (lyrics.isEmpty)
                    FolkSongCard(
                      title: EtStrings.musicFolk,
                      lyricLines: body,
                      translit: card.translit,
                      note: (card.meta['license'] ?? '').toString(),
                      accent: accent,
                      audioUrl: card.audioUrl.isEmpty ? null : card.audioUrl,
                    )
                  else
                    ...lyrics.map(
                      (l) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FolkSongCard(
                          title: l.line,
                          lyricLines: l.line,
                          translit: l.translit,
                          note: l.note,
                          accent: accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (card.audioUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: IconButton.filledTonal(
                onPressed: () => AudioService.instance.play(card.audioUrl),
                icon: const Icon(Icons.volume_up_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  foregroundColor: accent,
                ),
              ),
            ),
          ],
          if (card.vocab.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              EtStrings.vocabWords,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 10),
            ...card.vocab.map((v) => _VocabTile(
                  item: v,
                  accent: accent,
                  baseLang: baseLang,
                )),
          ],
          if (card.pdfUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(AudioService.resolve(card.pdfUrl));
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: Text(EtStrings.readOpenLesson),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ArShareCardScreen(
                    title: card.kindLabel,
                    target: title,
                    body: body,
                    translit: card.translit.isEmpty ? null : card.translit,
                  ),
                ));
              },
              icon: const Icon(Icons.share_rounded),
              label: Text(EtStrings.arShare),
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabTile extends StatefulWidget {
  final TeachItem item;
  final Color accent;
  final String baseLang;
  const _VocabTile({
    required this.item,
    required this.accent,
    required this.baseLang,
  });

  @override
  State<_VocabTile> createState() => _VocabTileState();
}

class _VocabTileState extends State<_VocabTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    final hasAudio = widget.item.audioUrl.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: EtColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.target,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (hasAudio)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          AudioService.instance.play(widget.item.audioUrl),
                      icon: Icon(Icons.volume_up_rounded, color: a, size: 18),
                    ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: EtColors.locked,
                  ),
                ],
              ),
              if (_open)
                Text(
                  widget.item.meaningFor(widget.baseLang),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
