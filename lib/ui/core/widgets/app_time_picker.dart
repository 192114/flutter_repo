import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'app_picker.dart';

int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

// 候选值有序，等距时保留较早的值。
int _nearest(List<int> candidates, int target) => candidates.reduce(
  (a, b) => (b - target).abs() < (a - target).abs() ? b : a,
);

/// 滚轮时间选择：底部弹层 + 时 / 分双列滚轮，中行高亮。
abstract final class AppTimePicker {
  /// 返回用户确认的时间；取消或遮罩关闭返回 null。
  ///
  /// [minuteInterval] 必须为正且整除 60，候选分钟从每小时的 00 分起。
  /// [minTime] / [maxTime] 为同一天的闭区间，不支持跨午夜；无合法候选时报错。
  /// 初值取距离最近的合法候选，等距取较早值；切换小时后也按此策略对齐分钟。
  static Future<TimeOfDay?> show(
    BuildContext context, {
    TimeOfDay? initialTime,
    int minuteInterval = 1,
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
    String? title,
  }) {
    if (minuteInterval <= 0 || 60 % minuteInterval != 0) {
      throw ArgumentError.value(minuteInterval, 'minuteInterval', '必须为正且整除 60');
    }
    final min = _minutes(minTime ?? const TimeOfDay(hour: 0, minute: 0));
    final max = _minutes(maxTime ?? const TimeOfDay(hour: 23, minute: 59));
    if (max < min) throw ArgumentError('maxTime 不能早于 minTime');
    final candidates = [
      for (var minute = 0; minute < 24 * 60; minute += minuteInterval)
        if (minute >= min && minute <= max) minute,
    ];
    if (candidates.isEmpty) throw ArgumentError('时间范围内没有符合步长的候选时间');
    final initial = _nearest(
      candidates,
      _minutes(initialTime ?? TimeOfDay.now()),
    );

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: appSheetBarrierColor(context),
      builder: (context) => _TimePickerSheet(
        title: title,
        initialMinute: initial,
        candidates: candidates,
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({
    required this.title,
    required this.initialMinute,
    required this.candidates,
  });

  final String? title;
  final int initialMinute;
  final List<int> candidates;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late int _selected = widget.initialMinute;
  late final List<int> _hours = widget.candidates
      .map((m) => m ~/ 60)
      .toSet()
      .toList();

  List<int> get _minutesInHour => [
    for (final minute in widget.candidates)
      if (minute ~/ 60 == _selected ~/ 60) minute,
  ];

  void _selectHour(int index) => setState(() {
    final hour = _hours[index];
    _selected = _nearest(
      widget.candidates.where((m) => m ~/ 60 == hour).toList(),
      hour * 60 + _selected % 60,
    );
  });

  @override
  Widget build(BuildContext context) => AppPickerSheet(
    title: widget.title ?? AppLocalizations.of(context)!.selectTime,
    onCancel: () => Navigator.of(context).pop(),
    onConfirm: () =>
        Navigator.of(context)
            .pop(TimeOfDay(hour: _selected ~/ 60, minute: _selected % 60)),
    child: AppPickerWheelGroup(
      children: [
        AppPickerWheel(
          items: [for (final hour in _hours) hour.toString().padLeft(2, '0')],
          selectedIndex: _hours.indexOf(_selected ~/ 60),
          onSelected: _selectHour,
        ),
        AppPickerWheel(
          items: [
            for (final minute in _minutesInHour)
              (minute % 60).toString().padLeft(2, '0'),
          ],
          selectedIndex: _minutesInHour.indexOf(_selected),
          onSelected: (index) =>
              setState(() => _selected = _minutesInHour[index]),
        ),
      ],
    ),
  );
}
