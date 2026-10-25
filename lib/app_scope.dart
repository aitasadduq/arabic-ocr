import 'package:flutter/widgets.dart';

import 'services/export_service.dart';
import 'services/history_store.dart';
import 'services/model_store.dart';
import 'services/ocr_backend.dart';
import 'services/page_loader.dart';
import 'services/platform_channel.dart';
import 'services/scan_runner.dart';
import 'services/settings.dart';

/// The app's services, created once and handed down the widget tree.
class AppServices {
  AppServices({
    required this.settings,
    required this.backend,
    required this.models,
    required this.history,
    required this.loader,
    required this.runner,
    this.exporter = const ExportService(),
    PlatformChannel? platform,
  }) : platform = platform ?? PlatformChannel();

  /// The production set-up: the real engine and background downloads.
  static Future<AppServices> create({OcrBackend? backend}) async {
    final settings = await Settings.load();
    final engine = backend ?? NuqtaBackend();
    final history = HistoryStore();
    final loader = PageLoader();
    return AppServices(
      settings: settings,
      backend: engine,
      models: ModelStore(backend: engine),
      history: history,
      loader: loader,
      runner: ScanRunner(
        backend: engine,
        loader: loader,
        history: history,
        keepHistory: () => settings.keepHistory,
      ),
    );
  }

  final Settings settings;
  final OcrBackend backend;
  final ModelStore models;
  final HistoryStore history;
  final PageLoader loader;
  final ScanRunner runner;
  final ExportService exporter;
  final PlatformChannel platform;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}

extension AppScopeX on BuildContext {
  AppServices get services => AppScope.of(this);
}
