import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/platform/download/download_file.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/apk/domain/models/apk_artifact_platform.dart';
import 'package:gait_charts/features/apk/domain/models/apk_file.dart';
import 'package:gait_charts/features/apk/domain/utils/apk_artifact_classifier.dart';
import 'package:gait_charts/features/apk/domain/utils/apk_download_uri_resolver.dart';
import 'package:gait_charts/features/apk/presentation/providers/apk_providers.dart';

/// 登入頁與儀表板共用的「安裝包下載」卡片。
class ApkDownloadsCard extends ConsumerWidget {
  const ApkDownloadsCard({
    super.key,
    this.maxVisibleItems = 3,
    this.showViewAllAction = true,
    this.isFloating = false,
    this.useDarkTheme = false,
    this.transparent = false,
    this.forceShowAllPlatforms,
  });

  /// 限制顯示筆數（登入頁用較小，下載頁可給很大數字）。
  final int maxVisibleItems;

  /// 是否顯示「顯示全部」按鈕（登入頁建議開啟；下載頁通常不需要）。
  final bool showViewAllAction;

  /// 是否為懸浮模式（用於登入頁左側）：啟用時會使用毛玻璃背景與更深邃的視覺風格。
  final bool isFloating;

  /// 強制使用深色主題（白字），忽略 context theme。
  final bool useDarkTheme;

  /// 是否背景透明（不繪製外框與底色），用於嵌入其他深色容器時。
  final bool transparent;

  /// 強制顯示全部平台（例如：Dialog/完整下載頁）。
  final bool? forceShowAllPlatforms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final theme = context.theme;

    // 決定是否為深色模式呈現
    final isDark = useDarkTheme || context.isDark;

    // floating（登入頁左側）希望「跨平台」展示，因此預設取全部平台；
    // 下載頁/Dialog 也會透過 forceShowAllPlatforms 強制取全部平台。
    final asyncGrouped = (isFloating || forceShowAllPlatforms == true)
        ? ref.watch(apkDownloadsGroupedFilesAllPlatformsProvider)
        : ref.watch(apkDownloadsGroupedFilesProvider);

    Future<void> openDialog() async {
      await showDialog<void>(
        context: context,
        builder: (_) => const _ApkDownloadsDialog(),
      );
    }

    // 根據是否懸浮決定背景與邊框樣式
    BoxDecoration? decoration;
    if (!transparent) {
      decoration = isFloating
          ? BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.6)
                  : colors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : colors.outlineVariant,
              ),
            )
          : BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            );
    }

    final content = Padding(
      padding: transparent ? EdgeInsets.zero : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.install_desktop_rounded,
                  color: isDark ? Colors.white : colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '應用程式下載',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : colors.onSurface,
                      ),
                    ),
                    if (isFloating)
                      Text(
                        '提供 Windows / macOS / Linux / Android 版本',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isFloating)
                IconButton(
                  tooltip: '重新整理',
                  onPressed: () => ref.invalidate(apkFileListProvider),
                  icon: Icon(
                    Icons.refresh, 
                    size: 20,
                    color: isDark ? Colors.white70 : null,
                  ),
                ),
              if (showViewAllAction && !isFloating)
                TextButton(
                  onPressed: openDialog,
                  child: const Text('顯示全部'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            fit: FlexFit.loose,
            child: AsyncRequestView<Map<ApkArtifactPlatform, List<ApkFile>>>(
              requestId: kApkListRequestId,
              value: asyncGrouped,
              loadingLabel: '讀取中…',
              onRetry: () => ref.invalidate(apkFileListProvider),
              isEmpty: (data) => data.values.every((v) => v.isEmpty),
              emptyBuilder: (context) => _EmptyState(
                label: '暫無安裝包',
                hint: '請確認後端資料目錄',
                isDark: isDark,
              ),
              dataBuilder: (context, grouped) {
                final order = <ApkArtifactPlatform>[
                  ApkArtifactPlatform.android,
                  ApkArtifactPlatform.windows,
                  ApkArtifactPlatform.macos,
                  ApkArtifactPlatform.linux,
                  ApkArtifactPlatform.unknown,
                ];

                // flatten（保持平台順序）
                final flattened = <ApkFile>[];
                for (final p in order) {
                  final list = grouped[p];
                  if (list == null || list.isEmpty) continue;
                  flattened.addAll(list);
                }

                // 懸浮模式：維持單一列表，避免過於擁擠
                if (isFloating) {
                  // 需求：空間夠就顯示更多「平台」（每個平台只顯示最新一個檔案）
                  // 空間不夠則自動顯示更少平台（依序 4→3→2→1...）
                  final floatingOrder = <ApkArtifactPlatform>[
                    ApkArtifactPlatform.windows,
                    ApkArtifactPlatform.android,
                    ApkArtifactPlatform.macos,
                    ApkArtifactPlatform.linux,
                    ApkArtifactPlatform.unknown,
                  ];

                  final candidates = <ApkFile>[];
                  for (final p in floatingOrder) {
                    final list = grouped[p];
                    if (list == null || list.isEmpty) continue;
                    candidates.add(list.first); // 每個平台只取最新一筆
                  }

                  // fallback：若分類無法命中，至少顯示最新的前 N 筆
                  final fallback = flattened.isNotEmpty ? flattened : <ApkFile>[];

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 600),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 粗估每列高度：包含 row padding + margin + 內容
                        const rowExtent = 84.0;
                        final reserved = showViewAllAction ? 68.0 : 0.0;
                        final available = (constraints.maxHeight - reserved).clamp(0.0, double.infinity);

                        var slots = (available / rowExtent).floor();
                        if (slots < 1) slots = 1;

                        final source = candidates.isNotEmpty ? candidates : fallback;
                        if (source.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final take = slots > maxVisibleItems ? maxVisibleItems : slots;
                        final visible = source.take(take).toList(growable: false);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final file in visible)
                              _ApkFileRow(
                                file: file,
                                isProminent: true,
                                isDark: isDark,
                              ),
                            if (showViewAllAction)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: openDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          isDark ? Colors.white : colors.onSurface,
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : colors.outlineVariant,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('查看全部歷史版本'),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  );
                }

                // 一般模式：依平台分區顯示
                final groups =
                    <({ApkArtifactPlatform platform, List<ApkFile> files})>[];
                for (final p in order) {
                  final list = grouped[p];
                  if (list == null || list.isEmpty) continue;
                  groups.add((platform: p, files: list));
                }

                // 限制顯示總筆數（維持舊行為）
                var remaining = maxVisibleItems;
                final limited =
                    <({ApkArtifactPlatform platform, List<ApkFile> files})>[];
                for (final g in groups) {
                  if (remaining <= 0) break;
                  final take =
                      g.files.length <= remaining ? g.files.length : remaining;
                  limited.add((
                    platform: g.platform,
                    files: g.files.take(take).toList(growable: false),
                  ));
                  remaining -= take;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final g in limited) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, top: 4),
                        child: Text(
                          g.platform.displayLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final file in g.files)
                        _ApkFileRow(
                          file: file,
                          isProminent: false,
                          isDark: isDark,
                        ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
          ),
          ),
        ],
      ),
    );

    if (isFloating) {
      // 懸浮模式：加上毛玻璃與陰影
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: decoration,
            child: content,
          ),
        ),
      );
    }

    return Container(
      decoration: decoration,
      child: content,
    );
  }
}

class _ApkFileRow extends ConsumerWidget {
  const _ApkFileRow({
    required this.file,
    this.isProminent = false,
    this.isDark = false,
  });

  final ApkFile file;
  final bool isProminent;
  final bool isDark;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final digits = unit == 0 ? 0 : (size >= 100 ? 0 : (size >= 10 ? 1 : 2));
    return '${size.toStringAsFixed(digits)} ${units[unit]}';
  }

  String _formatTime(DateTime utc) {
    return DateFormat('yyyy-MM-dd HH:mm').format(utc.toLocal());
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final config = ref.read(appConfigProvider);
    final base = Uri.parse(config.baseUrl);
    final uri = resolveApkDownloadUri(base: base, file: file);

    final ok = await downloadFile(uri: uri, filename: file.name);
    if (ok) return;
    if (!context.mounted) return;
    DashboardToast.show(
      context,
      message: '無法開啟下載連結：$uri',
      variant: DashboardToastVariant.danger,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final theme = context.theme;
    
    final textColor = isDark ? Colors.white : colors.onSurface;
    final subTextColor = isDark ? Colors.white70 : colors.onSurfaceVariant;

    final platform = classifyApkArtifactPlatform(file.name);

    IconData fileIcon;
    String typeLabel;
    Color typeColor;

    switch (platform) {
      case ApkArtifactPlatform.windows:
        fileIcon = Icons.desktop_windows_rounded;
        typeLabel = 'WINDOWS';
        typeColor = isDark ? const Color(0xFF64B5F6) : Colors.blueAccent;
      case ApkArtifactPlatform.android:
        fileIcon = Icons.android_rounded;
        typeLabel = 'ANDROID';
        typeColor = isDark ? const Color(0xFF81C784) : Colors.greenAccent;
      case ApkArtifactPlatform.macos:
        fileIcon = Icons.laptop_mac_rounded;
        typeLabel = 'MAC';
        typeColor = isDark ? const Color(0xFFB39DDB) : Colors.deepPurpleAccent;
      case ApkArtifactPlatform.linux:
        fileIcon = Icons.terminal_rounded;
        typeLabel = 'LINUX';
        typeColor = isDark ? const Color(0xFFFFCC80) : Colors.orangeAccent;
      case ApkArtifactPlatform.unknown:
        fileIcon = Icons.insert_drive_file_rounded;
        typeLabel = 'FILE';
        typeColor = isDark ? Colors.white60 : Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isProminent ? 16 : 12),
      decoration: BoxDecoration(
        color: isDark
            ? (isProminent ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05))
            : colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // 檔案 Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black26 
                  : colors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(fileIcon, size: 20, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: typeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        file.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatBytes(file.sizeBytes)} · ${_formatTime(file.modifiedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: () => _download(context, ref),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white : colors.primary,
              foregroundColor: isDark ? Colors.black : colors.onPrimary,
              padding: EdgeInsets.all(isProminent ? 12 : 8),
            ),
            icon: Icon(
              Icons.download_rounded, 
              size: isProminent ? 20 : 18,
            ),
            tooltip: '下載',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.label, 
    required this.hint,
    this.isDark = false,
  });

  final String label;
  final String hint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final theme = context.theme;
    
    final textColor = isDark ? Colors.white : colors.onSurface;
    final subTextColor = isDark ? Colors.white70 : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : colors.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: isDark 
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined, 
            size: 32, 
            color: isDark ? Colors.white30 : colors.outline,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ApkDownloadsDialog extends ConsumerWidget {

  const _ApkDownloadsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : colors.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : colors.shadow).withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '應用程式下載',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '關閉',
                    onPressed: () => context.navigator.pop(),
                    icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: ApkDownloadsCard(
                    maxVisibleItems: 999999,
                    showViewAllAction: false,
                    useDarkTheme: isDark, // 淺色模式跟隨 theme
                    transparent: true,  // 背景透明（由 Dialog 提供背景）
                    forceShowAllPlatforms: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


