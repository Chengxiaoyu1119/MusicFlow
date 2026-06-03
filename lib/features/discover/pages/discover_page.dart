import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../api/auth_service.dart';
import '../../../api/netease_api.dart';

/// 发现页 — 推荐、排行榜、新歌（参考 YesPlayMusic 首页设计）
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final NeteaseApiClient _api = NeteaseApiClient(baseUrl: 'http://localhost:3000');
  List<Map<String, dynamic>> _recommendPlaylists = [];
  List<Map<String, dynamic>> _toplists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 尝试从 API 加载，失败则用示例数据
      final results = await Future.wait([
        _api.getRecommendPlaylists().catchError((_) => <Map<String, dynamic>>[]),
        _api.getToplists().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          _recommendPlaylists = results[0];
          _toplists = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MusicFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            onPressed: () => context.push('/login'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // 欢迎栏
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('今天想听什么？',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold)),
                              if (auth.isLoggedIn && auth.nickname != null)
                                Text('${auth.nickname}，欢迎回来',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary)),
                            ],
                          ),
                        ),
                        // 搜索入口
                        IconButton.filled(
                          icon: const Icon(Icons.search_rounded),
                          onPressed: () => context.push('/search'),
                        ),
                      ],
                    ),
                  ),

                  // 推荐歌单
                  _buildSectionHeader(theme, '推荐歌单', '为你精选'),
                  SizedBox(
                    height: 200,
                    child: _recommendPlaylists.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _recommendPlaylists.length,
                            itemBuilder: (context, index) {
                              final pl = _recommendPlaylists[index];
                              return _PlaylistCard(
                                name: pl['name'] as String? ?? '',
                                cover: (pl['picUrl'] ?? pl['coverImgUrl']) as String? ?? '',
                                playCount: pl['playCount'] as int? ?? 0,
                                onTap: () => _playPlaylist(pl),
                              );
                            },
                          )
                        : _buildPlaceholderRow(theme, '登录后查看推荐歌单'),
                  ),
                  const SizedBox(height: 16),

                  // 排行榜
                  _buildSectionHeader(theme, '排行榜', '热门榜单'),
                  SizedBox(
                    height: 180,
                    child: _toplists.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _toplists.length,
                            itemBuilder: (context, index) {
                              final tl = _toplists[index];
                              return _PlaylistCard(
                                name: tl['name'] as String? ?? '',
                                cover: (tl['coverImgUrl'] ?? tl['picUrl']) as String? ?? '',
                                subtitle: tl['description'] as String?,
                                onTap: () => _playToplist(tl),
                                small: true,
                              );
                            },
                          )
                        : _buildPlaceholderRow(theme, '登录后查看排行榜'),
                  ),
                  const SizedBox(height: 24),

                  // 网易云登录提示
                  if (!auth.isLoggedIn)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primary.withValues(alpha: 0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('登录网易云音乐',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('获取你的歌单、每日推荐和更多功能',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () => context.push('/login'),
                            child: const Text('登录'),
                          ),
                        ],
                      ),
                    ),

                  // 功能入口
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _FeatureChip(
                          icon: Icons.local_fire_department_rounded,
                          label: '每日推荐',
                          color: Colors.orange,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _FeatureChip(
                          icon: Icons.radio_rounded,
                          label: '私人 FM',
                          color: Colors.purple,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _FeatureChip(
                          icon: Icons.podcasts_rounded,
                          label: '播客',
                          color: Colors.teal,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('查看全部')),
        ],
      ),
    );
  }

  Widget _buildPlaceholderRow(ThemeData theme, String message) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note_outlined, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), size: 32),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                  maxLines: 2),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playPlaylist(Map<String, dynamic> pl) async {
    try {
      // 歌单加载（需接入 API）
    } catch (_) {}
  }

  Future<void> _playToplist(Map<String, dynamic> tl) async {
    try {
    } catch (_) {}
  }
}

class _PlaylistCard extends StatelessWidget {
  final String name;
  final String cover;
  final int playCount;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool small;

  const _PlaylistCard({
    required this.name,
    required this.cover,
    this.playCount = 0,
    this.subtitle,
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = small ? 130.0 : 150.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    cover.isNotEmpty
                        ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _placeholder(theme))
                        : _placeholder(theme),
                    if (playCount > 0)
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                              Text(_formatCount(playCount),
                                style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(name, maxLines: small ? 1 : 2, overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
            if (subtitle != null)
              Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
    );
  }

  String _formatCount(int c) {
    if (c >= 10000) return '${(c / 10000).toStringAsFixed(1)}万';
    return c.toString();
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
