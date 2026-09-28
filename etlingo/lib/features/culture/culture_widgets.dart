import 'package:flutter/material.dart';
import '../../core/calendar/ethiopian_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../services/audio_service.dart';

/// Proverb of the Day card (home / culture).
class ProverbOfDayCard extends StatelessWidget {
  final String title;
  final String target;
  final String translit;
  final String body;
  final Color accent;
  final String? audioUrl;
  final VoidCallback? onTap;

  const ProverbOfDayCard({
    super.key,
    this.title = 'Proverb of the day',
    required this.target,
    this.translit = '',
    required this.body,
    this.accent = EtColors.gold,
    this.audioUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: accent, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (audioUrl != null && audioUrl!.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => AudioService.instance.play(audioUrl!),
                  icon: Icon(Icons.volume_up_rounded, color: accent, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            target,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (translit.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              translit,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (onTap != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTap,
                child: Text(EtStrings.tabRead,
                    style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ethiopian calendar + holiday highlight strip.
class EthiopianCalendarCard extends StatelessWidget {
  final String? holidayLabel;
  final VoidCallback? onTap;

  const EthiopianCalendarCard({
    super.key,
    this.holidayLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final eth = EthiopianCalendar.fromGregorian(now);
    final accent = EtColors.green;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ዛሬ · ${eth.label()}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: accent,
                      ),
                    ),
                    if (holidayLabel != null && holidayLabel!.isNotEmpty)
                      Text(
                        holidayLabel!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: EtColors.muted,
                        ),
                      )
                    else
                      Text(
                        EtStrings.ethiopianCalendar,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: EtColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    color: EtColors.locked),
            ],
          ),
        ),
      ),
    );
  }
}

/// Holiday / challenge banner (limited-time XP).
class HolidayChallengeBanner extends StatelessWidget {
  final String label;
  final String detail;
  final Color accent;
  final VoidCallback? onOpen;

  const HolidayChallengeBanner({
    super.key,
    required this.label,
    required this.detail,
    this.accent = EtColors.red,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          accent.withValues(alpha: 0.95),
          accent.withValues(alpha: 0.75),
        ]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

/// Fidel (Ge'ez) letter practice card — Phase 4 trainer entry.
class FidelTrainerCard extends StatelessWidget {
  final Color accent;
  final VoidCallback? onOpen;

  const FidelTrainerCard({super.key, this.accent = EtColors.blue, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('ሀ',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EtStrings.fidelTrainer,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: accent.computeLuminance() > 0.7
                        ? EtColors.ink
                        : accent,
                  ),
                ),
                Text(
                  EtStrings.fidelTrainerSub,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EtColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              onPressed: onOpen,
              icon: Icon(Icons.chevron_right_rounded, color: accent),
            ),
        ],
      ),
    );
  }
}

/// Public-domain folk / music lyrics card (Phase 4).
class FolkSongCard extends StatelessWidget {
  final String title;
  final String lyricLines;
  final String translit;
  final String note;
  final Color accent;
  final String? audioUrl;

  const FolkSongCard({
    super.key,
    required this.title,
    required this.lyricLines,
    this.translit = '',
    this.note = '',
    this.accent = EtColors.blue,
    this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EtColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EtColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded, color: accent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              if (audioUrl != null && audioUrl!.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => AudioService.instance.play(audioUrl!),
                  icon: Icon(Icons.play_circle_rounded,
                      color: accent, size: 22),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lyricLines,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          if (translit.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              translit,
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(
                fontSize: 11.5,
                color: EtColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Community story card (Phase 4) — admin-approved snippets.
class CommunityStoryCard extends StatelessWidget {
  final String author;
  final String snippet;
  final String? audioUrl;
  final Color accent;

  const CommunityStoryCard({
    super.key,
    required this.author,
    required this.snippet,
    this.audioUrl,
    this.accent = EtColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Text(
              author.isEmpty ? '?' : author.characters.first.toUpperCase(),
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                Text(
                  snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: EtColors.muted),
                ),
              ],
            ),
          ),
          if (audioUrl != null && audioUrl!.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => AudioService.instance.play(audioUrl!),
              icon: Icon(Icons.volume_up_rounded, color: accent, size: 18),
            ),
        ],
      ),
    );
  }
}

/// AR-style share card (Phase 4) — flag / tibeb overlay prompt.
class ArShareCard extends StatelessWidget {
  final Color accent;
  final VoidCallback? onShare;

  const ArShareCard({super.key, this.accent = EtColors.green, this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          EtColors.green,
          EtColors.yellow,
          EtColors.red,
        ]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AR / photo share',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5),
                ),
                Text(
                  'Flag, tibeb, traditional dress overlays',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onShare != null)
            IconButton(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

/// Language exchange / partner match teaser (Phase 4).
class LanguageExchangeCard extends StatelessWidget {
  final Color accent;
  final VoidCallback? onOpen;

  const LanguageExchangeCard({super.key, this.accent = EtColors.blue, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.handshake_rounded, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EtStrings.languageExchange,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: accent.computeLuminance() > 0.7
                          ? EtColors.ink
                          : accent),
                ),
                Text(
                  EtStrings.languageExchangeSub,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EtColors.muted),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              onPressed: onOpen,
              icon: Icon(Icons.chevron_right_rounded, color: accent),
            ),
        ],
      ),
    );
  }
}

/// Offline cache status chip (Phase 2 leftover).
class OfflineCacheChip extends StatelessWidget {
  final bool cached;
  final VoidCallback? onDownload;
  final Color accent;

  const OfflineCacheChip({
    super.key,
    required this.cached,
    this.onDownload,
    this.accent = EtColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (cached ? accent : EtColors.muted).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (cached ? accent : EtColors.muted).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            cached ? Icons.download_done_rounded : Icons.download_rounded,
            size: 16,
            color: cached ? accent : EtColors.muted,
          ),
          const SizedBox(width: 6),
          Text(
            cached ? EtStrings.offlineReady : EtStrings.downloadOffline,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cached ? accent : EtColors.muted,
            ),
          ),
          if (!cached && onDownload != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDownload,
              child: Text(
                EtStrings.download,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
