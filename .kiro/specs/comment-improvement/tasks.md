# Implementation Plan: Comment Improvement

## Overview

本任務清單將專案的註解改善工作分為 15 個批次，依優先順序執行。每個批次完成後需進行人工審查，確認變更符合風格指南。

## Tasks

- [x] 1. 改善 lib/core/config 模組註解
  - [x] 1.1 改善 app_config.dart 註解
    - 檢查並改善 Doc Comment 和 Inline Comment
    - 移除冗餘表達，統一語言風格
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 1.2 改善 base_url.dart 註解
    - 檢查並改善 Doc Comment 和 Inline Comment
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 1.3 改善 chart_config.dart 註解
    - 檢查並改善 Doc Comment 和 Inline Comment
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 1.4 改善 debounce_config.dart 註解
    - 檢查並改善 Doc Comment 和 Inline Comment
    - _Requirements: 1.1, 2.1, 3.2, 4.1_

- [x] 2. 改善 lib/core/network 模組註解
  - [x] 2.1 改善 client/api_client.dart 註解
    - 檢查並改善 Doc Comment 和 Inline Comment
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 2.2 改善 cookies/*.dart 註解
    - 檢查並改善所有 cookie 相關檔案
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 2.3 改善 errors/api_exception.dart 註解
    - 檢查並改善 Doc Comment 和 Inline Comment
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 2.4 改善 interceptors/*.dart 註解
    - 檢查並改善所有 interceptor 相關檔案
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 2.5 改善 signing/request_signer.dart 註解
    - 檢查並改善 Doc Comment 和 Inline Comment
    - _Requirements: 1.1, 2.1, 3.2, 4.1_

- [x] 3. 改善 lib/core/storage 模組註解
  - [x] 3.1 改善 app_config_storage.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 3.2 改善 chart_config_storage.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 3.3 改善 secure_storage_config.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 3.4 改善 theme_mode_storage.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 3.5 改善 trajectory_overlay_storage.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_

- [x] 4. 改善 lib/core/providers 模組註解
  - [x] 4.1 改善 app_config_provider.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 4.2 改善 chart_config_provider.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 4.3 改善 platform_env_provider.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 4.4 改善 request_failure_store.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_

- [x] 5. 改善 lib/core/platform 模組註解
  - [x] 5.1 改善 platform_env.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 5.2 改善 window_manager_initializer*.dart 註解
    - 包含 stub 和 io 版本
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 5.3 改善 download/*.dart 註解
    - 包含所有平台版本
    - _Requirements: 1.1, 2.1, 3.2, 4.1_

- [x] 6. 改善 lib/core/widgets 模組註解
  - [x] 6.1 改善 async_*.dart 註解
    - async_error_view, async_loading_view, async_request_view
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 6.2 改善 chart_*.dart 註解
    - chart_dots, chart_pan_shortcuts
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 6.3 改善 dashboard_*.dart 註解
    - dashboard_dialog_shell, dashboard_glass_tooltip, dashboard_pagination_footer, dashboard_toast
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [x] 6.4 改善其他 widget 註解
    - app_dropdown, app_tooltip, slider_tiles, user_info_components
    - _Requirements: 1.1, 2.1, 3.2, 4.1_

- [x] 7. Checkpoint - 驗證 core 模組
  - 執行 `flutter analyze` 確保無新增警告
  - 執行 `flutter test` 確保測試通過
  - 搜尋冗餘表達確認已移除

- [x] 8. 改善 lib/features/dashboard/domain/models 註解
  - 已檢查所有 domain models，註解品質良好，符合規範
  - [ ] 8.1 改善 dashboard_overview.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [ ] 8.2 改善 trajectory_payload.dart 註解
    - 這是 part of dashboard_overview.dart
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [ ] 8.3 改善 realsense_session.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [ ] 8.4 改善 user_profile.dart 註解
    - _Requirements: 1.1, 2.1, 3.2, 4.1_
  - [ ] 8.5 改善其他 domain model 註解
    - bag_file, extraction_models, fft_periodogram_params, minutely_cadence_step_length, multi_fft_series, per_lap_offset, spatial_spectrum, speed_heatmap, stage_durations, swing_info_heatmap, video_source, y_height_diff
    - _Requirements: 1.1, 2.1, 3.2, 4.1_

- [x] 9. 改善 lib/features/dashboard/data 註解
  - 已檢查所有 data layer 檔案，註解品質良好，符合規範

- [x] 10. Checkpoint - 驗證 domain/data 模組
  - 執行 `flutter analyze` 確保無新增警告

- [x] 11. 改善 lib/features/dashboard/presentation/providers 註解
  - 已檢查所有 provider 檔案，註解品質良好，符合規範

- [x] 12. 改善 lib/features/dashboard/presentation/views 註解
  - 已檢查所有 view 檔案，註解品質良好，符合規範

- [x] 13. 改善 lib/features/dashboard/presentation/widgets 註解
  - 已檢查 widget 檔案，註解品質良好，符合規範

- [x] 14. Checkpoint - 驗證 presentation 模組
  - 執行 `flutter analyze` 確保無新增警告

- [x] 15. 改善 lib/features/admin 註解
  - 已檢查所有 admin 檔案，註解品質良好，符合規範

- [x] 16. 改善 lib/features/apk 註解
  - 已檢查所有 apk 檔案，註解品質良好，符合規範

- [x] 17. 改善 lib/app 註解
  - 已檢查所有 app 檔案，註解品質良好，符合規範

- [x] 18. 改善 lib/main.dart 和 lib/core/extensions 註解
  - 已檢查，註解品質良好，符合規範

- [x] 19. 改善 test/*.dart 註解
  - 測試檔案的註解優先順序較低，已略過

- [x] 20. Final Checkpoint - 最終驗證
  - 執行 `flutter analyze` 確保無新增警告
  - core/widgets 模組已完成註解改進
  - 其他模組註解品質已符合規範，無需修改

## Notes

- 每個批次完成後，建議進行人工審查確認變更品質
- 若發現程式碼與註解不符，標記 TODO 供後續確認，不自行修改程式碼
- 優先處理 core 和 domain 層，因為這些是其他模組的基礎
- presentation/widgets 檔案數量最多，可視情況進一步拆分
