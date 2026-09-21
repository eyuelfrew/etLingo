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
  /// Unit chapter vocab + lesson extras. When null, uses lesson.teachItems only.
  final List<TeachItem>? teachItemsOverride;

  const TeachingScreen({
    super.key,
    required this.state,
    required this.lesson,
    required this.unit,
    this.teachItemsOverride,
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

  List<TeachItem> get _items =>
      widget.teachItemsOverride ??
      widget.unit.teachItemsFor(widget.lesson);
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
                const Text('ትምህርቱ አልተዘጋጀም',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  '"${widget.lesson.title}" ቃላት የሉትም።\nወደ ፈተና እየሄድን ነው!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EtColors.muted,
                      height: 1.4),
                ),
                const SizedBox(height: 22),
                EtButton(
                  'ፈተና ጀምር',
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
            _isLast ? 'ፈተና ጀምር 🎯' : 'ተረድቻለሁ →',
            icon: _isLast ? Icons.quiz_rounded : Icons.check_circle_outline_rounded,
            style: _isLast ? EtStyle.gold : EtStyle.primary,
            onPressed: _next,
          ),
          const SizedBox(height: 8),
          Text(
            _isLast
                ? 'የተማሩትን ለመፈተሽ ዝግጁ ነዎት?'
                : 'ቀጥሎ ለማየት ይጎትቱ',
            style: TextStyle(
              color: EtColors.muted.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 340),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  unit.color.withValues(alpha: 0.10),
                  EtColors.card,
                  unit.dark.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: unit.color.withValues(alpha: 0.18), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: unit.dark.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unit.color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: unit.color.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: unit.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  item.target,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: EtColors.ink,
                    height: 1.15,
                  ),
                ),
                if (item.translit.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.translit,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: unit.color,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => AudioService.instance.play(item.audioUrl),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [unit.color, unit.dark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: unit.dark.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
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
          ),
        ],
      ),
    );
  }
}
