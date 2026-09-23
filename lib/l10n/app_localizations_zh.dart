// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get acknowledge => '知道了';

  @override
  String get selectPlaceholder => '请选择';

  @override
  String get selectDate => '选择日期';

  @override
  String get selectTime => '选择时间';

  @override
  String get noOptions => '暂无可选项';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get rangeStart => '开始';

  @override
  String get rangeEnd => '结束';

  @override
  String get rangeStartEnd => '开始/结束';

  @override
  String get today => '今';

  @override
  String get loadFailed => '加载失败，请稍后重试';

  @override
  String get retry => '重试';

  @override
  String get success => '成功';

  @override
  String get failure => '失败';

  @override
  String get warning => '警告';

  @override
  String get loading => '加载中';

  @override
  String get collapseMenu => '收起菜单';

  @override
  String deleteLabel(String label) {
    return '删除 $label';
  }

  @override
  String get addImage => '添加图片';

  @override
  String get uploadFailed => '上传失败';

  @override
  String get retryUpload => '重试上传';

  @override
  String get uploadedImage => '已上传图片';

  @override
  String get previewImage => '预览图片';

  @override
  String get uploading => '上传中';

  @override
  String get cropImage => '裁剪图片';

  @override
  String get cropFailed => '裁剪失败，请重试';

  @override
  String get imageLoadFailed => '图片加载失败';

  @override
  String get freeAspectRatio => '自由';

  @override
  String get rotateImage => '旋转图片';

  @override
  String get done => '完成';

  @override
  String toastAnnouncement(String status, String message) {
    return '$status：$message';
  }
}
