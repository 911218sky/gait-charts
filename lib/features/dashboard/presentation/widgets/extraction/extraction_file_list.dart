import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

/// Bag 檔案「來源」選擇卡片（伺服器 / 本機）。
class BagSourceCard extends StatelessWidget {
  const BagSourceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final borderColor = context.dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          // 用 onSurface 的極淡透明度，確保淺/深色都有一致的「可點擊區域」提示。
          color: colors.onSurface.withValues(alpha: isDark ? 0.03 : 0.02),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: onTap == null
                  ? colors.onSurfaceVariant.withValues(alpha: 0.55)
                  : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onTap == null
                          ? colors.onSurface.withValues(alpha: 0.6)
                          : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: onTap == null
                          ? colors.onSurfaceVariant.withValues(alpha: 0.6)
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 已選擇的檔案列表
class FileExtractionList extends StatelessWidget {
  const FileExtractionList({
    required this.isProcessing,
    required this.onRemove,
    required this.onRetry,
    super.key,
    this.onSessionNameChanged,
  });

  final bool isProcessing;
  final void Function(String key) onRemove;
  final void Function(String key) onRetry;
  final void Function(String key, String value)? onSessionNameChanged;

  @override
  Widget build(BuildContext context) {
    // 這個 widget 改由子列自行 watch provider（避免每次進度更新都整串 rebuild）。
    // 這裡只保留純 UI shell。
    final accents = DashboardAccentColors.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          const _FileExtractionListHeader(),
          _FileExtractionListBody(
            isProcessing: isProcessing,
            onRemove: onRemove,
            onRetry: onRetry,
            accents: accents,
            onSessionNameChanged: onSessionNameChanged,
          ),
        ],
      ),
    );
  }
}

class _FileExtractionListHeader extends ConsumerWidget {
  const _FileExtractionListHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final failedCount = ref.watch(
      batchExtractionControllerProvider.select((s) => s.failedCount),
    );
    if (failedCount <= 0) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(batchExtractionControllerProvider.notifier);
    final config = ref.read(extractConfigProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '有 $failedCount 筆失敗可重試',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => notifier.retryFailed(config: config),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('全部重試（失敗）'),
          ),
        ],
      ),
    );
  }
}

class _FileExtractionListBody extends ConsumerWidget {
  const _FileExtractionListBody({
    required this.isProcessing,
    required this.onRemove,
    required this.onRetry,
    required this.accents,
    this.onSessionNameChanged,
  });

  final bool isProcessing;
  final void Function(String key) onRemove;
  final void Function(String key) onRetry;
  final DashboardAccentColors accents;
  final void Function(String key, String value)? onSessionNameChanged;

  int _keysSignature(List<FileExtractionItem> items) {
    return Object.hashAll(items.map((it) => it.key));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只在「新增/刪除檔案（bagPath 變動）」時重建整個列表。
    // 進度/狀態更新只會重建對應列（見 _FileExtractionListRow）。
    ref.watch(
      batchExtractionControllerProvider.select(
        (s) => _keysSignature(s.items),
      ),
    );
    final keys = ref
        .read(batchExtractionControllerProvider)
        .items
        .map((it) => it.key)
        .toList(growable: false);

    return Column(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: context.dividerColor,
            ),
          _FileExtractionListRow(
            itemKey: keys[i],
            isProcessing: isProcessing,
            onRemove: onRemove,
            onRetry: onRetry,
            accents: accents,
            onSessionNameChanged: onSessionNameChanged,
          ),
        ],
      ],
    );
  }
}

class _FileExtractionListRow extends ConsumerWidget {
  const _FileExtractionListRow({
    required this.itemKey,
    required this.isProcessing,
    required this.onRemove,
    required this.onRetry,
    required this.accents,
    this.onSessionNameChanged,
  });

  final String itemKey;
  final bool isProcessing;
  final void Function(String key) onRemove;
  final void Function(String key) onRetry;
  final DashboardAccentColors accents;
  final void Function(String key, String value)? onSessionNameChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      batchExtractionItemsByKeyProvider.select((map) => map[itemKey]),
    );
    if (item == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: FileExtractionListItem(
        key: ValueKey(item.key),
        item: item,
        isProcessing: isProcessing,
        onRemove: () => onRemove(item.key),
        onRetry: () => onRetry(item.key),
        accents: accents,
        onSessionNameChanged: (value) =>
            onSessionNameChanged?.call(item.key, value),
      ),
    );
  }
}

/// 單一檔案列表項目
class FileExtractionListItem extends StatefulWidget {
  const FileExtractionListItem({
    required this.item,
    required this.isProcessing,
    required this.onRemove,
    required this.onRetry,
    super.key,
    this.accents,
    this.onSessionNameChanged,
  });

  final FileExtractionItem item;
  final bool isProcessing;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final DashboardAccentColors? accents;
  final ValueChanged<String>? onSessionNameChanged;

  @override
  State<FileExtractionListItem> createState() => _FileExtractionListItemState();
}

class _FileExtractionListItemState extends State<FileExtractionListItem> {
  late final TextEditingController _controller;

  bool get _isEditable =>
      !widget.isProcessing &&
      widget.item.status == FileExtractionStatus.pending;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.sessionName ?? widget.item.displayName,
    );
  }

  @override
  void didUpdateWidget(covariant FileExtractionListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.item.sessionName ?? widget.item.displayName;
    if (nextValue != _controller.text) {
      _controller.text = nextValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatusIcon(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.displayName,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.displayPath,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _controller,
                    enabled: _isEditable,
                    onChanged: widget.onSessionNameChanged,
                    decoration: InputDecoration(
                      labelText: 'session_name',
                      hintText: '自訂或使用預設檔名',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      helperText: '預設以檔名命名，可逐一覆寫',
                      labelStyle: TextStyle(
                        color: _isEditable
                            ? colors.onSurfaceVariant
                            : colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (widget.item.status == FileExtractionStatus.failed &&
                    widget.item.error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.item.error!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: widget.accents?.danger ?? Colors.red,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusLabel(context),
          if (widget.item.status == FileExtractionStatus.failed) ...[
            const SizedBox(width: 8),
            AppTooltip(
              message: '重新嘗試',
              child: IconButton(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                style: IconButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (!widget.isProcessing &&
              widget.item.status == FileExtractionStatus.pending) ...[
            const SizedBox(width: 8),
            AppTooltip(
              message: '移除',
              child: IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close, size: 18),
                style: IconButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final colors = context.colorScheme;
    final muted = colors.onSurfaceVariant.withValues(alpha: 0.75);
    switch (widget.item.status) {
      case FileExtractionStatus.pending:
        return Icon(
          Icons.schedule,
          size: 20,
          color: muted,
        );
      case FileExtractionStatus.running:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case FileExtractionStatus.success:
        return Icon(
          Icons.check_circle,
          size: 20,
          color: widget.accents?.success ?? Colors.green,
        );
      case FileExtractionStatus.failed:
        return Icon(
          Icons.error,
          size: 20,
          color: widget.accents?.danger ?? Colors.red,
        );
    }
  }

  Widget _buildStatusLabel(BuildContext context) {
    final colors = context.colorScheme;
    final (label, color) = switch (widget.item.status) {
      FileExtractionStatus.pending => ('等待中', colors.onSurfaceVariant),
      FileExtractionStatus.running => ('處理中', colors.primary),
      FileExtractionStatus.success => (
        '完成',
        widget.accents?.success ?? Colors.green,
      ),
      FileExtractionStatus.failed => (
        '失敗',
        widget.accents?.danger ?? Colors.red,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

