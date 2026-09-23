// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get acknowledge => 'Got it';

  @override
  String get selectPlaceholder => 'Please select';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get noOptions => 'No options';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get rangeStart => 'Start';

  @override
  String get rangeEnd => 'End';

  @override
  String get rangeStartEnd => 'Start/End';

  @override
  String get today => 'Today';

  @override
  String get loadFailed => 'Unable to load. Please try again later.';

  @override
  String get retry => 'Retry';

  @override
  String get success => 'Success';

  @override
  String get failure => 'Error';

  @override
  String get warning => 'Warning';

  @override
  String get loading => 'Loading';

  @override
  String get collapseMenu => 'Collapse menu';

  @override
  String deleteLabel(String label) {
    return 'Delete $label';
  }

  @override
  String get addImage => 'Add image';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get retryUpload => 'Retry upload';

  @override
  String get uploadedImage => 'Uploaded image';

  @override
  String get previewImage => 'Preview image';

  @override
  String get uploading => 'Uploading';

  @override
  String get cropImage => 'Crop image';

  @override
  String get cropFailed => 'Unable to crop. Please try again.';

  @override
  String get imageLoadFailed => 'Unable to load image';

  @override
  String get freeAspectRatio => 'Free';

  @override
  String get rotateImage => 'Rotate image';

  @override
  String get done => 'Done';

  @override
  String toastAnnouncement(String status, String message) {
    return '$status: $message';
  }
}
