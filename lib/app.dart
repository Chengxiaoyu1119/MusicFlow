import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'audio/audio_provider.dart';
import 'core/constants/platform_helper.dart';
import 'core/theme/app_theme.dart';
import 'data/database/hive_service.dart';
import 'data/repository/stats_service.dart';
import 'features/desktop/services/http_api_service.dart';
import 'shared/widgets/mini_player.dart';
import 'features/library/pages/library_page.dart';
import 'features/player/pages/player_page.dart';
import 'features/playlist/pages/playlist_detail_page.dart';
import 'features/search/pages/search_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'features/settings/pages/lyrics_settings_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/playlist/pages/user_playlists_page.dart';
import 'features/downloads/pages/downloads_page.dart';
import 'features/equalizer/pages/equalizer_page.dart';
import 'features/discover/pages/discover_page.dart';
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
      if (PlatformHelper.isDesktop) {
        // Only start HTTP API, skip other services for now
        try {
          final apiService = HttpApiService(handler);
          await apiService.start();
        } catch (_) {}
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
                child: const DiscoverPage(),
              ),
            ),
            GoRoute(
              path: '/library',
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
              path: '/login',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const LoginPage(),
              ),
            ),
            GoRoute(
              path: '/user-playlists',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const UserPlaylistsPage(),
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
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PlayerPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                )),
                child: child,
              );
            },
          ),
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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return isDesktop ? _DesktopShell(child: child) : _MobileShell(child: child, hasMusic: hasMusic, theme: theme);
  }
}

class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/library')) currentIndex = 1;
    if (location.startsWith('/search')) currentIndex = 2;
    if (location.startsWith('/plugins')) currentIndex = 3;
    if (location.startsWith('/settings')) currentIndex = 4;

    final items = [
      (icon: Icons.explore_rounded, label: '发现', route: '/'),
      (icon: Icons.library_music_rounded, label: '音乐库', route: '/library'),
      (icon: Icons.search_rounded, label: '搜索', route: '/search'),
      (icon: Icons.extension_rounded, label: '插件', route: '/plugins'),
      (icon: Icons.settings_rounded, label: '设置', route: '/settings'),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Side navigation rail
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Logo
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.music_note_rounded,
                      color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(height: 24),
                  // Navigation items
                  ...List.generate(items.length, (i) {
                    final isSelected = i == currentIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Tooltip(
                        message: items[i].label,
                        child: GestureDetector(
                          onTap: () => context.go(items[i].route),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(items[i].icon,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                  size: 22),
                                const SizedBox(height: 4),
                                Text(items[i].label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Mini player on desktop (compact)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 44, height: 44,
                      child: Consumer(
                        builder: (context, watchRef, _) {
                          final music = watchRef.watch(currentMusicProvider).valueOrNull;
                          return GestureDetector(
                            onTap: () => context.push('/player'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: music != null
                                  ? (music.artworkUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: music.artworkUrl!, fit: BoxFit.cover))
                                      : Icon(Icons.music_note_rounded, size: 20))
                                  : Icon(Icons.music_note_outlined, size: 20,
                                      color: theme.colorScheme.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  final bool hasMusic;
  final ThemeData theme;
  const _MobileShell({required this.child, required this.hasMusic, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 64 + (hasMusic ? 64 : 0)),
          child: child,
        ),
        if (hasMusic)
          Positioned(bottom: 64, left: 0, right: 0, child: const MiniPlayer()),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                  border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
                ),
                child: SafeArea(top: false, child: _BottomNavContent()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomNavContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final theme = Theme.of(context);

    int currentIndex = 0;
    if (location.startsWith('/library')) currentIndex = 1;
    if (location.startsWith('/search')) currentIndex = 2;
    if (location.startsWith('/plugins')) currentIndex = 3;
    if (location.startsWith('/settings')) currentIndex = 4;

    final items = [
      (icon: Icons.explore_rounded, label: '发现', route: '/'),
      (icon: Icons.library_music_rounded, label: '音乐库', route: '/library'),
      (icon: Icons.search_rounded, label: '搜索', route: '/search'),
      (icon: Icons.extension_rounded, label: '插件', route: '/plugins'),
      (icon: Icons.settings_rounded, label: '设置', route: '/settings'),
    ];

    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isSelected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => context.go(item.route),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: isSelected ? 0 : 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(item.label,
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
