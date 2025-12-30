import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/app.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/app/widgets/app_connection_settings_panel.dart';
import 'package:gait_charts/core/widgets/dashboard_toast.dart';
import 'package:gait_charts/features/admin/data/admin_login_storage.dart';
import 'package:gait_charts/features/admin/domain/validators/admin_username_validator.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_auth_provider.dart';
import 'package:gait_charts/features/admin/presentation/widgets/admin_login_background.dart';
import 'package:gait_charts/features/apk/presentation/widgets/apk_downloads_card.dart';

/// 管理員登入 / 註冊畫面。
///
/// 設計重點：
/// - 這裡使用 local state（`ConsumerStatefulWidget`）管理表單輸入與 UI 狀態，避免把「一次性表單狀態」放到全域 provider。
/// - 真正的登入狀態以 `adminAuthProvider` 為準；成功後由 `AdminAuthGate` 依 session 自動切換到 Dashboard。
/// - 「記住我」僅用於提升 UX（自動帶入帳密/帳號）；Web 端會另外顯示安全性提示。
class AdminLoginView extends ConsumerStatefulWidget {
  const AdminLoginView({super.key});

  @override
  ConsumerState<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends ConsumerState<AdminLoginView> {
  // 表單控制器：避免在 build 內建立，並在 dispose 釋放。
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteController = TextEditingController();

  // UI 狀態：
  // - `_obscure`: 密碼顯示/隱藏
  // - `_registerMode`: 登入/註冊模式切換（註冊時會顯示邀請碼欄位）
  // - `_rememberMe`: 是否保存帳密（保存行為由 `_submit` 統一處理）
  // - `_isLoading`: 防止重複送出，並讓按鈕顯示 loading
  bool _obscure = true;
  bool _registerMode = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  // 建立 storage 實例，避免每次都建立。
  // 這個 storage 僅用於「記住我」的帳密保存（與真正的登入 session/token storage 不同）。
  final _storage = AdminLoginStorage();

  // 檢查密碼是否符合要求（與後端規則保持一致；若後端調整，記得同步更新）。
  bool _isValidPassword(String value) =>
      value.length >= 8 && value.length <= 128;

  @override
  void initState() {
    super.initState();
    // init 階段還原「記住我」資訊；避免在 build 內做 I/O。
    _restoreRemembered();
  }

  Future<void> _restoreRemembered() async {
    try {
      final remembered = await _storage.read();
      if (!mounted || remembered == null) return;
      setState(() {
        // 若讀到 remembered，視為使用者曾選擇「記住我」。
        _rememberMe = true;
        _usernameController.text = remembered.username;
        if (remembered.password != null) {
          _passwordController.text = remembered.password!;
        }
      });
    } catch (_) {
      // 讀取失敗通常不影響核心流程（使用者仍可手動輸入登入），但提示一次避免誤會「記住我」未生效。
      _toast('記住帳號失敗，請重新登入', variant: DashboardToastVariant.danger);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  void _toast(String message, {required DashboardToastVariant variant}) {
    DashboardToast.show(context, message: message, variant: variant);
  }

  Future<void> _submit() async {
    // 防止重複送出（例如連點按鈕 / Enter 多次）。
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final invite = _inviteController.text.trim();

    // 前端快速驗證：減少無效 API 呼叫，並提供即時回饋。
    if (!isValidAdminUsername(username)) {
      _toast('帳號需 3~64 字且僅限英數與 ._-', variant: DashboardToastVariant.danger);
      return;
    }
    if (!_isValidPassword(password)) {
      _toast('密碼需 8~128 字', variant: DashboardToastVariant.danger);
      return;
    }

    setState(() => _isLoading = true);

    // 使用 Notifier action 觸發登入/註冊：錯誤會往上拋出，這裡統一顯示 Toast。
    final notifier = ref.read(adminAuthProvider.notifier);
    try {
      if (_registerMode) {
        await notifier.register(
          username: username,
          password: password,
          inviteCode: invite.isEmpty ? null : invite,
        );
      } else {
        await notifier.login(username: username, password: password);
      }
      // 登入成功後：勾選記住我 → 儲存；未勾選 → 清除
      if (_rememberMe) {
        await _storage.save(username: username, password: password);
      } else {
        await _storage.clear();
      }
      if (mounted) {
        // 成功提示：實際畫面切換由 AdminAuthGate 依 auth provider 狀態處理。
        _toast(
          _registerMode ? '註冊並登入成功' : '登入成功',
          variant: DashboardToastVariant.success,
        );
      }
    } catch (error) {
      if (!mounted) return;
      // 直接顯示 error.toString()：
      _toast(error.toString(), variant: DashboardToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openConnectionSettings() {
    // 連線設定（baseUrl/timeout 等）屬於 app 設定，這裡用 dialog 快速入口，避免使用者找不到設定位置。
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: const AppConnectionSettingsPanel(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 透過 ThemeContextExtension 取得 theme/colors，避免到處硬編顏色。
    final theme = context.theme;
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'login_theme_toggle',
        onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        tooltip: '切換主題',
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Icon(
          themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // 桌面/寬螢幕：左右分割
            // - 左側：品牌與視覺，降低「只有表單」的單調感
            // - 右側：限制表單最大寬度（380）以維持閱讀性
            return Row(
              children: [
                // 左側：視覺區
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AdminLoginBackground(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 內容層：使用 Column + Flexible 讓卡片在高度不足時自動縮小（Scroll 內部），
                      // 避免整頁滾動條。
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final h = constraints.maxHeight;
                            // 根據高度動態計算顯示數量，避免內容撐爆或出現 ScrollBar。
                            // 基礎高度扣除 padding/標題等預留空間。
                            var limit = 10;
                            if (h < 850) {
                              limit = 4;
                            } else if (h < 1000) {
                              limit = 7;
                            }

                            return Padding(
                              // 讓左側下載卡片更貼近底部（原本 bottom padding 疊太多，卡片會被往上推）。
                              padding: const EdgeInsets.fromLTRB(64, 64, 48, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.auto_graph_outlined,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Realsense Pose\nDashboard',
                                        style: theme.textTheme.displaySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          height: 1.1,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '進階步態分析與即時骨架追蹤系統',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                        // 讓卡片靠底（避免疊加 padding 造成視覺偏上）。
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 480,
                                            maxHeight: 600,
                                          ),
                                          child: ApkDownloadsCard(
                                            maxVisibleItems: limit,
                                            showViewAllAction: true,
                                            isFloating: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // 右側：登入表單
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      // 這裡刻意用更「純」的黑/白底，讓表單區域更接近 Vercel 風格，
                      // 並降低不同平台 surface 色差造成的灰階偏色。
                      color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                      border: isDark 
                          ? const Border(left: BorderSide(color: Color(0xFF1F1F1F)))
                          : const Border(left: BorderSide(color: Color(0xFFE5E5E5))),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        // 右側背景微光
                        if (isDark)
                          Positioned(
                            top: -100,
                            right: -100,
                            child: Container(
                              width: 400,
                              height: 400,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    colors.primary.withValues(alpha: 0.03),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: SingleChildScrollView(
                            // 允許小高度視窗（例如 web/桌面縮小）時仍可捲動到按鈕。
                            padding: const EdgeInsets.all(48),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: _buildFormContent(theme, colors),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // 手機/窄螢幕：置中卡片
            // - 使用 Card 承載表單
            // - 保留背景以維持品牌一致性
            return Stack(
              children: [
                // 背景
                Positioned.fill(
                  child: AdminLoginBackground(
                    child: Container(color: Colors.black.withValues(alpha: 0.3)),
                  ),
                ),
                // 內容
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 0,
                        // 同寬螢幕表單區：保持更接近純黑/白的底色。
                        color: isDark ? const Color(0xFF111111) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: colors.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: _buildFormContent(theme, colors),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLogo(ColorScheme colors) {
    // 小圖示：用 primary 的 alpha 做淡色底，讓不同 theme 下仍有一致辨識度。
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.admin_panel_settings_rounded,
        size: 24,
        color: colors.primary,
      ),
    );
  }

  Widget _buildFormContent(ThemeData theme, ColorScheme colors) {
    // 內容本體：依 `_registerMode` 切換文案與欄位（邀請碼）。
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _buildLogo(colors)),
        const SizedBox(height: 32),
        Text(
          _registerMode ? '建立管理員帳號' : '歡迎回來',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _registerMode ? '請輸入詳細資訊以開始使用' : '請輸入您的帳號密碼以登入',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildInputFields(colors),
        const SizedBox(height: 20),
        _buildRememberRow(theme),
        if (kIsWeb) ...[
          const SizedBox(height: 16),
          _buildWebWarning(theme, colors),
        ],
        const SizedBox(height: 32),
        _buildSubmitButton(colors),
        const SizedBox(height: 24),
        _buildModeSwitch(theme, colors),
      ],
    );
  }

  Widget _buildInputFields(ColorScheme colors) {
    // 使用 AnimatedSize 讓「邀請碼欄位」出現/消失時有平滑高度變化。
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('帳號'),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'name@example.com',
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 14),
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 20),
          _buildLabel('密碼'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: '輸入您的密碼',
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                // 僅切 UI 顯示狀態；不影響資料提交。
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 14),
            // 支援鍵盤 Enter 直接送出（桌面/網頁更順）。
            onSubmitted: (_) => _submit(),
            enabled: !_isLoading,
          ),
          if (_registerMode) ...[
            const SizedBox(height: 20),
            _buildLabel('邀請碼'),
            const SizedBox(height: 8),
            TextField(
              controller: _inviteController,
              decoration: InputDecoration(
                hintText: '管理員邀請碼',
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: const TextStyle(fontSize: 14),
              enabled: !_isLoading,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    // 表單欄位 label：刻意使用較小字級但較高權重，維持「控制面板」視覺密度。
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildRememberRow(ThemeData theme) {
    // 「記住我」與「連線設定」放同一列：符合登入場景下最常用的次要操作。
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _isLoading ? null : () => setState(() => _rememberMe = !_rememberMe),
            child: Padding(
              // 視覺維持緊湊，但讓滑鼠/觸控更好點。
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _rememberMe,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: _isLoading
                        ? null
                        : (checked) => setState(() => _rememberMe = checked ?? false),
                  ),
                  const SizedBox(width: 4),
                  Text('記住我', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : _openConnectionSettings,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '連線設定',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildWebWarning(ThemeData theme, ColorScheme colors) {
    // Web 端安全提示：瀏覽器儲存空間通常無法提供 OS 級加密保證。
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Web 端記住帳密會存於瀏覽器（無系統加密），請確認裝置安全後再勾選。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colors) {
    // 送出按鈕：loading 時禁用並顯示 spinner，避免重複送出造成多次 API hit。
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: _isLoading ? null : _submit,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              )
            : Text(
                _registerMode ? '建立帳號' : '登入',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildModeSwitch(ThemeData theme, ColorScheme colors) {
    // 登入/註冊切換：只切換 UI；真正流程由 `_submit` 依 `_registerMode` 決定。
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _registerMode ? '已有帳號？' : '還沒有帳號？',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => setState(() => _registerMode = !_registerMode),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _registerMode ? '直接登入' : '使用邀請碼註冊',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
