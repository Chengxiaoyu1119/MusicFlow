import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/auth_service.dart';
import '../../../data/repository/sample_data.dart';

/// 发现页 — 参考 YesPlayMusic 首页设计
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
    // final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ===== 顶部栏 =====
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                Icon(Icons.music_note_rounded,
                  color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 8),
                Text('MusicFlow',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push('/search'),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => context.push('/login'),
              ),
            ],
          ),

          // ===== 欢迎语 =====
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今天想听什么？',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(auth.isLoggedIn && auth.nickname != null
                          ? '${auth.nickname}，欢迎回来'
                          : '发现音乐，发现美好',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      if (auth.isLoggedIn)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(auth.nickname![0],
                                  style: TextStyle(fontSize: 11,
                                    color: theme.colorScheme.onPrimary)),
                              ),
                              const SizedBox(width: 4),
                              Text(auth.nickname!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ===== 快捷分类入口 =====
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: SampleData.genres.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final g = SampleData.genres[index];
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          child: Text(g['name']!, style: const TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(height: 4),
                        Text(g['name']!, style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ===== 推荐歌单 =====
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text('推荐歌单', style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text('查看更多'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: SampleData.recommendPlaylists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final pl = SampleData.recommendPlaylists[index];
                    return _PlaylistCard(
                      name: pl['name'] as String,
                      playCount: pl['playCount'] as int,
                      index: index,
                      onTap: () {},
                    );
                  },
                ),
              ),
            ),
          ),

          // ===== 排行榜 =====
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text('排行榜', style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () { /* 查看全部排行榜 */ },
                    child: const Text('查看更多'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tl = SampleData.toplists[index];
                  return ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.colorScheme.primaryContainer,
                      ),
                      child: Center(
                        child: Text('${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index < 3 ? theme.colorScheme.primary : null,
                            fontSize: 16),
                        ),
                      ),
                    ),
                    title: Text(tl['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(tl['description'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                    trailing: const Icon(Icons.play_circle_outline_rounded),
                    onTap: () {},
                  );
                },
                childCount: SampleData.toplists.length,
              ),
            ),
          ),

          // ===== 登录引导 =====
          if (!auth.isLoggedIn)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.surfaceContainerHighest,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
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
                            Text('获取你的歌单、每日推荐',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.login_rounded, size: 18),
                        onPressed: () => context.push('/login'),
                        label: const Text('登录'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ===== 底部间距 =====
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String name;
  final int playCount;
  final int index;
  final VoidCallback onTap;

  static const List<Color> _gradients = [
    Colors.blue, Colors.purple, Colors.teal, Colors.orange,
    Colors.pink, Colors.indigo,
  ];

  const _PlaylistCard({
    required this.name,
    required this.playCount,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _gradients[index % _gradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${_formatCount(playCount)} 次播放',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int c) {
    if (c >= 10000) return '${(c / 10000).toStringAsFixed(1)}万';
    return c.toString();
  }
}
