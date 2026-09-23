import 'dart:typed_data';

import 'package:flutter_repo/data/services/image_crop_session_store.dart';
import 'package:flutter_repo/ui/features/image_crop/view_model/image_crop_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('会话按唯一 ID 读取，输入和输出均不可外部改写', () {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final bytes = Uint8List.fromList([1, 2, 3]);
    final first = sessions.create(bytes);
    final second = sessions.create(bytes);
    expect(first, isNot(second));
    bytes[0] = 9;
    final subscription = container.listen(
      imageCropViewModelProvider(first),
      (_, _) {},
    );
    expect(subscription.read(), [1, 2, 3]);
    expect(() => subscription.read()![0] = 9, throwsUnsupportedError);
    sessions.release(first);
    expect(sessions.read(first), isNull);
    expect(sessions.read(second), [1, 2, 3]);
  });

  test('过期或未知 ID 返回空状态', () {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(Uint8List.fromList([1]));
    sessions.release(id);
    expect(
      container.listen(imageCropViewModelProvider(id), (_, _) {}).read(),
      isNull,
    );
    expect(
      container.listen(imageCropViewModelProvider('missing'), (_, _) {}).read(),
      isNull,
    );
  });

  test('取消立即释放会话且可重复清理', () {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(Uint8List.fromList([1]));
    container.listen(imageCropViewModelProvider(id), (_, _) {});
    final viewModel = container.read(imageCropViewModelProvider(id).notifier);
    expect(viewModel.cancel(), isTrue);
    expect(viewModel.cancel(), isFalse);
    expect(viewModel.complete(Uint8List.fromList([2])), isNull);
    expect(sessions.read(id), isNull);
  });

  test('完成返回裁剪结果并立即释放源图会话', () {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(Uint8List.fromList([1]));
    container.listen(imageCropViewModelProvider(id), (_, _) {});
    final bytes = Uint8List.fromList([8, 9]);
    expect(
      container.read(imageCropViewModelProvider(id).notifier).complete(bytes),
      same(bytes),
    );
    expect(sessions.read(id), isNull);
  });

  test('最后一个页面监听移除后释放会话，重新访问已过期', () async {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(Uint8List.fromList([1]));
    final first = container.listen(imageCropViewModelProvider(id), (_, _) {});
    final second = container.listen(imageCropViewModelProvider(id), (_, _) {});
    first.close();
    await container.pump();
    expect(sessions.read(id), isNotNull);
    second.close();
    await container.pump();
    expect(sessions.read(id), isNull);
    expect(
      container.listen(imageCropViewModelProvider(id), (_, _) {}).read(),
      isNull,
    );
  });

  test('容器卸载释放尚未打开的会话', () {
    final container = ProviderContainer();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(Uint8List.fromList([1]));
    container.dispose();
    expect(sessions.read(id), isNull);
  });
}
