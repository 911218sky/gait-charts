import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// FFT 參數說明對話框。
class FftPeriodogramHelpDialog extends StatelessWidget {
  const FftPeriodogramHelpDialog({super.key});

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
            _buildHeader(context, textTheme, colors, accent),
            const Divider(height: 1),
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
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colors,
    DashboardAccentColors accent,
  ) {
    return Padding(
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
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 說明元件
// ─────────────────────────────────────────────────────────────

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
          child: Divider(color: colors.onSurface.withValues(alpha: 0.1)),
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
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
