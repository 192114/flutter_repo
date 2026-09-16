import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_local_service.dart';

/// 主题偏好本地存储：持久化用户选择的主题模式。
///
/// 只读写原始字符串，不感知 Flutter 的 ThemeMode 枚举——
/// 枚举映射由 UI 层的 ThemeModeNotifier 负责，
/// 保持 data 层不依赖 UI 概念。
class ThemeModeStorage {
  ThemeModeStorage(this._prefs);

  static const String _themeModeKey = 'app_theme_mode';

  final SharedPreferences _prefs;

  /// 读取持久化的主题模式名（'system' / 'light' / 'dark'）。
  ///
  /// 未设置或值非法时返回 null，由调用方决定回落值。
  String? read() => _prefs.getString(_themeModeKey);

  /// 保存主题模式名。
  ///
  /// 必须等待落盘完成，防止调用方拿到未持久化的状态。
  Future<void> save(String modeName) async {
    await _prefs.setString(_themeModeKey, modeName);
  }
}

/// 依赖注入：ThemeModeStorage 的唯一装配点。
final themeModeStorageProvider = Provider<ThemeModeStorage>((ref) {
  return ThemeModeStorage(ref.watch(sharedPreferencesProvider));
});
