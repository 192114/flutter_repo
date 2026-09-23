import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

/// 下拉菜单选项（面板中的一行）。
class AppDropdownMenuOption<T extends Object> {
  const AppDropdownMenuOption({
    required this.label,
    required this.value,
    this.enabled = true,
  });

  /// 展示文案。
  final String label;

  /// 选中后回传的值。
  final T value;

  /// 是否可选；禁用时灰显且不响应点击。
  final bool enabled;
}

/// 菜单栏上的一个菜单项（标题 + 对应的选项面板）。
class AppDropdownMenuItem<T extends Object> {
  const AppDropdownMenuItem({
    required this.title,
    required this.options,
    this.value,
    this.onChanged,
    this.enabled = true,
  });

  /// 栏上展示的标题。
  final String title;

  /// 展开面板中的选项列表。
  final List<AppDropdownMenuOption<T>> options;

  /// 当前选中值；与选项 [AppDropdownMenuOption.value] 相等时该行高亮并显示对勾。
  final T? value;

  /// 选中选项后的回调。
  final ValueChanged<T>? onChanged;

  /// 是否可展开；还需提供 [onChanged]，否则标题灰显。
  final bool enabled;

  bool get _interactive => enabled && onChanged != null && options.isNotEmpty;

  /// 将选中的 [value] 分发给 [onChanged]。
  ///
  /// 组件以 `AppDropdownMenuItem<Object>` 持有菜单，直接调用 [onChanged]
  /// 会因函数参数逆变在运行期抛类型错误，必须在此还原泛型后再分发。
  void _selectValue(Object value) => onChanged?.call(value as T);
}

/// Vant 风格顶部下拉菜单（DropdownMenu）。
///
/// 结构：顶部 48px 菜单栏 + 页面内容（[child]）整体叠放，点击栏上标题后
/// 选项面板自栏下滑出，其余内容被半透明黑色遮罩覆盖：
/// - 激活标题变主色且箭头翻转 180°，再次点击或点遮罩收起；
/// - 展开时点击其他标题直接切换面板内容（不重复播放展开动画）；
/// - 选中项主色文字 + 行尾对勾，点击后触发回调并收起。
///
/// 用法：
/// ```dart
/// AppDropdownMenu(
///   items: [
///     AppDropdownMenuItem<String>(
///       title: '综合排序',
///       value: sort,
///       onChanged: (v) => setState(() => sort = v),
///       options: const [
///         AppDropdownMenuOption(label: '综合排序', value: '综合排序'),
///         AppDropdownMenuOption(label: '最新优先', value: '最新优先'),
///       ],
///     ),
///   ],
///   child: ListView(...),
/// )
/// ```
class AppDropdownMenu extends StatefulWidget {
  const AppDropdownMenu({
    super.key,
    required this.items,
    required this.child,
    this.barHeight = 48,
  }) : assert(items.length > 0, '至少需要一个菜单项');

  /// 菜单项列表，在栏上从左到右均分排列。
  final List<AppDropdownMenuItem<Object>> items;

  /// 页面内容，自动下移一个栏高，不会被菜单栏遮挡。
  final Widget child;

  /// 菜单栏高度，默认 48（Vant 规格）。
  final double barHeight;

  @override
  State<AppDropdownMenu> createState() => _AppDropdownMenuState();
}

class _AppDropdownMenuState extends State<AppDropdownMenu>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 250);

  late final AnimationController _controller;
  late final Animation<double> _maskFade;
  late final Animation<Offset> _panelSlide;

  /// 逻辑上展开的菜单下标（标题高亮与箭头翻转）；null 表示已收起。
  int? _activeIndex;

  /// 面板中实际渲染的菜单下标；收起动画结束后才置 null（保证动画有内容可播）。
  int? _panelIndex;

  /// 各标题的焦点节点：收起面板时把焦点归还给展开过的标题。
  final Map<int, FocusNode> _titleFocusNodes = {};

  /// 菜单整体焦点域：面板行被移除后焦点仍留在菜单内。
  final FocusScopeNode _scopeNode = FocusScopeNode(
    debugLabel: 'AppDropdownMenu',
  );

  FocusNode _titleFocus(int index) =>
      _titleFocusNodes.putIfAbsent(index, FocusNode.new);

  @override
  void didUpdateWidget(AppDropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_panelIndex != null && _panelIndex! >= widget.items.length) {
      _activeIndex = null;
      _panelIndex = null;
      _controller.value = 0;
    } else if (_activeIndex != null &&
        !widget.items[_activeIndex!]._interactive) {
      _close();
    }
    _titleFocusNodes.removeWhere((index, node) {
      if (index >= widget.items.length) {
        node.dispose();
        return true;
      }
      return false;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _maskFade = curved;
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void dispose() {
    for (final node in _titleFocusNodes.values) {
      node.dispose();
    }
    _scopeNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggle(int index) {
    if (_activeIndex == index) {
      _close();
    } else {
      _open(index);
    }
  }

  void _open(int index) {
    if (index >= widget.items.length || !widget.items[index]._interactive) {
      return;
    }
    setState(() {
      _activeIndex = index;
      _panelIndex = index;
    });
    _controller.forward();
  }

  void _close() {
    final openIndex = _activeIndex;
    if (openIndex == null) return;
    setState(() {
      _activeIndex = null;
      if (_controller.isDismissed) _panelIndex = null;
    });
    if (_scopeNode.hasFocus && widget.items[openIndex]._interactive) {
      _titleFocusNodes[openIndex]?.requestFocus();
    }
    _controller.reverse().then((_) {
      if (mounted && _activeIndex == null && _controller.isDismissed) {
        setState(() => _panelIndex = null);
      }
    });
  }

  void _select(
    int index,
    AppDropdownMenuItem<Object> item,
    AppDropdownMenuOption<Object> option,
  ) {
    if (!mounted ||
        _activeIndex != index ||
        index >= widget.items.length ||
        !identical(widget.items[index], item) ||
        !item._interactive ||
        !option.enabled ||
        !item.options.contains(option)) {
      return;
    }
    _close();
    item._selectValue(option.value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Esc 收起：焦点位于菜单内任意位置（标题/选项行）时生效。
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: FocusScope(
        node: _scopeNode,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 面板最大高度按组件自身可用高度推导（而非全屏 MediaQuery）：
            // 组件嵌入弹层/半屏等任意容器时边界依然正确。
            final panelMaxHeight =
                (constraints.maxHeight - widget.barHeight) * 0.8;
            return Stack(
              // 组件按页面级容器设计，必须占满可用区域：loose 会让 Stack 收缩到
              // 内容尺寸，导致遮罩/面板宽度异常。
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: widget.barHeight),
                  child: widget.child,
                ),
                if (_panelIndex != null) ...[
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _maskFade,
                      child: BlockSemantics(
                        child: Semantics(
                          button: true,
                          label: AppLocalizations.of(context)!.collapseMenu,
                          onTap: _close,
                          child: GestureDetector(
                            key: const Key('app_dropdown_menu_mask'),
                            onTap: _close,
                            child: ColoredBox(
                              // Vant/设计稿规格：浅色 60% 黑，深色 70% 黑。
                              color: Colors.black.withValues(
                                alpha: context.isDarkMode ? 0.7 : 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: widget.barHeight,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: SlideTransition(
                        position: _panelSlide,
                        child: _buildPanel(colors, panelMaxHeight),
                      ),
                    ),
                  ),
                ],
                // 菜单栏最后绘制（hit test 最优先），保证始终位于遮罩与面板之上。
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.barHeight,
                  child: _buildBar(colors),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBar(AppColors colors) {
    return Material(
      color: colors.card,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // 必须显式填充背景色：BoxShadow 默认 BlurStyle.normal 会把模糊阴影
          // 同时画在形状内侧，装饰无底色时内阴影直接覆盖在栏上，整体被洗灰。
          color: colors.card,
          border: Border(bottom: BorderSide(color: colors.border)),
          // Vant 规格：0 2px 12px rgba(100, 101, 102, 0.12)。
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F646566),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < widget.items.length; i++)
              Expanded(
                child: _BarTitle(
                  key: Key('app_dropdown_menu_title_$i'),
                  item: widget.items[i],
                  active: _activeIndex == i,
                  onTap: () => _toggle(i),
                  focusNode: _titleFocus(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(AppColors colors, double maxHeight) {
    final panelIndex = _panelIndex!;
    final item = widget.items[panelIndex];
    final interactive = _activeIndex == panelIndex && item._interactive;

    return Material(
      color: colors.card,
      // 白色雾化遮罩上面板与内容反差弱，底部分隔线保持面板边缘清晰。
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: item.options.length,
            itemBuilder: (context, index) {
              final option = item.options[index];
              return _OptionRow(
                option: option,
                selected: option.value == item.value,
                onTap: interactive && option.enabled
                    ? () => _select(panelIndex, item, option)
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 菜单栏上的单个标题（文字 + 可翻转箭头）。
class _BarTitle extends StatelessWidget {
  const _BarTitle({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
    this.focusNode,
  });

  final AppDropdownMenuItem<Object> item;
  final bool active;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = !item._interactive
        ? colors.mutedForeground
        : active
        ? colors.primary
        : colors.foreground;

    return Semantics(
      button: true,
      enabled: item._interactive,
      expanded: active,
      child: InkWell(
        focusNode: focusNode,
        onTap: item._interactive ? onTap : null,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: textColor),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedRotation(
                turns: active ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.expand_more,
                  size: 16,
                  color: active ? colors.primary : colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 选项面板中的一行（选中态：主色文字 + 行尾对勾）。
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppDropdownMenuOption<Object> option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = onTap == null
        ? colors.mutedForeground
        : selected
        ? colors.primary
        : colors.cardForeground;

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: textColor),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check, size: 18, color: colors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(
  name: 'DropdownMenu · Light',
  group: 'Navigation',
  size: Size(375, 480),
)
Widget dropdownMenuLightPreview() => _dropdownMenuPreview(AppTheme.light);

@Preview(name: 'DropdownMenu · Dark', group: 'Navigation', size: Size(375, 480))
Widget dropdownMenuDarkPreview() => _dropdownMenuPreview(AppTheme.dark);

Widget _dropdownMenuPreview(ThemeData theme) {
  var sort = '综合排序';
  var filter = '全部';
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    theme: theme,
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => AppDropdownMenu(
          items: [
            AppDropdownMenuItem<String>(
              title: sort,
              value: sort,
              onChanged: (value) => setState(() => sort = value),
              options: const [
                AppDropdownMenuOption(label: '综合排序', value: '综合排序'),
                AppDropdownMenuOption(label: '最新优先', value: '最新优先'),
                AppDropdownMenuOption(label: '价格从低到高', value: '价格从低到高'),
                AppDropdownMenuOption(
                  label: '价格从高到低',
                  value: '价格从高到低',
                  enabled: false,
                ),
              ],
            ),
            AppDropdownMenuItem<String>(
              title: '筛选',
              value: filter,
              onChanged: (value) => setState(() => filter = value),
              options: const [
                AppDropdownMenuOption(label: '全部', value: '全部'),
                AppDropdownMenuOption(label: '只看有货', value: '只看有货'),
              ],
            ),
          ],
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: const [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('商品卡片 A'),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('商品卡片 B'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
