import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_dropdown_menu.dart';

/// DropdownMenu 演示页：顶部菜单栏做排序与筛选，下方模拟商品列表实时响应。
///
/// 选中值由本页本地持有（纯演示状态），真实业务中应下沉到 ViewModel。
class DropdownMenuDemoScreen extends StatefulWidget {
  const DropdownMenuDemoScreen({super.key});

  @override
  State<DropdownMenuDemoScreen> createState() => _DropdownMenuDemoScreenState();
}

class _DropdownMenuDemoScreenState extends State<DropdownMenuDemoScreen> {
  static const _filterDefault = '全部';

  /// 模拟商品：（名称，价格，是否有货）。
  static const _products = <(String, int, bool)>[
    ('机械键盘', 329, true),
    ('无线鼠标', 99, true),
    ('降噪耳机', 899, false),
    ('显示器挂灯', 199, true),
    ('人体工学椅', 1299, true),
  ];

  String _sort = '综合排序';
  String _filter = _filterDefault;

  List<(String, int, bool)> get _visibleProducts {
    var list = _filter == '只看有货'
        ? _products.where((p) => p.$3).toList()
        : [..._products];
    switch (_sort) {
      case '最新优先':
        list = list.reversed.toList();
      case '价格从低到高':
        list.sort((a, b) => a.$2.compareTo(b.$2));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final products = _visibleProducts;

    return Scaffold(
      appBar: AppBar(title: const Text('下拉菜单')),
      body: AppDropdownMenu(
        items: [
          AppDropdownMenuItem<String>(
            title: _sort,
            value: _sort,
            onChanged: (v) => setState(() => _sort = v),
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
            title: _filter == _filterDefault ? '筛选' : _filter,
            value: _filter,
            onChanged: (v) => setState(() => _filter = v),
            options: const [
              AppDropdownMenuOption(label: '全部', value: '全部'),
              AppDropdownMenuOption(label: '只看有货', value: '只看有货'),
            ],
          ),
        ],
        // 对齐设计稿关闭状态：内容区铺 background（浅色纯白 / 深色近黑）。
        child: ColoredBox(
          color: colors.background,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) =>
                _ProductCard(product: products[index]),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final (String, int, bool) product;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (name, price, inStock) = product;

    // 设计稿卡片：白底白卡，以细边框（light #E4E4E7）分隔，不用全局 CardTheme。
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.cardForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!inStock) ...[
            Text(
              '缺货',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            '¥$price',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
