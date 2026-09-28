import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/audio_service.dart';

/// In-house promo slot (admin-managed, not AdMob).
class AdBanner {
  final int id;
  final String title;
  final String body;
  final String imageUrl;
  final String ctaLabel;
  final String position;
  final String actionType;
  final String actionValue;
  final int impressions;
  final int clicks;

  AdBanner({
    required this.id,
    required this.title,
    this.body = '',
    this.imageUrl = '',
    this.ctaLabel = 'Learn more',
    this.position = 'home_top',
    this.actionType = 'none',
    this.actionValue = '',
    this.impressions = 0,
    this.clicks = 0,
  });

  factory AdBanner.fromJson(Map<String, dynamic> j) => AdBanner(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        imageUrl: (j['imageUrl'] ?? j['image_url'] ?? '').toString(),
        ctaLabel: (j['ctaLabel'] ?? j['cta_label'] ?? 'Learn more').toString(),
        position: (j['position'] ?? '').toString(),
        actionType: (j['actionType'] ?? j['action_type'] ?? 'none').toString(),
        actionValue: (j['actionValue'] ?? j['action_value'] ?? '').toString(),
        impressions: (j['impressions'] as num?)?.toInt() ?? 0,
        clicks: (j['clicks'] as num?)?.toInt() ?? 0,
      );

  Future<void> trackClick(
      Future<dynamic> Function(String path, Map<String, dynamic> body) post) async {
    try {
      await post('/app/ads/$id/click', {});
    } catch (_) {}
  }

  /// Open external URLs; screen navigation is handled by AdSlot.
  Future<void> openUrl() async {
    if (actionType == 'url' && actionValue.isNotEmpty) {
      final uri = Uri.parse(actionValue);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Promo card UI used in home / culture / profile slots.
class AppAdCard extends StatelessWidget {
  final AdBanner ad;
  final Future<void> Function()? onTap;
  final bool compact;

  const AppAdCard({
    super.key,
    required this.ad,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                EtColors.blue.withValues(alpha: 0.1),
                EtColors.gold.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EtColors.blue.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              if (ad.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    AudioService.resolve(ad.imageUrl),
                    width: compact ? 48 : 56,
                    height: compact ? 48 : 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const _AdIcon(),
                  ),
                )
              else
                const _AdIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EtColors.gold.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ad.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ad.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ad.body,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: EtColors.muted,
                        ),
                      ),
                    ],
                    if (ad.actionType != 'none' && ad.ctaLabel.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${ad.ctaLabel} →',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: EtColors.blue,
                          ),
                        ),
                      ),
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

class _AdIcon extends StatelessWidget {
  const _AdIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: EtColors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.campaign_rounded, color: EtColors.blue),
    );
  }
}
