import 'package:flutter/material.dart';
import '../features/calendar/ethiopian_calendar_screen.dart';
import '../features/culture/culture_phase4_screens.dart';
import '../features/topics/topics_screen.dart';
import '../state/app_state.dart';
import 'app_ad_card.dart';

/// Loads one ad for [position] and renders the promo card. Empty if no ad.
class AdSlot extends StatefulWidget {
  final AppState state;
  final String position;
  final bool compact;

  const AdSlot({
    super.key,
    required this.state,
    required this.position,
    this.compact = false,
  });

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  AdBanner? _ad;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ad = await widget.state.loadAd(widget.position);
    if (mounted) setState(() => _ad = ad);
  }

  Future<void> _tap() async {
    final ad = _ad;
    if (ad == null) return;
    await widget.state.trackAdClick(ad.id);
    if (!mounted) return;
    final action = ad.actionType;
    final value = ad.actionValue;
    if (action == 'url') {
      await ad.openUrl();
      return;
    }
    if (action == 'screen' || action == 'topic') {
      final route = value.replaceAll('/', '');
      if (route == 'topics' || action == 'topic') {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TopicsScreen(state: widget.state),
        ));
      } else if (route == 'calendar') {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const EthiopianCalendarScreen(),
        ));
      } else if (route == 'fidel') {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FidelTrainerScreen(state: widget.state),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AppAdCard(ad: ad, onTap: _tap, compact: widget.compact),
      ),
    );
  }
}
