import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/document/ocr_document.dart';
import '../core/export/export_format.dart';
import 'labels.dart';

/// Lists the formats that suit the document, best first, each with "save to
/// Files" and "share".
Future<void> showExportSheet(
  BuildContext context, {
  required OcrDocument document,
  required String title,
  List<ExportFormat>? formats,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ExportSheet(
      document: document,
      title: title,
      formats: formats ?? ExportFormat.suggestionsFor(document),
      parent: context,
    ),
  );
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({
    required this.document,
    required this.title,
    required this.formats,
    required this.parent,
  });

  final OcrDocument document;
  final String title;
  final List<ExportFormat> formats;
  final BuildContext parent;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final exporter = context.services.exporter;
    final messenger = ScaffoldMessenger.of(parent);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(l.export, style: tt.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_rounded),
              title: Text(l.copyAll),
              onTap: () async {
                await exporter.copyDocument(document);
                if (context.mounted) Navigator.pop(context);
                messenger.showSnackBar(SnackBar(content: Text(l.copied)));
              },
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < formats.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  color: i == 0 ? cs.primaryContainer : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              formats[i].icon,
                              color: i == 0
                                  ? cs.onPrimaryContainer
                                  : cs.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          formats[i].label(l),
                                          style: tt.titleMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '.${formats[i].extension}',
                                        style: tt.labelMedium?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      if (i == 0) ...[
                                        const SizedBox(width: 8),
                                        _Badge(l.exportRecommended),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    formats[i].hint(l),
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Builder(
                              builder: (b) => TextButton.icon(
                                icon: const Icon(
                                  Icons.ios_share_rounded,
                                  size: 18,
                                ),
                                label: Text(l.share),
                                onPressed: () async {
                                  final box =
                                      b.findRenderObject() as RenderBox?;
                                  final origin = box == null
                                      ? null
                                      : box.localToGlobal(Offset.zero) &
                                            box.size;
                                  await exporter.share(
                                    document,
                                    formats[i],
                                    title: title,
                                    origin: origin,
                                  );
                                },
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(
                                Icons.save_alt_rounded,
                                size: 18,
                              ),
                              label: Text(l.exportSaveTo),
                              onPressed: () async {
                                final ok = await exporter.saveAs(
                                  document,
                                  formats[i],
                                  title: title,
                                );
                                if (!ok) return;
                                if (context.mounted) Navigator.pop(context);
                                messenger.showSnackBar(
                                  SnackBar(content: Text(l.saved)),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: cs.onPrimary),
      ),
    );
  }
}
