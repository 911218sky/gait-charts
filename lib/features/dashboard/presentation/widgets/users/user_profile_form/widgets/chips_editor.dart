import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 標籤編輯器：可新增/刪除多個字串標籤。
class ChipsEditor extends StatefulWidget {
  const ChipsEditor({
    super.key,
    required this.label,
    required this.labelStyle,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  final String label;
  final TextStyle labelStyle;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final String? hintText;

  @override
  State<ChipsEditor> createState() => _ChipsEditorState();
}

class _ChipsEditorState extends State<ChipsEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addFromInput() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    // 支援逗號或頓號分隔多個標籤
    final parts = raw
        .split(RegExp(r'[,、]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    final next = [...widget.items];
    for (final part in parts) {
      if (next.contains(part)) continue;
      next.add(part);
    }
    widget.onChanged(next);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: widget.labelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in widget.items)
              InputChip(
                label: Text(item),
                labelStyle: TextStyle(color: colors.onSurface, fontSize: 13),
                onDeleted: () {
                  widget.onChanged(
                    widget.items
                        .where((e) => e != item)
                        .toList(growable: false),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(color: colors.onSurface, fontSize: 14),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF111111) : colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
                onSubmitted: (_) => _addFromInput(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _addFromInput,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('加入'),
            ),
          ],
        ),
      ],
    );
  }
}
