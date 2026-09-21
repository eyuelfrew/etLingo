import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';

class ListenView extends StatelessWidget {
  final Question question;
  final int? selected;
  final bool revealed;
  final Color accent;
  final ValueChanged<int> onSelect;

  const ListenView({
    super.key,
    required this.question,
    required this.selected,
    required this.revealed,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => AudioService.instance.play(question.audioUrl),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 26),
            decoration: BoxDecoration(
              color: EtColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: EtColors.line, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.75)]),
                    shape: BoxShape.circle,
                    boxShadow: EtShadows.lift(accent),
                  ),
                  child:
                      const Icon(Icons.volume_up_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(EtStrings.tapToListen,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: EtColors.muted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(child: _optionGrid()),
      ],
    );
  }

  Widget _optionGrid() => GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        itemCount: question.options.length,
        itemBuilder: (context, i) {
          final isPicked = selected == i;
          final isAnswer = i == question.answerIndex;
          Color border = EtColors.line;
          Color fill = EtColors.card;
          var width = 1.5;
          if (revealed && isAnswer) {
            border = EtColors.green;
            fill = EtColors.green.withValues(alpha: 0.10);
            width = 2.5;
          } else if (revealed && isPicked && !isAnswer) {
            border = EtColors.red;
            fill = EtColors.red.withValues(alpha: 0.08);
            width = 2.5;
          } else if (!revealed && isPicked) {
            border = accent;
            fill = accent.withValues(alpha: 0.08);
            width = 2.5;
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: width),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: revealed ? null : () => onSelect(i),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      question.options[i].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isPicked || (revealed && isAnswer)
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: revealed && isAnswer
                            ? EtColors.greenDark
                            : EtColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class McqView extends StatelessWidget {
  final Question question;
  final int? selected;
  final bool revealed;
  final Color accent;
  final ValueChanged<int> onSelect;
  final String baseLanguage;

  const McqView({
    super.key,
    required this.question,
    required this.selected,
    required this.revealed,
    required this.accent,
    required this.onSelect,
    this.baseLanguage = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final localizedSubPrompt = question.subPromptFor(baseLanguage);
    final localizedHint = question.hintFor(baseLanguage);
    return Column(
      children: [
        if (localizedSubPrompt.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.08),
                  EtColors.card,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: accent.withValues(alpha: 0.2), width: 1.5),
              boxShadow: EtShadows.soft,
            ),
            child: Column(
              children: [
                Text(
                  localizedSubPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w800, height: 1.15),
                ),
                if (localizedHint.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(localizedHint,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: accent.computeLuminance() > 0.6
                                ? EtColors.greenDark
                                : accent,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: question.options.length,
            itemBuilder: (context, i) {
              final isPicked = selected == i;
              final isAnswer = i == question.answerIndex;
              Color border = EtColors.line;
              Color fill = EtColors.card;
              var width = 1.5;
              if (revealed && isAnswer) {
                border = EtColors.green;
                fill = EtColors.green.withValues(alpha: 0.10);
                width = 2.5;
              } else if (revealed && isPicked && !isAnswer) {
                border = EtColors.red;
                fill = EtColors.red.withValues(alpha: 0.08);
                width = 2.5;
              } else if (!revealed && isPicked) {
                border = accent;
                fill = accent.withValues(alpha: 0.08);
                width = 2.5;
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border, width: width),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: revealed ? null : () => onSelect(i),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        question.options[i].label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isPicked || (revealed && isAnswer)
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                          color: revealed && isAnswer
                              ? EtColors.greenDark
                              : EtColors.ink,
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FillView extends StatelessWidget {
  final Question question;
  final int? selected;
  final bool revealed;
  final Color accent;
  final ValueChanged<int> onSelect;
  final String baseLanguage;

  const FillView({
    super.key,
    required this.question,
    required this.selected,
    required this.revealed,
    required this.accent,
    required this.onSelect,
    this.baseLanguage = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final localizedSubPrompt = question.subPromptFor(baseLanguage);
    final parts = localizedSubPrompt.split('___');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: EtColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: EtColors.line, width: 1.5),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 10,
            children: [
              for (var p = 0; p < parts.length; p++) ...[
                if (parts[p].isNotEmpty)
                  Text(parts[p].trim(),
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w600)),
                if (p < parts.length - 1)
                  Container(
                    constraints: const BoxConstraints(minWidth: 90),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected != null
                          ? accent.withValues(alpha: 0.10)
                          : EtColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected != null
                            ? accent
                            : EtColors.locked.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      selected != null
                          ? question.options[selected!].label
                          : '?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: selected != null
                            ? accent.computeLuminance() > 0.7
                                ? EtColors.greenDark
                                : accent
                            : EtColors.locked,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: question.options.length,
            itemBuilder: (context, i) {
              final isPicked = selected == i;
              final isAnswer = i == question.answerIndex;
              Color border = EtColors.line;
              Color fill = EtColors.card;
              var width = 1.5;
              if (revealed && isAnswer) {
                border = EtColors.green;
                fill = EtColors.green.withValues(alpha: 0.10);
                width = 2.5;
              } else if (revealed && isPicked && !isAnswer) {
                border = EtColors.red;
                fill = EtColors.red.withValues(alpha: 0.08);
                width = 2.5;
              } else if (!revealed && isPicked) {
                border = accent;
                fill = accent.withValues(alpha: 0.08);
                width = 2.5;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: revealed ? null : () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border, width: width),
                    ),
                    child: Text(question.options[i].label,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: revealed && isAnswer
                                ? EtColors.greenDark
                                : EtColors.ink)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MatchView extends StatefulWidget {
  final Question question;
  final Color accent;
  final VoidCallback onAllMatched;
  final VoidCallback onWrongPair;

  const MatchView({
    super.key,
    required this.question,
    required this.accent,
    required this.onAllMatched,
    required this.onWrongPair,
  });

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  late final List<int> _rightOrder;
  int? _selectedLeft;
  final Set<int> _matchedLeft = {};
  final Set<int> _matchedRight = {};
  int? _wrongLeft;
  int? _wrongRight;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.question.matchLeft.length * 31);
    _rightOrder =
        List.generate(widget.question.matchRight.length, (i) => i);
    _rightOrder.shuffle(rng);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _tapRight(int originalIndex) {
    if (_matchedRight.contains(originalIndex)) return;
    final left = _selectedLeft;
    if (left == null) return;

    if (left == originalIndex) {
      setState(() {
        _matchedLeft.add(left);
        _matchedRight.add(originalIndex);
        _selectedLeft = null;
      });
      if (_matchedLeft.length == widget.question.matchLeft.length) {
        Future.delayed(const Duration(milliseconds: 350), widget.onAllMatched);
      }
    } else {
      setState(() {
        _wrongLeft = left;
        _wrongRight = originalIndex;
      });
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 550), () {
        setState(() {
          _wrongLeft = null;
          _wrongRight = null;
          _selectedLeft = null;
        });
      });
      widget.onWrongPair();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.question.matchLeft.length; i++)
                  _tile(
                    text: widget.question.matchLeft[i],
                    state: _stateOf(i, true),
                    big: true,
                    onTap: () => setState(() =>
                        _selectedLeft = _matchedLeft.contains(i) ? null : i),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final originalIdx in _rightOrder)
                  _tile(
                    text: widget.question.matchRight[originalIdx],
                    state: _stateOf(originalIdx, false),
                    big: false,
                    onTap: () => _tapRight(originalIdx),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _TileState _stateOf(int index, bool leftSide) {
    final matched = leftSide
        ? _matchedLeft.contains(index)
        : _matchedRight.contains(index);
    if (matched) return _TileState.matched;
    final wrong =
        leftSide ? _wrongLeft == index : _wrongRight == index;
    if (wrong) return _TileState.wrong;
    if (leftSide && _selectedLeft == index) return _TileState.selected;
    return _TileState.idle;
  }

  Widget _tile({
    required String text,
    required _TileState state,
    required bool big,
    required VoidCallback onTap,
  }) {
    Color border = EtColors.line;
    Color fill = EtColors.card;
    Color textColor = EtColors.ink;
    var borderWidth = 1.5;

    switch (state) {
      case _TileState.selected:
        border = widget.accent;
        fill = widget.accent.withValues(alpha: 0.10);
        borderWidth = 2.5;
      case _TileState.matched:
        border = EtColors.green.withValues(alpha: 0.45);
        fill = EtColors.green.withValues(alpha: 0.07);
        textColor = EtColors.muted;
      case _TileState.wrong:
        border = EtColors.red;
        fill = EtColors.red.withValues(alpha: 0.10);
        textColor = EtColors.red;
        borderWidth = 2.5;
      case _TileState.idle:
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: big ? 15 : 11),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border, width: borderWidth),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: state == _TileState.matched ? null : onTap,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: big ? 15 : 12.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TileState { idle, selected, matched, wrong }
