import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';

/// In-app inbox: broadcasts from admins + messages sent to this user only.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final items = await auth.fetchNotifications();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(AppNotification n) {
    switch (n.type) {
      case 'update':
        return Icons.system_update_rounded;
      case 'event':
        return Icons.celebration_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.read) {
      try {
        await context.read<AuthService>().markNotificationRead(n.id);
        if (mounted) {
          setState(() {
            _items = [
              for (final item in _items)
                if (item.id == n.id) _markRead(item) else item,
            ];
          });
        }
      } catch (_) {}
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EtColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Icon(_iconFor(n), color: EtColors.green, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(n.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ]),
        content: Text(n.body.isEmpty ? 'No details provided.' : n.body,
            style:
                const TextStyle(height: 1.45, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(EtStrings.gotIt,
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  AppNotification _markRead(AppNotification item) => AppNotification(
        id: item.id,
        title: item.title,
        body: item.body,
        type: item.type,
        broadcast: item.broadcast,
        read: true,
        createdAt: item.createdAt,
      );

  String _when(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: EtColors.ink),
                  ),
                  const Expanded(
                    child: Text('Notifications',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: EtColors.green));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 42, color: EtColors.locked),
            const SizedBox(height: 10),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: EtColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.notifications_off_rounded,
                size: 44, color: EtColors.locked),
            SizedBox(height: 12),
            Text('No notifications yet',
                style: TextStyle(
                    color: EtColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: EtColors.green,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final n = _items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color:
                  n.read ? EtColors.card : EtColors.yellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: n.read
                    ? EtColors.line
                    : EtColors.yellowDark.withValues(alpha: 0.5),
                width: 1.3,
              ),
            ),
            child: ListTile(
              onTap: () => _open(n),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: n.read
                    ? EtColors.paper
                    : EtColors.green.withValues(alpha: 0.14),
                child: Icon(_iconFor(n),
                    size: 20,
                    color: n.read ? EtColors.locked : EtColors.green),
              ),
              title: Row(children: [
                Expanded(
                  child: Text(n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: EtColors.ink)),
                ),
                if (!n.read)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                        color: EtColors.red, shape: BoxShape.circle),
                  ),
              ]),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.broadcast ? 'Everyone' : 'Just you · ${n.type}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: EtColors.blue)),
                  const SizedBox(height: 2),
                  Text(n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: EtColors.muted)),
                  Text(_when(n.createdAt),
                      style: const TextStyle(
                          fontSize: 10.5, color: EtColors.locked)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}