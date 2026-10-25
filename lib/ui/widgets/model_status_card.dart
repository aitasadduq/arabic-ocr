import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../services/model_store.dart';
import '../labels.dart';

/// The model's state on the home screen, with the action that fits it.
/// Hidden once the model is ready.
class ModelStatusCard extends StatelessWidget {
  const ModelStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final models = context.services.models;
    return ListenableBuilder(
      listenable: models,
      builder: (context, _) {
        final status = models.status;
        if (status == ModelStatus.ready || status == ModelStatus.unknown) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _Card(models: models),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.models});
  final ModelStore models;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final settings = context.services.settings;
    final percent = formatPercent(context, models.progress);
    final size = formatBytes(context, ModelStore.totalBytes);
    final (title, body, icon) = switch (models.status) {
      ModelStatus.downloading => (
        l.modelCardDownloading(percent),
        l.downloadKeepsGoing,
        Icons.downloading_rounded,
      ),
      ModelStatus.paused => (
        l.modelCardPaused(percent),
        null,
        Icons.pause_circle_outline_rounded,
      ),
      ModelStatus.loading => (
        l.modelCardLoading,
        null,
        Icons.hourglass_top_rounded,
      ),
      ModelStatus.error => (
        l.modelCardError,
        models.errorDetail,
        Icons.error_outline_rounded,
      ),
      _ => (
        l.modelCardMissingTitle,
        l.modelCardMissingBody(size),
        Icons.download_for_offline_outlined,
      ),
    };
    return Card(
      color: models.status == ModelStatus.error
          ? cs.errorContainer
          : cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(color: cs.onPrimaryContainer),
              ),
            ],
            if (models.status == ModelStatus.downloading ||
                models.status == ModelStatus.paused ||
                models.status == ModelStatus.loading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: models.status == ModelStatus.loading
                    ? null
                    : models.progress,
                minHeight: 6,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: switch (models.status) {
                ModelStatus.downloading => [
                  TextButton(
                    onPressed: models.cancelDownload,
                    child: Text(l.cancel),
                  ),
                  TextButton(onPressed: models.pause, child: Text(l.pause)),
                ],
                ModelStatus.paused => [
                  TextButton(
                    onPressed: models.cancelDownload,
                    child: Text(l.cancel),
                  ),
                  FilledButton.tonal(
                    onPressed: models.resume,
                    child: Text(l.resume),
                  ),
                ],
                ModelStatus.loading => const [],
                ModelStatus.error => [
                  TextButton(
                    onPressed: () => importModelFiles(context),
                    child: Text(l.importModel),
                  ),
                  FilledButton(
                    onPressed: () =>
                        models.download(wifiOnly: settings.wifiOnly),
                    child: Text(l.retry),
                  ),
                ],
                _ => [
                  TextButton(
                    onPressed: () => importModelFiles(context),
                    child: Text(l.importModel),
                  ),
                  FilledButton(
                    onPressed: () =>
                        models.download(wifiOnly: settings.wifiOnly),
                    child: Text(l.download),
                  ),
                ],
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the user pick the two GGUF files from Files and installs them.
Future<void> importModelFiles(BuildContext context) async {
  final models = context.services.models;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final picked = await FilePicker.pickFiles(type: FileType.any);
  final paths = [for (final f in picked) ?f.path];
  if (paths.isEmpty) return;
  final unknown = await models.importFiles(paths);
  if (unknown.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(l.importUnknown(unknown.join(', ')))),
    );
  }
}
