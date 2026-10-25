import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  final services = await AppServices.create();
  runApp(ArabicOcrApp(services: services));
}

Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = {
    'IBM Plex Sans': 'ibmplexsans',
    'Noto Sans Arabic': 'notosansarabic',
    'Noto Naskh Arabic': 'notonaskharabic',
    'Source Serif 4': 'sourceserif4',
  };
  for (final MapEntry(:key, :value) in fonts.entries) {
    final text = await rootBundle.loadString('assets/fonts/OFL-$value.txt');
    yield LicenseEntryWithLineBreaks([key], text);
  }
  yield const LicenseEntryWithLineBreaks(
    ['Nuqta-OCR', 'nuqta_engine'],
    'Nuqta-OCR engine, prompts and sample pages: '
    'https://github.com/SalahAlHaismawi/nuqta-ocr\n'
    'Copyright Salah AlHaismawi, Mohamed Saleh Tulib, Ahmed ElSayed Mohamed '
    'Ibrahim. Licensed under the Apache License, Version 2.0.',
  );
  yield const LicenseEntryWithLineBreaks(
    ['llama.cpp', 'ggml'],
    'Copyright (c) 2023-2026 The ggml authors. MIT License. '
    'https://github.com/ggml-org/llama.cpp',
  );
}
