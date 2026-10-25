import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

import '../core/export/export_format.dart';
import '../l10n/app_localizations.dart';
import '../models/scan.dart';
import '../services/page_loader.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Human-readable names and icons for the app's enums.
extension ModeLabels on NuqtaMode {
  String label(AppLocalizations l) => switch (this) {
    NuqtaMode.asWritten => l.modeAsWritten,
    NuqtaMode.bare => l.modeBare,
    NuqtaMode.markdown => l.modeMarkdown,
  };

  String hint(AppLocalizations l) => switch (this) {
    NuqtaMode.asWritten => l.modeAsWrittenHint,
    NuqtaMode.bare => l.modeBareHint,
    NuqtaMode.markdown => l.modeMarkdownHint,
  };

  IconData get icon => switch (this) {
    NuqtaMode.asWritten => Icons.text_fields_rounded,
    NuqtaMode.bare => Icons.short_text_rounded,
    NuqtaMode.markdown => Icons.table_chart_outlined,
  };
}

extension QualityLabels on ReadQuality {
  String label(AppLocalizations l) => switch (this) {
    ReadQuality.accurate => l.qualityAccurate,
    ReadQuality.fast => l.qualityFast,
  };

  String hint(AppLocalizations l) => switch (this) {
    ReadQuality.accurate => l.qualityAccurateHint,
    ReadQuality.fast => l.qualityFastHint,
  };
}

extension StatusLabels on PageStatus {
  String label(AppLocalizations l) => switch (this) {
    PageStatus.queued => l.statusQueued,
    PageStatus.preparing => l.statusPreparing,
    PageStatus.reading => l.statusReading,
    PageStatus.writing => l.statusWriting,
    PageStatus.done => l.statusDone,
    PageStatus.cancelled => l.statusCancelled,
    PageStatus.failed => l.statusFailed,
  };
}

extension FormatLabels on ExportFormat {
  String label(AppLocalizations l) => switch (this) {
    ExportFormat.docx => l.formatDocx,
    ExportFormat.xlsx => l.formatXlsx,
    ExportFormat.txt => l.formatTxt,
    ExportFormat.md => l.formatMd,
    ExportFormat.html => l.formatHtml,
    ExportFormat.csv => l.formatCsv,
  };

  String hint(AppLocalizations l) => switch (this) {
    ExportFormat.docx => l.formatDocxHint,
    ExportFormat.xlsx => l.formatXlsxHint,
    ExportFormat.txt => l.formatTxtHint,
    ExportFormat.md => l.formatMdHint,
    ExportFormat.html => l.formatHtmlHint,
    ExportFormat.csv => l.formatCsvHint,
  };

  IconData get icon => switch (this) {
    ExportFormat.docx => Icons.description_outlined,
    ExportFormat.xlsx => Icons.grid_on_rounded,
    ExportFormat.txt => Icons.notes_rounded,
    ExportFormat.md => Icons.tag_rounded,
    ExportFormat.html => Icons.language_rounded,
    ExportFormat.csv => Icons.view_list_outlined,
  };
}

/// A page error as a sentence for the user.
String pageErrorText(AppLocalizations l, String? code) {
  for (final k in PageLoadError.values) {
    if (k.name == code) {
      return switch (k) {
        PageLoadError.missingFile => l.errorMissingFile,
        PageLoadError.unreadableImage => l.errorUnreadableImage,
        PageLoadError.pdfPassword => l.errorPdfPassword,
        PageLoadError.pdfUnreadable => l.errorPdfUnreadable,
      };
    }
  }
  return l.errorEngine(code ?? '');
}

String formatBytes(BuildContext context, int bytes) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final f = NumberFormat('#,##0.#', locale);
  if (bytes >= 1e9) return '${f.format(bytes / 1e9)} GB';
  if (bytes >= 1e6) {
    return '${NumberFormat('#,##0', locale).format(bytes / 1e6)} MB';
  }
  return '${f.format(bytes / 1e3)} KB';
}

String formatPercent(BuildContext context, double v) =>
    NumberFormat.percentPattern(Localizations.localeOf(context).toLanguageTag())
        .format(v);

String formatSeconds(BuildContext context, double s) => NumberFormat(
  s < 10 ? '0.0' : '0',
  Localizations.localeOf(context).toLanguageTag(),
).format(s);

String formatDate(BuildContext context, DateTime d) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return DateFormat.jm(locale).format(d);
  }
  if (d.year == now.year) return DateFormat.MMMd(locale).format(d);
  return DateFormat.yMMMd(locale).format(d);
}
