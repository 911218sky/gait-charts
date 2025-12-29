/// 統一的 debounce 設定，用於各種 config notifier。
/// 當使用者停止操作（放開滑桿）後，等待此時間再發送 API 請求。
const kConfigDebounceDuration = Duration(milliseconds: 600);
