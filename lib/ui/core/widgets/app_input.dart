import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

/// 移动端文本输入：标签 + 输入框 + 错误文案。
///
/// 规格（与设计稿一致）：
/// - 单行高 44、圆角 12；边框 `input`，聚焦 2px `ring`；
/// - 错误：2px `destructive` 边框 + 下方 12px 错误文案；
/// - 禁用：底 `muted`、字 `mutedForeground`、无边框；
/// - 填充式（[filled]）：`muted` 底、默认无边框，聚焦 2px `ring`、
///   错误 2px `destructive`，用于填充式表单排版；
/// - 多行（[maxLines] > 1）时高度随内容伸展，占位符顶对齐；
/// - 框内图标（[prefixIcon]/[suffixIcon]）：20px `mutedForeground`，
///   距边 12、距文字 8；传入 onXxxIconPressed 后可点击（禁用态不响应）。
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.enabled = true,
    this.readOnly = false,
    this.filled = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixIconTooltip,
    this.suffixIconTooltip,
    this.prefixIconSemanticLabel,
    this.suffixIconSemanticLabel,
    this.onPrefixIconPressed,
    this.onSuffixIconPressed,
    this.onChanged,
    this.onSubmitted,
  }) : assert(controller == null || initialValue == null),
       assert(prefix == null || prefixIcon == null),
       assert(suffix == null || suffixIcon == null),
       assert(maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(minLines == null || minLines <= maxLines),
       assert(!obscureText || maxLines == 1),
       assert(
         maxLength == null ||
             maxLength == TextField.noMaxLength ||
             maxLength > 0,
       );

  final TextEditingController? controller;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final bool readOnly;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final Widget? prefix;
  final Widget? suffix;
  final String? prefixIconTooltip;
  final String? suffixIconTooltip;
  final String? prefixIconSemanticLabel;
  final String? suffixIconSemanticLabel;

  /// 供外部控制焦点（如校验失败时把焦点带回出错项）。
  final FocusNode? focusNode;

  /// 输入框上方标签。
  final String? label;

  /// 占位文案。
  final String? hint;

  /// 错误文案：非空即进入错误态（边框与文案均为 `destructive`）。
  final String? errorText;
  final bool enabled;

  /// 填充式样式：`muted` 底、默认无边框；默认 false 为描边样式。
  final bool filled;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;

  /// 键盘动作键（如「完成/搜索/下一项」）。
  final TextInputAction? textInputAction;

  /// 输入框内最左侧图标。
  final IconData? prefixIcon;

  /// 输入框内最右侧图标。
  final IconData? suffixIcon;

  /// 左/右图标点击回调；为 null 时图标仅展示。
  final VoidCallback? onPrefixIconPressed;
  final VoidCallback? onSuffixIconPressed;
  final ValueChanged<String>? onChanged;

  /// 键盘动作键触发（单行时对应「完成/搜索」等）。
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = errorText != null && errorText!.isNotEmpty;

    final borderRadius = AppRadius.circular(AppRadius.md);
    // 填充式默认无描边（仍用 OutlineInputBorder 保持圆角一致）。
    final flatBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide.none,
    );
    final defaultBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.input),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.ring, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colors.destructive, width: 2),
    );

    final field = TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      forceErrorText: hasError ? errorText : null,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction:
          textInputAction ??
          (maxLines == 1 ? TextInputAction.done : TextInputAction.newline),
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: enabled ? colors.foreground : colors.mutedForeground,
      ),
      cursorColor: colors.ring,
      decoration: InputDecoration(
        errorStyle: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colors.destructive, fontSize: 12, height: 1.2),
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: colors.mutedForeground),
        filled: true,
        fillColor: filled || !enabled ? colors.muted : colors.card,
        isDense: true,
        contentPadding: EdgeInsets.only(
          left: prefixIcon == null && prefix == null ? AppSpacing.md : 0,
          right: suffixIcon == null && suffix == null ? AppSpacing.md : 0,
          top: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        prefixIcon:
            prefix ??
            (prefixIcon == null
                ? null
                : _buildIcon(
                    prefixIcon!,
                    onPrefixIconPressed,
                    isPrefix: true,
                    color: colors.mutedForeground,
                    tooltip: prefixIconTooltip,
                    semanticLabel: prefixIconSemanticLabel,
                  )),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon:
            suffix ??
            (suffixIcon == null
                ? null
                : _buildIcon(
                    suffixIcon!,
                    onSuffixIconPressed,
                    isPrefix: false,
                    color: colors.mutedForeground,
                    tooltip: suffixIconTooltip,
                    semanticLabel: suffixIconSemanticLabel,
                  )),
        suffixIconConstraints: const BoxConstraints(),
        border: filled ? flatBorder : defaultBorder,
        enabledBorder: hasError
            ? errorBorder
            : (filled ? flatBorder : defaultBorder),
        focusedBorder: hasError ? errorBorder : focusedBorder,
        disabledBorder: flatBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        field,
      ],
    );
  }

  Widget _buildIcon(
    IconData icon,
    VoidCallback? onPressed, {
    required bool isPrefix,
    required Color color,
    String? tooltip,
    String? semanticLabel,
  }) {
    final iconWidget = Icon(
      icon,
      size: 20,
      color: color,
      semanticLabel: semanticLabel,
    );
    if (onPressed == null) {
      return Padding(
        padding: isPrefix
            ? const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm)
            : const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.md),
        child: iconWidget,
      );
    }
    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: iconWidget,
    );
  }
}

@Preview(name: 'Input · Light', group: 'Form', size: Size(420, 820))
Widget appInputLightPreview() => _inputPreview(AppTheme.light);

@Preview(name: 'Input · Dark', group: 'Form', size: Size(420, 820))
Widget appInputDarkPreview() => _inputPreview(AppTheme.dark);

Widget _inputPreview(ThemeData theme) => MaterialApp(
  theme: theme,
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        AppInput(label: '用户名', hint: '请输入用户名'),
        SizedBox(height: AppSpacing.lg),
        AppInput(label: '搜索', hint: '请输入关键词', prefixIcon: Icons.search_rounded),
        SizedBox(height: AppSpacing.lg),
        AppInput(
          label: '密码',
          hint: '请输入密码',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: Icons.visibility_off_outlined,
        ),
        SizedBox(height: AppSpacing.lg),
        AppInput(label: '验证码', hint: '请输入验证码', errorText: '验证码不正确'),
        SizedBox(height: AppSpacing.lg),
        AppInput(label: '邀请码', hint: '不可编辑', enabled: false),
        SizedBox(height: AppSpacing.lg),
        AppInput(label: '备注', hint: '请输入备注', maxLines: 4),
      ],
    ),
  ),
);
