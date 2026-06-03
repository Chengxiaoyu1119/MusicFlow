import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/music.dart';
import '../../../data/repository/favorites_provider.dart';
import '../../../data/repository/library_service.dart';
import '../../../data/repository/stats_service.dart';

/// Defines a smart playlist that auto-generates based on rules.
enum SmartPlaylistType {
  mostPlayed('Most Played', 'Top tracks by play count'),
  recentlyPlayed('Recently Played', 'Tracks you played recently'),
  recentlyAdded('Recently Added', 'Latest imported tracks'),
  favorites('Favorites', 'Your liked tracks'),
  frequentArtists('Frequent Artists', 'Artists you listen to most'),
  recentlyFavorited('Recent Favorites', 'Recently liked tracks'),
  ;

  final String displayName;
  final String description;
  const SmartPlaylistType(this.displayName, this.description);
}

class SmartPlaylist {
  final SmartPlaylistType type;
  final List<Music> tracks;
  final DateTime updatedAt;

  const SmartPlaylist({
    required this.type,
    required this.tracks,
    required this.updatedAt,
  });
}

/// Generates smart playlists based on listening data.
class SmartPlaylistService {
  List<SmartPlaylist> generateAll({
    required List<Music> localMusic,
    required Set<String> favIds,
    required List<TrackStats> topTracks,
  }) {
    return SmartPlaylistType.values.map((type) {
      return SmartPlaylist(
        type: type,
        tracks: _generate(type, localMusic, favIds, topTracks),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  List<Music> _generate(
    SmartPlaylistType type,
    List<Music> localMusic,
    Set<String> favIds,
    List<TrackStats> topTracks,
  ) {
    switch (type) {
      case SmartPlaylistType.mostPlayed:
        final topIds = topTracks.map((t) => t.musicId).toSet();
        return localMusic.where((m) => topIds.contains(m.id)).toList()
          ..sort((a, b) {
            final aStats = topTracks.where((t) => t.musicId == a.id).firstOrNull;
            final bStats = topTracks.where((t) => t.musicId == b.id).firstOrNull;
            return (bStats?.playCount ?? 0).compareTo(aStats?.playCount ?? 0);
          });

      case SmartPlaylistType.recentlyPlayed:
        final recentIds = topTracks.map((t) => t.musicId).toList();
        return recentIds.map((id) => localMusic.where((m) => m.id == id).firstOrNull)
            .whereType<Music>().toList();

      case SmartPlaylistType.recentlyAdded:
        return localMusic.toList().reversed.take(50).toList();

      case SmartPlaylistType.favorites:
        return localMusic.where((m) => favIds.contains(m.id)).toList();

      case SmartPlaylistType.frequentArtists:
        final artistCount = <String, int>{};
        for (final stat in topTracks) {
          final music = localMusic.where((m) => m.id == stat.musicId).firstOrNull;
          if (music != null) {
            artistCount[music.artist] = (artistCount[music.artist] ?? 0) + 1;
          }
        }
        final topArtists = artistCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topArtistNames = topArtists.take(5).map((e) => e.key).toSet();
        return localMusic.where((m) => topArtistNames.contains(m.artist)).toList();

      case SmartPlaylistType.recentlyFavorited:
        return localMusic.where((m) => favIds.contains(m.id)).toList().reversed.take(30).toList();
    }
  }
}

final smartPlaylistProvider = Provider<List<SmartPlaylist>>((ref) {
  final localMusic = ref.watch(libraryServiceProvider).localMusic;
  final favoriteIds = ref.watch(favoritesProvider);
  final statsService = ref.watch(statsServiceProvider);

  final service = SmartPlaylistService();
  return service.generateAll(
    localMusic: localMusic,
    favIds: favoriteIds,
    topTracks: statsService.getTopTracks(limit: 50),
  );
});
