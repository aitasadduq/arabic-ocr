import 'package:flutter/material.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

import '../../models/scan.dart';
import '../labels.dart';

/// Choice of what to read: three cards with a one-line explanation each.
class ModePicker extends StatelessWidget {
  const ModePicker({super.key, required this.value, required this.onChanged});

  final NuqtaMode value;
  final ValueChanged<NuqtaMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.modeLabel,
          style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        for (final m in NuqtaMode.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: m == value
                  ? cs.primaryContainer
                  : cs.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: m == value ? cs.primary : cs.outlineVariant,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onChanged(m),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        m.icon,
                        color: m == value
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.label(l), style: tt.titleMedium),
                            Text(
                              m.hint(l),
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (m == value)
                        Icon(Icons.check_circle_rounded, color: cs.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The same choice as three tiles in a row, for narrow screens.
class CompactModePicker extends StatelessWidget {
  const CompactModePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final NuqtaMode value;
  final ValueChanged<NuqtaMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.modeLabel,
          style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final m in NuqtaMode.values) ...[
              if (m != NuqtaMode.values.first) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  selected: m == value,
                  button: true,
                  child: Material(
                    color: m == value
                        ? cs.primaryContainer
                        : cs.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: m == value ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onChanged(m),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              m.icon,
                              color: m == value
                                  ? cs.onPrimaryContainer
                                  : cs.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.label(l),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: tt.labelLarge?.copyWith(
                                color: m == value
                                    ? cs.onPrimaryContainer
                                    : cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value.hint(l),
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class QualityPicker extends StatelessWidget {
  const QualityPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ReadQuality value;
  final ValueChanged<ReadQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.qualityLabel,
          style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ReadQuality>(
          segments: [
            for (final q in ReadQuality.values)
              ButtonSegment(
                value: q,
                label: Text(q.label(l)),
                icon: Icon(
                  q == ReadQuality.accurate
                      ? Icons.center_focus_strong_outlined
                      : Icons.bolt_rounded,
                ),
              ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
        ),
        const SizedBox(height: 6),
        Text(
          value.hint(l),
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
