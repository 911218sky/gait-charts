import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/dialogs/session_picker_sheet.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';

/// 影片播放頁面的搜尋工具列。
///
/// 提供 session 搜尋和瀏覽功能，會根據螢幕大小自動調整佈局。
class VideoToolbar extends StatelessWidget {
  const VideoToolbar({
    required this.controller,
    required this.onLoadSession,
    required this.onClear,
    required this.isMobile,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onLoadSession;
  final VoidCallback onClear;
  final bool isMobile;

  Future<void> _showSessionPicker(BuildContext context) async {
    final result = await SessionPickerDialog.showForVideo(context);
    if (result != null && context.mounted) {
      controller.text = result.sessionName;
      onLoadSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? _MobileToolbar(
            controller: controller,
            onLoadSession: onLoadSession,
            onClear: onClear,
            onShowPicker: () => _showSessionPicker(context),
          )
        : _DesktopToolbar(
            controller: controller,
            onLoadSession: onLoadSession,
            onClear: onClear,
            onShowPicker: () => _showSessionPicker(context),
          );
  }
}

/// 桌面版工具列。
class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.controller,
    required this.onLoadSession,
    required this.onClear,
    required this.onShowPicker,
  });

  final TextEditingController controller;
  final VoidCallback onLoadSession;
  final VoidCallback onClear;
  final VoidCallback onShowPicker;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, color: colors.onSurfaceVariant, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SessionAutocompleteField(
                      controller: controller,
                      labelText: '搜尋或輸入 Session 名稱...',
                      onSubmitted: (_) => onLoadSession(),
                      onSuggestionSelected: (_) => onLoadSession(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                        hintText: '搜尋或輸入 Session 名稱...',
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClear,
                    ),
                  IconButton(
                    onPressed: onLoadSession,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    tooltip: '載入',
                    color: colors.primary,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onShowPicker,
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: const Text('瀏覽'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 手機版工具列（更緊湊的垂直佈局）。
class _MobileToolbar extends StatelessWidget {
  const _MobileToolbar({
    required this.controller,
    required this.onLoadSession,
    required this.onClear,
    required this.onShowPicker,
  });

  final TextEditingController controller;
  final VoidCallback onLoadSession;
  final VoidCallback onClear;
  final VoidCallback onShowPicker;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 搜尋欄
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: context.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, color: colors.onSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: SessionAutocompleteField(
                  controller: controller,
                  labelText: 'Session 名稱...',
                  onSubmitted: (_) => onLoadSession(),
                  onSuggestionSelected: (_) => onLoadSession(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                    hintText: 'Session 名稱...',
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 按鈕列
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShowPicker,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('瀏覽 Sessions'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onLoadSession,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('載入'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
