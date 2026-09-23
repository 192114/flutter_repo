import 'dart:async';

import 'package:flutter_repo/data/models/user.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';

/// 测试用可控 Repository：用手动 Completer 驱动异步时序，
/// 覆盖并发请求、等待期间状态变化、失败回滚等难以用即时 Fake 表达的分支。
class ControllableUserRepository implements UserRepository {
  /// getUsers 的待完成请求队列（按到达顺序，测试手动 complete）。
  final listRequests = <Completer<List<User>>>[];

  /// getUser / getFavoriteIds 的失败注入（设置后调用即抛）。
  Object? detailError;
  Object? favoritesError;

  /// toggleFavorite 的待完成请求队列（同时用于断言调用次数）。
  final toggleRequests = <Completer<Set<int>>>[];

  /// getUser 成功时返回的用户表。
  List<User> users = const [User(id: 1, name: 'Alice')];

  @override
  Future<List<User>> getUsers() {
    final request = Completer<List<User>>();
    listRequests.add(request);
    return request.future;
  }

  @override
  Future<User> getUser(int id) async {
    if (detailError != null) {
      throw detailError!;
    }
    return users.firstWhere((user) => user.id == id);
  }

  @override
  Future<Set<int>> getFavoriteIds() async {
    if (favoritesError != null) {
      throw favoritesError!;
    }
    return const <int>{};
  }

  @override
  Future<Set<int>> toggleFavorite(int userId) {
    final request = Completer<Set<int>>();
    toggleRequests.add(request);
    return request.future;
  }
}
