import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储服务：负责 Access Token 等敏感数据的持久化（iOS Keychain / Android Keystore）。
///
/// 只做「读写删除」这一件事，不含任何业务逻辑；
/// 由 [AuthInterceptor] 组合使用，向上层屏蔽具体存储实现。
class TokenStorageService {
  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_access_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}

/// 依赖注入：TokenStorageService 的唯一装配点。
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});
