import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../player/services/equalizer_service.dart';

class EqualizerPage extends ConsumerWidget {
  const EqualizerPage({super.key});

  static const List<String> bandLabels = [
    '60Hz', '150Hz', '400Hz', '1kHz', '2.4kHz',
    '6kHz', '10kHz', '15kHz', '20kHz', '25kHz',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final eqService = ref.watch(equalizerProvider.notifier);
    final theme = Theme.of(context);
    final accent = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('均衡器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showPresets(context, eqService, eqState),
            tooltip: '预设',
          ),
        ],
      ),
      body: Column(
        children: [
          // Enable toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('启用均衡器',
                  style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: eqState.isEnabled,
                  onChanged: (_) => eqService.toggle(),
                ),
              ],
            ),
          ),

          if (!EqualizerService.isSupported)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18,
                    color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Native EQ is only supported on Android. '
                      'The UI is available for preview on all platforms.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Preset name
          Text(eqState.presetName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: eqState.isEnabled ? accent : null,
            ),
          ),

          const SizedBox(height: 24),

          // Band sliders
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(10, (i) {
                  return _BandSlider(
                    label: bandLabels[i],
                    value: eqState.gains.length > i ? eqState.gains[i] : 0,
                    enabled: eqState.isEnabled,
                    onChanged: (v) => eqService.updateBand(i, v),
                  );
                }),
              ),
            ),
          ),

          // Reset button
          Padding(
            padding: const EdgeInsets.all(24),
            child: OutlinedButton.icon(
              onPressed: eqState.isEnabled ? () => eqService.reset() : null,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('重置为平坦'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPresets(BuildContext context, EqualizerService service, EqualizerState state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('预设',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: EqualizerService.presets.map((preset) {
                  final isActive = state.presetName == preset.name;
                  return ChoiceChip(
                    label: Text(preset.name),
                    selected: isActive,
                    onSelected: (_) {
                      service.applyPreset(preset);
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
}

class _BandSlider extends StatelessWidget {
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Value label
            Text('${value.toStringAsFixed(0)}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: enabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            // Vertical slider
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: value,
                  min: -12,
                  max: 12,
                  divisions: 24,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
            // Band label
            Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
