import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/config/app_config.dart';
import 'package:gait_charts/core/providers/app_config_provider.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';

/// 提供使用者在 UI 內調整後端連線設定（baseUrl）。
class AppConnectionSettingsPanel extends ConsumerStatefulWidget {
  const AppConnectionSettingsPanel({super.key});

  @override
  ConsumerState<AppConnectionSettingsPanel> createState() =>
      _AppConnectionSettingsPanelState();
}

class _AppConnectionSettingsPanelState
    extends ConsumerState<AppConnectionSettingsPanel> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _saving = false;
  String? _lastSyncedBaseUrl;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      await ref.read(appConfigAsyncProvider.notifier).setBaseUrl(_controller.text);
      if (!mounted) return;
      context.navigator.pop();
      DashboardToast.show(
        context,
        message: '已更新後端連線設定',
        variant: DashboardToastVariant.success,
      );
    } on FormatException catch (e) {
      setState(() => _errorText = e.message);
    } catch (_) {
      setState(() => _errorText = '儲存失敗，請稍後再試。');
      if (mounted) {
        DashboardToast.show(
          context,
          message: '儲存失敗，請稍後再試。',
          variant: DashboardToastVariant.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await ref.read(appConfigAsyncProvider.notifier).resetToDefault();
      _controller.text = defaultAppConfig.baseUrl;
      _lastSyncedBaseUrl = defaultAppConfig.baseUrl;
      if (!mounted) return;
      DashboardToast.show(
        context,
        message: '已重置為預設 baseUrl',
        variant: DashboardToastVariant.info,
      );
    } catch (_) {
      setState(() => _errorText = '重置失敗，請稍後再試。');
      if (mounted) {
        DashboardToast.show(
          context,
          message: '重置失敗，請稍後再試。',
          variant: DashboardToastVariant.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final config = ref.watch(appConfigProvider);

    // 讓輸入框預設顯示「目前生效」的 baseUrl。
    // 若使用者尚未修改（仍維持上次同步的值），則在 baseUrl 變動時自動跟著更新。
    if (_lastSyncedBaseUrl == null) {
      _lastSyncedBaseUrl = config.baseUrl;
      _controller.text = config.baseUrl;
    } else if (_controller.text == _lastSyncedBaseUrl &&
        config.baseUrl != _lastSyncedBaseUrl) {
      _lastSyncedBaseUrl = config.baseUrl;
      _controller.text = config.baseUrl;
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_ethernet, size: 20, color: colors.onSurface),
                const SizedBox(width: 10),
                Text(
                  '後端連線設定',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  onPressed: _saving ? null : () => context.navigator.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: '關閉',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '修改後會立即套用到所有 API 呼叫（Dio 會重建）。建議輸入包含版本路徑，例如新版 /api/v1（或舊版 /v1）。',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.85),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: 'baseUrl',
                hintText: defaultAppConfig.baseUrl,
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Text(
              '目前生效：${config.baseUrl}',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _saving ? null : _reset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重置預設'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '儲存中…' : '儲存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


