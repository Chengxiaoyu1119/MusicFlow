import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/audio_provider.dart';
import '../../../data/models/music.dart';
import '../../../data/repository/library_service.dart';
import '../../../plugin/api/plugin_model.dart';
import '../../../plugin/plugin_manager.dart';
import '../../../shared/widgets/music_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  List<Music> _localResults = [];
  List<PluginSearchResult> _onlineResults = [];
  bool _isSearching = false;
  bool _showOnline = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          hintText: 'Search songs, artists, albums...',
          controller: _searchController,
          leading: const Icon(Icons.search_rounded),
          trailing: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _localResults = [];
                    _onlineResults = [];
                  });
                },
              ),
          ],
          onSubmitted: (query) => _search(query),
          onChanged: (query) {
            if (query.length > 2) _search(query);
            if (query.isEmpty) {
              setState(() {
                _localResults = [];
                _onlineResults = [];
              });
            }
          },
        ),
      ),
      body: _buildResults(theme),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final hasLocal = _localResults.isNotEmpty;
    final hasOnline = _onlineResults.isNotEmpty;
    final hasAny = hasLocal || hasOnline;

    if (!hasAny && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Search your music or explore online',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasAny) {
      return Center(child: Text('No results found',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant)));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        // Toggle: Local / Online
        if (hasLocal && hasOnline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Local'), icon: Icon(Icons.music_note_rounded)),
                ButtonSegment(value: true, label: Text('Online'), icon: Icon(Icons.cloud_rounded)),
              ],
              selected: {_showOnline},
              onSelectionChanged: (v) => setState(() => _showOnline = v.first),
            ),
          ),

        if (!_showOnline && hasLocal)
          ..._localResults.map((music) => MusicTile(
            music: music,
            onTap: () => _playLocal(music),
          )),

        if (_showOnline && hasOnline)
          ..._onlineResults.expand((result) {
            return result.music.map((item) {
              return MusicTile(
                music: _onlineItemToMusic(item, result.platform),
                trailing: _PlatformBadge(platform: result.platform),
                onTap: () => _playOnline(item, result.platform),
              );
            });
          }),
      ],
    );
  }

  void _search(String query) {
    setState(() => _isSearching = true);

    // Search local
    final library = ref.read(libraryServiceProvider);
    final localResults = library.localMusic.where((music) {
      final q = query.toLowerCase();
      return music.title.toLowerCase().contains(q) ||
          music.artist.toLowerCase().contains(q) ||
          music.album.toLowerCase().contains(q);
    }).toList();

    // Search online via plugins
    final pluginManager = ref.read(pluginManagerProvider.notifier);

    pluginManager.searchAll(query).then((results) {
      if (!mounted) return;
      setState(() {
        _localResults = localResults;
        _onlineResults = results.where((r) => r.music.isNotEmpty).toList();
        _isSearching = false;
        _showOnline = _onlineResults.isNotEmpty && localResults.isEmpty;
      });
    });
  }

  void _playLocal(Music music) {
    final handler = ref.read(audioHandlerProvider);
    handler.setQueue([music]);
  }

  void _playOnline(PluginMusicItem item, String platform) {
    final music = _onlineItemToMusic(item, platform);
    final handler = ref.read(audioHandlerProvider);
    handler.setQueue([music]);
  }

  Music _onlineItemToMusic(PluginMusicItem item, String platform) {
    return Music(
      id: '${platform}_${item.id}',
      title: item.title,
      artist: item.artist,
      album: item.album ?? '',
      artworkUrl: item.artwork,
      duration: Duration(seconds: item.duration),
      source: MusicSource.plugin,
      pluginId: platform,
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final String platform;
  const _PlatformBadge({required this.platform});

  @override
  Widget build(BuildContext context) {
    final label = platform == 'netease' ? 'Netease' : platform == 'qq' ? 'QQ' : platform;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onTertiaryContainer,
          fontSize: 10,
        ),
      ),
    );
  }
}
