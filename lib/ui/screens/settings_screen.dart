import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_scope.dart';
import '../../services/model_store.dart';
import '../labels.dart';
import '../theme.dart';
import '../widgets/mode_picker.dart';
import '../widgets/model_status_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListenableBuilder(
        listenable: Listenable.merge([s.settings, s.models]),
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: const [
                _Appearance(),
                _Defaults(),
                _Model(),
                _Storage(),
                _About(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: cs.primary),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Appearance extends StatelessWidget {
  const _Appearance();

  @override
  Widget build(BuildContext context) {
    final s = context.services.settings;
    final l = context.l10n;
    final tt = Theme.of(context).textTheme;
    return _Section(
      title: l.settingsAppearance,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.settingsTheme, style: tt.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l.themeSystem),
                    icon: const Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l.themeLight),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l.themeDark),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {s.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (v) => s.themeMode = v.first,
              ),
              const SizedBox(height: 16),
              Text(l.settingsLanguage, style: tt.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: '', label: Text(l.languageSystem)),
                  const ButtonSegment(value: 'en', label: Text('English')),
                  const ButtonSegment(value: 'ar', label: Text('العربية')),
                ],
                selected: {s.locale?.languageCode ?? ''},
                showSelectedIcon: false,
                onSelectionChanged: (v) =>
                    s.locale = v.first.isEmpty ? null : Locale(v.first),
              ),
              const SizedBox(height: 16),
              Text(l.settingsTextSize, style: tt.titleSmall),
              Slider(
                value: s.textScale,
                min: 0.8,
                max: 1.6,
                divisions: 8,
                label: '${(s.textScale * 100).round()}%',
                onChanged: (v) => s.textScale = v,
              ),
              Text(
                l.settingsTextSample,
                textDirection: TextDirection.rtl,
                style: AppTheme.reading(context, s.textScale),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Defaults extends StatelessWidget {
  const _Defaults();

  @override
  Widget build(BuildContext context) {
    final s = context.services.settings;
    final l = context.l10n;
    return _Section(
      title: l.settingsDefaults,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModePicker(value: s.mode, onChanged: (m) => s.mode = m),
              const SizedBox(height: 8),
              QualityPicker(value: s.quality, onChanged: (q) => s.quality = q),
            ],
          ),
        ),
      ],
    );
  }
}

class _Model extends StatefulWidget {
  const _Model();

  @override
  State<_Model> createState() => _ModelState();
}

class _ModelState extends State<_Model> {
  int? _bytes;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final b = await context.services.models.bytesOnDisk();
    if (mounted) setState(() => _bytes = b);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final models = s.models;
    final ready = models.status == ModelStatus.ready;
    return _Section(
      title: l.settingsModel,
      children: [
        ListTile(
          leading: Icon(
            ready ? Icons.check_circle_rounded : Icons.cloud_download_outlined,
            color: ready ? cs.primary : cs.outline,
          ),
          title: Text(
            ready
                ? l.settingsModelReady(
                    formatBytes(context, _bytes ?? ModelStore.totalBytes),
                  )
                : l.settingsModelMissing,
          ),
        ),
        if (!ready)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: ModelStatusCard(),
          ),
        SwitchListTile(
          title: Text(l.setupWifiOnly),
          value: s.settings.wifiOnly,
          onChanged: (v) => s.settings.wifiOnly = v,
        ),
        ListTile(
          leading: const Icon(Icons.file_open_outlined),
          title: Text(l.importModel),
          subtitle: Text(l.importModelHint),
          onTap: () async {
            await importModelFiles(context);
            await _refresh();
          },
        ),
        if (ready)
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: cs.error),
            title: Text(
              l.settingsDeleteModel,
              style: TextStyle(color: cs.error),
            ),
            onTap: () async {
              final ok = await _confirm(
                context,
                l.settingsDeleteModelConfirm(
                  formatBytes(context, ModelStore.totalBytes),
                ),
                l.delete,
              );
              if (!ok) return;
              await models.delete();
              await _refresh();
            },
          ),
      ],
    );
  }
}

class _Storage extends StatelessWidget {
  const _Storage();

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return _Section(
      title: l.settingsStorage,
      children: [
        SwitchListTile(
          title: Text(l.settingsKeepHistory),
          subtitle: Text(l.settingsKeepHistoryHint),
          value: s.settings.keepHistory,
          onChanged: (v) => s.settings.keepHistory = v,
        ),
        ListTile(
          leading: Icon(Icons.delete_sweep_outlined, color: cs.error),
          title: Text(
            l.settingsClearHistory,
            style: TextStyle(color: cs.error),
          ),
          onTap: () async {
            if (await _confirm(
              context,
              l.settingsClearHistoryConfirm,
              l.delete,
            )) {
              await s.history.clear();
            }
          },
        ),
      ],
    );
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return _Section(
      title: l.settingsAbout,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l.settingsAboutBody,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.code_rounded),
          title: Text(l.settingsSourceCode),
          trailing: const Icon(Icons.open_in_new_rounded, size: 18),
          onTap: () => launchUrl(
            Uri.parse('https://github.com/SalahAlHaismawi/nuqta-ocr'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_rounded),
          title: Text(l.settingsLicenses),
          onTap: () =>
              showLicensePage(context: context, applicationName: l.appTitle),
        ),
      ],
    );
  }
}

Future<bool> _confirm(
  BuildContext context,
  String message,
  String action,
) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
