# Cohort Benchmark UI 元件

## 概述

這個資料夾包含族群基準分析的 UI 元件，用於顯示使用者與族群的比對結果。

## 核心元件

### 1. MetricStatusBadge（指標狀態標籤）

顯示指標在族群中的狀態（正常/偏低/偏高）。

```dart
MetricStatusBadge(
  status: MetricComparisonStatus.normal,
  label: '正常',
  size: MetricStatusBadgeSize.medium,
)
```

**參數：**
- `status`: 指標狀態（normal/belowNormal/aboveNormal）
- `label`: 顯示文字
- `size`: 尺寸（small/medium/large）

### 2. MetricPerformanceBadge（指標表現標籤）

顯示指標表現評價（較佳/較差/正常）。

```dart
MetricPerformanceBadge(
  label: '較佳',
  variant: MetricPerformanceVariant.better,
  size: MetricStatusBadgeSize.medium,
)
```

**參數：**
- `label`: 顯示文字
- `variant`: 表現類型（better/worse/normal）
- `size`: 尺寸（small/medium/large）

### 3. MetricHighlightCard（指標重點卡片）

突出顯示重要指標的完整資訊卡片。

```dart
MetricHighlightCard(
  label: '速度',
  value: '1.23',
  unit: 'm/s',
  status: MetricComparisonStatus.normal,
  performanceLabel: '較佳',
  performanceVariant: MetricPerformanceVariant.better,
  percentile: 75.5,
  subtitle: '比中位數 快 15.2%',
)
```

**參數：**
- `label`: 指標名稱
- `value`: 數值
- `unit`: 單位
- `status`: 狀態
- `performanceLabel`: 表現標籤（可選）
- `performanceVariant`: 表現類型（可選）
- `percentile`: 百分位（可選）
- `subtitle`: 副標題（可選）
- `onTap`: 點擊回調（可選）

## 使用場景

### 總覽頁面

在總覽頁面使用 `MetricHighlightCard` 以網格佈局顯示 4-6 個重點指標：

- 速度 (m/s)
- 單圈總時間 (s)
- 步頻 (steps/min)
- 平均步長 (m)

### 詳細列表

在詳細列表中使用 `MetricStatusBadge` 和 `MetricPerformanceBadge` 標示每個指標的狀態和表現。

## 設計原則

1. **視覺層次**：使用顏色和圖示快速傳達資訊
2. **一致性**：所有狀態標籤使用統一的設計語言
3. **可讀性**：確保在深色模式下清晰可見
4. **響應式**：支援不同螢幕尺寸的佈局調整

## 顏色語意

- **綠色（inRange）**：正常範圍
- **藍色（lower）**：低於範圍
- **橙色（higher）**：高於範圍
- **青色（tertiary）**：表現較佳
- **紅色（error）**：表現較差
