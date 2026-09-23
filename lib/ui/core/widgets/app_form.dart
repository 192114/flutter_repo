import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';
import 'app_calendar.dart';
import 'app_input.dart';
import 'app_selection.dart';

/// 左侧标签列宽与表单行高下限（设计稿标注：Label 88 · Row ≥ 52）。
const double _kLeftLabelWidth = 88;
const double _kRowMinHeight = 52;

/// 标签位置：控件上方（默认）或左侧。
enum AppFormItemLayout { top, left }

/// 表单分组卡片：tonal 圆角容器，行与行只用留白分组，不渲染任何分割线。
///
/// 规格（与设计稿一致）：`muted` 填充、圆角 16、内边距 16/12；
/// 明暗两版共用同一语义 token，仅取值不同。
/// 卡片内的行控件请用 [AppPickerField] 的平铺样式（`filled: false`），
/// 点击水波纹由本卡片的 Material 提供。
class AppFormCard extends StatelessWidget {
  const AppFormCard({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
  });

  final List<Widget> children;

  /// 行与行之间的留白（替代分割线）。
  final double spacing;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.muted,
    borderRadius: AppRadius.circular(AppRadius.lg),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: children,
      ),
    ),
  );
}

/// 表单项：统一标签、必填标记、辅助与错误文案的排版容器。
///
/// - 上方标签（[AppFormItemLayout.top]，默认）：弱化色标签在控件上方，
///   间距 8；错误/辅助文案紧贴控件下方；
/// - 左侧标签（[AppFormItemLayout.left]）：固定 88 宽标签列 + 控件区，
///   行高 ≥52；错误/辅助文案缩进对齐控件区左缘；
/// - 文本输入控件（[AppInput]）请置 `label` 为 null，标签由本组件统一渲染；
///   其错误文案仍走 [AppInput.errorText]（自带读屏语义）。
class AppFormItem extends StatelessWidget {
  const AppFormItem({
    super.key,
    required this.label,
    required this.child,
    this.layout = AppFormItemLayout.top,
    this.labelWidth = _kLeftLabelWidth,
    this.required = false,
    this.helper,
    this.errorText,
  }) : assert(labelWidth > 0 && labelWidth < double.infinity);

  final String label;
  final double labelWidth;

  /// 标签位置。
  final AppFormItemLayout layout;

  /// 表单控件（输入框、选择字段、开关等）。
  final Widget child;

  /// 必填：标签前追加危险色星号。
  final bool required;

  /// 辅助说明（控件下方，弱化色）；[errorText] 非空时被其取代。
  final String? helper;

  /// 错误文案：非空即渲染错误行（危险色图标 + 文案）。
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: colors.mutedForeground, fontWeight: FontWeight.w500);

    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (required) ...[
          Text(
            '*',
            style: labelStyle?.copyWith(
              color: colors.destructive,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
        ],
        Flexible(child: Text(label, style: labelStyle)),
      ],
    );

    final feedback = _buildFeedback(context);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useLeft =
            layout == AppFormItemLayout.left &&
            textScale <= 1.3 &&
            constraints.maxWidth >=
                labelWidth + AppSpacing.md + 160 * textScale;
        if (useLeft) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _kRowMinHeight),
                child: Row(
                  children: [
                    SizedBox(width: labelWidth, child: labelRow),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: child),
                  ],
                ),
              ),
              if (feedback != null)
                Padding(
                  padding: EdgeInsets.only(left: labelWidth + AppSpacing.md),
                  child: feedback,
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            labelRow,
            const SizedBox(height: AppSpacing.sm),
            child,
            if (feedback != null) ...[
              const SizedBox(height: AppSpacing.xs),
              feedback,
            ],
          ],
        );
      },
    );
  }

  Widget? _buildFeedback(BuildContext context) {
    final colors = context.colors;
    final hasError = errorText != null && errorText!.isNotEmpty;
    final hasHelper = helper != null && helper!.isNotEmpty;
    if (hasError) return _FieldError(errorText!);
    if (!hasHelper) return null;

    return Text(
      helper!,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: colors.mutedForeground, height: 1.3),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 14,
          color: context.colors.destructive,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.colors.destructive, height: 1.3),
          ),
        ),
      ],
    ),
  );
}

/// 表单选择字段：值 + 尾随图标的可点控件，配合 [AppFormItem] 使用。
///
/// 两种样式：
/// - 填充式（默认）：`muted` 底、圆角 12、高 ≥52，用于上方标签布局；
/// - 平铺式（`filled: false`）：无底色无圆角，用于 [AppFormCard] 内的
///   左侧标签行，水波纹由卡片 Material 提供；
/// 尾随图标未显式指定时，仅在可点时显示 chevron（只读行无箭头）；
/// [errorText] 同时控制危险色描边与字段下方的错误文案。
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    this.value,
    this.placeholder,
    this.onTap,
    this.enabled = true,
    this.filled = true,
    this.trailing,
    this.errorText,
    this.maxLines,
    this.semanticLabel,
  }) : assert(maxLines == null || maxLines > 0);

  /// 已选值文案；为 null 时显示 [placeholder]。
  final String? value;

  final String? placeholder;

  /// 点击回调（通常弹出选择层）；为 null 时不可点。
  final VoidCallback? onTap;

  final bool enabled;

  /// 是否填充式样式。
  final bool filled;

  /// 尾随控件；显式传入时始终显示（如日历、锁）。
  final Widget? trailing;

  final String? errorText;

  final int? maxLines;

  /// 读屏语义标签（如「所在地区：浙江省」）；缺省用值或占位文案。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = value != null && value!.isNotEmpty;
    final active = enabled && onTap != null;
    final hasError = errorText != null && errorText!.isNotEmpty;
    final displayText = hasValue
        ? value!
        : placeholder ?? AppLocalizations.of(context)!.selectPlaceholder;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kRowMinHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: filled ? AppSpacing.md : 0,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                maxLines: maxLines,
                overflow: maxLines == null
                    ? TextOverflow.clip
                    : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: hasValue && enabled
                      ? colors.foreground
                      : colors.mutedForeground,
                ),
              ),
            ),
            if (trailing != null || active) ...[
              const SizedBox(width: AppSpacing.sm),
              IconTheme(
                data: IconThemeData(
                  size: 20,
                  color: colors.mutedForeground.withValues(
                    alpha: enabled ? 1 : 0.6,
                  ),
                ),
                child: trailing ?? const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ],
        ),
      ),
    );

    final field = Semantics(
      button: onTap != null,
      enabled: onTap == null ? null : enabled,
      onTap: active ? onTap : null,
      label: semanticLabel ?? displayText,
      excludeSemantics: true,
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: filled ? AppRadius.circular(AppRadius.md) : null,
        child: content,
      ),
    );

    final styledField = filled
        ? Material(
            color: colors.muted,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.circular(AppRadius.md),
              side: hasError
                  ? BorderSide(color: colors.destructive, width: 2)
                  : BorderSide.none,
            ),
            child: field,
          )
        : hasError
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.destructive, width: 2),
            ),
            child: field,
          )
        : field;

    if (!hasError) return styledField;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        styledField,
        const SizedBox(height: AppSpacing.xs),
        _FieldError(errorText!),
      ],
    );
  }
}

/// 日期区间字段：开始/结束两个填充小盒 + 中间箭头，整项点击弹出日历。
///
/// 规格（与设计稿一致）：两盒 `muted` 底、圆角 12，盒内上为 11px 弱化色
/// 标签、下为 16px 日期；中间 16px 箭头衔接，不用竖线分隔；
/// [errorText] 非空时两盒均显示 2px 危险色描边，错误文案只显示一次。
class AppFormDateRangeField extends StatelessWidget {
  const AppFormDateRangeField({
    super.key,
    this.range,
    this.startLabel,
    this.endLabel,
    this.onTap,
    this.enabled = true,
    this.errorText,
    this.semanticLabel,
  });

  /// 当前区间（[AppDateRange]）；为 null 时显示占位文案。
  final AppDateRange? range;

  final String? startLabel;
  final String? endLabel;

  /// 整项点击回调（弹出日历选择层）。
  final VoidCallback? onTap;

  final bool enabled;

  final String? errorText;

  /// 读屏语义标签；缺省使用 Material 本地化日期区间提示。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = enabled && onTap != null;
    final hasError = errorText != null && errorText!.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final startCaption = startLabel ?? l10n.startDate;
    final endCaption = endLabel ?? l10n.endDate;
    final startText = range == null
        ? null
        : materialL10n.formatCompactDate(range!.start);
    final endText = range == null
        ? null
        : materialL10n.formatCompactDate(range!.end);
    final textTheme = Theme.of(context).textTheme;
    final captionStyle = textTheme.bodySmall?.copyWith(
      fontSize: 11,
      height: 1.2,
    );
    final textPainter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
    );
    var contentWidth = 0.0;
    for (final text in [
      TextSpan(text: startText ?? l10n.selectDate, style: textTheme.bodyLarge),
      TextSpan(text: endText ?? l10n.selectDate, style: textTheme.bodyLarge),
      TextSpan(text: startCaption, style: captionStyle),
      TextSpan(text: endCaption, style: captionStyle),
    ]) {
      textPainter.text = text;
      textPainter.layout();
      if (textPainter.width > contentWidth) contentWidth = textPainter.width;
    }
    final horizontalMinWidth =
        (contentWidth.ceilToDouble() + AppSpacing.md * 2) * 2 +
        AppSpacing.sm * 2 +
        16;
    textPainter.dispose();

    final startBox = _RangeBox(
      caption: startCaption,
      text: startText,
      enabled: enabled,
      error: hasError,
    );
    final endBox = _RangeBox(
      caption: endCaption,
      text: endText,
      enabled: enabled,
      error: hasError,
    );
    final field = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kRowMinHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < horizontalMinWidth;
          final arrow = Padding(
            padding: EdgeInsets.symmetric(
              horizontal: stacked ? 0 : AppSpacing.sm,
              vertical: stacked ? AppSpacing.xs : 0,
            ),
            child: Icon(
              stacked
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_forward_rounded,
              size: 16,
              color: colors.mutedForeground,
            ),
          );
          if (stacked) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [startBox, arrow, endBox],
            );
          }
          return Row(
            children: [
              Expanded(child: startBox),
              arrow,
              Expanded(child: endBox),
            ],
          );
        },
      ),
    );

    final interactiveField = Material(
      color: Colors.transparent,
      child: Semantics(
        button: onTap != null,
        enabled: onTap == null ? null : enabled,
        onTap: active ? onTap : null,
        label: semanticLabel ?? materialL10n.dateRangePickerHelpText,
        value: range == null
            ? null
            : '$startCaption: $startText, $endCaption: $endText',
        excludeSemantics: true,
        child: InkWell(
          onTap: active ? onTap : null,
          borderRadius: AppRadius.circular(AppRadius.md),
          child: field,
        ),
      ),
    );
    if (!hasError) return interactiveField;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        interactiveField,
        const SizedBox(height: AppSpacing.xs),
        _FieldError(errorText!),
      ],
    );
  }
}

typedef AppPickerFieldBuilder<T extends Object> = Widget Function(
  BuildContext context,
  T? value,
  Future<void> Function()? onTap,
  bool enabled,
  String? errorText,
);

class AppPickerFormField<T extends Object> extends FormField<T> {
  AppPickerFormField({
    Key? key,
    T? initialValue,
    required String Function(T value) displayStringForOption,
    Future<T?> Function(T? value)? onPick,
    ValueChanged<T?>? onChanged,
    FormFieldValidator<T>? validator,
    FormFieldSetter<T>? onSaved,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    String? errorText,
    bool enabled = true,
    String? placeholder,
    bool filled = true,
    Widget? trailing,
    int? maxLines,
    String? semanticLabel,
  }) : this.custom(
         key: key,
         initialValue: initialValue,
         onPick: onPick,
         onChanged: onChanged,
         validator: validator,
         onSaved: onSaved,
         autovalidateMode: autovalidateMode,
         errorText: errorText,
         enabled: enabled,
         fieldBuilder: (context, value, onTap, enabled, errorText) =>
             AppPickerField(
               value: value == null ? null : displayStringForOption(value),
               placeholder: placeholder,
               onTap: onTap,
               enabled: enabled,
               filled: filled,
               trailing: trailing,
               errorText: errorText,
               maxLines: maxLines,
               semanticLabel: semanticLabel,
             ),
       );

  AppPickerFormField.custom({
    super.key,
    super.initialValue,
    required this.fieldBuilder,
    this.onPick,
    this.onChanged,
    super.validator,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
    String? errorText,
    super.enabled = true,
  }) : super(
         forceErrorText: errorText == null || errorText.isEmpty
             ? null
             : errorText,
         builder: (field) =>
             (field as _AppPickerFormFieldState<T>)._buildField(),
       );

  final AppPickerFieldBuilder<T> fieldBuilder;
  final Future<T?> Function(T? value)? onPick;
  final ValueChanged<T?>? onChanged;

  @override
  FormFieldState<T> createState() => _AppPickerFormFieldState<T>();
}

class _AppPickerFormFieldState<T extends Object> extends FormFieldState<T> {
  bool _picking = false;
  int _revision = 0;

  @override
  AppPickerFormField<T> get widget => super.widget as AppPickerFormField<T>;

  @override
  void didUpdateWidget(covariant AppPickerFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _revision++;
      setValue(widget.initialValue);
    }
    if (oldWidget.enabled != widget.enabled ||
        (oldWidget.onPick != null && widget.onPick == null)) {
      _revision++;
    }
  }

  @override
  void reset() {
    _revision++;
    super.reset();
  }

  Future<void> _pick() async {
    final onPick = widget.onPick;
    if (_picking || !widget.enabled || onPick == null) return;
    final revision = _revision;
    setState(() => _picking = true);
    try {
      final selected = await onPick(value);
      if (!mounted ||
          !widget.enabled ||
          revision != _revision ||
          selected == null) {
        return;
      }
      didChange(selected);
      widget.onChanged?.call(selected);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Widget _buildField() => widget.fieldBuilder(
    context,
    value,
    widget.onPick == null ? null : _pick,
    widget.enabled && !_picking,
    errorText,
  );
}

class AppDateRangeFormField extends AppPickerFormField<AppDateRange> {
  AppDateRangeFormField({
    super.key,
    super.initialValue,
    super.onPick,
    super.onChanged,
    super.validator,
    super.onSaved,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.errorText,
    super.enabled = true,
    String? startLabel,
    String? endLabel,
    String? semanticLabel,
  }) : super.custom(
         fieldBuilder: (context, value, onTap, enabled, errorText) =>
             AppFormDateRangeField(
               range: value,
               startLabel: startLabel,
               endLabel: endLabel,
               onTap: onTap,
               enabled: enabled,
               errorText: errorText,
               semanticLabel: semanticLabel,
             ),
       );
}

class _RangeBox extends StatelessWidget {
  const _RangeBox({
    required this.caption,
    required this.text,
    required this.enabled,
    required this.error,
  });

  final String caption;
  final String? text;
  final bool enabled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = text != null;

    return Material(
      color: colors.muted,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circular(AppRadius.md),
        side: error
            ? BorderSide(color: colors.destructive, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.2,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text ?? AppLocalizations.of(context)!.selectDate,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: hasValue && enabled
                    ? colors.foreground
                    : colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'FormItem · Light', group: 'Form', size: Size(420, 900))
Widget appFormLightPreview() => _formPreview(AppTheme.light);

@Preview(name: 'FormItem · Dark', group: 'Form', size: Size(420, 900))
Widget appFormDarkPreview() => _formPreview(AppTheme.dark);

Widget _formPreview(ThemeData theme) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: theme,
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppFormCard(
          children: [
            const AppFormItem(
              layout: AppFormItemLayout.left,
              label: '姓名',
              required: true,
              child: AppPickerField(filled: false, value: '林溪'),
            ),
            AppFormItem(
              layout: AppFormItemLayout.left,
              label: '所在地区',
              required: true,
              child: AppPickerField(
                filled: false,
                value: '浙江省 · 杭州市 · 西湖区',
                onTap: _previewTap,
              ),
            ),
            AppFormItem(
              layout: AppFormItemLayout.left,
              label: '日期区间',
              required: true,
              child: AppPickerField(
                filled: false,
                value: '开始 2026-09-22\n结束 2026-09-25',
                onTap: _previewTap,
              ),
            ),
            AppFormItem(
              layout: AppFormItemLayout.left,
              label: '消息通知',
              child: AppSwitch(value: true, onChanged: _previewToggle),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppFormItem(
          label: '姓名',
          required: true,
          child: AppInput(filled: true, hint: '请输入姓名'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppFormItem(
          label: '预约日期',
          required: true,
          child: AppPickerField(
            onTap: _previewTap,
            trailing: const Icon(Icons.calendar_today_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppFormItem(
          label: '日期区间',
          required: true,
          helper: '点击整项打开日历',
          child: AppFormDateRangeField(
            range: (start: DateTime(2026, 9, 22), end: DateTime(2026, 9, 25)),
            onTap: _previewTap,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppFormItem(
          label: '手机号',
          required: true,
          child: AppPickerField(value: '138', errorText: '请输入11位手机号'),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppFormItem(
          label: '编号',
          child: AppPickerField(
            value: '不可编辑',
            enabled: false,
            trailing: Icon(Icons.lock_outline_rounded),
          ),
        ),
      ],
    ),
  ),
);

void _previewTap() {}
void _previewToggle(bool _) {}
