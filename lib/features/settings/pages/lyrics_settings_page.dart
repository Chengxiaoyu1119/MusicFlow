import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../player/services/lyrics_settings_service.dart';

class LyricsSettingsPage extends ConsumerWidget {
  const LyricsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(lyricsSettingsProvider);
    final notifier = ref.watch(lyricsSettingsProvider.notifier);
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('桌面歌词')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preview
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: settings.backgroundOpacity),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '示例歌词文字',
                style: TextStyle(
                  fontSize: settings.fontSize.clamp(16, 36).toDouble(),
                  color: settings.activeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('上一句歌词',
              style: TextStyle(
                fontSize: (settings.fontSize.clamp(12, 24)).toDouble(),
                color: settings.textColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Font size
          Text('字体大小: ${settings.fontSize.toStringAsFixed(0)}',
            style: theme.textTheme.titleSmall),
          Slider(
            value: settings.fontSize,
            min: 14, max: 72,
            divisions: 29,
            onChanged: (v) => notifier.setFontSize(v),
          ),
          const SizedBox(height: 16),

          // Active color
          Text('当前行颜色',
            style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              Colors.cyan, Colors.blue, Colors.purple, Colors.pink,
              Colors.red, Colors.orange, Colors.yellow, Colors.green,
              Colors.white, Colors.grey,
            ].map((color) {
              final isSelected = settings.activeColor.value == color.value;
              return GestureDetector(
                onTap: () => notifier.setActiveColor(color),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Text color
          Text('文字颜色',
            style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              Colors.white, Colors.grey.shade300, Colors.blue.shade200,
              Colors.yellow.shade200,
            ].map((color) {
              final isSelected = settings.textColor.value == color.value;
              return GestureDetector(
                onTap: () => notifier.setTextColor(color),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: accent, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Background opacity
          Text('背景不透明度: ${(settings.backgroundOpacity * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.titleSmall),
          Slider(
            value: settings.backgroundOpacity,
            min: 0.0, max: 1.0,
            divisions: 10,
            onChanged: (v) => notifier.setBackgroundOpacity(v),
          ),
          const SizedBox(height: 16),

          // Pause transparent toggle
          SwitchListTile(
            title: const Text('暂停时提高透明度'),
            subtitle: const Text('暂停时歌词更透明'),
            value: settings.pauseTransparent,
            onChanged: (v) => notifier.setPauseTransparent(v),
          ),
        ],
      ),
    );
  }
}
