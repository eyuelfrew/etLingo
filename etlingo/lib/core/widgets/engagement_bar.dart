import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/engagement_service.dart';

/// Heart + comment count; opens a comments sheet.
class EngagementBar extends StatelessWidget {
  final String targetLabel;
  final int likes;
  final bool likedByMe;
  final int commentCount;
  final Color accent;
  final VoidCallback onToggleLike;
  final Future<void> Function(BuildContext context) onOpenComments;
  final bool compact;

  const EngagementBar({
    super.key,
    required this.targetLabel,
    required this.likes,
    required this.likedByMe,
    required this.commentCount,
    required this.accent,
    required this.onToggleLike,
    required this.onOpenComments,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = likedByMe ? EtColors.red : accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: likedByMe ? null : onToggleLike,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
            decoration: BoxDecoration(
              color: (likedByMe ? EtColors.red : accent).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: chipColor.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: compact ? 16 : 18,
                  color: chipColor,
                ),
                const SizedBox(width: 4),
                Text(
                  likedByMe ? '$likes · liked' : '$likes',
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                    color: chipColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onOpenComments(context),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: accent.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: compact ? 15 : 17, color: accent),
                const SizedBox(width: 4),
                Text(
                  '$commentCount',
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                    color: accent.computeLuminance() > 0.7
                        ? EtColors.ink
                        : accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet: list comments + write a new one (signed-in only).
class CommentsSheet extends StatefulWidget {
  final String title;
  final Engagement engagement;
  final Color accent;
  final bool canComment;
  final Future<EngagementComment?> Function(String body) onSubmit;

  const CommentsSheet({
    super.key,
    required this.title,
    required this.engagement,
    required this.accent,
    required this.canComment,
    required this.onSubmit,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late List<EngagementComment> _comments =
      List.of(widget.engagement.comments);
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final c = await widget.onSubmit(text);
      if (c != null && mounted) {
        setState(() {
          _comments = [c, ..._comments];
          _controller.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: _comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet. Be first!',
                      style: TextStyle(
                        color: EtColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, i) {
                      final c = _comments[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EtColors.cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: EtColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.author,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.body,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          if (!widget.canComment)
            const Text(
              'Sign in to like or comment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: EtColors.muted, fontWeight: FontWeight.w600),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Write a comment…',
                      counterText: '',
                      filled: true,
                      fillColor: EtColors.cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: EtColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: accent, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
