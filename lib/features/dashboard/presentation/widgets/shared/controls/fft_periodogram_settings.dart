import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'fft_settings/widgets/widgets.dart';

/// FFT / periodogram 進階參數控制面板。
///
/// - 這些參數會直接映射到後端 `fft_params` request 欄位。
/// - 預設值需與後端一致，避免 UI 看起來像「改了」但其實只是回到預設。
class FftPeriodogramSettings extends StatefulWidget {
  const FftPeriodogramSettings({
    required this.params,
    required this.onChanged,
    super.key,
    this.title = 'FFT 進階設定',
    this.subtitle = 'window / detrend / scaling / nfft / zero-padding / DC',
  });

  final FftPeriodogramParams params;
  final ValueChanged<FftPeriodogramParams> onChanged;
  final String title;
  final String subtitle;

  static const _windowOptions = <String>[
    'hann',
    'hamming',
    'blackman',
    'boxcar',
    'bartlett',
    'flattop',
  ];

  static const _nfftOptions = <int>[128, 256, 512, 1024, 2048, 4096, 8192];

  @override
  State<FftPeriodogramSettings> createState() => _FftPeriodogramSettingsState();
}

class _FftPeriodogramSettingsState extends State<FftPeriodogramSettings> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final accent = DashboardAccentColors.of(context);

    Future<void> openHelpDialog() async {
      return showDialog<void>(
        context: context,
        builder: (context) => const FftPeriodogramHelpDialog(),
      );
    }

    final windowOptions = List<String>.from(FftPeriodogramSettings._windowOptions);
    if (widget.params.window.trim().isNotEmpty &&
        !windowOptions.contains(widget.params.window)) {
      windowOptions.insert(0, widget.params.window);
    }
    final nfftOptions = List<int>.from(FftPeriodogramSettings._nfftOptions);
    if (widget.params.minNfft > 0 &&
        !nfftOptions.contains(widget.params.minNfft)) {
      nfftOptions.insert(0, widget.params.minNfft);
    }
    final resolvedWindow = windowOptions.firstWhere(
      (value) => value == widget.params.window,
      orElse: () => windowOptions.first,
    );
    final resolvedMinNfft = nfftOptions.firstWhere(
      (value) => value == widget.params.minNfft,
      orElse: () => nfftOptions.firstWhere(
        (value) => value == 512,
        orElse: () => nfftOptions.first,
      ),
    );

    final borderColor = colors.onSurface.withValues(alpha: 0.14);
    final tileBg = colors.onSurface.withValues(alpha: 0.02);

    return ExpansionTile(
      onExpansionChanged: (value) => setState(() => _expanded = value),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: tileBg,
      collapsedBackgroundColor: tileBg,
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      iconColor: colors.onSurface.withValues(alpha: 0.86),
      collapsedIconColor: colors.onSurface.withValues(alpha: 0.86),
      trailing: ExpandHintTrailing(
        isExpanded: _expanded,
        borderColor: borderColor,
        labelColor: colors.onSurface.withValues(alpha: 0.82),
      ),
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          IconButton(
            tooltip: '完整說明',
            onPressed: openHelpDialog,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.65),
            ),
          ),
          if (!_expanded) ...[
            const SizedBox(height: 4),
            Text(
              '點擊展開查看更多設定與白話解釋',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.52),
              ),
            ),
          ],
        ],
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BeginnerHelpBox(accent: accent, onOpenFullHelp: openHelpDialog),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                LabeledSelect<String>(
                  label: 'Window',
                  value: resolvedWindow,
                  items: windowOptions,
                  onChanged: (value) => widget.onChanged(
                    widget.params.copyWith(window: value.trim()),
                  ),
                  tooltip: 'scipy.signal.periodogram 的 window 參數（窗函數）',
                ),
                LabeledSelect<FftDetrend>(
                  label: 'Detrend',
                  value: widget.params.detrend,
                  items: const [
                    FftDetrend.none,
                    FftDetrend.constant,
                    FftDetrend.linear,
                  ],
                  onChanged: (value) =>
                      widget.onChanged(widget.params.copyWith(detrend: value)),
                  itemLabelBuilder: (val) => val.apiValue,
                  tooltip: 'FFT 前的 detrend 模式（none/constant/linear）',
                ),
                LabeledSelect<FftScaling>(
                  label: 'Scaling',
                  value: widget.params.scaling,
                  items: const [FftScaling.spectrum, FftScaling.density],
                  onChanged: (value) =>
                      widget.onChanged(widget.params.copyWith(scaling: value)),
                  itemLabelBuilder: (val) => val.apiValue,
                  tooltip: 'periodogram 的 scaling（spectrum 或 density）',
                ),
                LabeledSelect<int>(
                  label: 'Min NFFT',
                  value: resolvedMinNfft,
                  items: nfftOptions,
                  onChanged: (value) =>
                      widget.onChanged(widget.params.copyWith(minNfft: value)),
                  tooltip: '最小 FFT 點數；不足會補零（也會受到 zero-pad 與 pow2 設定影響）',
                ),
                AppDoubleSliderTile(
                  label: 'Zero pad factor',
                  value: widget.params.zeroPadFactor.clamp(1.0, 4.0).toDouble(),
                  min: 1.0,
                  max: 4.0,
                  step: 0.1,
                  onChanged: (value) => widget.onChanged(
                    widget.params.copyWith(zeroPadFactor: value),
                  ),
                  formatter: (value) => '×${value.toStringAsFixed(2)}',
                  tooltip: '額外零填充倍率，例如 2.0 代表至少補到原長度兩倍',
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildBoolChip(
                      context: context,
                      label: 'Pad to 2^n',
                      selected: widget.params.padToPow2,
                      onSelected: (value) => widget.onChanged(
                        widget.params.copyWith(padToPow2: value),
                      ),
                      tooltip: '將 nfft 補到 2 的次方（常見於加速 FFT）',
                      accent: accent,
                    ),
                    _buildBoolChip(
                      context: context,
                      label: 'Remove DC',
                      selected: widget.params.removeDc,
                      onSelected: (value) => widget.onChanged(
                        widget.params.copyWith(removeDc: value),
                      ),
                      tooltip: 'FFT 前扣除平均值以移除 DC 成分',
                      accent: accent,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => widget.onChanged(const FftPeriodogramParams()),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重置 FFT 參數'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoolChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required DashboardAccentColors accent,
    String? tooltip,
  }) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;

    final chip = FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      labelStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: selected ? colors.onSurface : null,
        letterSpacing: 0.2,
      ),
      backgroundColor: colors.onSurface.withValues(alpha: 0.04),
      selectedColor: accent.success.withValues(alpha: 0.18),
      side: BorderSide(
        color: selected
            ? accent.success
            : colors.onSurface.withValues(alpha: 0.18),
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      pressElevation: 0,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
    );

    if (tooltip == null || tooltip.isEmpty) {
      return chip;
    }
    return AppTooltip(message: tooltip, child: chip);
  }
}
