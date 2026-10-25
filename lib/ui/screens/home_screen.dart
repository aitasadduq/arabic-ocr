import 'package:flutter/material.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

import '../../app_scope.dart';
import '../../models/scan.dart';
import '../adaptive.dart';
import '../labels.dart';
import '../page_import.dart';
import '../widgets/model_status_card.dart';
import '../widgets/page_thumbnail.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, box) {
            // two columns once there is room (tablets, unfolded foldables)
            final wide = box.maxWidth >= 840;
            final pad = EdgeInsets.symmetric(horizontal: wide ? 32 : 20);
            if (!wide) {
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: pad,
                    sliver: const SliverToBoxAdapter(child: _Header()),
                  ),
                  SliverPadding(
                    padding: pad,
                    sliver: const SliverToBoxAdapter(child: _Start()),
                  ),
                  SliverPadding(padding: pad, sliver: const _RecentList()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              );
            }
            return AdaptiveSplit(
              resizable: false,
              initialFraction: 5 / 9,
              first: ListView(
                padding: pad,
                children: const [_Header(), _Start()],
              ),
              second: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 72)),
                  SliverPadding(padding: pad, sliver: const _RecentList()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.appTitle,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: l.settings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(l.homeHeadline, style: tt.displaySmall),
        const SizedBox(height: 8),
        Text(
          l.homeSubtitle,
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        const ModelStatusCard(),
      ],
    );
  }
}

class _Start extends StatelessWidget {
  const _Start();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.photo_camera_outlined,
                label: l.actionCamera,
                hint: l.actionCameraHint,
                primary: true,
                onTap: () => openCamera(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.photo_library_outlined,
                label: l.actionPhotos,
                hint: l.actionPhotosHint,
                onTap: () => pickFromPhotos(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.folder_open_rounded,
                label: l.actionFiles,
                hint: l.actionFilesHint,
                onTap: () => pickFromFiles(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          l.samplesTitle,
          style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: samples.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                _SampleTile(asset: samples[i].$1, mode: samples[i].$2),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = primary ? cs.onPrimary : cs.onSurface;
    return Semantics(
      button: true,
      label: '$label, $hint',
      excludeSemantics: true,
      child: Material(
        color: primary ? cs.primary : cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: primary
              ? BorderSide.none
              : BorderSide(color: cs.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 116),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: primary ? cs.onPrimary : cs.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    label,
                    style: tt.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.75),
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

class _SampleTile extends StatelessWidget {
  const _SampleTile({required this.asset, required this.mode});
  final String asset;
  final NuqtaMode mode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final label = sampleLabel(context, asset);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => readSample(context, asset, mode),
        child: SizedBox(
          width: 98,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                    color: Colors.white,
                  ),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList();

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([s.history, s.runner]),
      builder: (context, _) {
        final scans = s.history.scans;
        final header = SliverList.list(
          children: [
            Text(
              l.recentTitle,
              style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            if (scans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: cs.outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.recentEmpty,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
        Widget tile(Scan scan) => _RecentTile(
          scan: scan,
          running: identical(s.runner.scan, scan) && s.runner.isRunning,
        );
        return SliverMainAxisGroup(
          slivers: [
            header,
            SliverLayoutBuilder(
              builder: (context, c) {
                // two columns once a single column gets wide (the iPhone Duo
                // unfolded in portrait, small tablets)
                if (c.crossAxisExtent >= 560) {
                  return SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 108,
                        ),
                    itemCount: scans.length,
                    itemBuilder: (context, i) => tile(scans[i]),
                  );
                }
                return SliverList.builder(
                  itemCount: scans.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: tile(scans[i]),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.scan, required this.running});
  final Scan scan;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final first = scan.pages.firstOrNull;
    final title = scan.title.isNotEmpty ? scan.title : l.untitled;
    final subtitle = [
      formatDate(context, scan.createdAt),
      l.pagesCount(scan.pages.length),
      scan.mode.label(l),
    ].join(' · ');
    return Dismissible(
      key: ValueKey(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.onErrorContainer),
      ),
      onDismissed: (_) {
        s.history.hide(scan);
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger
            .showSnackBar(
              SnackBar(
                content: Text(l.scanDeleted),
                action: SnackBarAction(
                  label: l.undo,
                  onPressed: () => s.history.restore(scan),
                ),
              ),
            )
            .closed
            .then((reason) {
              if (reason != SnackBarClosedReason.action) s.history.delete(scan);
            });
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ResultScreen(scan: scan))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 68,
                    child: first == null
                        ? const SizedBox()
                        : PageThumbnail(
                            source: first.source,
                            imagePath: first.imagePath,
                            quarterTurns: first.quarterTurns,
                            cacheWidth: 160,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scan.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: tt.bodySmall?.copyWith(
                          fontFamily: 'NotoNaskhArabic',
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                if (running)
                  const Padding(
                    padding: EdgeInsets.all(6),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
