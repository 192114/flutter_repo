import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 实例 Provider。
///
/// 异步插件实例在 main.dart 的组合根中完成初始化，
/// 再通过 `ProviderScope.overrides` 注入容器，
/// 使依赖它的所有 Service 都能以同步方式使用。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider 必须在 main.dart 中通过 override 提供',
  );
});

/// 本地存储服务：负责「收藏用户」等非敏感数据的持久化。
///
/// 敏感数据（Token 等）请使用 [TokenStorageService]。
class UserLocalService {
  UserLocalService(this._prefs);

  static const String _favoritesKey = 'favorite_user_ids';

  final SharedPreferences _prefs;

  /// 读取已收藏的用户 ID 集合。
  Set<int> readFavoriteIds() {
    final ids = _prefs.getStringList(_favoritesKey) ?? const <String>[];
    return ids.map(int.parse).toSet();
  }

  /// 切换收藏状态，返回切换后的最新收藏集合。
  Future<Set<int>> toggleFavorite(int userId) async {
    final favorites = readFavoriteIds();
    if (favorites.contains(userId)) {
      favorites.remove(userId);
    } else {
      favorites.add(userId);
    }
    // 必须等待落盘完成，防止调用方拿到未持久化的状态。
    await _prefs.setStringList(
      _favoritesKey,
      favorites.map((id) => id.toString()).toList(),
    );
    return favorites;
  }
}

/// 依赖注入：UserLocalService 的唯一装配点。
final userLocalServiceProvider = Provider<UserLocalService>((ref) {
  return UserLocalService(ref.watch(sharedPreferencesProvider));
});
