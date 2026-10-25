import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Arabic OCR'**
  String get appTitle;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Read Arabic pages'**
  String get homeHeadline;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Text, tashkeel and tables — read on this phone, offline.'**
  String get homeSubtitle;

  /// No description provided for @actionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get actionCamera;

  /// No description provided for @actionCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Scan pages'**
  String get actionCameraHint;

  /// No description provided for @actionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get actionPhotos;

  /// No description provided for @actionPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'From your library'**
  String get actionPhotosHint;

  /// No description provided for @actionFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get actionFiles;

  /// No description provided for @actionFilesHint.
  ///
  /// In en, this message translates to:
  /// **'PDF or images'**
  String get actionFilesHint;

  /// No description provided for @samplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Try a sample'**
  String get samplesTitle;

  /// No description provided for @sampleBook.
  ///
  /// In en, this message translates to:
  /// **'Vowelled book'**
  String get sampleBook;

  /// No description provided for @sampleTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get sampleTable;

  /// No description provided for @samplePassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get samplePassport;

  /// No description provided for @sampleOldBook.
  ///
  /// In en, this message translates to:
  /// **'Old scan'**
  String get sampleOldBook;

  /// No description provided for @recentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentTitle;

  /// No description provided for @recentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your readings will appear here.'**
  String get recentEmpty;

  /// No description provided for @pagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pagesCount(int count);

  /// No description provided for @deleteScan.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteScan;

  /// No description provided for @scanDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reading deleted'**
  String get scanDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @modelCardMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Download the reading model'**
  String get modelCardMissingTitle;

  /// No description provided for @modelCardMissingBody.
  ///
  /// In en, this message translates to:
  /// **'One-time download of {size}. After that, everything works offline.'**
  String modelCardMissingBody(String size);

  /// No description provided for @modelCardDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading the model… {percent}'**
  String modelCardDownloading(String percent);

  /// No description provided for @modelCardPaused.
  ///
  /// In en, this message translates to:
  /// **'Download paused at {percent}'**
  String modelCardPaused(String percent);

  /// No description provided for @modelCardLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing the reader…'**
  String get modelCardLoading;

  /// No description provided for @modelCardError.
  ///
  /// In en, this message translates to:
  /// **'The model could not be set up'**
  String get modelCardError;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @importModel.
  ///
  /// In en, this message translates to:
  /// **'Import model files'**
  String get importModel;

  /// No description provided for @importModelHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the two .gguf files if you already have them'**
  String get importModelHint;

  /// No description provided for @importUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not model files: {names}'**
  String importUnknown(String names);

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Reads Arabic on your phone'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'Arabic OCR uses Nuqta-OCR, an open model that reproduces the tashkeel printed on the page and keeps tables as tables. Pages never leave your device.'**
  String get setupBody;

  /// No description provided for @setupPointOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline after a one-time download'**
  String get setupPointOffline;

  /// No description provided for @setupPointPrivate.
  ///
  /// In en, this message translates to:
  /// **'Nothing is uploaded'**
  String get setupPointPrivate;

  /// No description provided for @setupPointTables.
  ///
  /// In en, this message translates to:
  /// **'Text, diacritics, headings and tables'**
  String get setupPointTables;

  /// No description provided for @setupDownloadSize.
  ///
  /// In en, this message translates to:
  /// **'Model size: {size}'**
  String setupDownloadSize(String size);

  /// No description provided for @setupWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Download on Wi-Fi only'**
  String get setupWifiOnly;

  /// No description provided for @setupLowMemory.
  ///
  /// In en, this message translates to:
  /// **'This device has {ram} of memory. Reading may be slow or stop on long pages.'**
  String setupLowMemory(String ram);

  /// No description provided for @setupLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get setupLater;

  /// No description provided for @setupStart.
  ///
  /// In en, this message translates to:
  /// **'Download and start'**
  String get setupStart;

  /// No description provided for @downloadKeepsGoing.
  ///
  /// In en, this message translates to:
  /// **'The download continues if you leave the app.'**
  String get downloadKeepsGoing;

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan pages'**
  String get cameraTitle;

  /// No description provided for @cameraHint.
  ///
  /// In en, this message translates to:
  /// **'Fit the page inside the frame'**
  String get cameraHint;

  /// No description provided for @cameraFlash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get cameraFlash;

  /// No description provided for @cameraDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cameraDone;

  /// No description provided for @cameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan pages.'**
  String get cameraPermission;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device.'**
  String get cameraUnavailable;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get reviewTitle;

  /// No description provided for @reviewRead.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 page} other{Read {count} pages}}'**
  String reviewRead(int count);

  /// No description provided for @reviewAddPages.
  ///
  /// In en, this message translates to:
  /// **'Add pages'**
  String get reviewAddPages;

  /// No description provided for @reviewRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get reviewRotate;

  /// No description provided for @reviewCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get reviewCrop;

  /// No description provided for @reviewRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get reviewRemove;

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pages yet'**
  String get reviewEmpty;

  /// No description provided for @reviewSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get reviewSelectAll;

  /// No description provided for @reviewSelectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get reviewSelectNone;

  /// No description provided for @reviewSelected.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String reviewSelected(int selected, int total);

  /// No description provided for @reviewTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get reviewTitleHint;

  /// No description provided for @pageN.
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String pageN(int n);

  /// No description provided for @modeLabel.
  ///
  /// In en, this message translates to:
  /// **'What to read'**
  String get modeLabel;

  /// No description provided for @modeAsWritten.
  ///
  /// In en, this message translates to:
  /// **'As written'**
  String get modeAsWritten;

  /// No description provided for @modeAsWrittenHint.
  ///
  /// In en, this message translates to:
  /// **'Text with the tashkeel printed on the page'**
  String get modeAsWrittenHint;

  /// No description provided for @modeBare.
  ///
  /// In en, this message translates to:
  /// **'No tashkeel'**
  String get modeBare;

  /// No description provided for @modeBareHint.
  ///
  /// In en, this message translates to:
  /// **'Plain text without diacritics'**
  String get modeBareHint;

  /// No description provided for @modeMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get modeMarkdown;

  /// No description provided for @modeMarkdownHint.
  ///
  /// In en, this message translates to:
  /// **'Headings, lists and tables'**
  String get modeMarkdownHint;

  /// No description provided for @qualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get qualityLabel;

  /// No description provided for @qualityAccurate.
  ///
  /// In en, this message translates to:
  /// **'Accurate'**
  String get qualityAccurate;

  /// No description provided for @qualityAccurateHint.
  ///
  /// In en, this message translates to:
  /// **'Full detail (2.4 MP)'**
  String get qualityAccurateHint;

  /// No description provided for @qualityFast.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get qualityFast;

  /// No description provided for @qualityFastHint.
  ///
  /// In en, this message translates to:
  /// **'About twice as fast (1 MP)'**
  String get qualityFastHint;

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusQueued;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the page…'**
  String get statusPreparing;

  /// No description provided for @statusReading.
  ///
  /// In en, this message translates to:
  /// **'Looking at the page…'**
  String get statusReading;

  /// No description provided for @statusWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get statusWriting;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusCancelled;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read'**
  String get statusFailed;

  /// No description provided for @statusPausedBackground.
  ///
  /// In en, this message translates to:
  /// **'Paused while the app is in the background'**
  String get statusPausedBackground;

  /// No description provided for @readingPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {n} of {total}'**
  String readingPageOf(int n, int total);

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @stopAll.
  ///
  /// In en, this message translates to:
  /// **'Stop reading'**
  String get stopAll;

  /// No description provided for @readAgain.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get readAgain;

  /// No description provided for @readAgainWith.
  ///
  /// In en, this message translates to:
  /// **'Read again as…'**
  String get readAgainWith;

  /// No description provided for @allPages.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allPages;

  /// No description provided for @viewFormatted.
  ///
  /// In en, this message translates to:
  /// **'Formatted'**
  String get viewFormatted;

  /// No description provided for @viewText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get viewText;

  /// No description provided for @showPage.
  ///
  /// In en, this message translates to:
  /// **'Show page'**
  String get showPage;

  /// No description provided for @hidePage.
  ///
  /// In en, this message translates to:
  /// **'Hide page'**
  String get hidePage;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @doneEditing.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneEditing;

  /// No description provided for @editHint.
  ///
  /// In en, this message translates to:
  /// **'Correct the text'**
  String get editHint;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all text'**
  String get copyAll;

  /// No description provided for @copyTable.
  ///
  /// In en, this message translates to:
  /// **'Copy table'**
  String get copyTable;

  /// No description provided for @tableCopied.
  ///
  /// In en, this message translates to:
  /// **'Table copied — paste it into a spreadsheet'**
  String get tableCopied;

  /// No description provided for @saveTable.
  ///
  /// In en, this message translates to:
  /// **'Save as Excel'**
  String get saveTable;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Save or share'**
  String get export;

  /// No description provided for @exportRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get exportRecommended;

  /// No description provided for @exportSaveTo.
  ///
  /// In en, this message translates to:
  /// **'Save to Files'**
  String get exportSaveTo;

  /// No description provided for @formatDocx.
  ///
  /// In en, this message translates to:
  /// **'Word document'**
  String get formatDocx;

  /// No description provided for @formatDocxHint.
  ///
  /// In en, this message translates to:
  /// **'Text and tables, right-to-left'**
  String get formatDocxHint;

  /// No description provided for @formatXlsx.
  ///
  /// In en, this message translates to:
  /// **'Excel workbook'**
  String get formatXlsx;

  /// No description provided for @formatXlsxHint.
  ///
  /// In en, this message translates to:
  /// **'Each table on its own sheet'**
  String get formatXlsxHint;

  /// No description provided for @formatTxt.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get formatTxt;

  /// No description provided for @formatTxtHint.
  ///
  /// In en, this message translates to:
  /// **'Text only, tables as tab-separated rows'**
  String get formatTxtHint;

  /// No description provided for @formatMd.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get formatMd;

  /// No description provided for @formatMdHint.
  ///
  /// In en, this message translates to:
  /// **'Headings, lists and tables as written by the model'**
  String get formatMdHint;

  /// No description provided for @formatHtml.
  ///
  /// In en, this message translates to:
  /// **'Web page'**
  String get formatHtml;

  /// No description provided for @formatHtmlHint.
  ///
  /// In en, this message translates to:
  /// **'Opens in any browser, prints well'**
  String get formatHtmlHint;

  /// No description provided for @formatCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get formatCsv;

  /// No description provided for @formatCsvHint.
  ///
  /// In en, this message translates to:
  /// **'Tables only'**
  String get formatCsvHint;

  /// No description provided for @statsLine.
  ///
  /// In en, this message translates to:
  /// **'Read in {seconds} s · first words after {first} s · offline on this device'**
  String statsLine(String seconds, String first);

  /// No description provided for @emptyResult.
  ///
  /// In en, this message translates to:
  /// **'No text was found on this page.'**
  String get emptyResult;

  /// No description provided for @errorMissingFile.
  ///
  /// In en, this message translates to:
  /// **'The page file is no longer available.'**
  String get errorMissingFile;

  /// No description provided for @errorUnreadableImage.
  ///
  /// In en, this message translates to:
  /// **'This image could not be opened.'**
  String get errorUnreadableImage;

  /// No description provided for @errorPdfPassword.
  ///
  /// In en, this message translates to:
  /// **'This PDF is password-protected.'**
  String get errorPdfPassword;

  /// No description provided for @errorPdfUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This PDF could not be opened.'**
  String get errorPdfUnreadable;

  /// No description provided for @errorEngine.
  ///
  /// In en, this message translates to:
  /// **'The reader stopped: {detail}'**
  String errorEngine(String detail);

  /// No description provided for @modelNeeded.
  ///
  /// In en, this message translates to:
  /// **'Download the model first to read pages.'**
  String get modelNeeded;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get untitled;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Reading text size'**
  String get settingsTextSize;

  /// No description provided for @settingsTextSample.
  ///
  /// In en, this message translates to:
  /// **'يَتَدَحْرَجُ بِسُرْعَةٍ كَبِيرَةٍ'**
  String get settingsTextSample;

  /// No description provided for @settingsDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get settingsDefaults;

  /// No description provided for @settingsModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsModel;

  /// No description provided for @settingsModelReady.
  ///
  /// In en, this message translates to:
  /// **'Nuqta-OCR 0.8B · {size} on this device'**
  String settingsModelReady(String size);

  /// No description provided for @settingsModelMissing.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get settingsModelMissing;

  /// No description provided for @settingsDeleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete model'**
  String get settingsDeleteModel;

  /// No description provided for @settingsDeleteModelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the model? You will need to download it again ({size}) to read pages.'**
  String settingsDeleteModelConfirm(String size);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsKeepHistory.
  ///
  /// In en, this message translates to:
  /// **'Keep readings'**
  String get settingsKeepHistory;

  /// No description provided for @settingsKeepHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Save readings and their page images on this device'**
  String get settingsKeepHistoryHint;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete all readings'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all saved readings?'**
  String get settingsClearHistoryConfirm;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Reading is done by Nuqta-OCR (Salah AlHaismawi, Mohamed Saleh Tulib, Ahmed ElSayed Mohamed Ibrahim), an open Arabic OCR model, running through llama.cpp.'**
  String get settingsAboutBody;

  /// No description provided for @settingsSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Nuqta-OCR on GitHub'**
  String get settingsSourceCode;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
