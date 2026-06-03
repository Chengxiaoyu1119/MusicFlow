import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'audio/audio_provider.dart';
import 'core/constants/platform_helper.dart';
import 'core/theme/app_theme.dart';
import 'data/database/hive_service.dart';
import 'data/repository/stats_service.dart';
import 'features/desktop/services/global_shortcuts_service.dart';
import 'features/desktop/services/http_api_service.dart';
import 'shared/widgets/mini_player.dart';
import 'features/library/pages/library_page.dart';
import 'features/player/pages/player_page.dart';
import 'features/playlist/pages/playlist_detail_page.dart';
import 'features/search/pages/search_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/settings/pages/lyrics_settings_page.dart';
import 'features/downloads/pages/downloads_page.dart';
import 'features/equalizer/pages/equalizer_page.dart';
import 'features/plugins/pages/plugin_manager_page.dart';
import 'features/stats/pages/stats_page.dart';
import 'features/player/widgets/desktop_lyrics_overlay.dart';

class MusicPlayerApp extends ConsumerStatefulWidget {
  const MusicPlayerApp({super.key});

  @override
  ConsumerState<MusicPlayerApp> createState() => _MusicPlayerAppState();
}

class _MusicPlayerAppState extends ConsumerState<MusicPlayerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final handler = ref.read(audioHandlerProvider);
      await handler.init();

      // Initialize desktop services (if supported)
      if (GlobalShortcutsService.isSupported) {
        await GlobalShortcutsService().init(handler);
      }
      if (PlatformHelper.isDesktop) {
        final apiService = HttpApiService(handler);
        await apiService.start();
      }
    });
  }

  // Track play stats via build method (ref.listen only allowed in build)
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Track play stats when music changes (ref.listen only valid in build)
    ref.listen(currentMusicProvider, (prev, next) {
      final prevMusic = prev?.valueOrNull;
      final nextMusic = next.valueOrNull;
      final prevId = prevMusic == null ? '' : prevMusic.id;
      final nextId = nextMusic == null ? '' : nextMusic.id;
      if (prevId != nextId) {
        final statsService = ref.read(statsServiceProvider);
        if (prevMusic != null) statsService.trackStopped();
        if (nextMusic != null) statsService.trackStarted(nextMusic);
      }
    });

    return MaterialApp.router(
      title: 'MusicFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => _AppShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const LibraryPage(),
              ),
            ),
            GoRoute(
              path: '/search',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SearchPage(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SettingsPage(),
              ),
            ),
            GoRoute(
              path: '/lyrics-settings',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const LyricsSettingsPage(),
              ),
            ),
            GoRoute(
              path: '/plugins',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const PluginManagerPage(),
              ),
            ),
            GoRoute(
              path: '/downloads',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DownloadsPage(),
              ),
            ),
            GoRoute(
              path: '/equalizer',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const EqualizerPage(),
              ),
            ),
            GoRoute(
              path: '/stats',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const StatsPage(),
              ),
            ),
            GoRoute(
              path: '/lyrics-overlay',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DesktopLyricsOverlay(),
              ),
            ),
            GoRoute(
              path: '/playlist/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return PlaylistDetailPage(playlistId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/player',
          builder: (context, state) => const PlayerPage(),
        ),
      ],
    );
  }

}

class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMusic = ref.watch(currentMusicProvider).valueOrNull != null;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          if (hasMusic) const MiniPlayer(),
          const _BottomNavBar(),
        ],
      ),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/search')) currentIndex = 1;
    if (location.startsWith('/plugins')) currentIndex = 2;
    if (location.startsWith('/settings')) currentIndex = 3;

    return BottomAppBar(
      height: 64,
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.library_music_rounded,
                label: '音乐库',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: '搜索',
                isSelected: currentIndex == 1,
                onTap: () => context.go('/search'),
              ),
              _NavItem(
                icon: Icons.extension_rounded,
                label: '插件',
                isSelected: currentIndex == 2,
                onTap: () => context.go('/plugins'),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: '设置',
                isSelected: currentIndex == 3,
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
