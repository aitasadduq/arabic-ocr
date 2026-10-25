// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'قارئ النصوص العربية';

  @override
  String get homeHeadline => 'اقرأ الصفحات العربية';

  @override
  String get homeSubtitle =>
      'النص والتشكيل والجداول — تُقرأ على هاتفك دون اتصال.';

  @override
  String get actionCamera => 'الكاميرا';

  @override
  String get actionCameraHint => 'صوّر الصفحات';

  @override
  String get actionPhotos => 'الصور';

  @override
  String get actionPhotosHint => 'من مكتبة الصور';

  @override
  String get actionFiles => 'الملفات';

  @override
  String get actionFilesHint => 'PDF أو صور';

  @override
  String get samplesTitle => 'جرّب مثالًا';

  @override
  String get sampleBook => 'كتاب مشكول';

  @override
  String get sampleTable => 'جدول';

  @override
  String get samplePassport => 'جواز سفر';

  @override
  String get sampleOldBook => 'مسح قديم';

  @override
  String get recentTitle => 'الأخيرة';

  @override
  String get recentEmpty => 'ستظهر قراءاتك هنا.';

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحة',
      many: '$count صفحة',
      few: '$count صفحات',
      two: 'صفحتان',
      one: 'صفحة واحدة',
      zero: 'لا صفحات',
    );
    return '$_temp0';
  }

  @override
  String get deleteScan => 'حذف';

  @override
  String get scanDeleted => 'حُذفت القراءة';

  @override
  String get undo => 'تراجع';

  @override
  String get settings => 'الإعدادات';

  @override
  String get modelCardMissingTitle => 'نزّل نموذج القراءة';

  @override
  String modelCardMissingBody(String size) {
    return 'تنزيل لمرة واحدة بحجم $size. بعدها يعمل كل شيء دون اتصال.';
  }

  @override
  String modelCardDownloading(String percent) {
    return 'جارٍ تنزيل النموذج… $percent';
  }

  @override
  String modelCardPaused(String percent) {
    return 'توقف التنزيل عند $percent';
  }

  @override
  String get modelCardLoading => 'جارٍ تجهيز القارئ…';

  @override
  String get modelCardError => 'تعذّر تجهيز النموذج';

  @override
  String get download => 'تنزيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get resume => 'متابعة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'حاول مجددًا';

  @override
  String get importModel => 'استيراد ملفات النموذج';

  @override
  String get importModelHint => 'اختر ملفّي ‎.gguf إن كانا لديك';

  @override
  String importUnknown(String names) {
    return 'ليست ملفات النموذج: $names';
  }

  @override
  String get setupTitle => 'يقرأ العربية على هاتفك';

  @override
  String get setupBody =>
      'يعتمد التطبيق على نموذج «نقطة» المفتوح، الذي ينقل التشكيل كما هو مطبوع في الصفحة ويحفظ الجداول جداولَ. لا تغادر صفحاتك جهازك أبدًا.';

  @override
  String get setupPointOffline => 'يعمل دون اتصال بعد تنزيل واحد';

  @override
  String get setupPointPrivate => 'لا يُرفع أي شيء';

  @override
  String get setupPointTables => 'النص والتشكيل والعناوين والجداول';

  @override
  String setupDownloadSize(String size) {
    return 'حجم النموذج: $size';
  }

  @override
  String get setupWifiOnly => 'التنزيل عبر Wi-Fi فقط';

  @override
  String setupLowMemory(String ram) {
    return 'ذاكرة هذا الجهاز $ram. قد تكون القراءة بطيئة أو تتوقف في الصفحات الطويلة.';
  }

  @override
  String get setupLater => 'ليس الآن';

  @override
  String get setupStart => 'نزّل وابدأ';

  @override
  String get downloadKeepsGoing => 'يستمر التنزيل حتى إن غادرت التطبيق.';

  @override
  String get cameraTitle => 'تصوير الصفحات';

  @override
  String get cameraHint => 'اجعل الصفحة داخل الإطار';

  @override
  String get cameraFlash => 'الفلاش';

  @override
  String get cameraDone => 'تم';

  @override
  String get cameraPermission =>
      'يلزم السماح باستخدام الكاميرا لتصوير الصفحات.';

  @override
  String get cameraUnavailable => 'لا توجد كاميرا متاحة على هذا الجهاز.';

  @override
  String get openSettings => 'افتح الإعدادات';

  @override
  String get reviewTitle => 'الصفحات';

  @override
  String reviewRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اقرأ $count صفحة',
      many: 'اقرأ $count صفحة',
      few: 'اقرأ $count صفحات',
      two: 'اقرأ صفحتين',
      one: 'اقرأ صفحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get reviewAddPages => 'إضافة صفحات';

  @override
  String get reviewRotate => 'تدوير';

  @override
  String get reviewCrop => 'قص';

  @override
  String get reviewRemove => 'إزالة';

  @override
  String get reviewEmpty => 'لا توجد صفحات بعد';

  @override
  String get reviewSelectAll => 'تحديد الكل';

  @override
  String get reviewSelectNone => 'إلغاء التحديد';

  @override
  String reviewSelected(int selected, int total) {
    return '$selected من $total محددة';
  }

  @override
  String get reviewTitleHint => 'العنوان (اختياري)';

  @override
  String pageN(int n) {
    return 'صفحة $n';
  }

  @override
  String get modeLabel => 'ماذا تقرأ';

  @override
  String get modeAsWritten => 'كما كُتب';

  @override
  String get modeAsWrittenHint => 'النص مع التشكيل المطبوع في الصفحة';

  @override
  String get modeBare => 'دون تشكيل';

  @override
  String get modeBareHint => 'نص مجرد من الحركات';

  @override
  String get modeMarkdown => 'مستند';

  @override
  String get modeMarkdownHint => 'العناوين والقوائم والجداول';

  @override
  String get qualityLabel => 'الدقة';

  @override
  String get qualityAccurate => 'دقيقة';

  @override
  String get qualityAccurateHint => 'تفاصيل كاملة (2.4 ميغابكسل)';

  @override
  String get qualityFast => 'أسرع';

  @override
  String get qualityFastHint => 'أسرع بنحو الضعف (1 ميغابكسل)';

  @override
  String get statusQueued => 'في الانتظار';

  @override
  String get statusPreparing => 'جارٍ تجهيز الصفحة…';

  @override
  String get statusReading => 'جارٍ النظر في الصفحة…';

  @override
  String get statusWriting => 'جارٍ الكتابة…';

  @override
  String get statusDone => 'اكتملت';

  @override
  String get statusCancelled => 'أُوقفت';

  @override
  String get statusFailed => 'تعذّرت القراءة';

  @override
  String get statusPausedBackground =>
      'متوقفة مؤقتًا ما دام التطبيق في الخلفية';

  @override
  String readingPageOf(int n, int total) {
    return 'صفحة $n من $total';
  }

  @override
  String get stop => 'إيقاف';

  @override
  String get stopAll => 'أوقف القراءة';

  @override
  String get readAgain => 'اقرأ مجددًا';

  @override
  String get readAgainWith => 'اقرأ مجددًا بوضع…';

  @override
  String get allPages => 'الكل';

  @override
  String get viewFormatted => 'منسّق';

  @override
  String get viewText => 'نص';

  @override
  String get showPage => 'أظهر الصفحة';

  @override
  String get hidePage => 'أخفِ الصفحة';

  @override
  String get edit => 'تحرير';

  @override
  String get doneEditing => 'تم';

  @override
  String get editHint => 'صحّح النص';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'نُسخ';

  @override
  String get copyAll => 'نسخ النص كله';

  @override
  String get copyTable => 'نسخ الجدول';

  @override
  String get tableCopied => 'نُسخ الجدول — الصقه في جدول بيانات';

  @override
  String get saveTable => 'حفظ بصيغة Excel';

  @override
  String get share => 'مشاركة';

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'حُفظ';

  @override
  String get export => 'حفظ أو مشاركة';

  @override
  String get exportRecommended => 'مقترح';

  @override
  String get exportSaveTo => 'حفظ في الملفات';

  @override
  String get formatDocx => 'مستند Word';

  @override
  String get formatDocxHint => 'النص والجداول من اليمين إلى اليسار';

  @override
  String get formatXlsx => 'مصنف Excel';

  @override
  String get formatXlsxHint => 'كل جدول في ورقة';

  @override
  String get formatTxt => 'نص عادي';

  @override
  String get formatTxtHint => 'النص فقط، والجداول صفوف مفصولة بعلامات جدولة';

  @override
  String get formatMd => 'Markdown';

  @override
  String get formatMdHint => 'العناوين والقوائم والجداول كما كتبها النموذج';

  @override
  String get formatHtml => 'صفحة ويب';

  @override
  String get formatHtmlHint => 'تُفتح في أي متصفح وتُطبع جيدًا';

  @override
  String get formatCsv => 'CSV';

  @override
  String get formatCsvHint => 'الجداول فقط';

  @override
  String statsLine(String seconds, String first) {
    return 'قُرئت في $seconds ث · أول الكلمات بعد $first ث · دون اتصال على هذا الجهاز';
  }

  @override
  String get emptyResult => 'لم يُعثر على نص في هذه الصفحة.';

  @override
  String get errorMissingFile => 'ملف الصفحة لم يعد متاحًا.';

  @override
  String get errorUnreadableImage => 'تعذّر فتح هذه الصورة.';

  @override
  String get errorPdfPassword => 'ملف PDF هذا محمي بكلمة مرور.';

  @override
  String get errorPdfUnreadable => 'تعذّر فتح ملف PDF هذا.';

  @override
  String errorEngine(String detail) {
    return 'توقف القارئ: $detail';
  }

  @override
  String get modelNeeded => 'نزّل النموذج أولًا لقراءة الصفحات.';

  @override
  String get untitled => 'قراءة';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتحة';

  @override
  String get themeDark => 'داكنة';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'حسب النظام';

  @override
  String get settingsTextSize => 'حجم نص القراءة';

  @override
  String get settingsTextSample => 'يَتَدَحْرَجُ بِسُرْعَةٍ كَبِيرَةٍ';

  @override
  String get settingsDefaults => 'القراءة';

  @override
  String get settingsModel => 'النموذج';

  @override
  String settingsModelReady(String size) {
    return 'نقطة 0.8B · $size على هذا الجهاز';
  }

  @override
  String get settingsModelMissing => 'غير منزّل';

  @override
  String get settingsDeleteModel => 'حذف النموذج';

  @override
  String settingsDeleteModelConfirm(String size) {
    return 'أتحذف النموذج؟ ستحتاج إلى تنزيله مجددًا ($size) لقراءة الصفحات.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get settingsStorage => 'التخزين';

  @override
  String get settingsKeepHistory => 'الاحتفاظ بالقراءات';

  @override
  String get settingsKeepHistoryHint =>
      'حفظ القراءات وصور صفحاتها على هذا الجهاز';

  @override
  String get settingsClearHistory => 'حذف كل القراءات';

  @override
  String get settingsClearHistoryConfirm => 'أتحذف كل القراءات المحفوظة؟';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsAboutBody =>
      'تتم القراءة بنموذج «نقطة» (Salah AlHaismawi وMohamed Saleh Tulib وAhmed ElSayed Mohamed Ibrahim)، وهو نموذج مفتوح للتعرف على النص العربي، يعمل عبر llama.cpp.';

  @override
  String get settingsSourceCode => 'نقطة على GitHub';

  @override
  String get settingsLicenses => 'تراخيص البرمجيات المفتوحة';
}
