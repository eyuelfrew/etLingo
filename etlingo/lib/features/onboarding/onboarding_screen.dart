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
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Rich, deep emerald — reads premium rather than flat flag-green.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF04150C), Color(0xFF0A3D1F), Color(0xFF051F10)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4),
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/signin'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [
                    _MapPage(),
                    _HeritagePage(),
                    _ProgressPage(),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: TibebBand(height: 20),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? EtColors.yellow
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54A), Color(0xFFF7C60A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: EtColors.yellow.withValues(alpha: 0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _page < 2 ? 'Continue' : 'Get Started',
                        style: const TextStyle(
                          color: Color(0xFF1A1408),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.2,
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

// ── Page 1 · The Land of Origins — Ethiopian map hero ─────────────────────────

/// Simplified Ethiopia boundary in raw lon/lat pairs, drawn clockwise.
/// Normalized at paint time so it scales to any screen.
const List<(double, double)> kEthiopiaBorder = [
  (36.5, 14.3), (37.6, 14.9), (38.5, 14.7), (39.1, 14.5), (40.0, 14.5),
  (40.9, 14.4), (41.8, 13.9), (42.4, 12.5), (42.0, 12.0), (42.6, 11.0),
  (43.3, 10.7), (44.0, 10.4), (45.5, 9.5), (46.9, 8.2), (48.0, 8.0),
  (46.6, 6.9), (45.0, 5.0), (43.0, 4.8), (41.9, 3.9), (40.8, 4.3),
  (39.5, 3.4), (38.0, 3.6), (36.9, 4.4), (36.0, 4.45), (35.5, 5.0),
  (34.7, 6.6), (33.2, 7.8), (33.0, 8.4), (34.1, 9.5), (34.3, 10.9),
  (35.1, 11.8), (35.6, 12.6), (36.1, 13.0),
];

class _MapPage extends StatelessWidget {
  const _MapPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'ኢትዮጵያ  ·  ETHIOPIA',
              style: TextStyle(
                color: EtColors.yellow,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 260,
            width: double.infinity,
            child: CustomPaint(painter: _EthiopiaMapPainter()),
          ),
          const SizedBox(height: 22),
          const Text(
            'The Land of Origins',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cradle of humankind. Home of the Blue Nile and more than '
            '80 languages spoken across these highlands.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _EthiopiaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = _geoBounds();
    Offset project(double lon, double lat) => Offset(
          ((lon - bounds.$1) / (bounds.$2 - bounds.$1)) * size.width,
          (1 - (lat - bounds.$3) / (bounds.$4 - bounds.$3)) * size.height,
        );

    final path = Path();
    for (var i = 0; i < kEthiopiaBorder.length; i++) {
      final p = project(kEthiopiaBorder[i].$1, kEthiopiaBorder[i].$2);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    // Soft outer glow.
    canvas.drawPath(
      path,
      Paint()
        ..color = EtColors.green.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
    // Land fill with a subtle vertical sheen.
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E9C4E).withValues(alpha: 0.85),
            const Color(0xFF0B5B29).withValues(alpha: 0.85),
          ],
        ).createShader(Offset.zero & size),
    );
    // Crisp border.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = EtColors.yellow.withValues(alpha: 0.9)
        ..strokeJoin = StrokeJoin.round,
    );

    // Addis Ababa marker.
    final addis = project(38.74, 9.03);
    canvas.drawCircle(addis, 9,
        Paint()..color = EtColors.yellow.withValues(alpha: 0.25));
    canvas.drawCircle(addis, 4, Paint()..color = EtColors.yellow);
    canvas.drawCircle(addis, 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF04150C));

    // Region dots for the featured languages.
    const cities = [(38.0, 11.6), (39.0, 8.5), (39.5, 13.5), (43.5, 9.0)];
    for (final (lon, lat) in cities) {
      canvas.drawCircle(project(lon, lat), 3,
          Paint()..color = Colors.white.withValues(alpha: 0.75));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

(double, double, double, double) _geoBounds() {
  var minLon = 999.0, maxLon = -999.0, minLat = 999.0, maxLat = -999.0;
  for (final (lon, lat) in kEthiopiaBorder) {
    if (lon < minLon) minLon = lon;
    if (lon > maxLon) maxLon = lon;
    if (lat < minLat) minLat = lat;
    if (lat > maxLat) maxLat = lat;
  }
  return (minLon, maxLon, minLat, maxLat);
}

// ── Page 2 · Birthplace of Coffee — languages & heritage ──────────────────────

class _HeritagePage extends StatelessWidget {
  const _HeritagePage();

  static const _langs = [
    ('አማርኛ', 'Amharic', 'Ethiopic'),
    ('Afaan Oromo', 'Oromo', 'Qubee'),
    ('ትግርኛ', 'Tigrinya', 'Ethiopic'),
    ('Af Soomaali', 'Somali', 'Latin'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4A21), Color(0xFF4E2B10)],
              ),
              border: Border.all(color: EtColors.yellow.withValues(alpha: 0.7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: EtColors.yellow.withValues(alpha: 0.18),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.local_cafe_rounded, color: Color(0xFFE8C08A), size: 42),
          ),
          const SizedBox(height: 22),
          const Text(
            'Birthplace of Coffee',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'From Kaldi\'s highland goats to the world\'s cup — every word '
            'you learn carries a story older than memory.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: _langs.map((l) => _LangCard(l)).toList(),
          ),
        ],
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  final (String, String, String) data;
  const _LangCard(this.data);

  @override
  Widget build(BuildContext context) {
    final (native, english, script) = data;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(native,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: EtColors.yellow,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 2),
          Text('$english · $script',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5)),
        ],
      ),
    );
  }
}

// ── Page 3 · Progress & habit building ────────────────────────────────────────

class _ProgressPage extends StatelessWidget {
  const _ProgressPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border:
                  Border.all(color: EtColors.yellow.withValues(alpha: 0.7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: EtColors.yellow.withValues(alpha: 0.18),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: EtColors.yellow, size: 44),
          ),
          const SizedBox(height: 22),
          const Text(
            'Small steps. Every day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Five minutes a lesson. Streaks that reward showing up. '
            'XP that turns practice into a habit you keep.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: _StatChip('13', 'months of sunshine')),
              const SizedBox(width: 10),
              Expanded(child: _StatChip('80+', 'languages spoken')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _StatChip('4', 'courses at launch')),
              const SizedBox(width: 10),
              Expanded(child: _StatChip('5 min', 'per quick lesson')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: EtColors.yellow,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.1)),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }
}
