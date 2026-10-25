import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

import '../../app_scope.dart';
import '../../core/bidi.dart';
import '../../core/document/document_parser.dart';
import '../../core/document/ocr_document.dart';
import '../../core/export/export_format.dart';
import '../../models/scan.dart';
import '../export_sheet.dart';
import '../labels.dart';
import '../theme.dart';
import '../widgets/document_view.dart';
import '../widgets/paced_text.dart';
import '../widgets/page_thumbnail.dart';

/// A reading: live while the model writes, then the result to copy, edit,
/// save or share. On wide screens the page image sits next to the text.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.scan});
  final Scan scan;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final PacedText _paced = PacedText(this);
  final _scroll = ScrollController();
  final _parsed = <String, (String, DocPage)>{};

  /// null = all pages.
  String? _pageId;
  bool _showImage = false;
  bool _follow = true;
  String? _editingId;
  final _editor = TextEditingController();
  Timer? _clock;

  Scan get scan => widget.scan;

  /// Kept from initState: callbacks may run after the element is deactivated.
  late final AppServices _s;

  @override
  void initState() {
    super.initState();
    _s = context.services;
    _s.runner.addListener(_onRunner);
    _paced.addListener(_onPaced);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunningHere && mounted) setState(() {});
    });
    if (scan.pages.length == 1) _pageId = scan.pages.first.id;
  }

  @override
  void dispose() {
    _s.runner.removeListener(_onRunner);
    _paced.dispose();
    _scroll.dispose();
    _editor.dispose();
    _clock?.cancel();
    super.dispose();
  }

  bool get _isRunningHere {
    final r = _s.runner;
    return r.isRunning && identical(r.scan, scan);
  }

  ScanPage? get _activePage {
    final r = _s.runner;
    return identical(r.scan, scan) ? r.currentPage : null;
  }

  void _onRunner() {
    final page = _activePage;
    if (page != null) {
      _paced.update(page.text, finished: page.status.isFinished);
    } else {
      _paced.flush();
    }
    if (mounted) setState(() {});
  }

  void _onPaced() {
    if (!mounted) return;
    setState(() {});
    if (_follow && _scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && _follow) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n is UserScrollNotification) {
      if (n.direction == ScrollDirection.forward) _follow = false;
    }
    if (n.metrics.extentAfter < 40) _follow = true;
    return false;
  }

  /// The text to show for [p]: paced while it is being written.
  String _textOf(ScanPage p) =>
      identical(p, _activePage) && !p.status.isFinished ? _paced.text : p.text;

  DocPage _doc(ScanPage p) {
    final text = _textOf(p);
    final cached = _parsed[p.id];
    if (cached != null && cached.$1 == text) return cached.$2;
    final doc = DocumentParser.parse(text, structured: scan.isStructured);
    _parsed[p.id] = (text, doc);
    return doc;
  }

  List<ScanPage> get _shownPages => _pageId == null
      ? scan.pages
      : scan.pages.where((p) => p.id == _pageId).toList();

  ScanPage? get _imagePage {
    if (_pageId != null) {
      return scan.pages.where((p) => p.id == _pageId).firstOrNull;
    }
    return _activePage ?? scan.pages.firstOrNull;
  }

  String get _title =>
      scan.title.isNotEmpty ? scan.title : context.l10n.untitled;

  Future<void> _rename() async {
    final l = context.l10n;
    final c = TextEditingController(text: scan.title);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.rename),
        content: TextField(
          controller: c,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (name == null) return;
    setState(() => scan.title = name.trim());
    await _persist();
  }

  Future<void> _persist() async {
    if (_s.settings.keepHistory) await _s.history.save(scan);
  }

  void _selectPage(String? id) => setState(() => _pageId = id);

  void _startEdit(ScanPage p) {
    _editor.text = p.text;
    setState(() => _editingId = p.id);
  }

  Future<void> _finishEdit() async {
    final page = scan.pages.where((p) => p.id == _editingId).firstOrNull;
    if (page != null) page.text = _editor.text;
    setState(() => _editingId = null);
    await _persist();
  }

  Future<void> _readAgain(NuqtaMode mode) async {
    final s = _s;
    if (!s.models.isReady) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.modelNeeded)));
      return;
    }
    await s.runner.stop();
    scan.mode = mode;
    for (final p in scan.pages) {
      p
        ..status = PageStatus.queued
        ..text = ''
        ..error = null;
    }
    _parsed.clear();
    setState(() {});
    unawaited(s.runner.run(scan));
  }

  Future<void> _delete() async {
    final s = _s;
    if (_isRunningHere) await s.runner.stop();
    await s.history.delete(scan);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _copyAll() async {
    await context.services.exporter.copyDocument(scan.document);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  Future<void> _copyTable(TableBlock t) async {
    await context.services.exporter.copyTable(t);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.tableCopied)));
  }

  void _saveTable(TableBlock t) {
    showExportSheet(
      context,
      document: OcrDocument([
        DocPage([t]),
      ], title: _title),
      title: _title,
      formats: const [ExportFormat.xlsx, ExportFormat.csv],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final running = _isRunningHere;
    final hasText = scan.pages.any((p) => p.text.trim().isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _rename,
          child: Text(_title, overflow: TextOverflow.ellipsis),
        ),
        actions: [
          IconButton(
            tooltip: _showImage ? l.hidePage : l.showPage,
            icon: Icon(_showImage ? Icons.image_rounded : Icons.image_outlined),
            onPressed: () => setState(() => _showImage = !_showImage),
          ),
          IconButton(
            tooltip: l.copyAll,
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: hasText ? _copyAll : null,
          ),
          IconButton(
            tooltip: l.export,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: hasText
                ? () => showExportSheet(
                    context,
                    document: scan.document,
                    title: _title,
                  )
                : null,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'rename':
                  _rename();
                case 'delete':
                  _delete();
                default:
                  _readAgain(NuqtaMode.fromId(v));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l.rename),
                ),
              ),
              for (final m in NuqtaMode.values)
                PopupMenuItem(
                  value: m.id,
                  child: ListTile(
                    leading: Icon(m.icon),
                    title: Text(m.label(l)),
                    subtitle: Text(l.readAgain),
                    trailing: m == scan.mode
                        ? const Icon(Icons.check_rounded)
                        : null,
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                  title: Text(l.delete, style: TextStyle(color: cs.error)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 840;
          final text = _TextPane(state: this, running: running);
          final image = _imagePage;
          if (wide && _showImage && image != null) {
            return Row(
              children: [
                Expanded(flex: 5, child: _ImagePane(page: image)),
                VerticalDivider(width: 1, color: cs.outlineVariant),
                Expanded(flex: 6, child: text),
              ],
            );
          }
          if (_showImage && image != null) {
            return Column(
              children: [
                SizedBox(
                  height: box.maxHeight * 0.42,
                  child: _ImagePane(page: image),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                Expanded(child: text),
              ],
            );
          }
          return text;
        },
      ),
      bottomNavigationBar: running ? _RunningBar(state: this) : null,
      floatingActionButton: _editingId != null
          ? FloatingActionButton.extended(
              onPressed: _finishEdit,
              icon: const Icon(Icons.check_rounded),
              label: Text(l.doneEditing),
            )
          : null,
    );
  }
}

class _TextPane extends StatelessWidget {
  const _TextPane({required this.state, required this.running});
  final _ResultScreenState state;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final scan = state.scan;
    final pages = state._shownPages;
    return ListenableBuilder(
      listenable: s.settings,
      builder: (context, _) {
        final formatted = s.settings.formattedView;
        final scale = s.settings.textScale;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: scan.pages.length > 1
                        ? _PageChips(state: state)
                        : const SizedBox(),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.article_outlined),
                        tooltip: l.viewFormatted,
                      ),
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.notes_rounded),
                        tooltip: l.viewText,
                      ),
                    ],
                    selected: {formatted},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) =>
                        s.settings.formattedView = v.first,
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: state._onScroll,
                child: SelectionArea(
                  child: ListView(
                    controller: state._scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      for (final p in pages) ...[
                        if (pages.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  l.pageN(scan.pages.indexOf(p) + 1),
                                  style: tt.labelLarge?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Divider(color: cs.outlineVariant),
                                ),
                              ],
                            ),
                          ),
                        _PageBody(
                          state: state,
                          page: p,
                          formatted: formatted,
                          scale: scale,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.state,
    required this.page,
    required this.formatted,
    required this.scale,
  });
  final _ResultScreenState state;
  final ScanPage page;
  final bool formatted;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final s = context.services;
    final writing =
        identical(page, state._activePage) && !page.status.isFinished;

    if (state._editingId == page.id) {
      return TextField(
        controller: state._editor,
        maxLines: null,
        autofocus: true,
        textDirection: Bidi.isRtl(page.text)
            ? TextDirection.rtl
            : TextDirection.ltr,
        style: AppTheme.reading(context, scale),
        decoration: InputDecoration(
          hintText: l.editHint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    final text = state._textOf(page);
    if (page.status == PageStatus.failed) {
      return _Notice(
        icon: Icons.error_outline_rounded,
        color: cs.error,
        text: pageErrorText(l, page.error),
        action: TextButton(
          onPressed: () => s.runner.retry(state.scan, page),
          child: Text(l.retry),
        ),
      );
    }
    if (text.trim().isEmpty) {
      if (page.status == PageStatus.done) {
        return _Notice(
          icon: Icons.find_in_page_outlined,
          color: cs.onSurfaceVariant,
          text: l.emptyResult,
        );
      }
      return _Waiting(page: page, paused: s.runner.isPausedInBackground);
    }

    final body = formatted
        ? DocumentView(
            blocks: state._doc(page).blocks,
            textScale: scale,
            writing: writing,
            onCopyTable: writing ? null : state._copyTable,
            onSaveTable: writing ? null : state._saveTable,
          )
        : Directionality(
            textDirection: Bidi.isRtl(text)
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Text(text, style: AppTheme.reading(context, scale)),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        if (page.status.isFinished && !writing)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                if (page.seconds != null)
                  Expanded(
                    child: Text(
                      l.statsLine(
                        formatSeconds(context, page.seconds!),
                        formatSeconds(context, page.firstWordsSeconds ?? 0),
                      ),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                else
                  const Spacer(),
                if (page.status == PageStatus.cancelled)
                  TextButton(
                    onPressed: () => s.runner.retry(state.scan, page),
                    child: Text(l.readAgain),
                  ),
                IconButton(
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_note_rounded),
                  onPressed: state._isRunningHere
                      ? null
                      : () => state._startEdit(page),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.page, required this.paused});
  final ScanPage page;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          if (page.status.isActive)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Icon(Icons.schedule_rounded, color: cs.outline),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              paused ? l.statusPausedBackground : page.status.label(l),
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.text,
    this.action,
  });
  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _PageChips extends StatelessWidget {
  const _PageChips({required this.state});
  final _ResultScreenState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final pages = state.scan.pages;
    Widget chip(String label, String? id, PageStatus? status) {
      final selected = state._pageId == id;
      Widget? avatar;
      if (status != null) {
        avatar = switch (status) {
          PageStatus.preparing ||
          PageStatus.reading ||
          PageStatus.writing => const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          PageStatus.done => Icon(
            Icons.check_rounded,
            size: 16,
            color: cs.primary,
          ),
          PageStatus.failed => Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: cs.error,
          ),
          PageStatus.cancelled => Icon(
            Icons.stop_circle_outlined,
            size: 16,
            color: cs.outline,
          ),
          PageStatus.queued => null,
        };
      }
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: ChoiceChip(
          label: Text(label),
          avatar: avatar,
          showCheckmark: false,
          selected: selected,
          onSelected: (_) => state._selectPage(id),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(l.allPages, null, null),
          for (var i = 0; i < pages.length; i++)
            chip('${i + 1}', pages[i].id, pages[i].status),
        ],
      ),
    );
  }
}

class _ImagePane extends StatelessWidget {
  const _ImagePane({required this.page});
  final ScanPage page;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stored = page.imagePath;
    return ColoredBox(
      color: cs.surfaceContainer,
      child: InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: stored != null && File(stored).existsSync()
              ? Image.file(File(stored), fit: BoxFit.contain)
              : PageThumbnail(
                  source: page.source,
                  quarterTurns: page.quarterTurns,
                  fit: BoxFit.contain,
                  cacheWidth: 2000,
                ),
        ),
      ),
    );
  }
}

class _RunningBar extends StatelessWidget {
  const _RunningBar({required this.state});
  final _ResultScreenState state;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final scan = state.scan;
    final page = state._activePage;
    final index = page == null ? scan.doneCount : scan.pages.indexOf(page);
    final total = scan.pages.length;
    final started = s.runner.pageStartedAt;
    final elapsed = started == null
        ? 0
        : DateTime.now().difference(started).inSeconds;
    final status = s.runner.isPausedInBackground
        ? l.statusPausedBackground
        : (page?.status ?? PageStatus.preparing).label(l);
    return Material(
      color: cs.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          total > 1
                              ? l.readingPageOf(index + 1, total)
                              : status,
                          style: tt.titleSmall,
                        ),
                        Text(
                          total > 1 ? '$status · ${elapsed}s' : '${elapsed}s',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: s.runner.cancelAll,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(l.stopAll),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: total > 1
                    ? (scan.doneCount / total).clamp(0.02, 1.0)
                    : null,
                minHeight: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
