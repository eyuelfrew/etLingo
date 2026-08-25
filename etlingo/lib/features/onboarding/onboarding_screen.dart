import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tibeb_band.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _page = 0;

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

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF05340F), EtColors.green, Color(0xFF032B10)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/signin'),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [
                    _OnboardPage(
                      icon: Icons.language_rounded,
                      title: 'Learn Ethiopian Languages',
                      subtitle:
                          'Master Amharic, Afaan Oromo, Tigrinya, and Somali through fun, interactive lessons.',
                    ),
                    _OnboardPage(
                      icon: Icons.school_rounded,
                      title: 'Interactive Lessons',
                      subtitle:
                          'Practice with quizzes, build vocab, and track your progress as you learn.',
                    ),
                    _OnboardPage(
                      icon: Icons.emoji_events_rounded,
                      title: 'Track Your Progress',
                      subtitle:
                          'Earn XP, keep streaks, and watch yourself become fluent over time.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TibebBand(height: 22),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = _page == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: active ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active
                          ? EtColors.yellow
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: EtColors.yellow,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFC99E00),
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _page < 2 ? 'Next' : 'Get Started',
                        style: const TextStyle(
                          color: EtColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EtColors.blue,
              border: Border.all(color: EtColors.yellow, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: EtColors.yellow.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: EtColors.yellow, size: 46),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
