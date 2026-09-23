import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/services/image_crop_session_store.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_upload_image.dart';
import 'gallery_section.dart';

/// 图片上传演示页：真实选图 → 剪裁 → 模拟上传进度，以及三态静态示例。
class UploadImageDemoScreen extends ConsumerStatefulWidget {
  const UploadImageDemoScreen({super.key});

  @override
  ConsumerState<UploadImageDemoScreen> createState() =>
      _UploadImageDemoScreenState();
}

class _UploadImageDemoScreenState extends ConsumerState<UploadImageDemoScreen> {
  static const _maxCount = 9;
  static const _maxBytes = 10 * 1024 * 1024;

  final _picker = ImagePicker();
  final _items = <AppUploadImageItem>[];
  final _timers = <Object, Timer>{};
  late final ImageCropSessionStore _sessions;
  String? _activeSessionId;
  int _nextId = 0;
  bool _picking = false;

  static final _mockImageA = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    ),
  );
  static final _mockImageB = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ),
  );

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(imageCropSessionStoreProvider);
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    final sessionId = _activeSessionId;
    if (sessionId != null) _sessions.release(sessionId);
    super.dispose();
  }

  Future<void> _add() async {
    if (_picking) return;
    if (_items.length >= _maxCount) {
      AppToast.error(context, '最多上传 $_maxCount 张图片');
      return;
    }

    setState(() => _picking = true);
    String? sessionId;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxBytes) {
        AppToast.error(context, '图片大小不能超过 10MB');
        return;
      }

      sessionId = _sessions.create(bytes);
      _activeSessionId = sessionId;
      final cropped = await context.push<Uint8List>('/image-crop/$sessionId');
      if (cropped == null || !mounted) return;
      if (_items.length >= _maxCount) {
        AppToast.error(context, '最多上传 $_maxCount 张图片');
        return;
      }

      final id = _nextId++;
      setState(() {
        _items.add(
          AppUploadImageItem(
            id: id,
            image: MemoryImage(cropped),
            status: AppUploadImageStatus.uploading,
          ),
        );
      });
      _startUpload(id);
    } on Exception {
      if (mounted) AppToast.error(context, '选择图片失败，请重试');
    } finally {
      if (sessionId != null) _sessions.release(sessionId);
      _activeSessionId = null;
      if (mounted) setState(() => _picking = false);
    }
  }

  void _startUpload(Object id) {
    _timers.remove(id)?.cancel();
    _timers[id] = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final index = _items.indexWhere((item) => item.id == id);
      if (!mounted || index < 0) {
        timer.cancel();
        _timers.remove(id);
        return;
      }
      final item = _items[index];
      final progress = item.progress + 0.05;
      setState(() {
        _items[index] = AppUploadImageItem(
          id: id,
          image: item.image,
          status: progress >= 1
              ? AppUploadImageStatus.success
              : AppUploadImageStatus.uploading,
          progress: progress.clamp(0.0, 1.0),
        );
      });
      if (_items[index].status == AppUploadImageStatus.success) {
        timer.cancel();
        _timers.remove(id);
      }
    });
  }

  void _remove(Object id) {
    _timers.remove(id)?.cancel();
    setState(() => _items.removeWhere((item) => item.id == id));
  }

  void _retry(Object id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    setState(() {
      _items[index] = AppUploadImageItem(
        id: id,
        image: _items[index].image,
        status: AppUploadImageStatus.uploading,
      );
    });
    _startUpload(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('图片上传')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 720 ? 720 : double.infinity,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                GallerySection(
                  title: '选择并剪裁',
                  description: '从相册选图后进入剪裁页，确认后模拟上传进度。',
                  child: AppUploadImage(
                    label: '上传图片',
                    hint: '支持 JPG / PNG，单张不超过 10MB',
                    items: _items,
                    adding: _picking,
                    onAdd: _add,
                    onRemove: _remove,
                    onRetry: _retry,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '状态示例',
                  description: '成功、上传中与失败三态的静态展示。',
                  child: AppUploadImage(
                    label: '现场照片',
                    items: [
                      AppUploadImageItem(id: 'success', image: _mockImageA),
                      AppUploadImageItem(
                        id: 'uploading',
                        image: _mockImageB,
                        status: AppUploadImageStatus.uploading,
                        progress: 0.65,
                      ),
                      AppUploadImageItem(
                        id: 'failed',
                        image: _mockImageA,
                        status: AppUploadImageStatus.failed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
