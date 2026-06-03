import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/music.dart';

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: showArtwork ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: music.artworkUrl != null
              ? CachedNetworkImage(
                  imageUrl: music.artworkUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _placeholder(theme),
                  errorWidget: (_, __, ___) => _placeholder(theme),
                )
              : _placeholder(theme),
        ),
      ) : null,
      title: Text(
        music.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
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
              _formatDuration(music.duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.music_note_rounded,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
