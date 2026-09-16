import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/user/widgets/user_detail_screen.dart';
import '../../features/user/widgets/user_list_screen.dart';

/// 应用路由名称常量：避免散落各处的魔法字符串。
enum AppRoute { userList, userDetail }

/// 全局路由配置 Provider（go_router）。
///
/// - 路由集中声明，导航行为可预测、可测试；
/// - 页面间只传 ID（而非对象），天然支持深链接与状态恢复；
/// - 详情页数据由各自的 ViewModel 加载，页面自身无状态依赖。
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/users',
    routes: [
      GoRoute(
        path: '/users',
        name: AppRoute.userList.name,
        builder: (context, state) => const UserListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: AppRoute.userDetail.name,
            builder: (context, state) => UserDetailScreen(
              userId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );
});
