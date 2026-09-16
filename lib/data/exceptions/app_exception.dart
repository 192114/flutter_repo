/// Data Layer 统一异常定义。
///
/// Repository 负责把底层技术异常（DioException、存储异常等）
/// 转换为语义化的 [AppException]，保证上层（UI / ViewModel）
/// 不与任何具体技术实现耦合。
///
/// 使用 sealed class：编译器可穷举所有子类型，
/// UI 层 switch 处理时不会遗漏分支。
sealed class AppException implements Exception {
  const AppException(this.message);

  /// 面向用户的可读错误信息。
  final String message;

  @override
  String toString() => message;
}

/// 网络不可用 / 超时 / 服务器 5xx。
final class NetworkException extends AppException {
  const NetworkException([super.message = '网络连接失败，请检查网络后重试']);
}

/// 请求的资源不存在（404）。
final class NotFoundException extends AppException {
  const NotFoundException([super.message = '请求的数据不存在']);
}

/// 本地缓存读写失败。
final class CacheException extends AppException {
  const CacheException([super.message = '本地数据读写失败']);
}

/// 其他未预期异常。
final class UnknownException extends AppException {
  const UnknownException([super.message = '发生未知错误，请稍后重试']);
}
