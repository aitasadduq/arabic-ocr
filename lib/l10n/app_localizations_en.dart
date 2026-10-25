// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Arabic OCR';

  @override
  String get homeHeadline => 'Read Arabic pages';

  @override
  String get homeSubtitle =>
      'Text, tashkeel and tables — read on this phone, offline.';

  @override
  String get actionCamera => 'Camera';

  @override
  String get actionCameraHint => 'Scan pages';

  @override
  String get actionPhotos => 'Photos';

  @override
  String get actionPhotosHint => 'From your library';

  @override
  String get actionFiles => 'Files';

  @override
  String get actionFilesHint => 'PDF or images';

  @override
  String get samplesTitle => 'Try a sample';

  @override
  String get sampleBook => 'Vowelled book';

  @override
  String get sampleTable => 'Table';

  @override
  String get samplePassport => 'Passport';

  @override
  String get sampleOldBook => 'Old scan';

  @override
  String get recentTitle => 'Recent';

  @override
  String get recentEmpty => 'Your readings will appear here.';

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get deleteScan => 'Delete';

  @override
  String get scanDeleted => 'Reading deleted';

  @override
  String get undo => 'Undo';

  @override
  String get settings => 'Settings';

  @override
  String get modelCardMissingTitle => 'Download the reading model';

  @override
  String modelCardMissingBody(String size) {
    return 'One-time download of $size. After that, everything works offline.';
  }

  @override
  String modelCardDownloading(String percent) {
    return 'Downloading the model… $percent';
  }

  @override
  String modelCardPaused(String percent) {
    return 'Download paused at $percent';
  }

  @override
  String get modelCardLoading => 'Preparing the reader…';

  @override
  String get modelCardError => 'The model could not be set up';

  @override
  String get download => 'Download';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Try again';

  @override
  String get importModel => 'Import model files';

  @override
  String get importModelHint =>
      'Pick the two .gguf files if you already have them';

  @override
  String importUnknown(String names) {
    return 'Not model files: $names';
  }

  @override
  String get setupTitle => 'Reads Arabic on your phone';

  @override
  String get setupBody =>
      'Arabic OCR uses Nuqta-OCR, an open model that reproduces the tashkeel printed on the page and keeps tables as tables. Pages never leave your device.';

  @override
  String get setupPointOffline => 'Works offline after a one-time download';

  @override
  String get setupPointPrivate => 'Nothing is uploaded';

  @override
  String get setupPointTables => 'Text, diacritics, headings and tables';

  @override
  String setupDownloadSize(String size) {
    return 'Model size: $size';
  }

  @override
  String get setupWifiOnly => 'Download on Wi-Fi only';

  @override
  String setupLowMemory(String ram) {
    return 'This device has $ram of memory. Reading may be slow or stop on long pages.';
  }

  @override
  String get setupLater => 'Not now';

  @override
  String get setupStart => 'Download and start';

  @override
  String get downloadKeepsGoing =>
      'The download continues if you leave the app.';

  @override
  String get cameraTitle => 'Scan pages';

  @override
  String get cameraHint => 'Fit the page inside the frame';

  @override
  String get cameraFlash => 'Flash';

  @override
  String get cameraDone => 'Done';

  @override
  String get cameraPermission => 'Camera access is needed to scan pages.';

  @override
  String get cameraUnavailable => 'No camera is available on this device.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get reviewTitle => 'Pages';

  @override
  String reviewRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read $count pages',
      one: 'Read 1 page',
    );
    return '$_temp0';
  }

  @override
  String get reviewAddPages => 'Add pages';

  @override
  String get reviewRotate => 'Rotate';

  @override
  String get reviewCrop => 'Crop';

  @override
  String get reviewRemove => 'Remove';

  @override
  String get reviewEmpty => 'No pages yet';

  @override
  String get reviewSelectAll => 'Select all';

  @override
  String get reviewSelectNone => 'Select none';

  @override
  String reviewSelected(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get reviewTitleHint => 'Title (optional)';

  @override
  String pageN(int n) {
    return 'Page $n';
  }

  @override
  String get modeLabel => 'What to read';

  @override
  String get modeAsWritten => 'As written';

  @override
  String get modeAsWrittenHint => 'Text with the tashkeel printed on the page';

  @override
  String get modeBare => 'No tashkeel';

  @override
  String get modeBareHint => 'Plain text without diacritics';

  @override
  String get modeMarkdown => 'Document';

  @override
  String get modeMarkdownHint => 'Headings, lists and tables';

  @override
  String get qualityLabel => 'Detail';

  @override
  String get qualityAccurate => 'Accurate';

  @override
  String get qualityAccurateHint => 'Full detail (2.4 MP)';

  @override
  String get qualityFast => 'Faster';

  @override
  String get qualityFastHint => 'About twice as fast (1 MP)';

  @override
  String get statusQueued => 'Waiting';

  @override
  String get statusPreparing => 'Preparing the page…';

  @override
  String get statusReading => 'Looking at the page…';

  @override
  String get statusWriting => 'Writing…';

  @override
  String get statusDone => 'Done';

  @override
  String get statusCancelled => 'Stopped';

  @override
  String get statusFailed => 'Could not read';

  @override
  String get statusPausedBackground =>
      'Paused while the app is in the background';

  @override
  String readingPageOf(int n, int total) {
    return 'Page $n of $total';
  }

  @override
  String get stop => 'Stop';

  @override
  String get stopAll => 'Stop reading';

  @override
  String get readAgain => 'Read again';

  @override
  String get readAgainWith => 'Read again as…';

  @override
  String get allPages => 'All';

  @override
  String get viewFormatted => 'Formatted';

  @override
  String get viewText => 'Text';

  @override
  String get showPage => 'Show page';

  @override
  String get hidePage => 'Hide page';

  @override
  String get edit => 'Edit';

  @override
  String get doneEditing => 'Done';

  @override
  String get editHint => 'Correct the text';

  @override
  String get rename => 'Rename';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get copyAll => 'Copy all text';

  @override
  String get copyTable => 'Copy table';

  @override
  String get tableCopied => 'Table copied — paste it into a spreadsheet';

  @override
  String get saveTable => 'Save as Excel';

  @override
  String get share => 'Share';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get export => 'Save or share';

  @override
  String get exportRecommended => 'Recommended';

  @override
  String get exportSaveTo => 'Save to Files';

  @override
  String get formatDocx => 'Word document';

  @override
  String get formatDocxHint => 'Text and tables, right-to-left';

  @override
  String get formatXlsx => 'Excel workbook';

  @override
  String get formatXlsxHint => 'Each table on its own sheet';

  @override
  String get formatTxt => 'Plain text';

  @override
  String get formatTxtHint => 'Text only, tables as tab-separated rows';

  @override
  String get formatMd => 'Markdown';

  @override
  String get formatMdHint =>
      'Headings, lists and tables as written by the model';

  @override
  String get formatHtml => 'Web page';

  @override
  String get formatHtmlHint => 'Opens in any browser, prints well';

  @override
  String get formatCsv => 'CSV';

  @override
  String get formatCsvHint => 'Tables only';

  @override
  String statsLine(String seconds, String first) {
    return 'Read in $seconds s · first words after $first s · offline on this device';
  }

  @override
  String get emptyResult => 'No text was found on this page.';

  @override
  String get errorMissingFile => 'The page file is no longer available.';

  @override
  String get errorUnreadableImage => 'This image could not be opened.';

  @override
  String get errorPdfPassword => 'This PDF is password-protected.';

  @override
  String get errorPdfUnreadable => 'This PDF could not be opened.';

  @override
  String errorEngine(String detail) {
    return 'The reader stopped: $detail';
  }

  @override
  String get modelNeeded => 'Download the model first to read pages.';

  @override
  String get untitled => 'Reading';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsTextSize => 'Reading text size';

  @override
  String get settingsTextSample => 'يَتَدَحْرَجُ بِسُرْعَةٍ كَبِيرَةٍ';

  @override
  String get settingsDefaults => 'Reading';

  @override
  String get settingsModel => 'Model';

  @override
  String settingsModelReady(String size) {
    return 'Nuqta-OCR 0.8B · $size on this device';
  }

  @override
  String get settingsModelMissing => 'Not downloaded';

  @override
  String get settingsDeleteModel => 'Delete model';

  @override
  String settingsDeleteModelConfirm(String size) {
    return 'Delete the model? You will need to download it again ($size) to read pages.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsKeepHistory => 'Keep readings';

  @override
  String get settingsKeepHistoryHint =>
      'Save readings and their page images on this device';

  @override
  String get settingsClearHistory => 'Delete all readings';

  @override
  String get settingsClearHistoryConfirm => 'Delete all saved readings?';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutBody =>
      'Reading is done by Nuqta-OCR (Salah AlHaismawi, Mohamed Saleh Tulib, Ahmed ElSayed Mohamed Ibrahim), an open Arabic OCR model, running through llama.cpp.';

  @override
  String get settingsSourceCode => 'Nuqta-OCR on GitHub';

  @override
  String get settingsLicenses => 'Open-source licenses';
}
