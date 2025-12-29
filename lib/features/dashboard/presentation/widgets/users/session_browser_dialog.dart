import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/dashboard_dialog_shell.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/cards/session_grid_card.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionBrowserDialog extends ConsumerStatefulWidget {
  const SessionBrowserDialog({super.key});

  @override
  ConsumerState<SessionBrowserDialog> createState() =>
      _SessionBrowserDialogState();
}

class _SessionBrowserDialogState extends ConsumerState<SessionBrowserDialog> {
  final ScrollController _scrollController = ScrollController();
  final List<RealsenseSessionItem> _items = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 20;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset)) return;

    if (reset) {
      setState(() {
        _page = 1;
        _items.clear();
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final result = await repo.fetchRealsenseSessions(
        page: _page,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.items);
        _hasMore = result.canLoadMore;
        if (_hasMore) {
          _page++;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return DashboardDialogShell(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: colors.surfaceContainer,
      header: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Session',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '選擇一個 Session 以載入分析數據',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppTooltip(
              message: '重新整理',
              child: IconButton(
                onPressed: _isLoading ? null : () => _loadMore(reset: true),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, color: colors.onSurface),
              ),
            ),
            const SizedBox(width: 8),
            AppTooltip(
              message: '關閉',
              child: IconButton(
                onPressed: () => context.navigator.pop(),
                icon: Icon(Icons.close, color: colors.onSurface),
              ),
            ),
          ],
        ),
      ),
      body: _items.isEmpty && !_isLoading
          ? Center(
              child: _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colors.error,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '載入失敗',
                          style: GoogleFonts.inter(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _error!,
                          style: GoogleFonts.inter(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => _loadMore(reset: true),
                          child: const Text('重試'),
                        ),
                      ],
                    )
                  : Text(
                      '沒有資料',
                      style: GoogleFonts.inter(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
            )
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 180, // Fixed height for cards
              ),
              itemCount: _items.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final item = _items[index];
                return SessionGridCard.fromRealsenseSession(
                  item: item,
                  onTap: () => context.navigator.pop(item),
                );
              },
            ),
    );
  }
}
