import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';

/// Learner-facing notification settings. Each toggle maps 1:1 onto a backend
/// preference column, so the push pipeline can skip opted-out categories.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  AppNotificationPrefs? _prefs;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await context.read<AuthService>().fetchNotificationPrefs();
      if (!mounted) return;
      setState(() => _prefs = prefs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Optimistic update: flip immediately, roll back on save failure.
  Future<void> _update(AppNotificationPrefs next) async {
    final previous = _prefs!;
    setState(() { _prefs = next; _saving = true; _error = null; });
    try {
      final saved = await context.read<AuthService>().saveNotificationPrefs(next);
      if (!mounted) return;
      setState(() => _prefs = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _prefs = previous;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EtColors.paper,
      appBar: AppBar(
        backgroundColor: EtColors.green,
        foregroundColor: Colors.white,
        title: const Text('Notification settings',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EtColors.green))
          : (_error != null && _prefs == null)
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _masterSwitch(AppNotificationPrefs prefs) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: prefs.pushEnabled
            ? EtColors.green.withValues(alpha: 0.08)
            : EtColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: prefs.pushEnabled
              ? EtColors.green.withValues(alpha: 0.5)
              : EtColors.line,
          width: 1.3,
        ),
      ),
      child: SwitchListTile(
        activeThumbColor: Colors.white,
        activeTrackColor: EtColors.green,
        value: prefs.pushEnabled,
        onChanged: _saving ? null : (v) => _update(prefs.copyWith(pushEnabled: v)),
        title: const Text('Push notifications',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(
          prefs.pushEnabled
              ? 'Notifications appear in your system tray'
              : 'All device notifications are muted',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final prefs = _prefs!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _masterSwitch(prefs),
        const SizedBox(height: 20),
        if (!prefs.pushEnabled)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Turn on push notifications above to manage categories.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: EtColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          )
        else ...[
          _Group(header: 'Learning', icon: Icons.school_rounded, children: [
            _Toggle(
                label: 'Daily lesson reminders',
                desc: 'A nudge to keep your streak alive',
                value: prefs.lessonReminders,
                enabled: !_saving,
                onChanged: (v) => _update(prefs.copyWith(lessonReminders: v))),
            _Toggle(
                label: 'Streak milestones',
                desc: 'Celebrate 7, 30 and 100 day streaks',
                value: prefs.streakMilestones,
                enabled: !_saving,
                onChanged: (v) => _update(prefs.copyWith(streakMilestones: v))),
            _Toggle(
                label: 'Achievements',
                desc: 'Badges and level-ups you unlock',
                value: prefs.achievements,
                enabled: !_saving,
                onChanged: (v) => _update(prefs.copyWith(achievements: v))),
          ]),
          const SizedBox(height: 14),
          _Group(header: 'Updates', icon: Icons.system_update_rounded, children: [
            _Toggle(
                label: 'New lessons & languages',
                desc: 'When fresh content lands for you',
                value: prefs.newContent,
                enabled: !_saving,
                onChanged: (v) => _update(prefs.copyWith(newContent: v))),
            _Toggle(
                label: 'App updates',
                desc: 'Feature releases and improvements',
                value: prefs.appUpdates,
                enabled: !_saving,
                onChanged: (v) => _update(prefs.copyWith(appUpdates: v))),
            _Toggle(
                label: 'Tips of the day',
                desc: 'Language and culture nuggets',
                value: prefs.tips,
                enabled: !_saving,
                onChanged: (v) => _update(prefs.copyWith(tips: v))),
          ]),
          const SizedBox(height: 14),
          _Group(header: 'Offers', icon: Icons.local_offer_rounded, children: [
            _Toggle(
                label: 'Special offers',
                desc: 'Promotions and events (off by default)',
                value: prefs.promotions,
                enabled: !_saving,
                onChanged: (v) => _update(prefs.copyWith(promotions: v))),
          ]),
        ],
        if (_error != null && _prefs != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: EtColors.red, fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final String header;
  final IconData icon;
  final List<Widget> children;

  const _Group({required this.header, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 17, color: EtColors.green),
          const SizedBox(width: 7),
          Text(header.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: EtColors.muted)),
        ]),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: EtColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EtColors.line, width: 1.2),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 56, color: EtColors.line),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _Toggle({
    required this.label,
    required this.desc,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: Colors.white,
      activeTrackColor: EtColors.green,
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      subtitle: Text(desc,
          style: const TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w600, color: EtColors.muted)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: EtColors.locked),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      ),
    );
  }
}