import 'package:flutter/material.dart';
import 'package:omit/models/reader_settings.dart';
import 'package:omit/notifiers/reader_settings_notifier.dart';
import 'package:provider/provider.dart';

class ReaderThemeSheet extends StatelessWidget {
  const ReaderThemeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReaderSettingsNotifier>();
    final settings = notifier.settings;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Appearance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Font Selection
          SegmentedButton<ReaderFont>(
            segments: const [
              ButtonSegment(
                value: ReaderFont.sansSerif,
                label: Text(
                  'Sans',
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
              ),
              ButtonSegment(
                value: ReaderFont.serif,
                label: Text(
                  'Serif',
                  style: TextStyle(fontFamily: 'Serif'),
                ),
              ),
            ],
            selected: {settings.font},
            onSelectionChanged: (newSelection) {
              notifier.updateSettings(font: newSelection.first);
            },
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 24),
          // Font Size Control
          Row(
            children: [
              const Icon(Icons.text_decrease),
              Expanded(
                child: Slider(
                  value: settings.fontSizeScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 4,
                  label: '${(settings.fontSizeScale * 100).round()}%',
                  onChanged: (value) {
                    notifier.updateSettings(fontSizeScale: value);
                  },
                ),
              ),
              const Icon(Icons.text_increase),
            ],
          ),
          const SizedBox(height: 24),
          // Theme Selection — colors sourced from ReaderSettings constants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ThemeOption(
                label: 'Light',
                color: ReaderSettings.lightBg,
                textColor: ReaderSettings.lightText,
                isSelected: settings.theme == ReaderTheme.light,
                onTap: () => notifier.updateSettings(
                  theme: ReaderTheme.light,
                ),
              ),
              _ThemeOption(
                label: 'Sepia',
                color: ReaderSettings.sepiaBg,
                textColor: ReaderSettings.sepiaText,
                isSelected: settings.theme == ReaderTheme.sepia,
                onTap: () => notifier.updateSettings(
                  theme: ReaderTheme.sepia,
                ),
              ),
              _ThemeOption(
                label: 'Dark',
                color: ReaderSettings.darkBg,
                textColor: ReaderSettings.darkText,
                isSelected: settings.theme == ReaderTheme.dark,
                onTap: () => notifier.updateSettings(
                  theme: ReaderTheme.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.color,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                'Aa',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Serif',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
