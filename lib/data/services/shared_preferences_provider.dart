import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 实例 Provider（通用本地存储依赖，非某个业务专属）。
///
/// 异步插件实例在 main.dart 的组合根中完成初始化，
/// 再通过 `ProviderScope.overrides` 注入容器，
/// 使依赖它的所有 Service（收藏、主题偏好等）都能以同步方式使用。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider 必须在 main.dart 中通过 override 提供',
  );
});
