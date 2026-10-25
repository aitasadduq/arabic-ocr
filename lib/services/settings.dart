import 'package:flutter/material.dart';
import 'package:nuqta_engine/nuqta_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan.dart';

/// User preferences, persisted with shared_preferences.
class Settings extends ChangeNotifier {
  Settings(this._prefs);

  static Future<Settings> load() async => Settings(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    ),
  );

  final SharedPreferencesWithCache _prefs;

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
    (m) => m.name == _prefs.getString('themeMode'),
    orElse: () => ThemeMode.system,
  );
  set themeMode(ThemeMode v) => _put('themeMode', v.name);

  /// null follows the system language.
  Locale? get locale {
    final code = _prefs.getString('locale');
    return code == null || code.isEmpty ? null : Locale(code);
  }

  set locale(Locale? v) => _put('locale', v?.languageCode ?? '');

  NuqtaMode get mode => NuqtaMode.fromId(_prefs.getString('mode'));
  set mode(NuqtaMode v) => _put('mode', v.id);

  ReadQuality get quality => ReadQuality.fromName(_prefs.getString('quality'));
  set quality(ReadQuality v) => _put('quality', v.name);

  /// Size of the reading text, as a factor of the default.
  double get textScale => _prefs.getDouble('textScale') ?? 1.0;
  set textScale(double v) => _put('textScale', v);

  bool get wifiOnly => _prefs.getBool('wifiOnly') ?? false;
  set wifiOnly(bool v) => _put('wifiOnly', v);

  bool get keepHistory => _prefs.getBool('keepHistory') ?? true;
  set keepHistory(bool v) => _put('keepHistory', v);

  /// The first-run model screen was seen (downloaded, or put off).
  bool get setupSeen => _prefs.getBool('setupSeen') ?? false;
  set setupSeen(bool v) => _put('setupSeen', v);

  /// Show the formatted document (true) or the raw model output.
  bool get formattedView => _prefs.getBool('formattedView') ?? true;
  set formattedView(bool v) => _put('formattedView', v);

  void _put(String key, Object v) {
    switch (v) {
      case String s:
        _prefs.setString(key, s);
      case bool b:
        _prefs.setBool(key, b);
      case double d:
        _prefs.setDouble(key, d);
      case int i:
        _prefs.setInt(key, i);
    }
    notifyListeners();
  }
}
