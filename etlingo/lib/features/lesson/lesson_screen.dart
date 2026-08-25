import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/et_button.dart';
import '../../core/widgets/audio_speed_button.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import 'lesson_result_screen.dart';
import 'question_views.dart';enum _Feedback { none, correct, wrong }

class LessonScreen extends StatefulWidget {
  final AppState state;
  final Lesson lesson;
  final Unit unit;

  const LessonScreen({
    super.key,
    required this.state,
    required this.lesson,
    required this.unit,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _index = 0;
  int? _selected;
  _Feedback _feedback = _Feedback.none;
  int _mistakes = 0;

  late final List<Question> _questions;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _questions = widget.lesson.questions.map((q) {
      if (q.kind == QuestionKind.match || q.options.length < 2) return q;
      final order = List<int>.generate(q.options.length, (i) => i)..shuffle(rng);
      return Question(
        kind: q.kind,
        prompt: q.prompt,
        subPrompt: q.subPrompt,
        hint: q.hint,
        options: [for (final i in order) q.options[i]],
        answerIndex: order.indexOf(q.answerIndex),
        matchLeft: q.matchLeft,
        matchRight: q.matchRight,
        audioUrl: q.audioUrl,
      );
    }).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  Question get _question => _questions[_index];
  bool get _revealed => _feedback != _Feedback.none;

  void _playPrompt() {
    final url = _question.audioUrl;
    if (url.isNotEmpty && mounted) AudioService.instance.play(url);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: _buildQuestion(),
                ),
              ),
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final total = widget.lesson.questions.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: _confirmExit,
            icon: const Icon(Icons.close_rounded, color: EtColors.muted),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(height: 14, color: EtColors.line),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      widthFactor: (_index + (_revealed ? 1 : 0)) / total,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [widget.unit.color, widget.unit.dark]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (_question.audioUrl.isNotEmpty) ...[
            IconButton(
              onPressed: _playPrompt,
              tooltip: 'Play audio',
              icon: const Icon(Icons.volume_up_rounded, color: EtColors.green),
            ),
            const AudioSpeedButton(),
            const SizedBox(width: 4),
          ],
          Icon(Icons.favorite_rounded,
              size: 20,
              color: widget.state.hearts > 0
                  ? EtColors.red
                  : EtColors.locked),
          const SizedBox(width: 4),
          Text('${widget.state.hearts}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    Widget content;
    switch (_question.kind) {
      case QuestionKind.mcq:
        content = McqView(
          question: _question,
          selected: _selected,
          revealed: _revealed,
          accent: widget.unit.color,
          onSelect: (i) => setState(() => _selected = i),
        );
      case QuestionKind.listen:
        content = ListenView(
          question: _question,
          selected: _selected,
          revealed: _revealed,
          accent: widget.unit.color,
          onSelect: (i) => setState(() => _selected = i),
        );
      case QuestionKind.fill:
        content = FillView(
          question: _question,
          selected: _selected,
          revealed: _revealed,
          accent: widget.unit.color,
          onSelect: (i) => setState(() => _selected = i),
        );
      case QuestionKind.match:
        content = MatchView(
          key: ValueKey('match_$_index'),
          question: _question,
          accent: widget.unit.color,
          onAllMatched: () {
            if (!mounted || _revealed) return;
            setState(() => _feedback = _Feedback.correct);
          },
          onWrongPair: () {
            if (!mounted || _revealed) return;
            setState(() {
              _mistakes++;
            });
            widget.state.loseHeart();
            _checkHearts();
          },
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_question.prompt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: _question.audioUrl.isEmpty ? null : _playPrompt,
              child: Text(
                _question.prompt,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: _question.audioUrl.isEmpty
                      ? EtColors.ink
                      : EtColors.greenDark,
                  decoration: _question.audioUrl.isEmpty
                      ? TextDecoration.none
                      : TextDecoration.underline,
                  decorationColor: EtColors.green.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        if (_question.kind == QuestionKind.match)
          content
        else
          Expanded(child: content),
      ],
    );
  }

  Widget _buildBottomArea() {
    if (_feedback != _Feedback.none) {
      return _FeedbackBar(
        correct: _feedback == _Feedback.correct,
        correctAnswer: _correctAnswerText(),
        onContinue: _next,
      );
    }

    final canCheck = _selected != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewPadding.bottom + 16,
        top: 6,
      ),
      child: EtButton(
        'Check',
        icon: Icons.check_circle_outline_rounded,
        style: EtStyle.primary,
        onPressed:
            canCheck ? () { _evaluate(); } : null,
      ),
    );
  }

  String _correctAnswerText() {
    switch (_question.kind) {
      case QuestionKind.mcq:
      case QuestionKind.fill:
      case QuestionKind.listen:
        return _question.options[_question.answerIndex].label;
      case QuestionKind.match:
        return '';
    }
  }

  void _evaluate() {
    final correct = _selected == _question.answerIndex;
    setState(() {
      _feedback = correct ? _Feedback.correct : _Feedback.wrong;
      if (!correct) _mistakes++;
    });
    if (!correct) {
      widget.state.loseHeart();
      _checkHearts();
    }
  }

  Future<void> _checkHearts() async {
    if (widget.state.hearts > 0) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Out of hearts!',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'You ran out of hearts. In this demo you get a free refill — keep learning!'),
        actions: [
          TextButton(
            onPressed: () {
              widget.state.refillHearts();
              Navigator.pop(ctx);
            },
            child: const Text('Refill ♥',
                style: TextStyle(
                    color: EtColors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_index == _questions.length - 1) {
      final mistakes = _mistakes;
      widget.state.completeLesson(widget.lesson, mistakes: mistakes);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => LessonResultScreen(
          state: widget.state,
          lesson: widget.lesson,
          unit: widget.unit,
          mistakes: mistakes,
        ),
      ));
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _feedback = _Feedback.none;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Leave lesson?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Progress in this lesson will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep learning',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit',
                style:
                    TextStyle(color: EtColors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _FeedbackBar extends StatelessWidget {
  final bool correct;
  final String correctAnswer;
  final VoidCallback onContinue;

  const _FeedbackBar({
    required this.correct,
    required this.correctAnswer,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bg = correct ? EtColors.green : EtColors.red;
    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Container(
        color: bg,
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewPadding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    correct
                        ? Icons.emoji_events_rounded
                        : Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correct ? 'ጎበዝ! Nicely done!' : 'Not quite...',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800),
                      ),
                      if (!correct && correctAnswer.isNotEmpty)
                        Text(
                          'Correct answer: $correctAnswer',
                          style: const TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            EtButton(
              'Continue',
              style: correct ? EtStyle.gold : EtStyle.danger,
              expanded: false,
              height: 48,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
