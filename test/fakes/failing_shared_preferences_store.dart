import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// 落盘永远失败的内存 store：模拟磁盘写入失败
/// （如 Android SharedPreferences.commit 返回 false）。
class FailingWriteStore extends InMemorySharedPreferencesStore {
  FailingWriteStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
