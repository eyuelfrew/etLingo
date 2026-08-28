import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/et_button.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';
import 'lesson_screen.dart';

class TeachingScreen extends StatefulWidget {
  final AppState state;
  final Lesson lesson;
  final Unit unit;

  const TeachingScreen({
    super.key,
    required this.state,
    required this.lesson,
    required this.unit,
  });

  @override
  State<TeachingScreen> createState() => _TeachingScreenState();
}

class _TeachingScreenState extends State<TeachingScreen> {
  late final PageController _pageController;
  int _page = 0;
  final Set<int> _seen = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<TeachItem> get _items => widget.lesson.teachItems;
  bool get _isLast => _page == _items.length - 1;

  void _next() {
    if (_isLast) {
      _startQuiz();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _startQuiz() {
    if (widget.lesson.questions.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => LessonScreen(
        state: widget.state,
        lesson: widget.lesson,
        unit: widget.unit,
      ),
    ));
  }

  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Leave lesson?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('You haven\'t finished learning these words yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep learning',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit',
                style: TextStyle(
                    color: EtColors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_rounded,
                    size: 58, color: EtColors.locked),
                const SizedBox(height: 16),
                const Text('No teach content yet',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  '"${widget.lesson.title}" has no words to learn yet.\nGoing straight to quiz!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EtColors.muted,
                      height: 1.4),
                ),
                const SizedBox(height: 22),
                EtButton(
                  'Start quiz',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _startQuiz,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmExit() && mounted) nav.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (i) => setState(() {
                    _page = i;
                    _seen.add(i);
                  }),
                  itemBuilder: (_, i) => _WordCard(
                    item: _items[i],
                    index: i,
                    total: _items.length,
                    unit: widget.unit,
                    state: widget.state,
                  ),
                ),
              ),
              _buildBottom(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (await _confirmExit() && mounted) {
                Navigator.of(context).pop();
              }
            },
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
                      widthFactor: (_seen.length) / _items.length,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.unit.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_page + 1}/${_items.length}',
              style: TextStyle(
                color: widget.unit.color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewPadding.bottom + 16,
        top: 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EtButton(
            _isLast ? 'Start Quiz 🎯' : 'Got it →',
            icon: _isLast ? Icons.quiz_rounded : Icons.check_circle_outline_rounded,
            style: _isLast ? EtStyle.gold : EtStyle.primary,
            onPressed: _next,
          ),
          const SizedBox(height: 8),
          Text(
            _isLast
                ? 'Ready to test what you learned?'
                : 'Swipe or tap to see the next word',
            style: TextStyle(
              color: EtColors.muted.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final TeachItem item;
  final int index;
  final int total;
  final Unit unit;
  final AppState state;

  const _WordCard({
    required this.item,
    required this.index,
    required this.total,
    required this.unit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unit.color.withValues(alpha: 0.12),
              border: Border.all(
                color: unit.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: unit.color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            item.target,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: EtColors.ink,
              height: 1.2,
            ),
          ),
          if (item.translit.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.translit,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: unit.color,
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: EtColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EtColors.line),
            ),
            child: Text(
              item.meaningFor(state.baseLanguage),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: EtColors.ink,
              ),
            ),
          ),
          if (item.audioUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => AudioService.instance.play(item.audioUrl),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unit.color.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: unit.color,
                  size: 26,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == index;
              final seen = i <= index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? unit.color
                      : seen
                          ? unit.color.withValues(alpha: 0.4)
                          : EtColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
