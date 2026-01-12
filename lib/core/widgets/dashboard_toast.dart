import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';

enum DashboardToastVariant { info, success, warning, danger }

/// 單次最多顯示的 Toast 數量，避免蓋住主要內容。
const int _dashboardToastHardLimit = 3;

/// 頂部浮出的 Toast 元件，支援堆疊顯示。
class DashboardToast {
  DashboardToast._();

  /// 單一 OverlayEntry，負責掛載整個 Toast host。
  static final _DashboardToastQueue _queue = _DashboardToastQueue();
  static OverlayEntry? _overlayEntry;
  static int _idSeed = 0;

  /// 可視 Toast 的預設上限。
  static int maxVisibleToasts = _dashboardToastHardLimit;

  static void show(
    BuildContext context, {
    required String message,
    DashboardToastVariant variant = DashboardToastVariant.info,
    Duration duration = const Duration(seconds: 3),
    int? maxStack,
  }) {
    final overlayState = Overlay.of(context);

    if (_overlayEntry == null) {
      // 第一次呼叫時，建立 Host 並插入 overlay。
      _overlayEntry = OverlayEntry(
        builder: (_) => _DashboardToastHost(queue: _queue),
      );
      overlayState.insert(_overlayEntry!);
    }

    final limit = (maxStack ?? maxVisibleToasts).clamp(
      1,
      _dashboardToastHardLimit,
    );
    final payload = _ToastPayload(
      // 遞增 id 確保 key 唯一
      id: ++_idSeed,
      message: message,
      variant: variant,
      duration: duration,
    );
    _queue.add(payload, limit);
  }

  static void dismiss() {
    _queue.clear();
  }
}

/// 監聽 Queue 並實際在螢幕上堆疊顯示 Toast。
class _DashboardToastHost extends StatefulWidget {
  const _DashboardToastHost({required this.queue});

  final _DashboardToastQueue queue;

  @override
  State<_DashboardToastHost> createState() => _DashboardToastHostState();
}

class _DashboardToastHostState extends State<_DashboardToastHost> {
  @override
  void initState() {
    super.initState();
    widget.queue.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.queue.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.queue.items;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _DashboardToastOverlay(
                  key: ValueKey(items[i].id),
                  message: items[i].message,
                  variant: items[i].variant,
                  duration: items[i].duration,
                  onClosed: () => widget.queue.remove(items[i].id),
                ),
                if (i != items.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// LIFO 佇列，自動裁切超出上限的項目。
class _DashboardToastQueue extends ChangeNotifier {
  final List<_ToastPayload> _items = [];

  List<_ToastPayload> get items => List.unmodifiable(_items);

  void add(_ToastPayload payload, int maxStack) {
    final limit = maxStack.clamp(1, _dashboardToastHardLimit);
    _items.insert(0, payload);
    if (_items.length > limit) {
      _items.removeRange(limit, _items.length);
    }
    notifyListeners();
  }

  void remove(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }
    _items.clear();
    notifyListeners();
  }
}

/// Toast 資料載體。
class _ToastPayload {
  _ToastPayload({
    required this.id,
    required this.message,
    required this.variant,
    required this.duration,
  });

  final int id;
  final String message;
  final DashboardToastVariant variant;
  final Duration duration;
}

class _DashboardToastOverlay extends StatefulWidget {
  const _DashboardToastOverlay({
    required this.message,
    required this.variant,
    required this.duration,
    required this.onClosed,
    super.key,
  });

  final String message;
  final DashboardToastVariant variant;
  final Duration duration;
  final VoidCallback onClosed;

  @override
  State<_DashboardToastOverlay> createState() => _DashboardToastOverlayState();
}

class _DashboardToastOverlayState extends State<_DashboardToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _offset =
      Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  Timer? _timer;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isClosing) {
      return;
    }
    _isClosing = true;
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onClosed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colors = context.colorScheme;
    final accent = context.extension<DashboardAccentColors>();

    final indicatorColor = switch (widget.variant) {
      DashboardToastVariant.success =>
        accent?.success ?? const Color(0xFF34D399),
      DashboardToastVariant.warning =>
        accent?.warning ?? const Color(0xFFFBBF24),
      DashboardToastVariant.danger => accent?.danger ?? const Color(0xFFF87171),
      DashboardToastVariant.info => colors.primary,
    };

    final background = context.surfaceDark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDark ? Colors.white : Colors.black;

    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _dismiss,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppTooltip(
                        message: '關閉',
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          onPressed: _dismiss,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
