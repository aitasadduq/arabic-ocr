import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:nuqta_engine/nuqta_engine.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app_scope.dart';
import '../../models/scan.dart';
import '../labels.dart';
import '../page_import.dart';
import '../widgets/mode_picker.dart';
import '../widgets/page_thumbnail.dart';

class _Item {
  _Item(this.source) : key = UniqueKey();
  final Key key;
  PageSource source;
  int turns = 0;
  bool selected = true;
}

/// The pages about to be read: order, rotate, crop, choose; then mode and
/// detail. Wide screens show the pages and the options side by side.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.initial});
  final List<PageSource> initial;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<_Item> _items = [for (final s in widget.initial) _Item(s)];
  late NuqtaMode _mode = context.services.settings.mode;
  late ReadQuality _quality = context.services.settings.quality;
  final _title = TextEditingController();

  int get _selectedCount => _items.where((i) => i.selected).length;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _add(String how) async {
    List<PageSource>? more;
    switch (how) {
      case 'files':
        more = await pickPageFiles(context);
      case 'camera':
        if (!mounted) return;
        await openCamera(context);
        return;
      default:
        await pickFromPhotos(context);
        return;
    }
    if (more == null || more.isEmpty) return;
    setState(() => _items.addAll(more!.map(_Item.new)));
  }

  Future<void> _crop(_Item item) async {
    String? path;
    switch (item.source) {
      case FilePageSource(path: final fp):
        path = fp;
      case AssetPageSource(:final asset):
        final data = await rootBundle.load(asset);
        final f = File(
          p.join((await getTemporaryDirectory()).path, p.basename(asset)),
        );
        await f.writeAsBytes(data.buffer.asUint8List());
        path = f.path;
      case PdfPageSource():
        return;
    }
    if (!mounted) return;
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: l.reviewCrop,
          toolbarColor: cs.surface,
          toolbarWidgetColor: cs.onSurface,
          activeControlsWidgetColor: cs.primary,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: l.reviewCrop, aspectRatioLockEnabled: false),
      ],
    );
    if (cropped == null) return;
    setState(() {
      item
        ..source = FilePageSource(cropped.path)
        ..turns = 0;
    });
  }

  void _read() {
    final s = context.services;
    s.settings
      ..mode = _mode
      ..quality = _quality;
    final chosen = _items.where((i) => i.selected).toList();
    final scan = Scan(
      id: newId(),
      createdAt: DateTime.now(),
      mode: _mode,
      quality: _quality,
      title: _title.text.trim(),
      pages: [
        for (var i = 0; i < chosen.length; i++)
          ScanPage(
            id: 'p${i + 1}',
            source: chosen[i].source,
            quarterTurns: chosen[i].turns,
          ),
      ],
    );
    startScan(context, scan, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final count = _selectedCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reviewTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.reviewAddPages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onSelected: _add,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'camera',
                child: ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l.actionCamera),
                ),
              ),
              PopupMenuItem(
                value: 'photos',
                child: ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l.actionPhotos),
                ),
              ),
              PopupMenuItem(
                value: 'files',
                child: ListTile(
                  leading: const Icon(Icons.folder_open_rounded),
                  title: Text(l.actionFiles),
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 760;
          final header = _SelectionHeader(
            items: _items,
            onChanged: () => setState(() {}),
          );
          Widget item(BuildContext context, int i) => _PageTile(
            key: _items[i].key,
            item: _items[i],
            index: i,
            onChanged: () => setState(() {}),
            onRemove: () => setState(() => _items.removeAt(i)),
            onCrop: () => _crop(_items[i]),
          );
          // onReorderItem already adjusts the target index for the removed item
          void reorder(int from, int to) =>
              setState(() => _items.insert(to, _items.removeAt(from)));

          final titleField = TextField(
            controller: _title,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l.reviewTitleHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
          if (wide) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      header,
                      Expanded(
                        child: _items.isEmpty
                            ? Center(child: Text(l.reviewEmpty))
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  4,
                                  12,
                                  12,
                                ),
                                buildDefaultDragHandles: false,
                                itemCount: _items.length,
                                onReorderItem: reorder,
                                itemBuilder: item,
                              ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: cs.outlineVariant),
                Expanded(
                  flex: 4,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      titleField,
                      const SizedBox(height: 20),
                      ModePicker(
                        value: _mode,
                        onChanged: (m) => setState(() => _mode = m),
                      ),
                      const SizedBox(height: 12),
                      QualityPicker(
                        value: _quality,
                        onChanged: (q) => setState(() => _quality = q),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CompactModePicker(
                        value: _mode,
                        onChanged: (m) => setState(() => _mode = m),
                      ),
                      const SizedBox(height: 14),
                      QualityPicker(
                        value: _quality,
                        onChanged: (q) => setState(() => _quality = q),
                      ),
                      const SizedBox(height: 14),
                      titleField,
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: header),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                sliver: SliverReorderableList(
                  itemCount: _items.length,
                  onReorderItem: reorder,
                  itemBuilder: item,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.auto_stories_outlined),
            label: Text(l.reviewRead(count)),
            onPressed: count == 0 ? null : _read,
          ),
        ),
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.items, required this.onChanged});

  final List<_Item> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (items.length < 2) return const SizedBox(height: 4);
    final selected = items.where((i) => i.selected).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.reviewSelected(selected, items.length),
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              final all = selected != items.length;
              for (final i in items) {
                i.selected = all;
              }
              onChanged();
            },
            child: Text(
              selected == items.length ? l.reviewSelectNone : l.reviewSelectAll,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    super.key,
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
    required this.onCrop,
  });

  final _Item item;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onCrop;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tt = Theme.of(context).textTheme;
    final canCrop = item.source is! PdfPageSource;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: item.selected ? 1 : 0.45,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              item.selected = !item.selected;
              onChanged();
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Checkbox(
                    value: item.selected,
                    onChanged: (v) {
                      item.selected = v ?? true;
                      onChanged();
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 74,
                      child: ColoredBox(
                        color: Colors.white,
                        child: PageThumbnail(
                          source: item.source,
                          quarterTurns: item.turns,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.pageN(index + 1), style: tt.titleSmall),
                  ),
                  IconButton(
                    tooltip: l.reviewRotate,
                    icon: const Icon(Icons.rotate_right_rounded),
                    onPressed: () {
                      item.turns = (item.turns + 1) % 4;
                      onChanged();
                    },
                  ),
                  if (canCrop)
                    IconButton(
                      tooltip: l.reviewCrop,
                      icon: const Icon(Icons.crop_rounded),
                      onPressed: onCrop,
                    ),
                  IconButton(
                    tooltip: l.reviewRemove,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onRemove,
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_indicator_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
