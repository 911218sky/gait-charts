import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gait_charts/core/storage/secure_storage_config.dart';

/// ThemeMode 本機持久化。
class ThemeModeStorage {
  ThemeModeStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? SecureStorageConfig.instance;

  final FlutterSecureStorage _storage;

  static const String _kThemeModeKey = 'app.theme_mode';

  Future<ThemeMode?> readThemeMode() async {
    final raw = await _storage.read(key: _kThemeModeKey);
    return _decode(raw);
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    await _storage.write(key: _kThemeModeKey, value: _encode(mode));
  }

  Future<void> clearThemeMode() async {
    await _storage.delete(key: _kThemeModeKey);
  }
}

String _encode(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

ThemeMode? _decode(String? raw) {
  return switch ((raw ?? '').trim()) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    '' => null,
    _ => null,
  };
}
