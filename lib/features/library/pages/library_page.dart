import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../audio/audio_provider.dart';
import '../../../data/models/music.dart';
import '../../../data/repository/library_service.dart';
import '../../../shared/widgets/music_tile.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go('/search'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'scan':
                  library.scanLocalMusic();
                  break;
                case 'pick':
                  library.pickMusicFiles();
                  break;
                case 'plugins':
                  context.go('/plugins');
                  break;
                case 'settings':
                  context.go('/settings');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'scan', child: ListTile(
                leading: Icon(Icons.refresh_rounded),
                title: Text('Scan Local Music'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'pick', child: ListTile(
                leading: Icon(Icons.file_open_rounded),
                title: Text('Import Files'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'plugins', child: ListTile(
                leading: Icon(Icons.extension_rounded),
                title: Text('Plugins'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'settings', child: ListTile(
                leading: Icon(Icons.settings_rounded),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ],
      ),
      body: localMusic.isEmpty
          ? _EmptyLibrary(onPickFiles: () => library.pickMusicFiles())
          : _MusicList(musicList: localMusic),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onPickFiles;

  const _EmptyLibrary({required this.onPickFiles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Your music library is empty',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import local music files or install plugins\nto start listening',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onPickFiles,
              icon: const Icon(Icons.file_open_rounded),
              label: const Text('Import Music Files'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/plugins'),
              child: const Text('Browse Plugins'),
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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: musicList.length,
      itemBuilder: (context, index) {
        final music = musicList[index];
        return MusicTile(
          music: music,
          onTap: () => _playMusic(ref, musicList, index),
        );
      },
    );
  }

  void _playMusic(WidgetRef ref, List<Music> list, int index) {
    final handler = ref.read(audioHandlerProvider);
    handler.setQueue(list, startIndex: index);
  }
}
