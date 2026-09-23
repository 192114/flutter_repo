import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_calendar.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_picker.dart';
import '../../../core/widgets/app_selection.dart';
import '../../../core/widgets/app_time_picker.dart';
import 'gallery_section.dart';

/// 表单组件演示页：按钮、输入、选择控件与各类选择器的真实交互。
class FormDemoScreen extends StatefulWidget {
  const FormDemoScreen({super.key});

  @override
  State<FormDemoScreen> createState() => _FormDemoScreenState();
}

class _FormDemoScreenState extends State<FormDemoScreen> {
  var _radioIndex = 0;
  var _rememberMe = true;
  var _receiveNotice = false;
  var _notificationOn = true;
  var _darkModeOn = false;
  var _submitting = false;
  var _obscurePassword = true;

  String? _city;
  DateTime? _date;
  TimeOfDay? _time;
  DateTime? _calendarDate;
  AppDateRange? _calendarRange;

  // 表单排版演示（左侧标签卡片 + 上方标签填充式）。
  final _formName = TextEditingController();
  final _formPhone = TextEditingController();
  final _formRemark = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _formSubmitting = false;
  String? _region;
  DateTime? _formDate;
  AppDateRange? _formRange;

  static const _cityOptions = [
    AppSelectorOption(label: '杭州', value: '杭州'),
    AppSelectorOption(label: '上海', value: '上海'),
    AppSelectorOption(label: '北京', value: '北京'),
    AppSelectorOption(label: '深圳', value: '深圳'),
  ];

  static const _regionOptions = [
    AppSelectorOption(label: '浙江省 · 杭州市 · 西湖区', value: '浙江省 · 杭州市 · 西湖区'),
    AppSelectorOption(label: '广东省 · 深圳市 · 南山区', value: '广东省 · 深圳市 · 南山区'),
    AppSelectorOption(label: '四川省 · 成都市 · 武侯区', value: '四川省 · 成都市 · 武侯区'),
  ];

  @override
  void dispose() {
    _formName.dispose();
    _formPhone.dispose();
    _formRemark.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final city = await AppSelector.show<String>(
      context,
      title: '请选择城市',
      options: _cityOptions,
      initialValue: _city,
    );
    if (mounted && city != null) setState(() => _city = city);
  }

  Future<void> _pickDate() async {
    final date = await AppDatePicker.show(
      context,
      initialDate: _date,
      minDate: DateTime(2020),
      maxDate: DateTime(2030, 12, 31),
    );
    if (mounted && date != null) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await AppTimePicker.show(context, initialTime: _time);
    if (mounted && time != null) setState(() => _time = time);
  }

  Future<void> _pickCalendarDate() async {
    final date = await AppCalendarPicker.showDate(
      context,
      initialDate: _calendarDate,
      minDate: DateTime(2020),
      maxDate: DateTime(2030, 12, 31),
    );
    if (mounted && date != null) setState(() => _calendarDate = date);
  }

  Future<void> _pickCalendarRange() async {
    final range = await AppCalendarPicker.showRange(
      context,
      initialRange: _calendarRange,
      minDate: DateTime(2020),
      maxDate: DateTime(2030, 12, 31),
    );
    if (mounted && range != null) setState(() => _calendarRange = range);
  }

  Future<void> _pickRegion() async {
    final region = await AppSelector.show<String>(
      context,
      title: '请选择所在地区',
      options: _regionOptions,
      initialValue: _region,
    );
    if (mounted && region != null) setState(() => _region = region);
  }

  Future<void> _pickFormDate() async {
    final date = await AppCalendarPicker.showDate(
      context,
      initialDate: _formDate,
      minDate: DateTime(2020),
      maxDate: DateTime(2030, 12, 31),
    );
    if (mounted && date != null) setState(() => _formDate = date);
  }

  Future<void> _pickFormRange() async {
    final range = await AppCalendarPicker.showRange(
      context,
      initialRange: _formRange,
      minDate: DateTime(2020),
      maxDate: DateTime(2030, 12, 31),
    );
    if (mounted && range != null) setState(() => _formRange = range);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _formSubmitting = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _formSubmitting = false);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('表单组件')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 720 ? 720 : double.infinity,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  '表单组件演示',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '查看按钮、输入与选择器在当前主题下的真实交互效果。',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: AppSpacing.xxl),
                GallerySection(
                  title: '按钮',
                  description: '五种变体覆盖主要操作层级，支持加载与禁用态。',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        key: const Key('form-submit'),
                        label: _submitting ? '提交中' : '提交',
                        loading: _submitting,
                        expand: true,
                        onPressed: _submit,
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppButton(
                            label: '次要',
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.medium,
                            onPressed: () {},
                          ),
                          AppButton(
                            label: '描边',
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.medium,
                            onPressed: () {},
                          ),
                          AppButton(
                            label: '危险',
                            variant: AppButtonVariant.destructive,
                            size: AppButtonSize.medium,
                            onPressed: () {},
                          ),
                          AppButton(
                            label: '文字',
                            variant: AppButtonVariant.text,
                            size: AppButtonSize.medium,
                            onPressed: () {},
                          ),
                          const AppButton(
                            label: '禁用',
                            size: AppButtonSize.medium,
                          ),
                          AppButton(
                            label: '小号',
                            size: AppButtonSize.small,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '输入',
                  description: '标签、占位、前后图标、错误与禁用态，支持多行文本。',
                  child: Column(
                    spacing: AppSpacing.lg,
                    children: [
                      const AppInput(
                        label: '用户名',
                        hint: '请输入用户名',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      AppInput(
                        key: const Key('input-password'),
                        label: '密码',
                        hint: '请输入密码',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onSuffixIconPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      const AppInput(
                        label: '验证码',
                        hint: '请输入验证码',
                        errorText: '验证码不正确',
                      ),
                      const AppInput(
                        label: '邀请码',
                        hint: '不可编辑',
                        enabled: false,
                      ),
                      const AppInput(label: '备注', hint: '请输入备注', maxLines: 3),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '选择控件',
                  description: '单选、多选与开关，点按即时切换。',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.sm,
                    children: [
                      RadioGroup<int>(
                        groupValue: _radioIndex,
                        onChanged: (value) =>
                            setState(() => _radioIndex = value!),
                        child: const Wrap(
                          spacing: AppSpacing.xl,
                          children: [
                            AppRadio(
                              value: 0,
                              label: '选项一',
                              key: Key('radio-0'),
                            ),
                            AppRadio(
                              value: 1,
                              label: '选项二',
                              key: Key('radio-1'),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: AppSpacing.xl,
                        children: [
                          AppCheckbox(
                            value: _rememberMe,
                            label: '记住我',
                            onChanged: (v) => setState(() => _rememberMe = v),
                          ),
                          AppCheckbox(
                            value: _receiveNotice,
                            label: '接收通知',
                            onChanged: (v) =>
                                setState(() => _receiveNotice = v),
                          ),
                        ],
                      ),
                      AppSwitch(
                        label: '消息通知',
                        value: _notificationOn,
                        onChanged: (v) => setState(() => _notificationOn = v),
                      ),
                      AppSwitch(
                        label: '深色模式',
                        value: _darkModeOn,
                        onChanged: (v) => setState(() => _darkModeOn = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '选择器与日期',
                  description: '底部弹层完成单选、日期（可限范围）与时间选择。',
                  child: Column(
                    spacing: AppSpacing.sm,
                    children: [
                      AppSelectorField(
                        key: const Key('field-city'),
                        label: '城市',
                        value: _city,
                        onTap: _pickCity,
                      ),
                      AppSelectorField(
                        key: const Key('field-date'),
                        label: '日期',
                        value: _date == null ? null : _formatDate(_date!),
                        onTap: _pickDate,
                      ),
                      AppSelectorField(
                        key: const Key('field-time'),
                        label: '时间',
                        value: _time == null ? null : _formatTime(_time!),
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '日历',
                  description: '底部弹层日历，月份吸顶滚动，支持单选与范围。',
                  child: Column(
                    spacing: AppSpacing.sm,
                    children: [
                      AppSelectorField(
                        key: const Key('field-calendar-date'),
                        label: '单选日历',
                        value: _calendarDate == null
                            ? null
                            : _formatDate(_calendarDate!),
                        onTap: _pickCalendarDate,
                      ),
                      AppSelectorField(
                        key: const Key('field-calendar-range'),
                        label: '范围日历',
                        value: _calendarRange == null
                            ? null
                            : '${_formatDate(_calendarRange!.start)} ~ '
                                  '${_formatDate(_calendarRange!.end)}',
                        onTap: _pickCalendarRange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '表单排版',
                  description: 'Form 统一校验：左侧标签卡片分组 + 上方标签填充输入。',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.lg,
                      children: [
                        AppFormCard(
                          children: [
                            const AppFormItem(
                              layout: AppFormItemLayout.left,
                              label: '姓名',
                              required: true,
                              child: AppPickerField(filled: false, value: '林溪'),
                            ),
                            const AppFormItem(
                              layout: AppFormItemLayout.left,
                              label: '手机号',
                              required: true,
                              child: AppPickerField(
                                filled: false,
                                value: '138 0013 8000',
                              ),
                            ),
                            AppFormItem(
                              layout: AppFormItemLayout.left,
                              label: '所在地区',
                              required: true,
                              child: AppPickerField(
                                key: const Key('form-row-region'),
                                filled: false,
                                value: _region,
                                onTap: _pickRegion,
                              ),
                            ),
                            AppFormItem(
                              layout: AppFormItemLayout.left,
                              label: '预约日期',
                              required: true,
                              child: AppPickerField(
                                key: const Key('form-row-date'),
                                filled: false,
                                value: _formDate == null
                                    ? null
                                    : _formatDate(_formDate!),
                                onTap: _pickFormDate,
                              ),
                            ),
                            AppFormItem(
                              layout: AppFormItemLayout.left,
                              label: '日期区间',
                              required: true,
                              child: AppPickerField(
                                key: const Key('form-row-range'),
                                filled: false,
                                value: _formRange == null
                                    ? null
                                    : '开始 ${_formatDate(_formRange!.start)}\n'
                                          '结束 ${_formatDate(_formRange!.end)}',
                                onTap: _pickFormRange,
                              ),
                            ),
                            const AppFormItem(
                              layout: AppFormItemLayout.left,
                              label: '备注',
                              child: AppPickerField(
                                filled: false,
                                placeholder: '请输入补充说明',
                              ),
                            ),
                            AppFormItem(
                              layout: AppFormItemLayout.left,
                              label: '消息通知',
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: AppSwitch(
                                  value: _notificationOn,
                                  onChanged: (v) =>
                                      setState(() => _notificationOn = v),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppFormItem(
                          label: '姓名',
                          required: true,
                          child: AppInput(
                            filled: true,
                            controller: _formName,
                            hint: '请输入姓名',
                          ),
                        ),
                        AppFormItem(
                          label: '手机号',
                          required: true,
                          child: AppInput(
                            key: const Key('form-input-phone'),
                            filled: true,
                            controller: _formPhone,
                            hint: '请输入手机号',
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                value?.trim().length == 11 ? null : '请输入11位手机号',
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                        ),
                        AppFormItem(
                          label: '所在地区',
                          required: true,
                          child: AppPickerField(
                            key: const Key('form-field-region'),
                            value: _region,
                            onTap: _pickRegion,
                          ),
                        ),
                        AppFormItem(
                          label: '预约日期',
                          required: true,
                          child: AppPickerField(
                            key: const Key('form-field-date'),
                            value: _formDate == null
                                ? null
                                : _formatDate(_formDate!),
                            onTap: _pickFormDate,
                            trailing: const Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                        AppFormItem(
                          label: '日期区间',
                          required: true,
                          helper: '点击整项打开日历',
                          child: AppFormDateRangeField(
                            key: const Key('form-field-range'),
                            range: _formRange,
                            onTap: _pickFormRange,
                          ),
                        ),
                        AppFormItem(
                          label: '备注（选填）',
                          child: AppInput(
                            filled: true,
                            controller: _formRemark,
                            hint: '请输入补充说明',
                            maxLines: 3,
                          ),
                        ),
                        const AppFormItem(
                          label: '编号',
                          child: AppPickerField(
                            value: '不可编辑',
                            enabled: false,
                            trailing: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        AppButton(
                          key: const Key('form-layout-submit'),
                          label: _formSubmitting ? '提交中' : '提交',
                          loading: _formSubmitting,
                          expand: true,
                          onPressed: _submitForm,
                        ),
                        AppButton(
                          key: const Key('form-layout-reset'),
                          label: '重置',
                          variant: AppButtonVariant.secondary,
                          onPressed: _formSubmitting
                              ? null
                              : () {
                                  _formKey.currentState!.reset();
                                  setState(() {
                                    _region = null;
                                    _formDate = null;
                                    _formRange = null;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatDate(DateTime date) =>
    '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';

String _formatTime(TimeOfDay time) =>
    '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
