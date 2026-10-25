import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'l10n/app_localizations.dart';
import 'services/model_store.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/theme.dart';

class ArabicOcrApp extends StatefulWidget {
  const ArabicOcrApp({super.key, required this.services, this.home});

  final AppServices services;

  /// Overrides the first screen (tests, screenshots).
  final Widget? home;

  @override
  State<ArabicOcrApp> createState() => _ArabicOcrAppState();
}

class _ArabicOcrAppState extends State<ArabicOcrApp> {
  @override
  void initState() {
    super.initState();
    final s = widget.services;
    s.models.init();
    s.history.load();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.services.settings;
    return AppScope(
      services: widget.services,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final locale = settings.locale;
          return MaterialApp(
            onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
            debugShowCheckedModeBanner: false,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: settings.themeMode,
            theme: AppTheme.light(locale ?? _systemLocale()),
            darkTheme: AppTheme.dark(locale ?? _systemLocale()),
            home: widget.home ?? const _StartGate(),
          );
        },
      ),
    );
  }

  Locale _systemLocale() {
    final l = WidgetsBinding.instance.platformDispatcher.locale;
    return l.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
  }
}

/// Shows the model set-up on first run, the home screen otherwise.
class _StartGate extends StatelessWidget {
  const _StartGate();

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    return ListenableBuilder(
      listenable: Listenable.merge([s.models, s.settings]),
      builder: (context, _) {
        final firstRun =
            !s.settings.setupSeen &&
            (s.models.status == ModelStatus.missing ||
                s.models.status == ModelStatus.downloading ||
                s.models.status == ModelStatus.paused);
        return firstRun ? const SetupScreen() : const HomeScreen();
      },
    );
  }
}
