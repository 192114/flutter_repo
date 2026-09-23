import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../exceptions/app_exception.dart';
import 'shared_preferences_provider.dart';

/// 本地存储服务：负责「收藏用户」等非敏感数据的持久化。
///
/// 敏感数据（Token 等）请使用 [TokenStorageService]。
class UserLocalService {
  UserLocalService(this._prefs);

  static const String _favoritesKey = 'favorite_user_ids';

  final SharedPreferences _prefs;

  /// 读取已收藏的用户 ID 集合。
  ///
  /// 历史数据损坏（类型不符 / 含非数字项）时降级为可解析的子集，
  /// 不抛异常击穿边界——收藏是非关键数据，不应阻断页面加载。
  Set<int> readFavoriteIds() {
    final List<String>? rawIds;
    try {
      rawIds = _prefs.getStringList(_favoritesKey);
    } on TypeError {
      return <int>{};
    }
    if (rawIds == null) {
      return <int>{};
    }
    return {
      for (final rawId in rawIds)
        if (int.tryParse(rawId) case final int id) id,
    };
  }

  /// 切换收藏状态，返回切换后的最新收藏集合。
  ///
  /// `setStringList` 返回 false 表示落盘失败（此时插件已先行更新内存
  /// 缓存，await 完成不等于持久化成功）：先 reload 恢复缓存与磁盘
  /// 一致，再上抛 [CacheException]，防止上层误把未持久化当成功。
  Future<Set<int>> toggleFavorite(int userId) async {
    final favorites = readFavoriteIds();
    if (favorites.contains(userId)) {
      favorites.remove(userId);
    } else {
      favorites.add(userId);
    }
    final persisted = await _prefs.setStringList(
      _favoritesKey,
      favorites.map((id) => id.toString()).toList(),
    );
    if (!persisted) {
      await _prefs.reload();
      throw const CacheException();
    }
    return favorites;
  }
}

/// 依赖注入：UserLocalService 的唯一装配点。
final userLocalServiceProvider = Provider<UserLocalService>((ref) {
  return UserLocalService(ref.watch(sharedPreferencesProvider));
});
