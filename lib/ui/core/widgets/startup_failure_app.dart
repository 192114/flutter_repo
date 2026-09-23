import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';
import 'app_button.dart';

class StartupFailureApp extends StatefulWidget {
  const StartupFailureApp({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<StartupFailureApp> createState() => _StartupFailureAppState();
}

class _StartupFailureAppState extends State<StartupFailureApp> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Repo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: context.colors.destructive,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '启动失败',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '暂时无法启动应用，请重试。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: context.colors.mutedForeground),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: _retrying ? '正在重试' : '重试',
                      loading: _retrying,
                      onPressed: _retry,
                      expand: true,
                    ),
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

@Preview(
  name: 'Startup failure · Light',
  group: 'Feedback',
  size: Size(390, 620),
  brightness: Brightness.light,
)
@Preview(
  name: 'Startup failure · Dark',
  group: 'Feedback',
  size: Size(390, 620),
  brightness: Brightness.dark,
)
Widget startupFailurePreview() => StartupFailureApp(
  onRetry: () => Future<void>.delayed(const Duration(seconds: 1)),
);
