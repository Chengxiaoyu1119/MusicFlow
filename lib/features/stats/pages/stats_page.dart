import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/audio_provider.dart';
import '../../../data/repository/stats_service.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsService = ref.watch(statsServiceProvider);
    final localMusic = ref.watch(audioHandlerProvider).getMusicList();
    final theme = Theme.of(context);

    final topTracks = statsService.getTopTracks(limit: 20);
    final totalTime = statsService.totalListeningTimeMs;
    final totalPlays = statsService.totalPlays;
    final uniqueTracks = statsService.uniqueTracks;

    return Scaffold(
      appBar: AppBar(title: const Text('Play Statistics')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Summary cards
          Row(
            children: [
              _StatCard(
                icon: Icons.play_circle_rounded,
                label: 'Total Plays',
                value: '$totalPlays',
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.timer_rounded,
                label: 'Listening Time',
                value: _formatDuration(totalTime),
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                icon: Icons.music_note_rounded,
                label: 'Unique Tracks',
                value: '$uniqueTracks',
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.analytics_rounded,
                label: 'Avg Plays/Track',
                value: uniqueTracks > 0
                    ? (totalPlays / uniqueTracks).toStringAsFixed(1)
                    : '0',
                color: theme.colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top tracks
          Text('Most Played',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (topTracks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text('No data yet. Start listening!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ...topTracks.map((stat) {
              final music = localMusic.where((m) => m.id == stat.musicId).firstOrNull;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text('${topTracks.indexOf(stat) + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold)),
                ),
                title: Text(music?.title ?? stat.musicId,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${stat.playCount} plays · ${_formatDuration(stat.totalPlayTimeMs)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${stat.playCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer)),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final hours = ms ~/ 3600000;
    final minutes = (ms % 3600000) ~/ 60000;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
