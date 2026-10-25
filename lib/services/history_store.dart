import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/scan.dart';

/// Saved scans: `<documents>/scans/<id>/scan.json` plus the page images.
class HistoryStore extends ChangeNotifier {
  HistoryStore({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDir;
  final List<Scan> _scans = [];
  bool _loaded = false;

  List<Scan> get scans => List.unmodifiable(_scans);
  bool get isLoaded => _loaded;

  Future<Directory> _root() async =>
      Directory(p.join((await _baseDir()).path, 'scans'));

  Future<Directory> scanDir(String id) async {
    final d = Directory(p.join((await _root()).path, id));
    await d.create(recursive: true);
    return d;
  }

  Future<void> load() async {
    final root = await _root();
    _scans.clear();
    if (await root.exists()) {
      await for (final e in root.list()) {
        if (e is! Directory) continue;
        final f = File(p.join(e.path, 'scan.json'));
        if (!await f.exists()) continue;
        try {
          final scan = Scan.fromJson(
            (jsonDecode(await f.readAsString()) as Map).cast<String, dynamic>(),
          );
          _relocate(scan, e.path);
          _scans.add(scan);
        } catch (_) {
          // skip unreadable entries
        }
      }
    }
    _scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _loaded = true;
    notifyListeners();
  }

  /// iOS changes the app container path between installs: page image paths
  /// are stored relative to the scan folder and resolved here.
  void _relocate(Scan scan, String dir) {
    for (final page in scan.pages) {
      final img = page.imagePath;
      if (img != null && !p.isAbsolute(img)) page.imagePath = p.join(dir, img);
    }
  }

  /// Writes the page image the model saw; returns its path.
  Future<String> savePageImage(Scan scan, ScanPage page, Uint8List jpeg) async {
    final dir = await scanDir(scan.id);
    final path = p.join(dir.path, '${page.id}.jpg');
    await File(path).writeAsBytes(jpeg, flush: true);
    return path;
  }

  Future<void> save(Scan scan) async {
    final dir = await scanDir(scan.id);
    final json = scan.toJson();
    for (final page in json['pages'] as List) {
      final m = page as Map<String, dynamic>;
      final img = m['imagePath'] as String?;
      if (img != null && p.isWithin(dir.path, img)) {
        m['imagePath'] = p.relative(img, from: dir.path);
      }
    }
    final f = File(p.join(dir.path, 'scan.json'));
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(json), flush: true);
    await tmp.rename(f.path);
    final i = _scans.indexWhere((s) => s.id == scan.id);
    if (i >= 0) {
      _scans[i] = scan;
    } else {
      _scans.insert(0, scan);
    }
    notifyListeners();
  }

  /// Hides a scan from the list (for "undo"); [restore] brings it back,
  /// [delete] removes it for good.
  void hide(Scan scan) {
    _scans.removeWhere((s) => s.id == scan.id);
    notifyListeners();
  }

  void restore(Scan scan) {
    if (_scans.any((s) => s.id == scan.id)) return;
    _scans
      ..add(scan)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> delete(Scan scan) async {
    _scans.removeWhere((s) => s.id == scan.id);
    notifyListeners();
    final dir = Directory(p.join((await _root()).path, scan.id));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> clear() async {
    _scans.clear();
    notifyListeners();
    final root = await _root();
    if (await root.exists()) await root.delete(recursive: true);
  }
}
