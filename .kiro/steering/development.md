---
inclusion: always
---

# Gait Charts Dashboard 開發規範

> 讓 AI 與開發者在不看所有歷史脈絡的前提下，也能穩定地延伸功能、保持 UI/架構一致、避免效能與狀態管理踩雷。

## 核心原則（違反視為不合格）

1. **分層不可破**：`domain` 放規則/計算/模型，`data` 放 IO/HTTP，`presentation` 放畫面與互動
2. **Riverpod 3 唯一**：不引入其他 state management
3. **build() 禁止副作用**：重計算、JSON parse、排序聚合、showSnackBar、navigation 都不該在 `build()` 觸發

## 語言規範

- 註解、UI 文案、README 以**繁體中文**為主
- 技術名詞保留英文：`session`, `lap`, `offset`, `payload`, `debounce`

## 目錄結構（DDD / feature-based）

```
lib/
├── app/                    # App 等級（MaterialApp、theme、home 入口）
├── core/                   # 可重用共用層
│   ├── config/             # 跨 feature 設定（AppConfig）
│   ├── network/            # dioProvider、API retry、例外映射
│   ├── providers/          # 全域 provider
│   └── widgets/            # 跨 feature 共用 UI（AsyncRequestView）
└── features/<feature>/     # 功能模組
    ├── data/               # API service、repository
    ├── domain/             # 純模型、計算邏輯（不依賴 Flutter）
    └── presentation/
        ├── providers/      # Notifier / AsyncNotifier
        ├── views/          # 大畫面組裝
        └── widgets/        # 小組件
```

### 依賴方向（強制）

- `presentation` → `domain`、`data` ✓
- `data` → `domain`、`core` ✓
- `domain` → Flutter / UI ✗
- `core` → 單一 feature business rule ✗

## Network 規範（Dio）

- **禁止** UI 直接 `Dio()` 或處理 `DioException`
- 統一用 `dioProvider`（`lib/core/network/api_client.dart`）
- 錯誤用 `mapDioError`（`lib/core/network/api_exception.dart`）
- 重試用 `withApiRetry(...)`
- `baseUrl` 在 `lib/core/config/app_config.dart`

## Riverpod 規範

### 放置位置

| 類型 | 位置 |
|------|------|
| 全域 | `lib/app` 或 `lib/core/providers` |
| Feature 專屬 | `lib/features/<feature>/presentation/providers` |

### 命名

- Provider 以 `...Provider` 結尾
- Notifier 以 `...Notifier` 結尾
- 提供 `<feature>_providers.dart` barrel export

### 錯誤處理

- UI async 狀態用 `AsyncRequestView`
- 不在 UI catch Dio 例外，在 data 層轉成 `ApiException`
- 副作用用 `ref.listen()` 處理，不在 `build()` 觸發

## UI / Theme

- 深色為預設（`ThemeMode.dark`）
- 用 `context.colorScheme`、`context.theme`（ThemeContextExtension）
- **禁止**硬編顏色常數（除非在 `lib/app/theme.dart`）
- 寬螢幕用 `NavigationRail`，小螢幕用 `NavigationBar`
- 動畫 150–300ms

## Domain Model

- immutable：`final` 欄位，`const` 建構子優先
- JSON：`factory Xxx.fromJson` 內部做型別防呆
- 聚合/排序/filter 放 `domain` 或衍生 provider

## 程式碼風格

- 2-space 縮排
- 能 `const` 就 `const`
- 多行結尾逗號保留
- 檔名 `snake_case.dart`
- 對外 API 用 `///` 註解

## 開發流程

1. 定位 feature（既有 or 新增）
2. 先做 domain（模型/計算）
3. 再做 data（API service → repository）
4. 最後做 presentation（provider → view/widget）
5. 參考既有 pattern 再擴充

## 變更前 Checklist

- [ ] domain/data/presentation 邊界清楚
- [ ] provider 位置與命名正確
- [ ] 沒在 `build()` 觸發副作用
- [ ] 網路錯誤經過 `mapDioError`
- [ ] 沒有硬編顏色
- [ ] 沒在 `build()` 做重計算
- [ ] 新邏輯有補單元測試
