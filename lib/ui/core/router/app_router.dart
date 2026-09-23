import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/gallery/widgets/async_value_demo_screen.dart';
import '../../features/gallery/widgets/dropdown_menu_demo_screen.dart';
import '../../features/gallery/widgets/empty_demo_screen.dart';
import '../../features/gallery/widgets/feedback_demo_screen.dart';
import '../../features/gallery/widgets/form_demo_screen.dart';
import '../../features/gallery/widgets/gallery_screen.dart';
import '../../features/gallery/widgets/tag_demo_screen.dart';
import '../../features/gallery/widgets/tokens_demo_screen.dart';
import '../../features/gallery/widgets/upload_image_demo_screen.dart';
import '../../features/image_crop/widgets/image_crop_screen.dart';
import '../../features/user/widgets/user_detail_screen.dart';
import '../../features/user/widgets/user_list_screen.dart';

/// 应用路由名称常量：避免散落各处的魔法字符串。
enum AppRoute {
  userList,
  userDetail,
  gallery,
  galleryFeedback,
  galleryDropdown,
  galleryAsync,
  galleryTokens,
  galleryForm,
  galleryTag,
  galleryUpload,
  galleryEmpty,
  imageCrop,
}

/// 全局路由配置 Provider（go_router）。
///
/// - 路由集中声明，导航行为可预测、可测试；
/// - 页面间只传 ID（而非对象），天然支持深链接与状态恢复；
/// - 详情页数据由各自的 ViewModel 加载，页面自身无状态依赖。
final goRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/users',
    routes: [
      GoRoute(
        path: '/image-crop/:id',
        name: AppRoute.imageCrop.name,
        pageBuilder: (context, state) => _materialPage<Uint8List>(
          state,
          ImageCropScreen(sessionId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/users',
        name: AppRoute.userList.name,
        pageBuilder: (context, state) =>
            _materialPage<void>(state, const UserListScreen()),
        routes: [
          GoRoute(
            path: ':id',
            name: AppRoute.userDetail.name,
            pageBuilder: (context, state) {
              // ID 来自外部（深链 / 手输 URL），不受控：
              // 解析失败进兜底页，而非页面构建时抛错。
              final userId = int.tryParse(state.pathParameters['id']!);
              return _materialPage<void>(
                state,
                userId == null
                    ? const _InvalidUserIdScreen()
                    : UserDetailScreen(userId: userId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/gallery',
        name: AppRoute.gallery.name,
        pageBuilder: (context, state) =>
            _materialPage<void>(state, const GalleryScreen()),
        routes: [
          GoRoute(
            path: 'feedback',
            name: AppRoute.galleryFeedback.name,
            pageBuilder: (context, state) =>
                _materialPage<void>(state, const FeedbackDemoScreen()),
          ),
          GoRoute(
            path: 'dropdown',
            name: AppRoute.galleryDropdown.name,
            pageBuilder: (context, state) =>
                _materialPage<void>(state, const DropdownMenuDemoScreen()),
          ),
          GoRoute(
            path: 'async-value',
            name: AppRoute.galleryAsync.name,
            pageBuilder: (context, state) =>
                _materialPage<void>(state, const AsyncValueDemoScreen()),
          ),
          GoRoute(
            path: 'tokens',
            name: AppRoute.galleryTokens.name,
            pageBuilder: (context, state) =>
                _materialPage<void>(state, const TokensDemoScreen()),
          ),
          GoRoute(
            path: 'form',
            name: AppRoute.galleryForm.name,
            pageBuilder: (context, state) =>
                _materialPage<void>(state, const FormDemoScreen()),
          ),
          GoRoute(
            path: 'tag',
            name: AppRoute.galleryTag.name,
            pageBuilder: (context, state) =>
                _materialPage<void>(state, const TagDemoScreen()),
          ),
          GoRoute(
            path: 'upload',
            name: AppRoute.galleryUpload.name,
            pageBuilder: (context, state) =>
                _materialPage<void>(state, const UploadImageDemoScreen()),
          ),
          GoRoute(
            path: 'empty',
            name: AppRoute.galleryEmpty.name,
            pageBuilder: (context, state) =>
                _materialPage<void>(state, const EmptyDemoScreen()),
          ),
        ],
      ),
    ],
  );
  // Provider 销毁时释放路由器持有的资源。
  ref.onDispose(router.dispose);
  return router;
});

// go_router 18 的 material_ui 类型识别不兼容 SDK MaterialApp，需显式指定页面。
MaterialPage<T> _materialPage<T>(GoRouterState state, Widget child) {
  return MaterialPage<T>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: {...state.pathParameters, ...state.uri.queryParameters},
    restorationId: state.pageKey.value,
    child: child,
  );
}

/// 路由参数非法（如 /users/abc）时的兜底页。
class _InvalidUserIdScreen extends StatelessWidget {
  const _InvalidUserIdScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户详情')),
      body: Center(
        child: Text('无效的用户 ID', style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
