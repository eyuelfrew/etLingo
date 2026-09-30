import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../state/app_state.dart';
import 'payment_verify_screen.dart';

/// Subscription packages (from admin-managed plans).
class SubscribePlansScreen extends StatefulWidget {
  final AppState state;
  const SubscribePlansScreen({super.key, required this.state});

  @override
  State<SubscribePlansScreen> createState() => _SubscribePlansScreenState();
}

class _SubscribePlansScreenState extends State<SubscribePlansScreen> {
  List<Map<String, dynamic>> _plans = const [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.state.apiGet('/app/offers');
      if (data is Map && data['plans'] is List) {
        _plans = (data['plans'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      _plans = const [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _choose(Map<String, dynamic> plan) async {
    final sku = (plan['sku'] ?? '').toString();
    try {
      final data =
          await widget.state.apiPost('/app/checkout/intent', {'sku': sku});
      if (!mounted) return;
      if (data is! Map) {
        setState(() => _message = EtStrings.premiumSoon);
        return;
      }
      final payUrl = (data['paymentUrl'] ?? '').toString();
      final txRef = (data['txRef'] ?? '').toString();
      final msg = (data['message'] ?? '').toString();

      if (payUrl.isNotEmpty && txRef.isNotEmpty) {
        setState(() => _message = 'Opening payment…');
        final uri = Uri.parse(payUrl);
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) {
          setState(() => _message = 'Could not open payment link.');
          return;
        }
        if (!mounted) return;
        // Auto-verify when the user returns from Chapa.
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymentVerifyScreen(
              state: widget.state,
              txRef: txRef,
              sku: sku,
              paymentUrl: payUrl,
            ),
          ),
        );
        if (paid == true && mounted) {
          setState(() =>
              _message = 'You’re subscribed — premium is unlocked.');
        }
        return;
      }

      setState(() => _message = msg.isNotEmpty ? msg : EtStrings.premiumSoon);
    } catch (e) {
      setState(() =>
          _message = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: EtColors.ink,
        elevation: 0,
        title: Text(EtStrings.subscribeTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  EtStrings.subscribeBody,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: EtColors.muted),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EtColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_message!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 16),
                ..._plans.map((p) {
                  final highlighted = p['isHighlighted'] == true;
                  final features = (p['features'] is List)
                      ? (p['features'] as List)
                          .map((e) => e.toString())
                          .toList()
                      : const <String>[];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? EtColors.gold.withValues(alpha: 0.12)
                          : EtColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: highlighted ? EtColors.gold : EtColors.line,
                        width: highlighted ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (p['title'] ?? '').toString(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            if ((p['badge'] ?? '').toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: EtColors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p['badge'].toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            (p['priceLabel'] ?? '').toString(),
                            (p['periodLabel'] ?? '').toString(),
                            (p['subtitle'] ?? '').toString(),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: EtColors.muted),
                        ),
                        const SizedBox(height: 10),
                        ...features.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 16, color: EtColors.green),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  highlighted ? EtColors.gold : EtColors.blue,
                              foregroundColor:
                                  highlighted ? EtColors.ink : Colors.white,
                            ),
                            onPressed: () => _choose(p),
                            child: Text(EtStrings.subscribeTitle),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
