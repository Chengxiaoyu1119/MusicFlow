import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../audio/audio_provider.dart';
import '../../../data/models/music.dart';
import '../../../data/repository/library_service.dart';
import '../../../shared/widgets/music_tile.dart';
import '../widgets/album_grid.dart';
import '../../playlist/services/smart_playlist_service.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryServiceProvider).scanLocalMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryServiceProvider);
    final localMusic = library.localMusic;
    final smartPlaylists = ref.watch(smartPlaylistProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go('/search'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'scan': library.scanLocalMusic(); break;
                case 'pick': library.pickMusicFiles(); break;
                case 'plugins': context.go('/plugins'); break;
                case 'settings': context.go('/settings'); break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'scan', child: ListTile(
                leading: Icon(Icons.refresh_rounded),
                title: Text('扫描本地音乐'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'pick', child: ListTile(
                leading: Icon(Icons.file_open_rounded),
                title: Text('导入文件'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'folder', child: ListTile(
                leading: Icon(Icons.folder_open_rounded),
                title: Text('导入文件夹'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'plugins', child: ListTile(
                leading: Icon(Icons.extension_rounded),
                title: Text('插件'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'settings', child: ListTile(
                leading: Icon(Icons.settings_rounded),
                title: Text('设置'),
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // View mode toggle
          if (localMusic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: screenWidth > 500 ? 400 : null,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('曲目'), icon: Icon(Icons.music_note_rounded, size: 16)),
                    ButtonSegment(value: 1, label: Text('专辑'), icon: Icon(Icons.album_rounded, size: 16)),
                    ButtonSegment(value: 2, label: Text('智能'), icon: Icon(Icons.auto_awesome_rounded, size: 16)),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (v) => setState(() => _viewMode = v.first),
                ),
              ),
            ),
          Expanded(
            child: localMusic.isEmpty
                ? _EmptyLibrary(onPickFiles: () => library.pickMusicFiles(), theme: theme)
                : _viewMode == 1
                    ? const AlbumGrid()
                    : _viewMode == 2
                        ? _SmartPlaylistsView(playlists: smartPlaylists)
                        : _MusicList(musicList: localMusic),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onPickFiles;
  final ThemeData theme;
  const _EmptyLibrary({required this.onPickFiles, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child: Icon(Icons.library_music_outlined, size: 48,
                color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text('音乐库为空', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('导入本地音乐文件或安装插件即可开始聆听',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onPickFiles,
              icon: const Icon(Icons.file_open_rounded),
              label: const Text('导入音乐文件'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/plugins'),
              child: const Text('浏览插件'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicList extends ConsumerWidget {
  final List<Music> musicList;
  const _MusicList({required this.musicList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (musicList.isEmpty) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async { /* refresh */ },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: musicList.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
        itemBuilder: (context, index) {
          final music = musicList[index];
          return MusicTile(
            music: music,
            onTap: () => _playMusic(ref, musicList, index),
            showArtwork: true,
          );
        },
      ),
    );
  }

  void _playMusic(WidgetRef ref, List<Music> list, int index) {
    ref.read(audioHandlerProvider).setQueue(list, startIndex: index);
  }
}

class _SmartPlaylistsView extends ConsumerWidget {
  final List<SmartPlaylist> playlists;
  const _SmartPlaylistsView({required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: playlists.map((playlist) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(_iconForType(playlist.type),
                color: theme.colorScheme.onPrimaryContainer, size: 20),
            ),
            title: Text(playlist.type.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${playlist.tracks.length} 首 · ${playlist.type.description}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              if (playlist.tracks.isNotEmpty) {
                ref.read(audioHandlerProvider).setQueue(playlist.tracks);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForType(SmartPlaylistType type) {
    switch (type) {
      case SmartPlaylistType.mostPlayed: return Icons.trending_up_rounded;
      case SmartPlaylistType.recentlyPlayed: return Icons.history_rounded;
      case SmartPlaylistType.recentlyAdded: return Icons.fiber_new_rounded;
      case SmartPlaylistType.favorites: return Icons.favorite_rounded;
      case SmartPlaylistType.frequentArtists: return Icons.people_rounded;
      case SmartPlaylistType.recentlyFavorited: return Icons.favorite_border_rounded;
    }
  }
}
