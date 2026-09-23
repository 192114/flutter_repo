import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageCropSessionStoreProvider = Provider<ImageCropSessionStore>((ref) {
  final store = ImageCropSessionStore();
  ref.onDispose(store.dispose);
  return store;
});

/// 仅在内存中保留待裁剪字节；路由只携带会话 ID，不支持恢复原图。
class ImageCropSessionStore {
  final _sessions = <String, Uint8List>{};
  int _nextId = 0;

  String create(Uint8List bytes) {
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';
    _sessions[id] = Uint8List.fromList(bytes).asUnmodifiableView();
    return id;
  }

  Uint8List? read(String id) => _sessions[id];

  void release(String id) => _sessions.remove(id);

  void dispose() => _sessions.clear();
}
