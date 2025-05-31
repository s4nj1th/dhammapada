import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme_notifier.dart';
import '../providers/verse_tracker_provider.dart';
import '../providers/translations_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const appVersion = '1.1.0';

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final verseTracker = Provider.of<VerseTrackerProvider>(
      context,
      listen: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: themeNotifier.toggleTheme,
          ),
          SwitchListTile(
            title: const Text('AMOLED Mode'),
            value: themeNotifier.isAmoled,
            onChanged: isDark ? themeNotifier.toggleAmoled : null,
          ),

          const Divider(height: 32),

          const Text('Accessibility', style: TextStyle(fontSize: 18)),
          SwitchListTile(
            title: const Text('System Fonts'),
            value: themeNotifier.useSystemFont,
            onChanged: (val) => themeNotifier.toggleFont(val),
          ),

          // SwitchListTile(
          //   title: const Text('Sepia Mode'),
          //   value: themeNotifier.sepiaMode,
          //   onChanged: (val) => themeNotifier.toggleSepia(val),
          // ),
          const Divider(height: 32),

          const Text('Translations', style: TextStyle(fontSize: 18)),
          Consumer<TranslationsProvider>(
            builder: (context, provider, _) {
              final all = provider.allTranslations;
              final order = provider.translationOrder;
              final selected = provider.selectedTranslations;

              return ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: provider.reorderTranslations,
                children: order.map((code) {
                  final isSelected = selected.contains(code);
                  return CheckboxListTile(
                    key: ValueKey(code),
                    value: isSelected,
                    title: Text(all[code]!),
                    onChanged: (val) => provider.toggleTranslation(code, val!),
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: const Icon(Icons.drag_handle),
                  );
                }).toList(),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'PocketDhamma',
                applicationVersion: appVersion,
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Contribute'),
            onTap: () {
              launchUrl(
                Uri.parse('https://github.com/s4nj1th/pocket-dhamma'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),

          // ListTile(
          //   leading: const Icon(Icons.favorite),
          //   title: const Text('Donate'),
          //   onTap: () {
          //     launchUrl(Uri.parse(''), mode: LaunchMode.externalApplication);
          //   },
          // ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text(
              'Clear History',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Clear History'),
                  content: const Text(
                    'Are you sure you want to clear your viewing history? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );

              if (context.mounted && confirm == true) {
                verseTracker.resetSessionHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
