import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A frosted-glass effect overlay on album artwork.
///
/// Used as a full-screen background on the player page, creating
/// a glassmorphism aesthetic with blurred album art.
class GlassmorphicArt extends StatelessWidget {
  final String? imageUrl;
  final double blurSigma;
  final double opacity;

  const GlassmorphicArt({
    super.key,
    this.imageUrl,
    this.blurSigma = 40,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        if (imageUrl != null)
          CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _placeholder(theme),
          )
        else
          _placeholder(theme),

        // Frosted glass overlay
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Container(
            color: theme.colorScheme.surface.withValues(alpha: opacity),
          ),
        ),

        // Subtle gradient overlay for depth
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                theme.colorScheme.surface.withValues(alpha: 0.1),
                theme.colorScheme.surface.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 120,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
