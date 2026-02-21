import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:omit/models/models.dart';
import 'package:xml/xml.dart';

/// Service for importing and exporting feeds in OPML format.
///
/// OPML (Outline Processor Markup Language) is the standard format
/// for exchanging feed subscriptions between RSS readers.
class ImportExportService {
  /// Export feeds as an OPML file.
  /// Returns the path where the file was saved, or null if cancelled/failed.
  Future<String?> exportFeeds(List<Feed> feeds) async {
    if (feeds.isEmpty) return null;

    try {
      final opml = _buildOpml(feeds);
      final content = opml.toXmlString(pretty: true, indent: '  ');
      final bytes = Uint8List.fromList(content.codeUnits);

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Feeds (OPML)',
        fileName: 'omit_feeds.opml',
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
        bytes: bytes,
      );

      if (path != null) {
        // On desktop platforms, FilePicker doesn't write bytes automatically
        if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
          await File(path).writeAsString(content);
        }
        return path;
      }
    } on Object catch (e) {
      developer.log('OPML export failed: $e');
      rethrow;
    }
    return null;
  }

  /// Pick and parse an OPML or plain-text feed file.
  /// Returns a list of feed URLs found in the file.
  Future<List<String>> pickAndParseFeedFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        // Try OPML first, then fall back to plain text (one URL per line)
        if (content.trimLeft().startsWith('<?xml') ||
            content.trimLeft().startsWith('<opml')) {
          return _parseOpml(content);
        }

        // Plain text fallback
        return content
            .split('\n')
            .map((e) => e.trim())
            .where(
              (e) =>
                  e.isNotEmpty &&
                  (e.startsWith('http://') || e.startsWith('https://')),
            )
            .toList();
      }
    } on Object catch (e) {
      developer.log('Feed import failed: $e');
      rethrow;
    }
    return [];
  }

  /// Builds an OPML XML document from a list of feeds.
  XmlDocument _buildOpml(List<Feed> feeds) {
    final outlines = feeds.map(
      (feed) => XmlElement(
        XmlName('outline'),
        [
          XmlAttribute(XmlName('type'), 'rss'),
          XmlAttribute(XmlName('text'), feed.title),
          XmlAttribute(XmlName('title'), feed.title),
          XmlAttribute(XmlName('xmlUrl'), feed.url),
          if (feed.description != null)
            XmlAttribute(XmlName('description'), feed.description!),
        ],
      ),
    );

    return XmlDocument([
      XmlProcessing('xml', 'version="1.0" encoding="UTF-8"'),
      XmlElement(
        XmlName('opml'),
        [XmlAttribute(XmlName('version'), '2.0')],
        [
          XmlElement(XmlName('head'), [], [
            XmlElement(XmlName('title'), [], [XmlText('Omit Feed Export')]),
            XmlElement(XmlName('dateCreated'), [], [
              XmlText(DateTime.now().toUtc().toIso8601String()),
            ]),
          ]),
          XmlElement(XmlName('body'), [], [...outlines]),
        ],
      ),
    ]);
  }

  /// Parses an OPML XML string and extracts feed URLs.
  ///
  /// Supports nested outlines (feed folders) by recursively
  /// extracting `xmlUrl` attributes from all `<outline>` elements.
  List<String> _parseOpml(String content) {
    try {
      final document = XmlDocument.parse(content);
      final urls = <String>[];

      // Recursively find all outline elements with xmlUrl
      for (final outline in document.findAllElements('outline')) {
        final xmlUrl =
            outline.getAttribute('xmlUrl') ??
            outline.getAttribute('xmlurl'); // Case-insensitive fallback
        if (xmlUrl != null && xmlUrl.isNotEmpty) {
          urls.add(xmlUrl);
        }
      }

      developer.log('Parsed ${urls.length} feeds from OPML');
      return urls;
    } on Object catch (e) {
      developer.log('OPML parsing failed: $e');
      throw FormatException('Invalid OPML file: $e');
    }
  }
}
