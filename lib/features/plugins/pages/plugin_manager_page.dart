import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugin/api/plugin_model.dart';
import '../../../plugin/plugin_manager.dart';

class PluginManagerPage extends ConsumerWidget {
  const PluginManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(pluginManagerProvider);
    final manager = ref.watch(pluginManagerProvider.notifier);
    final theme = Theme.of(context);

    final builtinPlugins = plugins.where((p) => p.isBuiltin).toList();
    final userPlugins = plugins.where((p) => !p.isBuiltin).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('插件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showInstallDialog(context, manager),
            tooltip: '安装插件',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader(title: 'Built-in'),
          ...builtinPlugins.map((p) => _PluginCard(
            plugin: p,
            onToggle: () => manager.togglePlugin(p.id),
          )),

          _SectionHeader(title: 'Installed'),
          if (userPlugins.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.extension_off_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No plugins installed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showInstallDialog(context, manager),
                      child: const Text('从 URL 安装'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...userPlugins.map((p) => _PluginCard(
              plugin: p,
              onToggle: () => manager.togglePlugin(p.id),
              onRemove: () => manager.removePlugin(p.id),
            )),
          const SizedBox(height: 24),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('插件系统',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Plugins can extend your music sources. '
                  'Built-in plugins use the Netease Cloud Music API. '
                  'You can also install external JS plugins from any URL.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showInstallDialog(BuildContext context, PluginManager manager) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装插件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('输入插件 JS 文件的 URL'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://example.com/plugin.js',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link_rounded),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                manager.installFromUrl(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
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

class _PluginCard extends StatelessWidget {
  final PluginInfo plugin;
  final VoidCallback onToggle;
  final VoidCallback? onRemove;

  const _PluginCard({
    required this.plugin,
    required this.onToggle,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            plugin.isBuiltin ? Icons.music_note_rounded : Icons.extension_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(plugin.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'v${plugin.version} · ${plugin.isBuiltin ? "Built-in" : "External"}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: plugin.isEnabled,
              onChanged: (_) => onToggle(),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
