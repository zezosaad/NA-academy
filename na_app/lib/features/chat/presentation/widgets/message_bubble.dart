import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/features/chat/domain/chat_models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String currentUserId;
  final VoidCallback? onTapImage;
  final String? baseUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onTapImage,
    this.baseUrl,
  });

  bool get _isMe => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (message.status == MessageDeliveryStatus.deleted) {
      return _DeletedBubble(isMe: _isMe);
    }

    return Padding(
      padding: EdgeInsets.only(
        left: _isMe ? 48.0 : 12.0,
        right: _isMe ? 12.0 : 48.0,
        bottom: 8.0,
      ),
      child: Align(
        alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: _isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: _isMe
                    ? (isDark ? AppColors.darkAccentSoft : AppColors.accent)
                    : (isDark ? AppColors.darkBgElevated : AppColors.bgElevated),
                borderRadius: _isMe
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(AppShapes.cardRadius),
                        topRight: Radius.circular(AppShapes.cardRadius),
                        bottomLeft: Radius.circular(AppShapes.cardRadius),
                        bottomRight: Radius.zero,
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(AppShapes.cardRadius),
                        topRight: Radius.circular(AppShapes.cardRadius),
                        bottomLeft: Radius.zero,
                        bottomRight: Radius.circular(AppShapes.cardRadius),
                      ),
                border: _isMe
                    ? null
                    : Border.all(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
                        width: 0.5,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.image && message.imageFileId != null)
                    _ImageBubble(
                      imageFileId: message.imageFileId!,
                      onTap: onTapImage,
                      baseUrl: baseUrl,
                      isMe: _isMe,
                    ),
                  if (message.text != null && message.text!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        message.text!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _isMe
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.sentAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (_isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _statusIcon,
                    size: 14,
                    color: _statusColor(context),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (message.status) {
        MessageDeliveryStatus.pending => Icons.schedule,
        MessageDeliveryStatus.sent => Icons.check,
        MessageDeliveryStatus.delivered => Icons.done_all,
        MessageDeliveryStatus.read => Icons.done_all,
        MessageDeliveryStatus.failed => Icons.error_outline,
        MessageDeliveryStatus.deleted => Icons.block,
      };

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return switch (message.status) {
      MessageDeliveryStatus.read => isDark ? AppColors.darkAccent : AppColors.accent,
      MessageDeliveryStatus.failed => isDark ? AppColors.darkDanger : AppColors.danger,
      _ => isDark ? AppColors.darkTextMuted : AppColors.textMuted,
    };
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ImageBubble extends StatelessWidget {
  final String imageFileId;
  final VoidCallback? onTap;
  final String? baseUrl;
  final bool isMe;

  const _ImageBubble({
    required this.imageFileId,
    this.onTap,
    this.baseUrl,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${baseUrl ?? 'http://10.0.2.2:3000'}/media/$imageFileId/stream';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(AppShapes.cardRadius),
        topRight: const Radius.circular(AppShapes.cardRadius),
        bottomLeft: isMe ? const Radius.circular(AppShapes.cardRadius) : Radius.zero,
        bottomRight: isMe ? Radius.zero : const Radius.circular(AppShapes.cardRadius),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 220,
          height: 180,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 220,
            height: 180,
            color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.darkAccent : AppColors.accent,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 220,
            height: 180,
            color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
            child: Icon(
              Icons.broken_image,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  final bool isMe;

  const _DeletedBubble({required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 48.0 : 12.0,
        right: isMe ? 12.0 : 48.0,
        bottom: 8.0,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          ),
          child: Text(
            'Message removed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}