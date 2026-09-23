import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/services/image_crop_session_store.dart';

final imageCropViewModelProvider = NotifierProvider.autoDispose
    .family<ImageCropViewModel, Uint8List?, String>(ImageCropViewModel.new);

class ImageCropViewModel extends Notifier<Uint8List?> {
  ImageCropViewModel(this.sessionId);

  final String sessionId;
  late ImageCropSessionStore _sessions;
  bool _closed = false;

  @override
  Uint8List? build() {
    final sessions = ref.read(imageCropSessionStoreProvider);
    _sessions = sessions;
    _closed = false;
    ref.onDispose(() {
      _closed = true;
      sessions.release(sessionId);
    });
    return sessions.read(sessionId);
  }

  bool cancel() {
    if (_closed) return false;
    _closed = true;
    _sessions.release(sessionId);
    return true;
  }

  Uint8List? complete(Uint8List bytes) => cancel() ? bytes : null;
}
