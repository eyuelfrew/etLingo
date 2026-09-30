import 'package:flutter/material.dart';
import '../../features/billing/payment_verify_screen.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../ui/et_strings.dart';

/// Locked chapter → one-time Chapa purchase (not subscription).
Future<void> showUnitPurchaseSheet(
  BuildContext context, {
  required AppState state,
  required int unitId,
  required String unitTitle,
  required String priceLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          const Icon(Icons.lock_rounded, color: EtColors.gold),
          const SizedBox(width: 8),
          Expanded(child: Text(EtStrings.subscribeTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unitTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            EtStrings.subscribeBody,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: EtColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            priceLabel,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, color: EtColors.gold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(EtStrings.okGotIt,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            final result = await state.checkoutUnit(unitId);
            if (result == null || !context.mounted) return;
            final payUrl = (result['paymentUrl'] ?? '').toString();
            final txRef = (result['txRef'] ?? '').toString();
            final msg = (result['message'] ?? '').toString();
            if (payUrl.isNotEmpty && txRef.isNotEmpty) {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => PaymentVerifyScreen(
                    state: state,
                    txRef: txRef,
                    sku: 'unit:$unitId',
                    paymentUrl: payUrl,
                  ),
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg.isNotEmpty ? msg : EtStrings.premiumSoon)),
              );
            }
          },
          child: Text(EtStrings.buyChapter,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}