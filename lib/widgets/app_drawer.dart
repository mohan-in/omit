import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    required this.onImportFeeds,
    required this.onExportFeeds,
    super.key,
  });

  final VoidCallback onImportFeeds;
  final VoidCallback onExportFeeds;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'OMIT',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Import Feeds'),
            onTap: onImportFeeds,
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export Feeds'),
            onTap: onExportFeeds,
          ),
        ],
      ),
    );
  }
}
