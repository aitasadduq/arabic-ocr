import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../services/model_store.dart';
import '../labels.dart';
import '../widgets/model_status_card.dart';

/// First run: what the app does, and the one-time model download.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int? _ram;

  @override
  void initState() {
    super.initState();
    context.services.platform.totalMemory().then((v) {
      if (mounted) setState(() => _ram = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListenableBuilder(
              listenable: Listenable.merge([s.models, s.settings]),
              builder: (context, _) {
                final models = s.models;
                final busy =
                    models.status == ModelStatus.downloading ||
                    models.status == ModelStatus.paused ||
                    models.status == ModelStatus.loading;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Mark(),
                      const SizedBox(height: 28),
                      Text(l.setupTitle, style: tt.displaySmall),
                      const SizedBox(height: 12),
                      Text(
                        l.setupBody,
                        style: tt.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _Point(
                        icon: Icons.wifi_off_rounded,
                        text: l.setupPointOffline,
                      ),
                      _Point(
                        icon: Icons.lock_outline_rounded,
                        text: l.setupPointPrivate,
                      ),
                      _Point(
                        icon: Icons.table_chart_outlined,
                        text: l.setupPointTables,
                      ),
                      const SizedBox(height: 24),
                      if (_ram != null && _ram! < 3.5e9)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            color: cs.tertiaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.memory_rounded,
                                    color: cs.onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l.setupLowMemory(
                                        formatBytes(context, _ram!),
                                      ),
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.onTertiaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (busy || models.status == ModelStatus.error)
                        const ModelStatusCard()
                      else ...[
                        Text(
                          l.setupDownloadSize(
                            formatBytes(context, ModelStore.totalBytes),
                          ),
                          style: tt.titleSmall,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.setupWifiOnly),
                          value: s.settings.wifiOnly,
                          onChanged: (v) => s.settings.wifiOnly = v,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.download_rounded),
                          label: Text(l.setupStart),
                          onPressed: () => startModelDownload(context),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.file_open_outlined),
                          label: Text(l.importModel),
                          onPressed: () => importModelFiles(context),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l.importModelHint,
                            textAlign: TextAlign.center,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => s.settings.setupSeen = true,
                        child: Text(l.setupLater),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The app mark: a green dot under a large Arabic letter, after the
/// "nuqta" (dot) the model is named for.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'ب',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 44,
                color: cs.onSurface,
                height: 1.2,
              ),
            ),
            Positioned(
              bottom: 14,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
