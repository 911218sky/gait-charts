import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 使用者名稱輸入框，支援呼叫 `/users/search` 提供即時建議（name + user_code）。
///
/// 設計上與 `SessionAutocompleteField` 一致：打字後 debounce 呼叫 API，並用 Overlay 顯示下拉提示。
class UserAutocompleteField extends ConsumerStatefulWidget {
  const UserAutocompleteField({
    required this.controller,
    super.key,
    this.labelText = '使用者姓名',
    this.hintText,
    this.helperText,
    this.onSubmitted,
    this.onSuggestionSelected,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
    this.maxSuggestions = 10,
    this.debounce = const Duration(milliseconds: 500),
    this.showClearButton = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<UserSearchSuggestionItem>? onSuggestionSelected;
  final bool enabled;
  final bool autofocus;
  final TextInputAction textInputAction;
  final int maxSuggestions;
  final Duration debounce;
  final bool showClearButton;

  @override
  ConsumerState<UserAutocompleteField> createState() =>
      _UserAutocompleteFieldState();
}

class _UserAutocompleteFieldState extends ConsumerState<UserAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey(debugLabel: 'user-input');

  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  List<UserSearchSuggestionItem> _suggestions = const [];
  bool _isLoading = false;
  bool _justSelected = false;
  Object? _error;
  int _requestId = 0;
  Size? _fieldSize;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(UserAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
    if (oldWidget.enabled && !widget.enabled) {
      _clearSuggestions();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_handleTextChanged);
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (!widget.enabled || _justSelected) {
      return;
    }
    final text = widget.controller.text;
    _debounceTimer?.cancel();

    if (text.trim().isEmpty) {
      _clearSuggestions();
      return;
    }

    _debounceTimer = Timer(widget.debounce, () {
      _fetchSuggestions(text);
    });
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      // 延遲清除，讓點擊建議項目的 onTap 有機會觸發
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _clearSuggestions();
        }
      });
    } else if (widget.controller.text.trim().isNotEmpty) {
      if (_justSelected) return;
      _refreshOverlay();
      if (_suggestions.isEmpty && !_isLoading) {
        _handleTextChanged();
      }
    }
  }

  Future<void> _fetchSuggestions(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty || !widget.enabled) {
      _clearSuggestions();
      return;
    }
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _refreshOverlay();

    try {
      final repository = ref.read(dashboardRepositoryProvider);
      final response = await repository.searchUserSuggestions(
        keyword: query,
        page: 1,
        pageSize: widget.maxSuggestions,
      );
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _isLoading = false;
        _suggestions = response.items;
        _error = null;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _isLoading = false;
        _suggestions = const [];
        _error = error;
      });
    }
    _refreshOverlay();
  }

  void _clearSuggestions() {
    _debounceTimer?.cancel();
    if (!_isLoading && _suggestions.isEmpty && _error == null) {
      _removeOverlay();
      return;
    }
    setState(() {
      _isLoading = false;
      _suggestions = const [];
      _error = null;
    });
    _removeOverlay();
  }

  bool _shouldShowOverlay() {
    if (!_focusNode.hasFocus || !widget.enabled) {
      return false;
    }
    if (_error != null) {
      return true;
    }
    return _suggestions.isNotEmpty;
  }

  void _refreshOverlay() {
    if (!_shouldShowOverlay()) {
      _removeOverlay();
      return;
    }
    _updateFieldSize();
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlay);
      final overlay = Overlay.of(context, rootOverlay: false);
      overlay.insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateFieldSize() {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _fieldSize = renderBox.size;
    }
  }

  void _handleSuggestionTap(UserSearchSuggestionItem item) {
    _justSelected = true;
    widget.controller
      ..text = item.name
      ..selection = TextSelection.collapsed(offset: item.name.length);
    widget.onSuggestionSelected?.call(item);
    FocusScope.of(context).requestFocus(_focusNode);
    _clearSuggestions();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _justSelected = false;
    });
  }

  Widget _buildOverlay(BuildContext context) {
    final width = _fieldSize?.width ?? 320;
    final height = _fieldSize?.height ?? 56;
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final backgroundColor = colors.surface;
    final borderColor = colors.outlineVariant;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, height + 8),
        child: Material(
          elevation: 8,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320, minWidth: 200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                    ),
                  Flexible(
                    child: _error != null
                        ? _SuggestionError(message: _error.toString())
                        : _suggestions.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: _SuggestionPlaceholder(
                                  message: '找不到相符的使用者',
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = _suggestions[index];
                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 0,
                                      ),
                                      leading: Icon(
                                        Icons.person_outline,
                                        size: 18,
                                        color: colors.onSurfaceVariant,
                                      ),
                                      title: Text(
                                        suggestion.name,
                                        style: context.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        suggestion.userCode,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      onTap: () =>
                                          _handleSuggestionTap(suggestion),
                                      hoverColor: context.hoverColor,
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: colors.outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final prefixColor = widget.enabled
        ? colors.onSurfaceVariant
        : colors.onSurfaceVariant.withValues(alpha: 0.5);
    final text = widget.controller.text.trim();
    final decoration = InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      helperMaxLines: 2,
      prefixIcon: Icon(Icons.search, color: prefixColor, size: 20),
      suffixIcon: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : (widget.showClearButton && text.isNotEmpty)
              ? IconButton(
                  onPressed: widget.enabled
                      ? () {
                          widget.controller.clear();
                          _clearSuggestions();
                        }
                      : null,
                  tooltip: '清除',
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                )
              : null,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        key: _fieldKey,
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        style: context.textTheme.bodyMedium,
        decoration: decoration,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

class _SuggestionPlaceholder extends StatelessWidget {
  const _SuggestionPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Text(
        message,
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SuggestionError extends StatelessWidget {
  const _SuggestionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: colors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}


