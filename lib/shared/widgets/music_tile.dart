import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/music.dart';

/// 精美音乐列表项 — 圆角封面 + 阴影 + 垂直居中排版
class MusicTile extends StatelessWidget {
  final Music music;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArtwork;

  const MusicTile({
    super.key,
    required this.music,
    this.onTap,
    this.trailing,
    this.showArtwork = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: showArtwork
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48, height: 48,
                  child: music.artworkUrl != null
                      ? CachedNetworkImage(
                          imageUrl: music.artworkUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(theme),
                        )
                      : _placeholder(theme),
                ),
              ),
            )
          : null,
      title: Text(
        music.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        music.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ?? (music.duration > Duration.zero
          ? Text(
              _fmtDuration(music.duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            )
          : null),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(Icons.music_note_rounded,
        color: theme.colorScheme.onPrimaryContainer, size: 22),
    );
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
