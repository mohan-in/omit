import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:omit/models/models.dart';

/// Service for importing and exporting feeds.
class ImportExportService {
  /// Export feeds to a file.
  /// Returns the path where the file was saved, or null if cancelled/failed.
  Future<String?> exportFeeds(List<Feed> feeds) async {
    if (feeds.isEmpty) return null;

    try {
      final content = feeds.map((e) => e.url).join('\n');
      final bytes = utf8.encode(content);

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Feeds',
        fileName: 'feeds_export.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: Uint8List.fromList(bytes),
      );

      if (path != null) {
        if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
          await File(path).writeAsString(content);
        }
        return path;
      }
    } catch (e) {
      developer.log('Export failed: $e');
      rethrow;
    }
    return null;
  }

  /// Pick and parse a feed file.
  /// Returns a list of URLs found in the file.
  Future<List<String>> pickAndParseFeedFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'opml', 'xml'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        return content
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (e) {
      developer.log('Import failed: $e');
      rethrow;
    }
    return [];
  }
}
