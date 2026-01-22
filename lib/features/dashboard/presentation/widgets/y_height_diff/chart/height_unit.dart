/// 高度單位 enum 與格式化 extension。
enum HeightUnit { cm, m }

extension HeightUnitFormatting on HeightUnit {
  double get yScale => switch (this) {
    .cm => 100,
    .m => 1,
  };

  String get label => switch (this) {
    .cm => 'cm',
    .m => 'm',
  };

  String formatAxisValue(double value) => switch (this) {
    .cm => '${value.toStringAsFixed(0)} $label',
    .m => '${value.toStringAsFixed(2)} $label',
  };

  String formatTooltipValue(double value) => switch (this) {
    .cm => '${value.toStringAsFixed(1)} $label',
    .m => '${value.toStringAsFixed(3)} $label',
  };
}
