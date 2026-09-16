import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../models/user.dart';
import '../services/user_api_service.dart';
import '../services/user_local_service.dart';
import 'user_repository_impl.dart';

/// 用户数据仓库（抽象契约）。
///
/// - UI / ViewModel 只依赖本抽象，不感知实现细节（依赖倒置）；
/// - 测试时可替换为 FakeUserRepository，无需网络与本地存储；
/// - 多环境（DEV / PROD / Demo）切换时仅需在 ProviderScope 中 override。
abstract class UserRepository {
  /// 获取用户列表。
  Future<List<User>> getUsers();

  /// 获取单个用户详情。
  Future<User> getUser(int id);

  /// 读取收藏的用户 ID 集合。
  Future<Set<int>> getFavoriteIds();

  /// 切换收藏状态，返回切换后的最新集合。
  Future<Set<int>> toggleFavorite(int userId);
}

/// 依赖注入绑定：默认绑定到生产实现。
///
/// 测试或切换环境时通过 ProviderScope 覆盖：
/// ```dart
/// ProviderScope(
///   overrides: [
///     userRepositoryProvider.overrideWithValue(FakeUserRepository()),
///   ],
///   child: const App(),
/// )
/// ```
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    apiService: ref.watch(userApiServiceProvider),
    localService: ref.watch(userLocalServiceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});
