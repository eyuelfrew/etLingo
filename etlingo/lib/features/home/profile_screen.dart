import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/et_button.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../notifications/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppState state;
  const ProfileScreen({super.key, required this.state});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().refreshProfile();
    });
  }

  String _initial(AuthService auth) {
    final name = auth.displayName?.trim();
    if (name == null || name.isEmpty) return 'ሰ';
    return name.characters.first.toUpperCase();
  }

  Future<void> _editName(AuthService auth) async {
    final controller = TextEditingController(text: auth.displayName ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EtColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Your name',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'How should we call you?',
            filled: true,
            fillColor: EtColors.paper,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: EtColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: EtColors.green, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save',
                style: TextStyle(
                    color: EtColors.green, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await auth.updateDisplayName(controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Name updated ✓')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: EtColors.red,
          content: Text(
              'Could not save: ${e.toString().replaceFirst('Exception: ', '')}'),
        ));
      }
    }
  }

  Future<void> _confirmSignOut(AuthService auth) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Sign out?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Your progress is saved on the server and will be here when you return.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out',
                style: TextStyle(
                    color: EtColors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      await auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signin', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final auth = context.watch<AuthService>();
    final lang = state.language;
    final lessonsDone = state.completedLessons.length;
    final totalLessons = lang.totalLessons;

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EtColors.card,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: EtColors.line, width: 1.4),
                boxShadow: EtShadows.soft,
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [EtColors.green, EtColors.yellow, EtColors.red]),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: EtColors.paper,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initial(auth),
                            style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: lang.dark),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: auth.isSignedIn ? () => _editName(auth) : null,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: EtColors.blue,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: auth.isSignedIn ? () => _editName(auth) : null,
                    child: Text(
                      auth.isSignedIn
                          ? (auth.displayName ?? 'Learner')
                          : 'Guest Learner',
                      style: const TextStyle(
                          fontSize: 17.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    auth.isSignedIn
                        ? (auth.email ?? 'Google account')
                        : 'Sign in to save your progress',
                    style: const TextStyle(
                        color: EtColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _GoalRing(progress: state.goalProgress, xpToday: state.xpToday),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Day streak',
                    value: '${state.streak}',
                    color: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bolt_rounded,
                    label: 'Total XP',
                    value: '${state.xp}',
                    color: EtColors.yellowDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.school_rounded,
                    label: 'Lessons',
                    value: '$lessonsDone/$totalLessons',
                    color: EtColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events_rounded,
                    label: 'League',
                    value: 'Gold',
                    color: EtColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: const TibebBand(height: 14)),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Achievements',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              ),
            ),
            SizedBox(
              height: 118,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Badge(
                    icon: Icons.local_fire_department_rounded,
                    title: 'On Fire',
                    desc: '7-day streak',
                    unlocked: state.streak >= 7,
                  ),
                  _Badge(
                    icon: Icons.coffee_rounded,
                    title: 'Buna Master',
                    desc: 'Finish Coffee unit',
                    unlocked: lang.units.length > 1 &&
                        lang.units[1].lessons.isNotEmpty &&
                        state.completedLessons
                            .contains(lang.units[1].lessons.last.id),
                  ),
                  _Badge(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Perfectionist',
                    desc: 'Lesson with 0 mistakes',
                    unlocked: state.xp >= 15 && lessonsDone > 0,
                  ),
                  _Badge(
                    icon: Icons.public_rounded,
                    title: 'Polyglot',
                    desc: 'Learn 2+ languages',
                    unlocked: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            EtButton(
              'Notifications',
              icon: Icons.notifications_rounded,
              style: EtStyle.gold,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen()),
              ),
            ),
            const SizedBox(height: 10),
            if (auth.isSignedIn)
              EtButton(
                'Sign out',
                icon: Icons.logout_rounded,
                style: EtStyle.danger,
                onPressed: () => _confirmSignOut(auth),
              )
            else
              EtButton(
                'Sign in with Google',
                icon: Icons.login_rounded,
                onPressed: () =>
                    Navigator.of(context).pushNamed('/signin'),
              ),
            const SizedBox(height: 10),
            EtButton(
              'Switch course',
              icon: Icons.swap_horiz_rounded,
              style: EtStyle.info,
              onPressed: () => Navigator.of(context).pushReplacementNamed('/pick'),
            ),
            const SizedBox(height: 10),
            EtButton(
              'Reset demo progress',
              style: EtStyle.neutral,
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                  title: const Text('Reset everything?',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  content: const Text(
                      'All XP and completed lessons in this demo will be cleared.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        state.resetProgress();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset',
                          style: TextStyle(
                              color: EtColors.red,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'ኢትLang demo v1.0 — made with ♥ for Ethiopia',
                style: TextStyle(
                    fontSize: 11.5, color: EtColors.muted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  final double progress;
  final int xpToday;
  const _GoalRing({required this.progress, required this.xpToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EtColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EtColors.line, width: 1.4),
        boxShadow: EtShadows.soft,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _RingPainter(progress),
              child: Center(
                child: Text('${(progress * 100).round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily goal',
                    style:
                        TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$xpToday of ${AppState.dailyGoal} XP earned today',
                    style: const TextStyle(
                        color: EtColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.35)),
                const SizedBox(height: 6),
                Text(progress >= 1 ? 'Goal smashed! ጎበዝ!' : 'Keep going! 💪',
                    style: const TextStyle(
                        color: EtColors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..color = EtColors.line.withValues(alpha: 0.5),
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -3.14159 / 2,
          endAngle: 3.14159 * 1.5,
          colors: [EtColors.green, EtColors.yellow],
          transform: GradientRotation(-3.14159 / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EtColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EtColors.line, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: EtColors.muted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool unlocked;

  const _Badge({
    required this.icon,
    required this.title,
    required this.desc,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? EtColors.yellow.withValues(alpha: 0.15) : EtColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? EtColors.yellowDark : EtColors.line,
          width: 1.4,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 30,
              color: unlocked ? EtColors.yellowDark : EtColors.locked),
          const SizedBox(height: 6),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: unlocked ? EtColors.ink : EtColors.locked)),
          Text(desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? EtColors.muted : EtColors.locked)),
        ],
      ),
    );
  }
}
