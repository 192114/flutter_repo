import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

/// 图片剪裁器：全屏深色编辑页，支持比例切换、旋转与双指缩放/拖拽。
///
/// 输出为 PNG 字节，由调用方决定后续上传或预览。页面恒为深色风格，
/// 与主题明暗无关（仅主色取当前 token）。
///
/// 旋转只记录 90° 的整数倍并在预览绘制时做画布变换，导出时统一映射
/// 回原图像素坐标——不生成旋转像素副本，旋转即时生效且无异步竞态。
class AppImageCropper extends StatefulWidget {
  AppImageCropper({
    super.key,
    required this.imageBytes,
    required this.onCropped,
    required this.onCancel,
    this.initialAspectRatio = 1,
    this.lockAspectRatio = false,
    List<double?> allowedAspectRatios = const [null, 1, 4 / 3, 16 / 9],
    this.maxDecodeDimension = 2048,
  }) : assert(_validRatio(initialAspectRatio)),
       assert(!lockAspectRatio || initialAspectRatio != null),
       assert(allowedAspectRatios.isNotEmpty),
       assert(allowedAspectRatios.every(_validRatio)),
       assert(allowedAspectRatios.toSet().length == allowedAspectRatios.length),
       assert(
         lockAspectRatio || allowedAspectRatios.contains(initialAspectRatio),
       ),
       assert(maxDecodeDimension > 0),
       allowedAspectRatios = List.unmodifiable(allowedAspectRatios);

  final Uint8List imageBytes;

  /// 初始宽高比；null 为自由裁剪。更改后会重置编辑状态。
  final double? initialAspectRatio;

  /// 锁定初始比例时隐藏比例选择，且初始比例不能为 null。
  final bool lockAspectRatio;

  /// 可选宽高比，null 表示自由；非锁定时须包含初始比例。
  final List<double?> allowedAspectRatios;

  /// 解码最长边上限（像素），预览和 PNG 导出共用此分辨率。
  final int maxDecodeDimension;

  /// 仅输出 PNG 数据，不执行导航。失败时显示错误提示，不回调。
  final ValueChanged<Uint8List> onCropped;
  final VoidCallback onCancel;

  static bool _validRatio(double? ratio) =>
      ratio == null || (ratio.isFinite && ratio > 0);

  @override
  State<AppImageCropper> createState() => _AppImageCropperState();
}

class _AppImageCropperState extends State<AppImageCropper> {
  String _ratioLabel(double? ratio, AppLocalizations l10n) => switch (ratio) {
    null => l10n.freeAspectRatio,
    1 => '1:1',
    _ when ratio == 4 / 3 => '4:3',
    _ when ratio == 16 / 9 => '16:9',
    _ =>
      '${ratio == ratio.truncateToDouble() ? ratio.toStringAsFixed(0) : ratio}:1',
  };

  /// 自由比例下剪裁框的最小边长（逻辑像素）。
  static const _minFreeSide = 80.0;

  ui.Image? _image;
  double? _aspectRatio;

  /// 顺时针 90° 旋转次数（0~3），仅影响预览变换与导出坐标映射。
  int _rotationQuarter = 0;

  /// 图片缩放（>=1，1 为恰好覆盖剪裁框）与相对剪裁框中心的偏移。
  double _scale = 1;
  Offset _offset = Offset.zero;

  /// 本次手势开始时的缩放倍率；[ScaleUpdateDetails.scale] 是相对手势
  /// 起点的累计值，必须乘以起点倍率，而非反复叠乘当前值。
  double? _gestureStartScale;

  /// 自由比例下的剪裁框（布局坐标）；为 null 时按图片比例初始化。
  Rect? _freeCropRect;
  Size _layoutSize = Size.zero;

  bool _busy = false;
  bool _decodeFailed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _aspectRatio = widget.initialAspectRatio;
    unawaited(_decode());
  }

  @override
  void didUpdateWidget(covariant AppImageCropper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes ||
        oldWidget.maxDecodeDimension != widget.maxDecodeDimension ||
        oldWidget.initialAspectRatio != widget.initialAspectRatio ||
        oldWidget.lockAspectRatio != widget.lockAspectRatio ||
        !listEquals(
          oldWidget.allowedAspectRatios,
          widget.allowedAspectRatios,
        )) {
      _image?.dispose();
      _image = null;
      _aspectRatio = widget.initialAspectRatio;
      _rotationQuarter = 0;
      _freeCropRect = null;
      _busy = false;
      _resetTransform();
      unawaited(_decode());
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    final generation = ++_generation;
    setState(() => _decodeFailed = false);

    // Web 不支持直接读取 ImageDescriptor 尺寸，交由跨平台解码回调限幅。
    ui.Codec? codec;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(widget.imageBytes);
      codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (width, height) {
          final longest = math.max(width, height);
          if (longest <= widget.maxDecodeDimension) {
            return const ui.TargetImageSize();
          }
          final scale = widget.maxDecodeDimension / longest;
          return ui.TargetImageSize(
            width: math.max(1, (width * scale).round()),
            height: math.max(1, (height * scale).round()),
          );
        },
      );
      final frame = await codec.getNextFrame();
      if (!mounted || generation != _generation) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _decodeFailed = true);
      }
    } finally {
      codec?.dispose();
    }
  }

  // ---------- 几何计算 ----------

  /// 旋转后的显示尺寸：奇数次旋转宽高互换。
  Size _displaySize(ui.Image image) => _rotationQuarter.isOdd
      ? Size(image.height.toDouble(), image.width.toDouble())
      : Size(image.width.toDouble(), image.height.toDouble());

  Rect _fitRect(Size bounds, double ratio) {
    var width = bounds.width;
    var height = width / ratio;
    if (height > bounds.height) {
      height = bounds.height;
      width = height * ratio;
    }
    return Rect.fromCenter(
      center: bounds.center(Offset.zero),
      width: width,
      height: height,
    );
  }

  Rect _resolveCropRect(Size bounds, ui.Image image) {
    final ratio = _aspectRatio;
    if (ratio == null) {
      final display = _displaySize(image);
      return _freeCropRect ??= _fitRect(bounds, display.width / display.height);
    }
    return _fitRect(bounds, ratio);
  }

  /// 计算恰好覆盖剪裁框的图片布局尺寸（scale 1 时的尺寸，旋转后的显示尺寸）。
  Size _coverSize(Size viewport, Size display) {
    final imageAspect = display.width / display.height;
    if (imageAspect > viewport.aspectRatio) {
      return Size(viewport.height * imageAspect, viewport.height);
    }
    return Size(viewport.width, viewport.width / imageAspect);
  }

  void _clampOffset(Rect cropRect, Size childSize) {
    final scaled = childSize * _scale;
    final maxDx = math.max(0.0, (scaled.width - cropRect.width) / 2);
    final maxDy = math.max(0.0, (scaled.height - cropRect.height) / 2);
    _offset = Offset(
      _offset.dx.clamp(-maxDx, maxDx),
      _offset.dy.clamp(-maxDy, maxDy),
    );
  }

  void _resetTransform() {
    _scale = 1;
    _offset = Offset.zero;
    _gestureStartScale = null;
  }

  // ---------- 手势 ----------

  void _onScaleStart() => _gestureStartScale = _scale;

  void _onScaleUpdate(
    ScaleUpdateDetails details,
    Rect cropRect,
    Size childSize,
  ) {
    if (_busy) return;
    final start = _gestureStartScale ?? _scale;
    setState(() {
      if (details.scale != 1) {
        final next = (start * details.scale).clamp(1.0, 5.0);
        final factor = next / _scale;
        final center = cropRect.center;
        // localFocalPoint 以剪裁框左上角为原点，换算回布局坐标。
        final focal = details.localFocalPoint + cropRect.topLeft;
        _offset = focal - center - (focal - center - _offset) * factor;
        _scale = next;
      }
      _offset += details.focalPointDelta;
      _clampOffset(cropRect, childSize);
    });
  }

  /// 分角约束：被拖动的边只与「固定的对边」比较，保证 clamp 上下限
  /// 永不倒置（拖过对边时停在最短边长处）。
  void _onHandleDrag(int corner, Offset delta, Size bounds) {
    final rect = _freeCropRect;
    if (rect == null || _busy) return;
    if (bounds.width < _minFreeSide * 2 || bounds.height < _minFreeSide * 2) {
      return;
    }

    final minWidth = math.min(_minFreeSide, rect.width);
    final minHeight = math.min(_minFreeSide, rect.height);
    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;
    switch (corner) {
      case 0: // 左上：右、下边固定
        left = (left + delta.dx).clamp(0.0, right - minWidth);
        top = (top + delta.dy).clamp(0.0, bottom - minHeight);
      case 1: // 右上：左、下边固定
        right = (right + delta.dx).clamp(left + minWidth, bounds.width);
        top = (top + delta.dy).clamp(0.0, bottom - minHeight);
      case 2: // 左下：右、上边固定
        left = (left + delta.dx).clamp(0.0, right - minWidth);
        bottom = (bottom + delta.dy).clamp(top + minHeight, bounds.height);
      case 3: // 右下：左、上边固定
        right = (right + delta.dx).clamp(left + minWidth, bounds.width);
        bottom = (bottom + delta.dy).clamp(top + minHeight, bounds.height);
    }

    setState(() {
      _freeCropRect = Rect.fromLTRB(left, top, right, bottom);
      // 框尺寸变化会改变 cover 基准，重置变换避免图片跳动。
      _resetTransform();
    });
  }

  // ---------- 操作 ----------

  /// 旋转仅推进四分之一圈计数，预览与导出按变换处理，无异步、无新位图。
  void _rotate() {
    if (_image == null || _busy) return;
    setState(() {
      _rotationQuarter = (_rotationQuarter + 1) % 4;
      _freeCropRect = null;
      _resetTransform();
    });
  }

  Future<void> _confirm() async {
    final image = _image;
    if (image == null || _busy) return;
    final generation = _generation;
    setState(() => _busy = true);

    try {
      final cropRect = _resolveCropRect(_layoutSize, image);
      final display = _displaySize(image);
      final childSize = _coverSize(cropRect.size, display);
      final center = cropRect.center;
      final childCenter = childSize.center(Offset.zero);

      // 布局坐标 → 旋转后显示坐标（布局单位）。
      Offset toChild(double x, double y) => Offset(
        childCenter.dx + (x - center.dx - _offset.dx) / _scale,
        childCenter.dy + (y - center.dy - _offset.dy) / _scale,
      );
      // 显示坐标（布局单位）→ 显示像素坐标，并裁剪到显示图范围内。
      final pixelScale = display.width / childSize.width;
      final cropDisp = Rect.fromPoints(
        toChild(cropRect.left, cropRect.top) * pixelScale,
        toChild(cropRect.right, cropRect.bottom) * pixelScale,
      ).intersect(Offset.zero & display);
      if (cropDisp.isEmpty) {
        throw StateError('剪裁区域为空');
      }

      final outWidth = math.max(1, cropDisp.width.round());
      final outHeight = math.max(1, cropDisp.height.round());
      final recorder = ui.PictureRecorder();
      ui.Image? output;
      try {
        // 与预览相同的旋转变换：输出画布工作在显示像素坐标系，
        // 绘制的是旋转后的内容而非原图未旋转像素。
        final canvas = Canvas(recorder)
          ..scale(outWidth / cropDisp.width, outHeight / cropDisp.height)
          ..translate(-cropDisp.left, -cropDisp.top);
        switch (_rotationQuarter) {
          case 1:
            canvas
              ..translate(display.width, 0)
              ..rotate(math.pi / 2);
          case 2:
            canvas
              ..translate(display.width, display.height)
              ..rotate(math.pi);
          case 3:
            canvas
              ..translate(0, display.height)
              ..rotate(-math.pi / 2);
        }
        final src = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        canvas.drawImageRect(
          image,
          src,
          src,
          Paint()..filterQuality = FilterQuality.high,
        );
        final picture = recorder.endRecording();
        try {
          output = await picture.toImage(outWidth, outHeight);
        } finally {
          picture.dispose();
        }
        final data = await output.toByteData(format: ui.ImageByteFormat.png);
        if (!mounted || generation != _generation) return;
        if (data == null) throw StateError('PNG 编码失败');
        widget.onCropped(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } finally {
        output?.dispose();
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cropFailed)),
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  // ---------- 构建 ----------

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _NavAction(
                        label: l10n.cancel,
                        color: Colors.white70,
                        onTap: _busy ? null : widget.onCancel,
                      ),
                    ),
                    Text(
                      l10n.cropImage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : _NavAction(
                              label: l10n.done,
                              color: colors.primary,
                              onTap: _image == null ? null : _confirm,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  if (_layoutSize != size) {
                    _layoutSize = size;
                    _freeCropRect = null;
                  }
                  final image = _image;
                  if (image == null) {
                    if (_decodeFailed) {
                      return _DecodeErrorView(
                        onRetry: _decode,
                        onCancel: widget.onCancel,
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    );
                  }

                  final cropRect = _resolveCropRect(size, image);
                  final childSize = _coverSize(
                    cropRect.size,
                    _displaySize(image),
                  );
                  _clampOffset(cropRect, childSize);
                  final scaled = childSize * _scale;
                  final topLeft =
                      cropRect.center +
                      _offset -
                      Offset(scaled.width / 2, scaled.height / 2);

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRect(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: topLeft.dx,
                                top: topLeft.dy,
                                width: scaled.width,
                                height: scaled.height,
                                child: CustomPaint(
                                  painter: _RotatedImagePainter(
                                    image: image,
                                    quarter: _rotationQuarter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CropOverlayPainter(rect: cropRect),
                          ),
                        ),
                      ),
                      Positioned.fromRect(
                        rect: cropRect,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: (_) => _onScaleStart(),
                          onScaleUpdate: (details) =>
                              _onScaleUpdate(details, cropRect, childSize),
                        ),
                      ),
                      if (_aspectRatio == null)
                        ..._buildHandles(cropRect, size),
                    ],
                  );
                },
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: widget.lockAspectRatio
                          ? const SizedBox.shrink()
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final ratio
                                      in widget.allowedAspectRatios)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: AppSpacing.sm,
                                      ),
                                      child: _RatioChip(
                                        label: _ratioLabel(ratio, l10n),
                                        selected: _aspectRatio == ratio,
                                        onTap: _busy
                                            ? null
                                            : () => setState(() {
                                                _aspectRatio = ratio;
                                                _freeCropRect = null;
                                                _resetTransform();
                                              }),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : _rotate,
                      icon: const Icon(
                        Icons.rotate_right_rounded,
                        color: Colors.white,
                      ),
                      tooltip: l10n.rotateImage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHandles(Rect rect, Size bounds) {
    const hit = 44.0;
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    return [
      for (var i = 0; i < corners.length; i++)
        Positioned(
          left: corners[i].dx - hit / 2,
          top: corners[i].dy - hit / 2,
          width: hit,
          height: hit,
          child: Semantics(
            label: AppLocalizations.of(context)!.cropImage,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) => _onHandleDrag(i, details.delta, bounds),
            ),
          ),
        ),
    ];
  }
}

class _DecodeErrorView extends StatelessWidget {
  const _DecodeErrorView({required this.onRetry, required this.onCancel});

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
          size: 48,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppLocalizations.of(context)!.imageLoadFailed,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NavAction extends StatelessWidget {
  const _NavAction({required this.label, required this.color, this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RatioChip extends StatelessWidget {
  const _RatioChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: AppRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.primaryForeground : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// 按 [quarter] 旋转绘制原图：先缩放到显示尺寸，再做画布旋转变换，
/// 原图像素直接映射，不产生旋转副本。
class _RotatedImagePainter extends CustomPainter {
  const _RotatedImagePainter({required this.image, required this.quarter});

  final ui.Image image;
  final int quarter;

  @override
  void paint(Canvas canvas, Size size) {
    final display = quarter.isOdd
        ? Size(image.height.toDouble(), image.width.toDouble())
        : Size(image.width.toDouble(), image.height.toDouble());
    final scale = size.width / display.width;

    canvas.save();
    canvas.scale(scale);
    switch (quarter) {
      case 1:
        canvas.translate(display.width, 0);
        canvas.rotate(math.pi / 2);
      case 2:
        canvas.translate(display.width, display.height);
        canvas.rotate(math.pi);
      case 3:
        canvas.translate(0, display.height);
        canvas.rotate(-math.pi / 2);
    }
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      src,
      src,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RotatedImagePainter oldDelegate) =>
      image != oldDelegate.image || quarter != oldDelegate.quarter;
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    // 框外 60% 黑遮罩。
    final dimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(
      dimPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // 九宫格辅助线。
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 2; i++) {
      final dx = rect.left + rect.width * i / 3;
      final dy = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(dx, rect.top), Offset(dx, rect.bottom), gridPaint);
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }

    // 白色边框。
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 四角 L 形加粗手柄。
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    const len = 20.0;
    void corner(Offset origin, double dirX, double dirY) {
      canvas.drawLine(origin, origin + Offset(len * dirX, 0), handlePaint);
      canvas.drawLine(origin, origin + Offset(0, len * dirY), handlePaint);
    }

    corner(rect.topLeft, 1, 1);
    corner(rect.topRight, -1, 1);
    corner(rect.bottomLeft, 1, -1);
    corner(rect.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      rect != oldDelegate.rect;
}
