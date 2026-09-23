import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_image_cropper.dart';
import '../view_model/image_crop_view_model.dart';

class ImageCropScreen extends ConsumerWidget {
  const ImageCropScreen({super.key, required this.sessionId});

  final String sessionId;

  void _close(BuildContext context, [Uint8List? result]) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go('/gallery/upload');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(imageCropViewModelProvider(sessionId));
    final viewModel = ref.read(imageCropViewModelProvider(sessionId).notifier);
    void cancel() {
      if (viewModel.cancel()) _close(context);
    }

    return PopScope<Uint8List>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) viewModel.cancel();
      },
      child: bytes == null
          ? Scaffold(
              appBar: AppBar(title: const Text('剪裁')),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('裁剪会话已过期，请重新选择图片'),
                    TextButton(onPressed: cancel, child: const Text('关闭')),
                  ],
                ),
              ),
            )
          : AppImageCropper(
              imageBytes: bytes,
              onCropped: (result) {
                final completed = viewModel.complete(result);
                if (completed != null) _close(context, completed);
              },
              onCancel: cancel,
            ),
    );
  }
}
