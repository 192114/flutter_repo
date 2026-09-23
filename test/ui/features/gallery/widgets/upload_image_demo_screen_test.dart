import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_upload_image.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/upload_image_demo_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({Locale locale = const Locale('zh')}) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: const UploadImageDemoScreen(),
  ),
);

void main() {
  testWidgets('上传演示挂载本地化，实际上传与只读三态保留稳定 ID', (tester) async {
    await tester.pumpWidget(_app());
    final uploads = tester.widgetList<AppUploadImage>(
      find.byType(AppUploadImage),
    );
    expect(uploads, hasLength(2));
    final interactive = uploads.first;
    expect(interactive.items, isEmpty);
    expect(interactive.adding, isFalse);
    expect(interactive.onAdd, isNotNull);
    expect(interactive.onRemove, isNotNull);
    expect(interactive.onRetry, isNotNull);
    final sample = uploads.last;
    expect(sample.items.map((item) => item.id), [
      'success',
      'uploading',
      'failed',
    ]);
    expect(sample.items.map((item) => item.status), [
      AppUploadImageStatus.success,
      AppUploadImageStatus.uploading,
      AppUploadImageStatus.failed,
    ]);
    expect(sample.items[1].progress, 0.65);
    expect(sample.onAdd, isNull);
    expect(sample.onPreview, isNull);
    expect(sample.onRetry, isNull);
    expect(sample.onRemove, isNull);
    expect(find.text('0/9'), findsOneWidget);
    expect(find.text('3/9'), findsOneWidget);
    expect(find.bySemanticsLabel('添加图片'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('上传失败'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('英文窄屏演示的图片组件默认提示跟随 locale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(locale: const Locale('en')));
    expect(find.bySemanticsLabel('Add image'), findsOneWidget);
    expect(find.bySemanticsLabel('Uploaded image'), findsOneWidget);
    expect(find.bySemanticsLabel('Uploading 65%'), findsOneWidget);
    expect(find.bySemanticsLabel('Upload failed'), findsOneWidget);
    expect(find.text('Add image'), findsOneWidget);
    expect(find.text('Upload failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
