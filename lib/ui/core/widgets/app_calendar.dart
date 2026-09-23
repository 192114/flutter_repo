import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/theme_ext.dart';
import 'app_picker.dart';

/// 已确定的日期范围。
typedef AppDateRange = ({DateTime start, DateTime end});

/// 范围选择过程态：仅选定起点时 [end] 为 null。
typedef AppDateRangeSelection = ({DateTime start, DateTime? end});

enum _CalendarMode { single, range }

/// 日历展示模式：全量滚动（月份标题吸顶）/ 按月切换（固定 6 行，高度不跳动）。
enum AppCalendarDisplayMode { scroll, monthSwitch }

// 单元格高 46 = 数字区 35（与选中圆同高）+ 角标区 11；设计稿标注的
// 「高 40 / 圆 36」无法同时容纳圆与「今天/开始/结束」角标，实现上微调。
const double _kCircleSize = 35;
const double _kCaptionHeight = 11;
const double _kMonthTitleHeight = 36;
const double _kWeekHeaderHeight = 28;

/// CalendarPicker 弹层内日历区的最大高度。
const double _kPickerMaxHeight = 420;

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

void _validateBounds(DateTime min, DateTime max) {
  if (max.isBefore(min)) throw ArgumentError('maxDate 不能早于 minDate');
}

DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
  final day = _dayOnly(value);
  if (day.isBefore(min)) return min;
  if (day.isAfter(max)) return max;
  return day;
}

AppDateRangeSelection _normalizeRange(
  AppDateRangeSelection value,
  DateTime min,
  DateTime max,
) {
  if (value.end != null &&
      _dayOnly(value.end!).isBefore(_dayOnly(value.start))) {
    throw ArgumentError('start 不能晚于 end');
  }
  return (
    start: _clampDate(value.start, min, max),
    end: value.end == null ? null : _clampDate(value.end!, min, max),
  );
}

/// 布局与滚动缓存共用一份尺寸，避免大字号下月份偏移与吸顶标题失步。
class _CalendarMetrics {
  const _CalendarMetrics({
    this.number = _kCircleSize,
    this.caption = _kCaptionHeight,
    this.title = _kMonthTitleHeight,
    this.week = _kWeekHeaderHeight,
  });

  factory _CalendarMetrics.of(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final text = Theme.of(context).textTheme;
    return _CalendarMetrics(
      number: (scaler.scale(15) * (text.bodyLarge?.height ?? 1.5) + 8).clamp(
        _kCircleSize,
        double.infinity,
      ),
      caption: (scaler.scale(9) * 1.2).clamp(_kCaptionHeight, double.infinity),
      title:
          (scaler.scale(text.titleMedium?.fontSize ?? 16) *
                      (text.titleMedium?.height ?? 1.5) +
                  12)
              .clamp(_kMonthTitleHeight, double.infinity),
      week:
          (scaler.scale(text.bodySmall?.fontSize ?? 12) *
                      (text.bodySmall?.height ?? 1.5) +
                  8)
              .clamp(_kWeekHeaderHeight, double.infinity),
    );
  }

  final double number;
  final double caption;
  final double title;
  final double week;
  double get cell => number + caption;
  double get navigation => title.clamp(40.0, double.infinity);
}

int _daysInMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0).day;

int _monthRowCount(DateTime month) {
  final leading = DateTime(month.year, month.month).weekday - 1;
  return ((leading + _daysInMonth(month)) / 7).ceil();
}

List<DateTime> _monthsBetween(DateTime min, DateTime max) {
  final last = DateTime(max.year, max.month);
  return [
    for (
      var m = DateTime(min.year, min.month);
      !m.isAfter(last);
      m = DateTime(m.year, m.month + 1)
    )
      m,
  ];
}

/// 日历视图：固定周表头 + 月网格，支持单选 / 范围与滚动 / 切换两种展示。
///
/// 规格（对照设计稿）：单元格无分割线仅靠留白；今天 = 主色加粗数字 +
/// 下方 9px「今天」；范围起止 = 主色实心圆 + 圆下「开始 / 结束」角标，
/// 中间日 accent 连接带 + accentForeground 数字。
///
/// [AppCalendarDisplayMode.scroll] 模式需要外部提供有界高度
/// （[AppCalendarPicker] 内部用限高 SizedBox 包裹）；
/// [AppCalendarDisplayMode.monthSwitch] 模式高度自包含
/// （导航 40 + 周表头 + 固定 6 行网格，切换时高度不跳动）。
class AppCalendarView extends StatefulWidget {
  /// 受控单选；父级需在 [onChanged] 中更新 value，null 回调禁用日期选择。
  AppCalendarView.single({
    super.key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    this.displayMode = AppCalendarDisplayMode.scroll,
    DateTime? minDate,
    DateTime? maxDate,
  }) : _mode = _CalendarMode.single,
       _date = value,
       _range = null,
       _onDateChanged = onChanged,
       _onRangeChanged = null,
       minDate = _dayOnly(minDate ?? DateTime(1900)),
       maxDate = _dayOnly(maxDate ?? DateTime(2100, 12, 31)) {
    _validateBounds(this.minDate, this.maxDate);
  }

  /// 受控范围；value 可仅含起点，父级持有整个选择过程态。
  AppCalendarView.range({
    super.key,
    AppDateRangeSelection? value,
    ValueChanged<AppDateRangeSelection>? onChanged,
    this.displayMode = AppCalendarDisplayMode.scroll,
    DateTime? minDate,
    DateTime? maxDate,
  }) : _mode = _CalendarMode.range,
       _date = null,
       _range = value,
       _onDateChanged = null,
       _onRangeChanged = onChanged,
       minDate = _dayOnly(minDate ?? DateTime(1900)),
       maxDate = _dayOnly(maxDate ?? DateTime(2100, 12, 31)) {
    _validateBounds(this.minDate, this.maxDate);
    if (value != null) _normalizeRange(value, this.minDate, this.maxDate);
  }

  final _CalendarMode _mode;
  final AppCalendarDisplayMode displayMode;
  final DateTime? _date;
  final AppDateRangeSelection? _range;
  final ValueChanged<DateTime>? _onDateChanged;
  final ValueChanged<AppDateRangeSelection>? _onRangeChanged;

  /// 可选范围（默认 1900-01-01 ~ 2100-12-31）；忽略时分秒。
  final DateTime minDate;
  final DateTime maxDate;

  @override
  State<AppCalendarView> createState() => _AppCalendarViewState();
}

class _AppCalendarViewState extends State<AppCalendarView> {
  List<DateTime> _months = const [];
  List<double> _monthExtents = const [];
  List<double> _monthStarts = const [];

  ScrollController? _scrollController;
  double _initialScrollOffset = 0;

  _CalendarMetrics _metrics = const _CalendarMetrics();
  late DateTime _visibleMonth;
  DateTime? _focusedDay;

  DateTime? get _selected =>
      widget._date == null ? null : _clampDay(widget._date!);
  AppDateRangeSelection? get _range => widget._range == null
      ? null
      : _normalizeRange(widget._range!, _minDay, _maxDay);
  DateTime? get _rangeStart => _range?.start;
  DateTime? get _rangeEnd => _range?.end;
  bool get _enabled => widget._mode == _CalendarMode.single
      ? widget._onDateChanged != null
      : widget._onRangeChanged != null;

  /// 网格键盘焦点：方向键移动选中日期的前提。
  final FocusNode _gridFocus = FocusNode();

  DateTime get _minDay => _dayOnly(widget.minDate);
  DateTime get _maxDay => _dayOnly(widget.maxDate);

  @override
  void initState() {
    super.initState();
    _rebuildMonthData();
    final anchor = _selected ?? _rangeStart ?? _clampDay(DateTime.now());
    _focusedDay = anchor;
    _visibleMonth = _clampMonth(DateTime(anchor.year, anchor.month));
    _initialScrollOffset = _monthStarts[_indexOfMonth(_visibleMonth)];
    _scrollController = ScrollController(
      initialScrollOffset: _initialScrollOffset,
    )..addListener(_rememberVisibleMonth);
    _gridFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didUpdateWidget(AppCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minDate != oldWidget.minDate ||
        widget.maxDate != oldWidget.maxDate) {
      _rebuildMonthData();
      _visibleMonth = _clampMonth(_visibleMonth);
      _focusedDay = _focusedDay == null ? null : _clampDay(_focusedDay!);
      _syncScroll(_monthStarts[_indexOfMonth(_visibleMonth)]);
    }
    if (widget._date != oldWidget._date ||
        widget._range != oldWidget._range ||
        widget._mode != oldWidget._mode) {
      _focusedDay = _selected ?? _rangeEnd ?? _rangeStart;
      if (_focusedDay != null) {
        final month = DateTime(_focusedDay!.year, _focusedDay!.month);
        if (month != _visibleMonth) {
          _visibleMonth = month;
          _syncScroll(_monthStarts[_indexOfMonth(month)]);
        }
      }
    }
    if (widget.displayMode != oldWidget.displayMode) {
      _syncScroll(_monthStarts[_indexOfMonth(_visibleMonth)]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final metrics = _CalendarMetrics.of(context);
    if (metrics.cell == _metrics.cell &&
        metrics.title == _metrics.title &&
        metrics.week == _metrics.week) {
      return;
    }
    final offset = widget.displayMode == AppCalendarDisplayMode.monthSwitch
        ? _monthStarts[_indexOfMonth(_visibleMonth)]
        : _scrollController!.hasClients
        ? _scrollController!.offset
        : _initialScrollOffset;
    final index = _monthIndexAtOffset(offset);
    final fraction = (offset - _monthStarts[index]) / _monthExtents[index];
    _metrics = metrics;
    _rebuildMonthData();
    _syncScroll(_monthStarts[index] + fraction * _monthExtents[index]);
  }

  void _rememberVisibleMonth() {
    if (_scrollController!.hasClients) {
      _visibleMonth = _months[_monthIndexAtOffset(_scrollController!.offset)];
    }
  }

  void _syncScroll(double offset) {
    _initialScrollOffset = offset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _scrollController;
      if (!mounted || controller == null || !controller.hasClients) return;
      controller.jumpTo(
        _initialScrollOffset.clamp(
          controller.position.minScrollExtent,
          controller.position.maxScrollExtent,
        ),
      );
    });
  }

  /// 重建月份列表、高度与偏移缓存（滚动模式惰性化与吸顶计算的依据）。
  void _rebuildMonthData() {
    _months = _monthsBetween(widget.minDate, widget.maxDate);
    _monthExtents = [
      for (final month in _months)
        _metrics.title + _monthRowCount(month) * _metrics.cell,
    ];
    final starts = <double>[];
    var offset = 0.0;
    for (final extent in _monthExtents) {
      starts.add(offset);
      offset += extent;
    }
    _monthStarts = starts;
  }

  @override
  void dispose() {
    _gridFocus.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  DateTime _clampDay(DateTime day) => _clampDate(day, _minDay, _maxDay);

  DateTime _clampMonth(DateTime month) {
    final minMonth = _months.first;
    final maxMonth = _months.last;
    if (month.isBefore(minMonth)) return minMonth;
    if (month.isAfter(maxMonth)) return maxMonth;
    return month;
  }

  int _indexOfMonth(DateTime month) =>
      (month.year * 12 + month.month - 1) -
      (_months.first.year * 12 + _months.first.month - 1);

  /// 二分定位偏移所在月份：最后一个起始偏移 ≤ [offset] 的月。
  int _monthIndexAtOffset(double offset) {
    var lo = 0;
    var hi = _monthStarts.length - 1;
    while (lo < hi) {
      final mid = lo + (hi - lo + 1) ~/ 2;
      if (_monthStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// 吸顶标题数据：视口顶部月份 + 被下一月标题推出的位移（0 ~ 标题高）。
  /// 下月标题顶部到达视口顶前一个标题高的位置时开始推出，与
  /// SliverPersistentHeader 吸顶的「推挤」节奏一致。
  (DateTime, double) _stickyTitleAt(double offset) {
    final index = _monthIndexAtOffset(offset);
    final nextStart = index + 1 < _monthStarts.length
        ? _monthStarts[index + 1]
        : double.infinity;
    final push = (offset - nextStart + _metrics.title)
        .clamp(0.0, _metrics.title)
        .toDouble();
    return (_months[index], push);
  }

  bool get _canGoPrev => _visibleMonth.isAfter(_months.first);
  bool get _canGoNext => _visibleMonth.isBefore(_months.last);

  void _shiftMonth(int delta) => setState(() {
    _visibleMonth = _clampMonth(
      DateTime(_visibleMonth.year, _visibleMonth.month + delta),
    );
    _focusedDay = _clampDay(
      DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        (_focusedDay?.day ?? 1).clamp(1, _daysInMonth(_visibleMonth)),
      ),
    );
  });

  void _onDayTapped(DateTime date) {
    if (!_enabled) return;
    _gridFocus.requestFocus();
    setState(() => _focusedDay = date);
    if (widget._mode == _CalendarMode.single) {
      widget._onDateChanged!(date);
      return;
    }
    final start = _rangeStart;
    final AppDateRangeSelection next;
    if (start == null || _rangeEnd != null) {
      next = (start: date, end: null);
    } else if (date.isBefore(start)) {
      next = (start: date, end: start);
    } else {
      next = (start: start, end: date);
    }
    widget._onRangeChanged!(next);
  }

  /// 使用日历日期构造步进，跨夏令时也始终落在当地午夜。
  void _moveSelection(int days) {
    if (!_enabled) return;
    final current =
        _focusedDay ??
        _selected ??
        _rangeStart ??
        _clampDay(DateTime(_visibleMonth.year, _visibleMonth.month));
    final next = _clampDay(
      DateTime(current.year, current.month, current.day + days),
    );
    if (next == current) return;

    setState(() {
      _focusedDay = next;
      if (widget.displayMode == AppCalendarDisplayMode.monthSwitch) {
        _visibleMonth = DateTime(next.year, next.month);
      }
    });
    if (widget._mode == _CalendarMode.single) widget._onDateChanged!(next);
    if (widget.displayMode == AppCalendarDisplayMode.scroll &&
        _scrollController!.hasClients) {
      final index = _indexOfMonth(DateTime(next.year, next.month));
      _scrollController!.animateTo(
        _monthStarts[index].clamp(
          _scrollController!.position.minScrollExtent,
          _scrollController!.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _activateFocusedDay() {
    if (!_enabled) return;
    _onDayTapped(
      _focusedDay ??
          _clampDay(DateTime(_visibleMonth.year, _visibleMonth.month)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _moveSelection(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _moveSelection(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveSelection(-7),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveSelection(7),
        const SingleActivator(LogicalKeyboardKey.enter): _activateFocusedDay,
        const SingleActivator(LogicalKeyboardKey.space): _activateFocusedDay,
      },
      child: Focus(
        focusNode: _gridFocus,
        canRequestFocus: _enabled,
        child: widget.displayMode == AppCalendarDisplayMode.monthSwitch
            ? _buildSwitchMode(context)
            : _buildScrollMode(context),
      ),
    );
  }

  Widget _buildScrollMode(BuildContext context) {
    final colors = context.colors;
    final titleStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: colors.cardForeground, fontWeight: FontWeight.w700);
    return Column(
      children: [
        _WeekHeader(height: _metrics.week),
        Expanded(
          // 单个 SliverVariedExtentList：月份是列表项，视口外月份既不构建
          // 也不布局（此前每月一组 SliverMainAxisGroup，1900-2100 默认范围
          // 会同步创建 2400+ 组且各组首行仍参与布局，打开弹层明显卡顿）。
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverVariedExtentList.builder(
                    itemCount: _months.length,
                    itemExtentBuilder: (index, _) => _monthExtents[index],
                    itemBuilder: (context, index) => _buildMonthItem(
                      index,
                      background: colors.card,
                      style: titleStyle,
                    ),
                  ),
                ],
              ),
              // 吸顶标题：悬浮在滚动区顶部的同款标题条，盖住滚出视口的月内
              // 标题；下月标题上滑进入时同步上移让位（被 Stack 裁掉），
              // 复现 pinned header 的推挤效果。AnimatedBuilder 只重建标题条。
              AnimatedBuilder(
                animation: _scrollController!,
                builder: (context, _) {
                  final offset = _scrollController!.hasClients
                      ? _scrollController!.position.pixels
                      : _initialScrollOffset;
                  final (month, push) = _stickyTitleAt(offset);
                  return Positioned(
                    top: -push,
                    left: 0,
                    right: 0,
                    child: _MonthTitle(
                      key: const ValueKey('calendar_sticky_month_title'),
                      month: month,
                      height: _metrics.title,
                      background: colors.card,
                      style: titleStyle,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthItem(
    int index, {
    required Color background,
    required TextStyle? style,
  }) {
    final month = _months[index];
    return Column(
      children: [
        _MonthTitle(
          month: month,
          height: _metrics.title,
          background: background,
          style: style,
        ),
        for (var row = 0; row < _monthRowCount(month); row++)
          _buildWeekRow(month, row),
      ],
    );
  }

  Widget _buildSwitchMode(BuildContext context) {
    final colors = context.colors;
    final materialL10n = MaterialLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _metrics.navigation,
          child: Row(
            children: [
              IconButton(
                tooltip: materialL10n.previousMonthTooltip,
                onPressed: _canGoPrev ? () => _shiftMonth(-1) : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: _canGoPrev
                      ? colors.cardForeground
                      : colors.mutedForeground,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    materialL10n.formatMonthYear(_visibleMonth),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.cardForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: materialL10n.nextMonthTooltip,
                onPressed: _canGoNext ? () => _shiftMonth(1) : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: _canGoNext
                      ? colors.cardForeground
                      : colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        _WeekHeader(height: _metrics.week),
        // 固定 6 行：任何月份高度一致，切换时不跳动。
        for (var row = 0; row < 6; row++) _buildWeekRow(_visibleMonth, row),
      ],
    );
  }

  Widget _buildWeekRow(DateTime month, int row) {
    final leading = DateTime(month.year, month.month).weekday - 1;
    final days = _daysInMonth(month);
    return Row(
      children: [
        for (var column = 0; column < 7; column++)
          Expanded(
            child: () {
              final day = row * 7 + column - leading + 1;
              if (day < 1 || day > days) {
                return SizedBox(height: _metrics.cell);
              }
              return _buildDayCell(DateTime(month.year, month.month, day));
            }(),
          ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final today = _isSameDay(date, DateTime.now());
    final disabled =
        !_enabled || date.isBefore(_minDay) || date.isAfter(_maxDay);

    var selected = false;
    var isStart = false;
    var isEnd = false;
    var inRange = false;
    if (widget._mode == _CalendarMode.single) {
      selected = _selected != null && _isSameDay(date, _selected!);
    } else {
      isStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
      isEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
      inRange =
          !isStart &&
          !isEnd &&
          _rangeStart != null &&
          _rangeEnd != null &&
          date.isAfter(_rangeStart!) &&
          date.isBefore(_rangeEnd!);
    }

    final hasCircle = selected || isStart || isEnd;
    // 连接带：起点右半格、终点左半格、中间日整格；起止同日不画。
    final bandLeft = inRange || (isEnd && !isStart);
    final bandRight = inRange || (isStart && !isEnd && _rangeEnd != null);

    final String? caption;
    if (isStart) {
      caption = l10n.rangeStart;
    } else if (isEnd) {
      caption = l10n.rangeEnd;
    } else if (today) {
      caption = l10n.today;
    } else {
      caption = null;
    }

    final Color numberColor;
    final FontWeight numberWeight;
    if (disabled) {
      numberColor = colors.mutedForeground;
      numberWeight = FontWeight.w400;
    } else if (hasCircle) {
      numberColor = colors.primaryForeground;
      numberWeight = FontWeight.w700;
    } else if (inRange) {
      numberColor = colors.accentForeground;
      numberWeight = FontWeight.w400;
    } else if (today) {
      numberColor = colors.primary;
      numberWeight = FontWeight.w700;
    } else {
      numberColor = colors.cardForeground;
      numberWeight = FontWeight.w400;
    }

    final semanticsLabel = [
      materialL10n.formatFullDate(date),
      if (today) l10n.today,
      if (isStart) l10n.rangeStart,
      if (isEnd) l10n.rangeEnd,
    ].join(', ');

    final focused = _gridFocus.hasFocus && _focusedDay == date;
    return Semantics(
      button: true,
      enabled: !disabled,
      focused: focused,
      selected: selected || isStart || isEnd,
      label: semanticsLabel,
      onTap: disabled ? null : () => _onDayTapped(date),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: disabled ? null : () => _onDayTapped(date),
        child: SizedBox(
          height: _metrics.cell,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (bandLeft || bandRight)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: _metrics.caption,
                  child: Row(
                    children: [
                      Expanded(
                        child: bandLeft
                            ? Container(color: colors.accent)
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: bandRight
                            ? Container(color: colors.accent)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              Column(
                children: [
                  SizedBox(
                    height: _metrics.number,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (hasCircle || focused)
                          Container(
                            width: _metrics.number,
                            height: _metrics.number,
                            decoration: BoxDecoration(
                              color: hasCircle ? colors.primary : null,
                              shape: BoxShape.circle,
                              border: focused
                                  ? Border.all(color: colors.primary)
                                  : null,
                            ),
                          ),
                        Text(
                          '${date.day}',
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 15,
                                color: numberColor,
                                fontWeight: numberWeight,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: _metrics.caption,
                    child: caption == null
                        ? null
                        : Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              height: 1.2,
                              color: colors.primary,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 固定周表头：一 二 三 四 五 六 日（周一开头）。
class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    // Material 的窄星期名称从周日开始；网格始终保持周一开头。
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var column = 0; column < 7; column++)
            Expanded(
              child: Center(
                child: Text(
                  weekdays[(column + 1) % 7],
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.colors.mutedForeground),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 月份标题条：滚动模式下既随内容滚动（月内标题），也用作吸顶悬浮条。
class _MonthTitle extends StatelessWidget {
  const _MonthTitle({
    super.key,
    required this.month,
    required this.height,
    required this.background,
    required this.style,
  });

  final DateTime month;
  final double height;
  final Color background;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    color: background,
    alignment: Alignment.center,
    child: Text(
      MaterialLocalizations.of(context).formatMonthYear(month),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    ),
  );
}

/// 日历选择弹层：AppPickerSheet 壳 + 滚动模式日历（限最大高度，超出滚动）。
abstract final class AppCalendarPicker {
  /// 单选：返回确认日期；取消或遮罩关闭返回 null。
  static Future<DateTime?> showDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    String? title,
  }) {
    final min = _dayOnly(minDate ?? DateTime(1900));
    final max = _dayOnly(maxDate ?? DateTime(2100, 12, 31));
    _validateBounds(min, max);
    final initial = initialDate == null
        ? null
        : _clampDate(initialDate, min, max);
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: appSheetBarrierColor(context),
      builder: (context) => _CalendarPickerSheet(
        mode: _CalendarMode.single,
        title: title,
        initialDate: initial,
        minDate: min,
        maxDate: max,
      ),
    );
  }

  /// 范围：返回确认的起止区间；取消或遮罩关闭返回 null。
  static Future<AppDateRange?> showRange(
    BuildContext context, {
    AppDateRange? initialRange,
    DateTime? minDate,
    DateTime? maxDate,
    String? title,
  }) {
    final min = _dayOnly(minDate ?? DateTime(1900));
    final max = _dayOnly(maxDate ?? DateTime(2100, 12, 31));
    _validateBounds(min, max);
    final initial = initialRange == null
        ? null
        : _normalizeRange(initialRange, min, max);
    return showModalBottomSheet<AppDateRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: appSheetBarrierColor(context),
      builder: (context) => _CalendarPickerSheet(
        mode: _CalendarMode.range,
        title: title,
        initialRange: initial,
        minDate: min,
        maxDate: max,
      ),
    );
  }
}

class _CalendarPickerSheet extends StatefulWidget {
  const _CalendarPickerSheet({
    required this.mode,
    required this.title,
    required this.minDate,
    required this.maxDate,
    this.initialDate,
    this.initialRange,
  });

  final _CalendarMode mode;
  final String? title;
  final DateTime? initialDate;
  final AppDateRangeSelection? initialRange;
  final DateTime minDate;
  final DateTime maxDate;

  @override
  State<_CalendarPickerSheet> createState() => _CalendarPickerSheetState();
}

class _CalendarPickerSheetState extends State<_CalendarPickerSheet> {
  DateTime get _min => widget.minDate;
  DateTime get _max => widget.maxDate;

  late DateTime? _date = widget.initialDate;
  late AppDateRangeSelection? _range = widget.initialRange;

  bool get _confirmEnabled =>
      widget.mode == _CalendarMode.single ? _date != null : _range?.end != null;

  /// 内容不足最大高度时收缩到内容高度，避免底部留白；
  /// 累计一旦达到 420 即可收口，无需遍历完所有月份。
  double get _calendarHeight {
    final metrics = _CalendarMetrics.of(context);
    var content = metrics.week;
    final last = DateTime(_max.year, _max.month);
    for (
      var m = DateTime(_min.year, _min.month);
      !m.isAfter(last);
      m = DateTime(m.year, m.month + 1)
    ) {
      content += metrics.title + _monthRowCount(m) * metrics.cell;
      if (content >= _kPickerMaxHeight) {
        return _kPickerMaxHeight;
      }
    }
    return content;
  }

  void _onConfirm() {
    if (!_confirmEnabled) return;
    if (widget.mode == _CalendarMode.single) {
      Navigator.of(context).pop(_date);
    } else {
      Navigator.of(context).pop((start: _range!.start, end: _range!.end!));
    }
  }

  @override
  Widget build(BuildContext context) => AppPickerSheet(
    title: widget.title ?? AppLocalizations.of(context)!.selectDate,
    onCancel: () => Navigator.of(context).pop(),
    onConfirm: _onConfirm,
    confirmEnabled: _confirmEnabled,
    child: SizedBox(
      height: _calendarHeight,
      child: widget.mode == _CalendarMode.single
          ? AppCalendarView.single(
              value: _date,
              minDate: _min,
              maxDate: _max,
              onChanged: (date) => setState(() => _date = date),
            )
          : AppCalendarView.range(
              value: _range,
              minDate: _min,
              maxDate: _max,
              onChanged: (range) => setState(() => _range = range),
            ),
    ),
  );
}
