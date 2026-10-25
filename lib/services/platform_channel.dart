import 'package:flutter/services.dart';

/// Native helpers (see ios/Runner/AppDelegate.swift and MainActivity.kt).
class PlatformChannel {
  static const _channel = MethodChannel('arabic_ocr/platform');

  /// Keeps a folder out of iCloud backups (no-op on Android, which uses
  /// backup rules instead).
  Future<void> excludeFromBackup(String path) async {
    try {
      await _channel.invokeMethod<bool>('excludeFromBackup', path);
    } on MissingPluginException {
      // tests and unsupported platforms
    } on PlatformException {
      // not fatal: the model can still be used
    }
  }

  /// Physical RAM in bytes, or null when unknown.
  Future<int?> totalMemory() async {
    try {
      return await _channel.invokeMethod<int>('totalMemory');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
