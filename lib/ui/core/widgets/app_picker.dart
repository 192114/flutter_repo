import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';
import 'app_button.dart';

/// 浮层遮罩色：随主题取 background（浅色白色雾化、深色近黑），与
/// AppDropdownMenu 的遮罩约定一致；替代 showModalBottomSheet 默认的黑色压暗。
Color appSheetBarrierColor(BuildContext context) =>
    context.colors.background.withValues(alpha: context.isDarkMode ? 0.7 : 0.6);

/// 底部弹层通用壳：拖拽把手 + 居中标题 + 内容区 + 可选「取消/确定」操作行。
///
/// 规格（与设计稿一致）：顶部圆角 16、把手 32×4、操作按钮高 40。
/// 白色雾化遮罩上边缘反差弱，壳顶部带 1px `border` 细分隔线保持清晰。
/// Selector / DatePicker / TimePicker 均基于此壳组装。
class AppPickerSheet extends StatelessWidget {
  const AppPickerSheet({
    super.key,
    required this.title,
    required this.child,
    this.onCancel,
    this.onConfirm,
    this.cancelLabel,
    this.confirmLabel,
    this.confirmEnabled = true,
  });

  final String title;
  final Widget child;

  /// 仅渲染提供了回调的操作；壳不负责关闭路由。
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final String? cancelLabel;
  final String? confirmLabel;
  final bool confirmEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final hasActions = onCancel != null || onConfirm != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colors.mutedForeground.withValues(alpha: 0.4),
                borderRadius: AppRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.cardForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(child: child),
            if (hasActions) ...[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    if (onCancel != null)
                      Expanded(
                        child: AppButton(
                          label: cancelLabel ?? l10n.cancel,
                          variant: AppButtonVariant.secondary,
                          onPressed: onCancel,
                        ),
                      ),
                    if (onConfirm != null)
                      Expanded(
                        child: AppButton(
                          label: confirmLabel ?? l10n.confirm,
                          onPressed: confirmEnabled ? onConfirm : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 表单选择行：48px 高，左标签、右值与箭头，点击弹出选择层。
class AppSelectorField extends StatelessWidget {
  const AppSelectorField({
    super.key,
    required this.label,
    this.value,
    this.placeholder,
    this.onTap,
    this.enabled = true,
  });

  final String label;

  /// 已选值文案；为 null 时显示 [placeholder]。
  final String? value;
  final String? placeholder;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = value != null && value!.isNotEmpty;
    final displayValue = hasValue
        ? value!
        : placeholder ?? AppLocalizations.of(context)!.selectPlaceholder;
    final interactive = enabled && onTap != null;

    return Material(
      color: colors.card,
      borderRadius: AppRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: interactive ? onTap : null,
        excludeFromSemantics: true,
        child: Semantics(
          button: onTap != null,
          enabled: onTap == null ? null : enabled,
          readOnly: onTap == null,
          onTap: interactive ? onTap : null,
          label: label,
          value: displayValue,
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // 标签与值都可收缩：空间不足时双方省略而非溢出。
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: colors.cardForeground),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      displayValue,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: hasValue
                            ? colors.cardForeground
                            : colors.mutedForeground,
                      ),
                    ),
                  ),
                  if (interactive) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.chevron_right, color: colors.mutedForeground),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 选择器选项。
class AppSelectorOption<T extends Object> {
  const AppSelectorOption({
    required this.label,
    required this.value,
    this.enabled = true,
  });

  final String label;
  final T value;
  final bool enabled;
}

/// 选择器：底部弹层单选列表，点选即返回。
abstract final class AppSelector {
  /// 弹出选项列表，返回选中的值；未选择（遮罩关闭）返回 null。
  ///
  /// 选项值必须唯一；[initialValue] 不在列表时不选中任何项。
  static Future<T?> show<T extends Object>(
    BuildContext context, {
    required String title,
    required List<AppSelectorOption<T>> options,
    T? initialValue,
  }) {
    final entries = List<AppSelectorOption<T>>.unmodifiable(options);
    if (entries.map((option) => option.value).toSet().length !=
        entries.length) {
      throw ArgumentError.value(options, 'options', '选项值必须唯一');
    }
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: appSheetBarrierColor(context),
      builder: (context) => AppPickerSheet(
        title: title,
        child: entries.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(AppLocalizations.of(context)!.noOptions),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const _OptionDivider(),
                itemBuilder: (context, index) {
                  final option = entries[index];
                  return _OptionTile(
                    label: option.label,
                    selected: option.value == initialValue,
                    onTap: option.enabled
                        ? () => Navigator.of(context).pop(option.value)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: onTap == null
                          ? colors.mutedForeground
                          : selected
                          ? colors.primary
                          : colors.cardForeground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionDivider extends StatelessWidget {
  const _OptionDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: AppSpacing.lg,
    color: context.colors.border,
  );
}

double _wheelItemExtent(BuildContext context) {
  final fontSize = Theme.of(context).textTheme.titleMedium?.fontSize ?? 16;
  return (MediaQuery.textScalerOf(context).scale(fontSize) * 1.1 + 16).clamp(
    40.0,
    double.infinity,
  );
}

/// 滚轮组：多列 [AppPickerWheel] 等宽排列 + 中行高亮带，随字号增高。
class AppPickerWheelGroup extends StatelessWidget {
  const AppPickerWheelGroup({super.key, required this.children});

  /// 各列滚轮（通常为 [AppPickerWheel]），按顺序等宽排列。
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _wheelItemExtent(context) * 5,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // 中行高亮带。
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            height: _wheelItemExtent(context),
            decoration: BoxDecoration(
              color: context.colors.muted,
              borderRadius: AppRadius.circular(AppRadius.sm),
            ),
          ),
        ),
        Row(children: [for (final child in children) Expanded(child: child)]),
      ],
    ),
  );
}

/// 单列滚轮：当前项主色加粗，其余项弱化渐隐。
///
/// 受控组件：外部通过 [selectedIndex] 指定当前项；当该值变化（如年/月
/// 联动导致日 clamp）时滚轮自动跳到对应位置。
class AppPickerWheel extends StatefulWidget {
  const AppPickerWheel({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(items.length > 0, 'items 不能为空'),
       assert(
         selectedIndex >= 0 && selectedIndex < items.length,
         'selectedIndex 必须在 items 范围内',
       );

  /// 全部候选项文案。
  final List<String> items;

  /// 当前选中下标。
  final int selectedIndex;

  /// 用户滚动选中变化回调。
  final ValueChanged<int> onSelected;

  @override
  State<AppPickerWheel> createState() => _AppPickerWheelState();
}

class _AppPickerWheelState extends State<AppPickerWheel> {
  late final FixedExtentScrollController _controller;
  double? _itemExtent;
  bool _syncPending = false;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.selectedIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extent = _wheelItemExtent(context);
    if (_itemExtent != null && _itemExtent != extent) _scheduleSync();
    _itemExtent = extent;
  }

  @override
  void didUpdateWidget(AppPickerWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.hasClients &&
        widget.selectedIndex != _controller.selectedItem) {
      _scheduleSync();
    }
  }

  void _scheduleSync() {
    if (_syncPending) return;
    _syncPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.hasClients) _controller.jumpToItem(widget.selectedIndex);
      _syncPending = false;
    });
  }

  void _onSelected(int index) {
    if (!_syncPending &&
        index != widget.selectedIndex &&
        index >= 0 &&
        index < widget.items.length) {
      widget.onSelected(index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: _itemExtent!,
      perspective: 0.004,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: _onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.items.length,
        builder: (context, index) {
          final selected = index == widget.selectedIndex;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                widget.items[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // 行高随 textScaler 缩放，大字号时仍居中且不裁切。
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? colors.primary : colors.mutedForeground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
