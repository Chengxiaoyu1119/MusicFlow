import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../audio/audio_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/database/hive_service.dart';
import '../../player/services/sleep_timer_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader(title: '播放'),
          _SettingsTile(
            icon: Icons.volume_up_rounded,
            title: 'Volume',
            trailing: SizedBox(
              width: 160,
              child: Slider(
                value: handler.volume,
                onChanged: (v) => handler.setVolume(v),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.speed_rounded,
            title: 'Playback Speed',
            trailing: DropdownButton<double>(
              value: handler.speed,
              underline: const SizedBox(),
              items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s}x'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) handler.setSpeed(v);
              },
            ),
          ),
          const Divider(),

          // Account
          _SectionHeader(title: '账号'),
          _SettingsTile(
            icon: Icons.person_rounded,
            title: '网易云音乐',
            subtitle: '登录后获取我的歌单',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/login'),
          ),
          _SettingsTile(
            icon: Icons.playlist_play_rounded,
            title: '我的歌单',
            subtitle: '查看并播放网易云歌单',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/user-playlists'),
          ),
          const Divider(),

          // Display
          _SectionHeader(title: '显示'),
          _SettingsTile(
            icon: Icons.palette_rounded,
            title: 'Theme',
            subtitle: _themeModeLabel(themeMode),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemeDialog(context, ref),
          ),
          _SettingsTile(
            icon: Icons.color_lens_rounded,
            title: '强调色',
            subtitle: 'Customize app colors',
            trailing: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            onTap: () => _showAccentColorDialog(context, ref),
          ),
          const Divider(),

          // Tools
          _SectionHeader(title: '工具'),
          _SettingsTile(
            icon: Icons.timer_rounded,
            title: '睡眠定时器',
            subtitle: 'Auto-pause playback',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showSleepTimerDialog(context, ref),
          ),
          _SettingsTile(
            icon: Icons.tune_rounded,
            title: 'Equalizer',
            subtitle: 'Adjust frequency bands',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/equalizer'),
          ),
          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Downloads',
            subtitle: 'Manage downloaded songs',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/downloads'),
          ),
          _SettingsTile(
            icon: Icons.bar_chart_rounded,
            title: 'Statistics',
            subtitle: 'Listening stats and top tracks',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/stats'),
          ),
          _SettingsTile(
            icon: Icons.lyrics_outlined,
            title: 'Desktop Lyrics',
            subtitle: 'Font, colors, opacity settings',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/lyrics-settings'),
          ),
          _SettingsTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Crossfade',
            subtitle: 'Crossfade between tracks (coming soon)',
            trailing: Switch(
              value: false,
              onChanged: (_) {},
            ),
          ),
          const Divider(),

          // Storage
          _SectionHeader(title: '存储'),
          _SettingsTile(
            icon: Icons.folder_rounded,
            title: 'Music Library Path',
            subtitle: 'Import music from folders',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickMusicDirectory(context),
          ),
          _SettingsTile(
            icon: Icons.cleaning_services_rounded,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () => _clearCache(context, ref),
          ),
          const Divider(),

          // About
          _SectionHeader(title: '关于'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: AppConstants.appVersion,
          ),
          _SettingsTile(
            icon: Icons.code_rounded,
            title: 'Open Source',
            subtitle: 'Built with Flutter & love',
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => '浅色',
      ThemeMode.dark => '深色',
      ThemeMode.system => '跟随系统',
    };
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('选择主题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...ThemeMode.values.map((mode) {
                final icon = switch (mode) {
                  ThemeMode.light => Icons.light_mode_rounded,
                  ThemeMode.dark => Icons.dark_mode_rounded,
                  ThemeMode.system => Icons.settings_brightness_rounded,
                };
                return ListTile(
                  leading: Icon(icon),
                  title: Text(_themeModeLabel(mode)),
                  trailing: current == mode ? const Icon(Icons.check_rounded) : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setTheme(mode);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('强调色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: accentColors.map((color) {
                  final isSelected = ref.watch(accentColorProvider) == color;
                  return GestureDetector(
                    onTap: () {
                      ref.read(accentColorProvider.notifier).setColor(color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, WidgetRef ref) {
    final timerService = ref.read(sleepTimerProvider.notifier);
    final state = ref.read(sleepTimerProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('睡眠定时器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('到达设定时间后自动暂停播放',
                style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),

              if (state.isActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('运行中: ${timerService.formattedRemaining}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          timerService.cancel();
                          Navigator.pop(context);
                        },
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SleepTimerService.presetMinutes.map((minutes) {
                  return ActionChip(
                    label: Text('$minutes 分钟'),
                    onPressed: () {
                      timerService.start(Duration(minutes: minutes));
                      timerService.savePreset(Duration(minutes: minutes));
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMusicDirectory(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已选择: $result')),
      );
    }
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(hiveStorageProvider);
    await storage.clearCache();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存已清除')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
    );
  }
}
