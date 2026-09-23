import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

/// 单张图片的上传状态。
enum AppUploadImageStatus { uploading, success, failed }

/// 上传列表项数据。
///
/// [image] 为本地缩略图（通常用 [MemoryImage] 承载选择/剪裁后的字节），
/// 组件本身不发起网络请求，上传进度由外部驱动后重建列表项更新。
class AppUploadImageItem {
  const AppUploadImageItem({
    required this.id,
    required this.image,
    this.status = AppUploadImageStatus.success,
    this.progress = 0,
  }) : assert(progress >= 0 && progress <= 1);

  /// 列表内唯一且跨重排稳定的标识；不得使用当前下标代替。
  final Object id;
  final ImageProvider<Object> image;
  final AppUploadImageStatus status;

  /// 上传进度 0~1，仅 [AppUploadImageStatus.uploading] 时生效。
  final double progress;
}

/// 受控图片上传组件：根据可用宽度排列正方形槽位与虚线添加入口。
///
/// 选择图片、上传请求与进度推进全部由调用方通过回调与重建驱动。
/// 需要有界宽度，默认目标尺寸在手机上约为三列。
class AppUploadImage extends StatelessWidget {
  AppUploadImage({
    super.key,
    this.label,
    required List<AppUploadImageItem> items,
    this.maxCount = 9,
    this.maxItemExtent = 128,
    this.adding = false,
    this.onAdd,
    this.onRemove,
    this.onRetry,
    this.onPreview,
    this.hint,
  }) : assert(maxCount > 0),
       assert(items.length <= maxCount),
       assert(items.map((item) => item.id).toSet().length == items.length),
       assert(maxItemExtent.isFinite && maxItemExtent > 0),
       items = List.unmodifiable(items);

  /// 标签文案（如「上传图片」），右侧自动展示 `已传/上限` 计数。
  final String? label;

  final List<AppUploadImageItem> items;

  /// 最大图片数量，必须大于零；达到后隐藏添加入口。
  final int maxCount;

  /// 槽位最大目标边长（逻辑像素）；列数随父布局宽度变化。
  final double maxItemExtent;

  /// 选图/裁剪进行中：保留添加入口，但禁用交互。
  final bool adding;

  /// 点击虚线添加入口；为 null 或已达上限时不展示入口。
  final VoidCallback? onAdd;

  /// 点击删除角标，回传稳定 ID。
  final ValueChanged<Object>? onRemove;

  /// 点击失败项重试，回传稳定 ID。
  final ValueChanged<Object>? onRetry;

  /// 点击成功项预览，回传稳定 ID。
  final ValueChanged<Object>? onPreview;

  /// 底部约束说明（如格式与大小限制）。
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  label!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${items.length}/$maxCount',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            assert(constraints.hasBoundedWidth);
            const gap = AppSpacing.sm;
            final columns = math.max(
              1,
              ((constraints.maxWidth + gap) / (maxItemExtent + gap)).ceil(),
            );
            final slot = math.max(
              0.0,
              (constraints.maxWidth - gap * (columns - 1)) / columns,
            );
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in items)
                  _ItemSlot(
                    key: ValueKey<Object>(item.id),
                    item: item,
                    size: slot,
                    onRemove: onRemove == null
                        ? null
                        : () => onRemove!(item.id),
                    onRetry: onRetry == null ? null : () => onRetry!(item.id),
                    onPreview: onPreview == null
                        ? null
                        : () => onPreview!(item.id),
                  ),
                if (onAdd != null && items.length < maxCount)
                  _AddSlot(
                    size: slot,
                    adding: adding,
                    onTap: adding ? null : onAdd,
                  ),
              ],
            );
          },
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            hint!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.mutedForeground),
          ),
        ],
      ],
    );
  }
}

class _ItemSlot extends StatelessWidget {
  const _ItemSlot({
    super.key,
    required this.item,
    required this.size,
    this.onRemove,
    this.onRetry,
    this.onPreview,
  });

  final AppUploadImageItem item;
  final double size;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final deleteLabel = MaterialLocalizations.of(context).deleteButtonTooltip;
    final status = item.status;
    final onTap = switch (status) {
      AppUploadImageStatus.failed => onRetry,
      AppUploadImageStatus.success => onPreview,
      AppUploadImageStatus.uploading => null,
    };

    final String semanticsLabel;
    final bool semanticsButton;
    switch (status) {
      case AppUploadImageStatus.uploading:
        semanticsLabel =
            '${l10n.uploading} ${(item.progress.clamp(0.0, 1.0) * 100).round()}%';
        semanticsButton = false;
      case AppUploadImageStatus.failed:
        semanticsLabel = onRetry == null ? l10n.uploadFailed : l10n.retryUpload;
        semanticsButton = onRetry != null;
      case AppUploadImageStatus.success:
        semanticsLabel = onPreview == null
            ? l10n.uploadedImage
            : l10n.previewImage;
        semanticsButton = onPreview != null;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppRadius.circular(AppRadius.md),
              child: Semantics(
                container: true,
                button: semanticsButton,
                label: semanticsLabel,
                excludeSemantics: true,
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      // 槽位为正方形，按物理像素解码避免 2048px 原图全尺寸进内存。
                      image: ResizeImage(
                        item.image,
                        width: math.max(
                          1,
                          (size * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                        ),
                        height: math.max(
                          1,
                          (size * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                        ),
                        policy: ResizeImagePolicy.fit,
                      ),
                      fit: BoxFit.cover,
                    ),
                    if (status != AppUploadImageStatus.success)
                      ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                    if (status == AppUploadImageStatus.uploading)
                      _UploadingOverlay(progress: item.progress),
                    if (status == AppUploadImageStatus.failed)
                      _FailedOverlay(canRetry: onRetry != null),
                    Positioned.fill(
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(onTap: onTap),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onRemove != null && status != AppUploadImageStatus.uploading)
            Positioned(
              top: 0,
              right: 0,
              width: math.min(48, size),
              height: math.min(48, size),
              child: Semantics(
                container: true,
                label: deleteLabel,
                button: true,
                excludeSemantics: true,
                onTap: onRemove,
                child: IconButton(
                  tooltip: deleteLabel,
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  icon: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.isDarkMode
                          ? colors.input
                          : Colors.black.withValues(alpha: 0.6),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = progress.clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: ClipRRect(
            borderRadius: AppRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(
                context.isDarkMode ? colors.primary : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FailedOverlay extends StatelessWidget {
  const _FailedOverlay({required this.canRetry});

  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            canRetry
                ? AppLocalizations.of(context)!.retryUpload
                : AppLocalizations.of(context)!.uploadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AddSlot extends StatelessWidget {
  const _AddSlot({required this.size, required this.adding, this.onTap});

  final double size;
  final bool adding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final l10n = AppLocalizations.of(context)!;
    final label = adding ? l10n.uploading : l10n.addImage;

    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.circular(AppRadius.md),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: colors.input,
              radius: AppRadius.md,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    adding ? Icons.hourglass_top : Icons.add,
                    size: 28,
                    color: colors.mutedForeground,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _dashWidth = 6.0;
  static const _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(0.5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}

// ---------- Previews ----------

final _previewImageA = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);
final _previewImageB = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

@Preview(name: 'UploadImage · Light', group: 'Form', size: Size(420, 360))
Widget appUploadImageLightPreview() => _uploadImagePreview(AppTheme.light);

@Preview(name: 'UploadImage · Dark', group: 'Form', size: Size(420, 360))
Widget appUploadImageDarkPreview() => _uploadImagePreview(AppTheme.dark);

Widget _uploadImagePreview(ThemeData theme) => MaterialApp(
  theme: theme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppUploadImage(
        label: '上传图片',
        hint: '支持 JPG / PNG，单张不超过 10MB',
        items: [
          AppUploadImageItem(id: 'success', image: _previewImageA),
          AppUploadImageItem(
            id: 'uploading',
            image: _previewImageB,
            status: AppUploadImageStatus.uploading,
            progress: 0.65,
          ),
          AppUploadImageItem(
            id: 'failed',
            image: _previewImageA,
            status: AppUploadImageStatus.failed,
          ),
        ],
        onAdd: () {},
        onRemove: (_) {},
        onRetry: (_) {},
      ),
    ),
  ),
);
