// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mechanix Camera';

  @override
  String get cameraNotInitialized => 'Camera is not initialized.';

  @override
  String get retry => 'Retry';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get capturedImage => 'Captured Image';

  @override
  String get filters => 'Filters';

  @override
  String get detectIssues => 'Detect Issues';

  @override
  String get scanTitle => 'Scan';

  @override
  String get reviewTitle => 'Review';

  @override
  String get aspectRatio43 => '4:3';

  @override
  String get aspectRatio169 => '16:9';

  @override
  String get aspectRatio11 => '1:1';

  @override
  String get aspectRatioFull => 'Full';
}
