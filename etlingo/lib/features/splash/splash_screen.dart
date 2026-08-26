import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;

      final auth = context.read<AuthService>();
      final state = context.read<AppState>();

      // Cold-start restore of the previously chosen course + background syncs.
      final restored = await state.restoreSavedLanguage();
      if (!mounted) return;
      unawaited(state.loadLanguages());
      unawaited(auth.refreshProfile());
      // Re-attach this device to push (persisted sessions) and keep tokens fresh.
      auth.listenForTokenRefresh();
      unawaited(auth.registerPushToken());

      Navigator.of(context)
          .pushReplacementNamed(restored ? '/home' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF04150C), Color(0xFF0A3D1F), Color(0xFF051F10)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
                    ),
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _Emblem(),
                          const SizedBox(height: 28),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                EtColors.yellow,
                                Color(0xFFFFE97A),
                                EtColors.yellow
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'ኢትLang',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Learn the languages of Ethiopia',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TibebBand(height: 22),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 26, top: 14),
                child: Text(
                  'Amharic · Afaan Oromo · Tigrinya · Somali',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
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

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: CustomPaint(painter: _StarPainter()),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.30;
    final paint = Paint()
      ..color = EtColors.yellow
      ..style = PaintingStyle.fill;

    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerAngle = -math.pi / 2 + i * 2 * math.pi / 5;
      final innerAngle = outerAngle + math.pi / 5;
      if (i == 0) {
        path.moveTo(center.dx + radius * math.cos(outerAngle),
            center.dy + radius * math.sin(outerAngle));
      } else {
        path.lineTo(center.dx + radius * math.cos(outerAngle),
            center.dy + radius * math.sin(outerAngle));
      }
      path.lineTo(center.dx + radius * 0.45 * math.cos(innerAngle),
          center.dy + radius * 0.45 * math.sin(innerAngle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
