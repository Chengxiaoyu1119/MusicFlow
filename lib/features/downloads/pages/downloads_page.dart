import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../plugin/download_provider.dart';
import '../../../plugin/download_service.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadManagerProvider);
    final manager = ref.watch(downloadManagerProvider.notifier);
    final completed = tasks.where((t) => t.state == DownloadState.completed).toList();
    final active = tasks.where((t) => t.state == DownloadState.downloading).toList();
    final failed = tasks.where((t) => t.state == DownloadState.failed).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载'),
        actions: [
          if (completed.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => manager.clearCompleted(),
              tooltip: '清空已完成',
            ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined, size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('暂无下载',
                    style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('从搜索结果下载歌曲',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader(title: 'Downloading (${active.length})'),
                  ...active.map((t) => _DownloadTile(task: t)),
                ],
                if (completed.isNotEmpty) ...[
                  _SectionHeader(title: 'Completed (${completed.length})'),
                  ...completed.map((t) => _DownloadTile(task: t)),
                ],
                if (failed.isNotEmpty) ...[
                  _SectionHeader(title: 'Failed (${failed.length})'),
                  ...failed.map((t) => _DownloadTile(task: t)),
                ],
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
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600)),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadTask task;
  const _DownloadTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _icon(task.state, theme),
        ),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          _subtitle(task),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: task.state == DownloadState.downloading
            ? SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: task.progress > 0 ? task.progress : null,
                ),
              )
            : task.state == DownloadState.completed
                ? IconButton(
                    icon: const Icon(Icons.folder_open_rounded, size: 20),
                    onPressed: () => _openFile(context, task.filePath),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () {},
                  ),
      ),
    );
  }

  Widget _icon(DownloadState state, ThemeData theme) {
    return Icon(
      state == DownloadState.downloading ? Icons.download_rounded
          : state == DownloadState.completed ? Icons.check_circle_rounded
          : Icons.error_outline_rounded,
      color: state == DownloadState.completed
          ? Colors.green
          : state == DownloadState.failed
              ? Colors.red
              : theme.colorScheme.primary,
      size: 22,
    );
  }

  String _subtitle(DownloadTask task) {
    switch (task.state) {
      case DownloadState.downloading:
        return 'Downloading... ${(task.progress * 100).toStringAsFixed(0)}%';
      case DownloadState.completed:
        return task.filePath?.split('/').last ?? '已完成';
      case DownloadState.failed:
        return task.error ?? '失败';
      default:
        return '';
    }
  }

  void _openFile(BuildContext context, String? path) async {
    if (path == null) return;
    try {
      await OpenFile.open(path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }
}
