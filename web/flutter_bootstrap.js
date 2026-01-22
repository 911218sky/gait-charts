// 自訂 Flutter Web bootstrap（會在 `flutter build web` 時被當作模板使用）
//
// 目的：
// - 將 CanvasKit / SkWasm 引擎資源改成「第一方同源」載入，避免依賴 Google CDN（www.gstatic.com）
// - 為後續啟用 COOP/COEP（跨來源隔離、SharedArrayBuffer）鋪路：同源資源最不會踩到 COEP 的限制
//
// 注意：這裡的 `{{...}}` 會在 build 時由 Flutter 工具替換。

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    // 重要：使用相對路徑，才能配合 `--base-href`（子路徑部署）。
    // 例如 base-href=/gait_charts/ 時，實際會抓 /gait_charts/canvaskit/...
    canvasKitBaseUrl: "canvaskit/",
  },
});
