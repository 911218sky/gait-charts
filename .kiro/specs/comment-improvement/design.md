# Design Document: Comment Improvement

## Overview

本設計文件描述如何系統性地改善 Gait Charts Dashboard 專案中的程式碼註解品質。由於註解品質改善主要依賴人工判斷，本設計著重於：

1. 定義明確的註解風格指南
2. 規劃分批處理的工作流程
3. 提供改善前後的範例對照

## Architecture

本專案採用人工審查與修改的方式進行註解改善，不涉及自動化工具開發。工作流程如下：

```
┌─────────────────────────────────────────────────────────────┐
│                    Comment Improvement Flow                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│  │ Batch 1 │ -> │ Batch 2 │ -> │ Batch 3 │ -> │ Batch N │  │
│  │ (core)  │    │(domain) │    │ (data)  │    │(present)│  │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘  │
│       │              │              │              │        │
│       v              v              v              v        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Human Review & Approval                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 批次劃分

專案檔案依功能模組分為以下批次：

| 批次 | 模組 | 檔案數量 | 優先順序 |
|------|------|----------|----------|
| 1 | lib/core/config | 4 | 高 |
| 2 | lib/core/network | 8 | 高 |
| 3 | lib/core/storage | 5 | 高 |
| 4 | lib/core/providers | 4 | 高 |
| 5 | lib/core/platform | 5 | 中 |
| 6 | lib/core/widgets | 13 | 中 |
| 7 | lib/features/dashboard/domain | 15+ | 高 |
| 8 | lib/features/dashboard/data | 10+ | 高 |
| 9 | lib/features/dashboard/presentation/providers | 15+ | 中 |
| 10 | lib/features/dashboard/presentation/views | 10 | 中 |
| 11 | lib/features/dashboard/presentation/widgets/* | 50+ | 低 |
| 12 | lib/features/admin | 15+ | 中 |
| 13 | lib/features/apk | 10+ | 低 |
| 14 | lib/app | 5 | 低 |
| 15 | test | 20+ | 低 |

### 註解風格指南

#### 語言使用規範

1. **主要語言**：繁體中文
2. **保留英文的情況**：
   - 技術術語：session, lap, offset, payload, debounce, frame, bounds, encoding, provider, notifier, widget, state, async, await
   - API 參數名稱：`max_frames`, `fps_out`, `smooth_window_s`
   - 程式碼識別符：類別名、方法名、變數名
   - 縮寫：API, HTTP, JSON, URL, UI, FPS

#### 應避免的表達方式

| 不良範例 | 改善後 |
|----------|--------|
| `// 時間戳記存在第 34 個「關節」的 z 欄位（這是我們的慣例）` | `// 時間戳記存於第 34 關節的 z 欄位` |
| `// 注意：這裡需要先檢查 null` | `// 先檢查 null 避免後續操作失敗` |
| `// 備註：此方法會修改原始陣列` | `// 會修改原始陣列` |
| `// 這個變數用來儲存使用者的名稱` | `// 使用者名稱` |
| `// 下面的程式碼是用來處理錯誤的` | `// 錯誤處理` |

#### Doc Comment 範例

**改善前：**
```dart
/// 這是一個用來解壓並反量化軌跡資料的函式。
/// 它會把 base64 編碼的 zlib 壓縮資料解開，然後把 uint16 座標轉換成世界座標。
TrajectoryDecodedPayload decodeTrajectoryPayload(TrajectoryPayloadResponse response)
```

**改善後：**
```dart
/// 解壓並反量化軌跡資料，將 base64+zlib 壓縮的 uint16 座標轉換為世界座標。
TrajectoryDecodedPayload decodeTrajectoryPayload(TrajectoryPayloadResponse response)
```

#### Inline Comment 範例

**改善前：**
```dart
// 這裡我們要把 bytes 轉成 ByteData
final bytes = ByteData.sublistView(rawBytes);
```

**改善後：**
```dart
// 轉為 ByteData 以便用 getUint16 讀取 little-endian 數值
final bytes = ByteData.sublistView(rawBytes);
```

## Data Models

本設計不涉及新的資料模型。

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

由於註解改善主要依賴人工判斷，大部分需求無法自動化測試。以下是少數可驗證的屬性：

### Property 1: 冗餘表達移除驗證

*For any* 改善後的程式碼檔案，搜尋「這是我們的慣例」、「這是慣例」等模式應回傳零結果。

**Validates: Requirements 1.1**

### Property 2: 程式碼邏輯不變驗證

*For any* 改善後的程式碼檔案，其 AST（抽象語法樹）結構應與改善前完全相同（僅註解內容不同）。

**Validates: Requirements 6.1**

### Property 3: 標記註解保留驗證

*For any* 改善前存在的 TODO、FIXME、HACK 標記註解，改善後應仍然存在。

**Validates: Requirements 6.3**

## Error Handling

### 發現程式碼與註解不符

當發現註解描述與實際程式碼行為不符時：
1. 在該處加上 `// TODO: 確認註解與程式碼是否一致` 標記
2. 不自行修改程式碼邏輯
3. 在批次摘要中列出需要確認的項目

### 不確定是否應修改

當不確定某個註解是否應該修改時：
1. 保留原始註解
2. 在批次摘要中列出需要討論的項目

## Testing Strategy

### 人工審查

由於註解品質改善主要依賴主觀判斷，測試策略以人工審查為主：

1. **批次審查**：每個批次完成後，由開發者審查變更
2. **抽樣檢查**：隨機抽取改善後的檔案，確認符合風格指南
3. **回歸測試**：執行現有測試套件，確保程式碼功能不受影響

### 自動化驗證

以下項目可透過自動化方式驗證：

1. **冗餘表達搜尋**：使用 grep 搜尋已知的不良模式
2. **測試套件執行**：執行 `flutter test` 確保功能正常
3. **靜態分析**：執行 `flutter analyze` 確保無新增警告

### 驗證指令

```bash
# 搜尋冗餘表達
grep -r "這是我們的慣例" lib/
grep -r "這是慣例" lib/

# 執行測試
flutter test

# 靜態分析
flutter analyze
```
