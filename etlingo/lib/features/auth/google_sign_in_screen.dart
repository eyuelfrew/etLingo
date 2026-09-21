import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../services/auth_service.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  bool _error = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthService>();
    try {
      setState(() {
        _error = false;
        _errorMsg = '';
      });
      await auth.signInWithGoogle();
      if (auth.isSignedIn && mounted) {
        Navigator.of(context).pushReplacementNamed('/pick');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacementNamed('/pick');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

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
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animCtrl,
                      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                    ),
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _animCtrl,
                        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: EtColors.blue,
                              border:
                                  Border.all(color: EtColors.yellow, width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      EtColors.yellow.withValues(alpha: 0.35),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.waving_hand_rounded,
                              color: EtColors.yellow,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                EtColors.yellow,
                                Color(0xFFFFE97A),
                                EtColors.yellow,
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
                            'የኢትዮጵያ ቋንቋዎችን ይማሩ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EtColors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: EtColors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: EtColors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMsg.isNotEmpty
                                    ? _errorMsg
                                    : 'Sign-in failed. Please try again.',
                                style: const TextStyle(
                                  color: EtColors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: auth.loading ? null : _signInWithGoogle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (auth.loading)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: EtColors.green,
                                ),
                              )
                            else ...[
                              const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: EtColors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            const Text(
                              'በ Google ይግቡ',
                              style: TextStyle(
                                color: EtColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: auth.loading ? null : _continueAsGuest,
                      child: const Text(
                        'ወይም እንደ እንግዳ ይቀጥሉ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
