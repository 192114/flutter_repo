import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import 'app_picker.dart';

/// 滚轮日期选择：底部弹层 + 年 / 月 / 日三列滚轮，中行高亮。
abstract final class AppDatePicker {
  /// 返回用户确认的日期；取消或遮罩关闭返回 null。
  ///
  /// - [minDate] / [maxDate] 限定可选范围（默认 1900-01-01 ~ 2100-12-31），
  ///   边界年月日的滚轮列表随之裁剪；
  /// - [initialDate] 超出范围时被夹紧到边界。
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    String? title,
  }) {
    final min = DateUtils.dateOnly(minDate ?? DateTime(1900));
    final max = DateUtils.dateOnly(maxDate ?? DateTime(2100, 12, 31));
    if (max.isBefore(min)) {
      throw ArgumentError('maxDate 不能早于 minDate');
    }

    var initial = DateUtils.dateOnly(initialDate ?? DateTime.now());
    if (initial.isBefore(min)) initial = min;
    if (initial.isAfter(max)) initial = max;

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: appSheetBarrierColor(context),
      builder: (context) => _DatePickerSheet(
        title: title,
        initialDate: initial,
        minDate: min,
        maxDate: max,
      ),
    );
  }
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.title,
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
  });

  final String? title;
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int _year = widget.initialDate.year;
  late int _month = widget.initialDate.month;
  late int _day = widget.initialDate.day;

  List<int> get _years => [
    for (var y = widget.minDate.year; y <= widget.maxDate.year; y++) y,
  ];

  List<int> get _months {
    final first = _year == widget.minDate.year ? widget.minDate.month : 1;
    final last = _year == widget.maxDate.year ? widget.maxDate.month : 12;
    return [for (var m = first; m <= last; m++) m];
  }

  List<int> get _days {
    var first = 1;
    var last = DateTime(_year, _month + 1, 0).day;
    if (_year == widget.minDate.year && _month == widget.minDate.month) {
      first = widget.minDate.day;
    }
    if (_year == widget.maxDate.year && _month == widget.maxDate.month) {
      last = widget.maxDate.day;
    }
    return [for (var d = first; d <= last; d++) d];
  }

  void _onYearChanged(int index) => setState(() {
    _year = _years[index];
    _month = _month.clamp(_months.first, _months.last);
    _day = _day.clamp(_days.first, _days.last);
  });

  void _onMonthChanged(int index) => setState(() {
    _month = _months[index];
    _day = _day.clamp(_days.first, _days.last);
  });

  void _onDayChanged(int index) => setState(() => _day = _days[index]);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final yearFormat = DateFormat.y(locale);
    final monthFormat = DateFormat.M(locale);
    final dayFormat = DateFormat.d(locale);
    return AppPickerSheet(
      title: widget.title ?? AppLocalizations.of(context)!.selectDate,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () => Navigator.of(context).pop(DateTime(_year, _month, _day)),
      child: AppPickerWheelGroup(
        children: [
          AppPickerWheel(
            items: [for (final y in _years) yearFormat.format(DateTime(y))],
            selectedIndex: _years.indexOf(_year),
            onSelected: _onYearChanged,
          ),
          AppPickerWheel(
            items: [
              for (final m in _months) monthFormat.format(DateTime(_year, m)),
            ],
            selectedIndex: _months.indexOf(_month),
            onSelected: _onMonthChanged,
          ),
          AppPickerWheel(
            items: [
              for (final d in _days)
                dayFormat.format(DateTime(_year, _month, d)),
            ],
            selectedIndex: _days.indexOf(_day),
            onSelected: _onDayChanged,
          ),
        ],
      ),
    );
  }
}
