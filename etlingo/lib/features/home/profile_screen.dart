import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/et_icons.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/notification_settings_screen.dart';

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
      widget.state.loadBaseLanguages();
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
            'እድገትዎ በሰርቨሩ ላይ ይቀመጣል — በተመለሱ ጊዜ እዚሁ ይገኛል።'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ቀይር')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ውጣ',
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

  void _showBaseLanguagePicker(BuildContext context, AppState state) {
    final baseLangs = state.baseLanguages;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: EtColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(EtStrings.baseLanguage,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                EtStrings.baseLanguage == 'Base language'
                    ? 'Prompts and meanings appear in this language'
                    : 'ትርጉሞች በዚህ ቋንቋ ይታያሉ',
                style: const TextStyle(
                    fontSize: 13, color: EtColors.muted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ...baseLangs.map((l) {
                final isSelected = state.baseLanguage == l.code;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      state.chooseBaseLanguage(l.code);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${EtStrings.baseSetTo} ${l.name}')),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? EtColors.green.withValues(alpha: 0.08)
                            : EtColors.paper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? EtColors.green : EtColors.line,
                          width: isSelected ? 2 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.nativeName,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? EtColors.greenDark
                                            : EtColors.ink)),
                                const SizedBox(height: 2),
                                Text(l.name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: EtColors.muted,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: EtColors.green, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppLanguagePicker(BuildContext context, AppState state) {
    const options = [
      {'code': 'en', 'label': 'English', 'native': 'English'},
      {'code': 'am', 'label': 'Amharic', 'native': 'አማርኛ'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: EtColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(EtStrings.appLanguage,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              EtStrings.appLanguageHint,
              style: const TextStyle(
                  fontSize: 13, color: EtColors.muted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ...options.map((l) {
              final isSelected = state.appLanguage == l['code'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () async {
                    await state.chooseAppLanguage(l['code']!);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${EtStrings.appLangSetTo} ${l['native']}')),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? EtColors.blue.withValues(alpha: 0.08)
                          : EtColors.paper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? EtColors.blue : EtColors.line,
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l['native']!,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? EtColors.blueDark
                                          : EtColors.ink)),
                              const SizedBox(height: 2),
                              Text(l['label']!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: EtColors.muted,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: EtColors.blue, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final auth = context.watch<AuthService>();
    final lang = state.language;
    final lessonsDone = state.completedLessons.length;
    final totalLessons = lang.totalLessons;
    final courseColors = lang.id.isEmpty
        ? const [EtColors.greenMid, EtColors.greenDeep]
        : [lang.color, lang.dark];

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // ── Identity hero ─────────────────────────────────────────────
            EtHeroCard(
              colors: courseColors,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [EtColors.green, EtColors.yellow, EtColors.red],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3.5),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initial(auth),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: courseColors.last,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: auth.isSignedIn ? () => _editName(auth) : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: EtColors.yellow, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                size: 15, color: EtColors.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    auth.isSignedIn
                        ? (auth.displayName ?? EtStrings.guestLearner)
                        : EtStrings.guestLearner,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.isSignedIn
                        ? (auth.email ?? 'Google')
                        : EtStrings.signInToSave,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Course chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(lang.icon, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          lang.id.isEmpty
                              ? EtStrings.brand
                              : '${lang.nativeName} · ${lang.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Goal ring + colored stats ────────────────────────────────
            _GoalRing(
              progress: state.goalProgress,
              xpToday: state.xpToday,
              accent: lang.id.isEmpty ? EtColors.green : lang.color,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    label: EtStrings.dayStreak,
                    value: '${state.streak}',
                    color: EtIcons.streak,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bolt_rounded,
                    label: EtStrings.xp,
                    value: '${state.xp}',
                    color: EtIcons.xp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.favorite_rounded,
                    label: EtStrings.hearts,
                    value: '${state.hearts}',
                    color: EtIcons.hearts,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.school_rounded,
                    label: EtStrings.lessonsDone,
                    value: '$lessonsDone/$totalLessons',
                    color: EtIcons.lessons,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatCard(
              icon: Icons.menu_book_rounded,
              label: EtStrings.phrasebook,
              value: '${lang.phrases.length}',
              color: EtColors.yellowDark,
            ),

            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                EtStrings.settingsTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: EtColors.muted,
                  letterSpacing: 0.4,
                ),
              ),
            ),

            // ── Settings rows (colorful, not flat buttons) ───────────────
            EtSettingsRow(
              icon: Icons.language_rounded,
              color: EtIcons.appLang,
              title: EtStrings.appLanguage,
              subtitle: state.appLanguage == 'am' ? 'አማርኛ' : 'English',
              onTap: () => _showAppLanguagePicker(context, state),
            ),
            const SizedBox(height: 8),
            EtSettingsRow(
              icon: Icons.translate_rounded,
              color: EtIcons.baseLang,
              title: EtStrings.baseLanguage,
              subtitle: state.baseLanguages
                      .where((b) => b.code == state.baseLanguage)
                      .map((b) => b.nativeName)
                      .followedBy([state.baseLanguage]).first,
              onTap: () => _showBaseLanguagePicker(context, state),
            ),
            const SizedBox(height: 8),
            EtSettingsRow(
              icon: Icons.auto_stories_rounded,
              color: EtColors.green,
              title: EtStrings.switchCourse,
              subtitle: lang.id.isEmpty ? '—' : lang.nativeName,
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed('/pick'),
            ),
            const SizedBox(height: 8),
            EtSettingsRow(
              icon: Icons.notifications_active_rounded,
              color: EtIcons.notify,
              title: EtStrings.notifications,
              subtitle: EtStrings.profile,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen()),
              ),
            ),
            const SizedBox(height: 8),
            EtSettingsRow(
              icon: Icons.tune_rounded,
              color: EtIcons.notifySettings,
              title: EtStrings.notificationSettings,
              subtitle: EtStrings.appLanguageHint,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
            const SizedBox(height: 8),
            EtSettingsRow(
              icon: auth.isSignedIn
                  ? Icons.logout_rounded
                  : Icons.login_rounded,
              color: EtIcons.signOut,
              title: auth.isSignedIn ? EtStrings.signOut : EtStrings.signInGoogle,
              onTap: auth.isSignedIn
                  ? () => _confirmSignOut(auth)
                  : () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/signin', (_) => false),
            ),

            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const TibebBand(height: 16, opacity: 0.85),
            ),
            const SizedBox(height: 16),

            // ── Achievements ─────────────────────────────────────────────
            Text(
              EtStrings.achievements,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Badge(
                    icon: Icons.local_fire_department_rounded,
                    color: EtIcons.streak,
                    title: 'On Fire',
                    desc: '7-day streak',
                    unlocked: state.streak >= 7,
                  ),
                  _Badge(
                    icon: Icons.coffee_rounded,
                    color: EtColors.yellowDark,
                    title: 'Buna Master',
                    desc: 'Finish Coffee unit',
                    unlocked: lang.units.length > 1 &&
                        lang.units[1].lessons.isNotEmpty &&
                        state.completedLessons
                            .contains(lang.units[1].lessons.last.id),
                  ),
                  _Badge(
                    icon: Icons.workspace_premium_rounded,
                    color: EtColors.gold,
                    title: 'Perfectionist',
                    desc: 'Lesson with 0 mistakes',
                    unlocked: state.xp >= 15 && lessonsDone > 0,
                  ),
                  _Badge(
                    icon: Icons.public_rounded,
                    color: EtIcons.you,
                    title: 'Polyglot',
                    desc: 'Learn 2+ languages',
                    unlocked: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.completedLessons.isNotEmpty || state.xp > 0)
              EtSettingsRow(
                icon: Icons.restart_alt_rounded,
                color: EtColors.muted,
                title: EtStrings.resetProgress,
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: EtColors.card,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      title: Text(EtStrings.resetProgress),
                      content: Text(EtStrings.progressSaved),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(EtStrings.cancel)),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(EtStrings.resetProgress,
                              style: const TextStyle(color: EtColors.red)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await state.resetProgress();
                },
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
  final Color accent;
  const _GoalRing({
    required this.progress,
    required this.xpToday,
    this.accent = EtColors.green,
  });

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
            width: 84,
            height: 84,
            child: CustomPaint(
              painter: _RingPainter(progress, accent: accent),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(progress * 100).round()}%',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: accent.computeLuminance() > 0.6
                                ? EtColors.ink
                                : accent)),
                    Text('${xpToday}XP',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: EtColors.muted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(EtStrings.dailyGoal,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    '$xpToday / ${AppState.dailyGoal} XP · ${EtStrings.xpEarned}',
                    style: const TextStyle(
                        color: EtColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.35)),
                const SizedBox(height: 6),
                Text(
                    progress >= 1
                        ? '${EtStrings.goalComplete} ጎበዝ!'
                        : EtStrings.keepGoing,
                    style: TextStyle(
                        color: accent,
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
  final Color accent;
  _RingPainter(this.progress, {this.accent = EtColors.green});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = EtColors.line.withValues(alpha: 0.45),
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -3.14159 / 2,
          endAngle: 3.14159 * 1.5,
          colors: [accent, EtColors.yellow],
          transform: const GradientRotation(-3.14159 / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.accent != accent;
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color.computeLuminance() > 0.7
                    ? EtColors.ink
                    : color,
              )),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: EtColors.muted,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final bool unlocked;

  const _Badge({
    required this.icon,
    required this.color,
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
        color: unlocked
            ? color.withValues(alpha: 0.12)
            : EtColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? color.withValues(alpha: 0.45) : EtColors.line,
          width: 1.4,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 30, color: unlocked ? color : EtColors.locked),
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
