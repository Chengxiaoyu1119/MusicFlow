import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/auth_service.dart';
import '../../../data/repository/sample_data.dart';

/// 发现页 — 像素级精修设计
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ===== 顶部栏 =====
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, safeTop + 8, 20, 16),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.music_note_rounded,
                      color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('MusicFlow',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Search icon
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.search_rounded, size: 20),
                      onPressed: () => context.push('/search'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar / Login
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: auth.isLoggedIn && auth.nickname != null
                          ? Center(child: Text(auth.nickname![0],
                              style: TextStyle(fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer)))
                          : Icon(Icons.person_outline_rounded, size: 20,
                              color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== 欢迎语 =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今天想听什么？',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(auth.isLoggedIn && auth.nickname != null
                      ? '${auth.nickname}，欢迎回来'
                      : '发现音乐，发现美好',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),

          // ===== 分类入口 =====
          SliverToBoxAdapter(
            child: SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: SampleData.genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final g = SampleData.genres[index];
                  final isSelected = index == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(g['name']!,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        )),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ===== 推荐歌单 =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text('推荐歌单',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text('查看更多', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: SampleData.recommendPlaylists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final pl = SampleData.recommendPlaylists[index];
                  return _PlaylistCard(
                    name: pl['name'] as String,
                    playCount: pl['playCount'] as int,
                    index: index,
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ===== 排行榜 =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text('排行榜',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('查看更多', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tl = SampleData.toplists[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20, right: 20,
                    bottom: index == SampleData.toplists.length - 1 ? 8 : 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Rank number
                        Container(
                          width: 32, height: 32,
                          alignment: Alignment.center,
                          child: Text('${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: index < 3
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            )),
                        ),
                        const SizedBox(width: 12),
                        // Cover placeholder
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.music_note_rounded, size: 22,
                            color: theme.colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tl['name'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(tl['description'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20,
                          color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              },
              childCount: SampleData.toplists.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ===== 登录引导 =====
          if (!auth.isLoggedIn)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.surfaceContainerHighest,
                      ],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('获取你的歌单、每日推荐',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12)),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => context.push('/login'),
                        child: const Text('登录', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Bottom spacing for mini player
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String name;
  final int playCount;
  final int index;

  static const List<Color> _colors = [
    Color(0xFF6C5CE7), Color(0xFFE17055), Color(0xFF00B894),
    Color(0xFF0984E3), Color(0xFFE84393), Color(0xFF00CEC9),
  ];

  const _PlaylistCard({required this.name, required this.playCount, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];

    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${_fmtCount(playCount)} 次播放',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _fmtCount(int c) {
    if (c >= 10000) return '${(c / 10000).toStringAsFixed(1)}万';
    return c.toString();
  }
}
