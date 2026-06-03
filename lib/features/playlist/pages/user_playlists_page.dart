import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../api/auth_service.dart';
import '../../../audio/audio_provider.dart';
import '../../../data/models/music.dart';
import '../../auth/pages/login_page.dart' show LoginPage;
import '../../player/pages/player_page.dart' show PlayerPage;

/// 用户歌单列表
class UserPlaylistsPage extends ConsumerStatefulWidget {
  const UserPlaylistsPage({super.key});

  @override
  ConsumerState<UserPlaylistsPage> createState() => _UserPlaylistsPageState();
}

class _UserPlaylistsPageState extends ConsumerState<UserPlaylistsPage> {
  List<Map<String, dynamic>> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(authProvider.notifier).api;
      final playlists = await api.getUserPlaylists();
      if (mounted) setState(() => _playlists = playlists);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<List<Music>> _loadTracks(String playlistId) async {
    final api = ref.read(authProvider.notifier).api;
    final tracks = await api.getPlaylistTracks(playlistId);

    // 获取每首歌的播放 URL
    final musicList = <Music>[];
    for (final t in tracks) {
      final id = t['id'].toString();
      final al = t['al'] as Map<String, dynamic>? ?? t['album'] as Map<String, dynamic>?;
      final ar = (t['ar'] as List<dynamic>?) ?? (t['artists'] as List<dynamic>?) ?? [];

      // 先获取播放 URL
      String? url;
      try {
        url = await api.getSongUrl(id);
      } catch (_) {}

      musicList.add(Music(
        id: 'netease_$id',
        title: t['name'] as String? ?? '',
        artist: ar.isNotEmpty ? ar.map((a) => a is Map ? a['name'] as String? ?? '' : '').join(', ') : '未知',
        album: al?['name'] as String? ?? '',
        artworkUrl: al?['picUrl'] as String? ?? al?['pic_url'] as String?,
        duration: Duration(milliseconds: t['dt'] as int? ?? t['duration'] as int? ?? 0),
        url: url,
        source: MusicSource.plugin,
        pluginId: 'netease',
      ));
    }
    return musicList;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的歌单')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login_rounded, size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('请先登录', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
                child: const Text('登录'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的歌单'),
        actions: [
          if (auth.nickname != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(auth.nickname!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_play_rounded, size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('暂无歌单', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlaylists,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      final pl = _playlists[index];
                      final name = pl['name'] as String? ?? '';
                      final cover = (pl['coverImgUrl'] ?? pl['coverImgUrl_str']) as String?;
                      final trackCount = pl['trackCount'] as int? ?? 0;
                      final playCount = pl['playCount'] as int? ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 56, height: 56,
                              child: cover != null
                                  ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _placeholder(theme))
                                  : _placeholder(theme),
                            ),
                          ),
                          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('$trackCount 首 · ${_formatPlayCount(playCount)} 次播放',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                          trailing: const Icon(Icons.play_arrow_rounded),
                          onTap: () async {
                            final tracks = await _loadTracks(pl['id'].toString());
                            if (tracks.isNotEmpty && context.mounted) {
                              ref.read(audioHandlerProvider).setQueue(tracks);
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const PlayerPage(),
                              ));
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(Icons.music_note_rounded, color: theme.colorScheme.onPrimaryContainer),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}万';
    return count.toString();
  }
}