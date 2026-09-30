import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../state/app_state.dart';

/// After opening Chapa: poll verify until paid / failed / timeout.
class PaymentVerifyScreen extends StatefulWidget {
  final AppState state;
  final String txRef;
  final String sku;
  final String? paymentUrl;
  const PaymentVerifyScreen({
    super.key,
    required this.state,
    required this.txRef,
    required this.sku,
    this.paymentUrl,
  });

  @override
  State<PaymentVerifyScreen> createState() => _PaymentVerifyScreenState();
}

class _PaymentVerifyScreenState extends State<PaymentVerifyScreen>
    with WidgetsBindingObserver {
  String _status = 'pending'; // pending | paid | failed
  String _note = '';
  bool _checking = true;
  Timer? _timer;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    // Keep polling while user is away or on this screen (~every 6s, max ~2 min).
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check as soon as they come back from the browser.
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_status == 'paid' || _status == 'failed') {
      _timer?.cancel();
      return;
    }
    setState(() => _checking = true);
    _polls += 1;
    try {
      final data = await widget.state
          .apiGet('/app/checkout/${widget.txRef}/status');
      final st = data is Map ? (data['status'] ?? 'pending').toString() : 'pending';
      if (!mounted) return;
      setState(() {
        _status = st;
        _checking = false;
      });
      if (st == 'paid') {
        _timer?.cancel();
        await widget.state.refreshLanguage();
        await widget.state.loadEntitlements();
        if (!mounted) return;
        setState(() => _note = 'Subscription active. Premium lessons unlocked.');
      } else if (st == 'failed') {
        _timer?.cancel();
        setState(() => _note = 'Payment was not completed.');
      } else if (_polls >= 20) {
        _timer?.cancel();
        setState(() => _note = 'Still waiting — try again later or contact support.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _note = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (_status) {
      'paid' => Icons.check_circle_rounded,
      'failed' => Icons.error_rounded,
      _ => Icons.hourglass_top_rounded,
    };
    final color = switch (_status) {
      'paid' => EtColors.green,
      'failed' => EtColors.red,
      _ => EtColors.gold,
    };
    final title = switch (_status) {
      'paid' => 'You’re subscribed!',
      'failed' => 'Payment not completed',
      _ => 'Checking your payment…',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.subscribeTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            if (_checking && _status == 'pending')
              const CircularProgressIndicator()
            else
              Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _note.isEmpty
                  ? 'We’ll confirm with Chapa automatically after you return.'
                  : _note,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: EtColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Ref: ${widget.txRef}',
              style: const TextStyle(fontSize: 11, color: EtColors.locked),
            ),
            const Spacer(),
            if (_status == 'pending' && widget.paymentUrl != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(widget.paymentUrl!),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open payment page again'),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor:
                        _status == 'paid' ? EtColors.green : EtColors.ink),
                onPressed: () => Navigator.of(context).pop(_status == 'paid'),
                child: Text(_status == 'paid' ? 'Start learning' : 'Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
