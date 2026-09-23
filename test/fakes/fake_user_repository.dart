import 'package:flutter_repo/data/exceptions/app_exception.dart';
import 'package:flutter_repo/data/models/user.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';

/// 测试用 Fake：纯内存实现，无网络、无本地存储依赖。
///
/// 因为 [UserRepository] 是抽象类，Fake 只需实现接口即可整体替换真实实现 ——
/// 这正是「Repository 必须抽象」带来的可测试性收益。
///
/// 典型用法：
/// ```dart
/// ProviderScope(
///   overrides: [
///     userRepositoryProvider.overrideWithValue(FakeUserRepository()),
///   ],
///   child: const App(),
/// )
/// ```
class FakeUserRepository implements UserRepository {
  FakeUserRepository({List<User>? users, Set<int>? favoriteIds})
    : _users = users ?? _defaultUsers,
      _favoriteIds = favoriteIds ?? <int>{};

  static const List<User> _defaultUsers = [
    User(
      id: 1,
      name: 'Leanne Graham',
      username: 'Bret',
      email: 'Sincere@april.biz',
      company: Company(name: 'Romaguera-Crona'),
    ),
    User(
      id: 2,
      name: 'Ervin Howell',
      username: 'Antonette',
      email: 'Shanna@melissa.tv',
      company: Company(name: 'Deckow-Crist'),
    ),
    User(
      id: 3,
      name: 'Clementine Bauch',
      username: 'Samantha',
      email: 'Nathan@yesenia.net',
      company: Company(name: 'Romaguera-Jacobson'),
    ),
  ];

  final List<User> _users;
  final Set<int> _favoriteIds;

  /// 可注入的失败行为，用于测试异常路径（如错误重试 UI）。
  Object? errorToThrow;

  @override
  Future<List<User>> getUsers() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return List.of(_users);
  }

  @override
  Future<User> getUser(int id) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return _users.firstWhere(
      (user) => user.id == id,
      orElse: () => throw const NotFoundException(),
    );
  }

  @override
  Future<Set<int>> getFavoriteIds() async {
    return Set.of(_favoriteIds);
  }

  @override
  Future<Set<int>> toggleFavorite(int userId) async {
    if (_favoriteIds.contains(userId)) {
      _favoriteIds.remove(userId);
    } else {
      _favoriteIds.add(userId);
    }
    return Set.of(_favoriteIds);
  }
}
