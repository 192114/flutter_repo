import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

class AppRadio<T extends Object> extends StatefulWidget {
  const AppRadio({
    super.key,
    required this.value,
    this.enabled = true,
    this.label,
  });

  final T value;
  final bool enabled;
  final String? label;

  @override
  State<AppRadio<T>> createState() => _AppRadioState<T>();
}

class _AppRadioState<T extends Object> extends State<AppRadio<T>> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final registry = RadioGroup.maybeOf<T>(context);
    assert(!widget.enabled || registry != null, 'AppRadio requires RadioGroup');

    return RawRadio<T>(
      value: widget.value,
      mouseCursor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
      ),
      toggleable: false,
      focusNode: _focusNode,
      autofocus: false,
      groupRegistry: registry,
      enabled: widget.enabled,
      builder: (context, state) {
        final selected = state.value ?? false;
        return Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.circular(AppRadius.sm),
              border: Border.all(
                color: state.states.contains(WidgetState.focused)
                    ? colors.ring
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? colors.primary : colors.input,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          widget.label!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: widget.enabled
                                    ? colors.foreground
                                    : colors.mutedForeground,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _SelectionControlShell(
      label: label,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      semanticChecked: value,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? colors.primary : Colors.transparent,
          borderRadius: AppRadius.circular(6),
          border: Border.all(
            color: value ? colors.primary : colors.input,
            width: 1.5,
          ),
        ),
        child: value
            ? Icon(Icons.check, size: 14, color: colors.primaryForeground)
            : null,
      ),
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged, this.label});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final thumbColor = value
        ? colors.primaryForeground
        : (context.isDarkMode ? colors.mutedForeground : Colors.white);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);

    return _SelectionControlShell(
      label: label,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      semanticChecked: value,
      switchSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? colors.primary : colors.input,
          borderRadius: AppRadius.circular(AppRadius.full),
        ),
        child: AnimatedAlign(
          duration: duration,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: thumbColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionControlShell extends StatelessWidget {
  const _SelectionControlShell({
    required this.child,
    required this.onTap,
    required this.semanticChecked,
    this.label,
    this.switchSemantics = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool semanticChecked;
  final String? label;
  final bool switchSemantics;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return MergeSemantics(
      child: Semantics(
        checked: switchSemantics ? null : semanticChecked,
        toggled: switchSemantics ? semanticChecked : null,
        enabled: enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: InkWell(
            onTap: onTap,
            canRequestFocus: enabled,
            borderRadius: AppRadius.circular(AppRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    child,
                    if (label != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          label!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: enabled
                                    ? colors.foreground
                                    : colors.mutedForeground,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Selection · Light', group: 'Form', size: Size(420, 420))
Widget appSelectionLightPreview() => _selectionPreview(AppTheme.light);

@Preview(name: 'Selection · Dark', group: 'Form', size: Size(420, 420))
Widget appSelectionDarkPreview() => _selectionPreview(AppTheme.dark);

Widget _selectionPreview(ThemeData theme) => MaterialApp(
  theme: theme,
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        RadioGroup<int>(
          groupValue: 1,
          onChanged: (_) {},
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppRadio(value: 1, label: '选项一'),
              AppRadio(value: 2, label: '选项二'),
              AppRadio(value: 3, label: '不可用', enabled: false),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppCheckbox(value: true, label: '选项一', onChanged: _noopBool),
        const AppCheckbox(value: false, label: '选项二', onChanged: _noopBool),
        const AppCheckbox(value: false, label: '不可用'),
        const SizedBox(height: AppSpacing.lg),
        const Row(
          spacing: AppSpacing.lg,
          children: [
            AppSwitch(value: true, onChanged: _noopBool),
            AppSwitch(value: false, onChanged: _noopBool),
            AppSwitch(value: false),
          ],
        ),
      ],
    ),
  ),
);

void _noopBool(bool _) {}
