import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/slider_tiles.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

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
        builder: (context) => const _FftPeriodogramHelpDialog(),
      );
    }

    Widget buildBoolChip({
      required String label,
      required bool selected,
      required ValueChanged<bool> onSelected,
      String? tooltip,
    }) {
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
      trailing: _ExpandHintTrailing(
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
            _BeginnerHelpBox(accent: accent, onOpenFullHelp: openHelpDialog),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _LabeledSelect<String>(
                  label: 'Window',
                  value: resolvedWindow,
                  items: windowOptions,
                  onChanged: (value) => widget.onChanged(
                    widget.params.copyWith(window: value.trim()),
                  ),
                  tooltip: 'scipy.signal.periodogram 的 window 參數（窗函數）',
                ),
                _LabeledSelect<FftDetrend>(
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
                _LabeledSelect<FftScaling>(
                  label: 'Scaling',
                  value: widget.params.scaling,
                  items: const [FftScaling.spectrum, FftScaling.density],
                  onChanged: (value) =>
                      widget.onChanged(widget.params.copyWith(scaling: value)),
                  itemLabelBuilder: (val) => val.apiValue,
                  tooltip: 'periodogram 的 scaling（spectrum 或 density）',
                ),
                _LabeledSelect<int>(
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
                    buildBoolChip(
                      label: 'Pad to 2^n',
                      selected: widget.params.padToPow2,
                      onSelected: (value) => widget.onChanged(
                        widget.params.copyWith(padToPow2: value),
                      ),
                      tooltip: '將 nfft 補到 2 的次方（常見於加速 FFT）',
                    ),
                    buildBoolChip(
                      label: 'Remove DC',
                      selected: widget.params.removeDc,
                      onSelected: (value) => widget.onChanged(
                        widget.params.copyWith(removeDc: value),
                      ),
                      tooltip: 'FFT 前扣除平均值以移除 DC 成分',
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
}

class _ExpandHintTrailing extends StatelessWidget {
  const _ExpandHintTrailing({
    required this.isExpanded,
    required this.borderColor,
    required this.labelColor,
  });

  final bool isExpanded;
  final Color borderColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        color: context.colorScheme.onSurface.withValues(alpha: 0.01),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isExpanded ? '收合' : '展開',
            style: context.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Icon(Icons.expand_more, size: 18, color: labelColor),
          ),
        ],
      ),
    );
  }
}

class _BeginnerHelpBox extends StatelessWidget {
  const _BeginnerHelpBox({
    required this.accent,
    required this.onOpenFullHelp,
  });

  final DashboardAccentColors accent;
  final VoidCallback onOpenFullHelp;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    return InkWell(
      onTap: onOpenFullHelp,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.04),
          border: Border.all(color: context.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: accent.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '遇到困難？查看 FFT 參數白話說明',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledSelect<T> extends StatelessWidget {
  const _LabeledSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
    this.tooltip,
    this.width = 320,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final String? tooltip;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final labelStyle = textTheme.labelMedium?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.7),
      fontWeight: FontWeight.w500,
    );

    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label, style: labelStyle, overflow: TextOverflow.ellipsis),
        ),
        if (tooltip != null && tooltip!.isNotEmpty) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.info_outline,
            size: 16,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ],
    );

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tooltip != null && tooltip!.isNotEmpty)
            AppTooltip(message: tooltip!, child: labelWidget)
          else
            labelWidget,
          const SizedBox(height: 10),
          AppSelect<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            itemLabelBuilder: itemLabelBuilder,
            menuWidth: BoxConstraints(minWidth: 140, maxWidth: width),
          ),
        ],
      ),
    );
  }
}

class _FftPeriodogramHelpDialog extends StatelessWidget {
  const _FftPeriodogramHelpDialog();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 900),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.tune, color: accent.success, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FFT 進階參數說明',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '調整頻譜分析的計算細節',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.navigator.pop(),
                    icon: const Icon(Icons.close, size: 28),
                    tooltip: '關閉',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HelpIntro(),
                    SizedBox(height: 32),
                    _HelpSectionTitle(title: '基本設定'),
                    SizedBox(height: 16),
                    _HelpItem(
                      title: 'Window',
                      code: 'window',
                      icon: Icons.graphic_eq,
                      oneLiner: '把訊號頭尾「淡出」，避免硬切造成假頻率。',
                      whenToUse:
                          '大多不用改，預設 hann 很通用；只有在你想比較「峰更尖/旁邊雜訊更少」時才會嘗試換。',
                      whatYouWillSee:
                          '換 window 可能讓主峰看起來更尖或更寬，也可能改變旁邊的「毛邊」。',
                    ),
                    SizedBox(height: 24),
                    _HelpItem(
                      title: 'Detrend',
                      code: 'detrend',
                      icon: Icons.trending_up,
                      oneLiner: '先把「慢慢漂移的趨勢」拿掉，只留下震盪。',
                      whenToUse:
                          '如果資料有慢慢上升/下降（漂移），可以用 constant（去平均）或 linear（去直線趨勢）。沒有漂移就用 none。',
                      whatYouWillSee:
                          '漂移被拿掉後，0 Hz 附近的能量通常會變小，其他頻率峰更容易看清楚。',
                    ),
                    SizedBox(height: 24),
                    _HelpItem(
                      title: 'Scaling',
                      code: 'scaling',
                      icon: Icons.bar_chart,
                      oneLiner: '決定 PSD 的「單位定義」：spectrum vs density。',
                      whenToUse:
                          '一般只在你要對照其他工具/論文的定義時才需要改；只找「峰在哪裡」通常差異不大。',
                      whatYouWillSee:
                          'y 軸數值會改（同一條曲線高度不同），但主峰頻率位置通常不變。',
                    ),
                    SizedBox(height: 48),
                    _HelpSectionTitle(title: '解析度與補零'),
                    SizedBox(height: 16),
                    _HelpItem(
                      title: 'Min NFFT',
                      code: 'min_nfft',
                      icon: Icons.expand,
                      oneLiner: 'FFT 最少用多少「點數」去算（頻率刻度會更細）。',
                      whenToUse:
                          '想要頻率軸更細、峰位置更好標註時可以提高；如果你只想快一點，就維持 512 或更低。',
                      whatYouWillSee:
                          '提高後曲線會更平滑、峰的位置更好看；但計算會更慢，而且不會憑空多出新訊息。',
                    ),
                    SizedBox(height: 24),
                    _HelpItem(
                      title: 'Pad to 2^n',
                      code: 'pad_to_pow2',
                      icon: Icons.exposure_plus_2,
                      oneLiner: '把 NFFT 補到 2 的次方（常見是讓 FFT 算更快）。',
                      whenToUse:
                          '通常保持開啟即可；只有在你想「完全固定某個 NFFT」時才會關掉。',
                      whatYouWillSee:
                          '多數情況結果差異很小，主要是速度/頻率刻度細微差別。',
                    ),
                    SizedBox(height: 24),
                    _HelpItem(
                      title: 'Zero pad factor',
                      code: 'zero_pad_factor',
                      icon: Icons.linear_scale,
                      oneLiner: '在尾巴補 0，讓頻率軸更密（曲線更順、更好看）。',
                      whenToUse:
                          '當你覺得頻率刻度太粗、峰值「卡在格子上」時可以調高；通常 1.0~2.0 就夠。',
                      whatYouWillSee:
                          '曲線更平滑、峰值位置更容易視覺化；但本質上是插值效果，並不代表訊號真的變更精準。',
                    ),
                    SizedBox(height: 48),
                    _HelpSectionTitle(title: '前處理'),
                    SizedBox(height: 16),
                    _HelpItem(
                      title: 'Remove DC',
                      code: 'remove_dc',
                      icon: Icons.filter_alt_off,
                      oneLiner: '先扣掉平均值，避免 0 Hz 大尖峰蓋住其他頻率。',
                      whenToUse:
                          '如果你看到 0 Hz 附近有超大尖峰、或整條頻譜被墊高，可以打開它。',
                      whatYouWillSee:
                          '0 Hz 附近會明顯變小，其他峰更容易被看見；主峰頻率通常更穩。',
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.navigator.pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('我知道了'),
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

class _HelpSectionTitle extends StatelessWidget {
  const _HelpSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: colors.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

class _HelpIntro extends StatelessWidget {
  const _HelpIntro();

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    final accent = DashboardAccentColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.warning.withValues(alpha: 0.08),
        border: Border.all(color: accent.warning.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: accent.warning, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '新手指南',
                  style: textTheme.labelMedium?.copyWith(
                    color: accent.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '你可以把 FFT 想成：把一段「時間序列」拆成很多個頻率，看哪個頻率最強。\n'
                  '進階參數通常不是必調：除非你遇到「0 Hz 超大尖峰、資料漂移、頻率刻度太粗」這些情況。',
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: colors.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.title,
    required this.code,
    required this.icon,
    required this.oneLiner,
    required this.whenToUse,
    required this.whatYouWillSee,
  });

  final String title;
  final String code;
  final IconData icon;
  final String oneLiner;
  final String whenToUse;
  final String whatYouWillSee;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            oneLiner,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HelpSubSection(
                  label: '什麼時候要改？',
                  content: whenToUse,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _HelpSubSection(
                  label: '你會看到什麼變化？',
                  content: whatYouWillSee,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpSubSection extends StatelessWidget {
  const _HelpSubSection({
    required this.label,
    required this.content,
    required this.color,
  });

  final String label;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.75),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

