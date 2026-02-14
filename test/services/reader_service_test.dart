import 'package:flutter_test/flutter_test.dart';
import 'package:omit/services/reader_service.dart';

// We need to subclass ReaderService to access the private
// cleanseArticleContent method for testing.
// Actually, let's just test the public parseArticle if we can mock
// readability, but since we just want to verify the cleansing,
// let's make a test-friendly version or use a trick.

class TestReaderService extends ReaderService {
  String? testCleanse(String? content) => cleanseArticleContent(content);
}

void main() {
  group('ReaderService Cleansing', () {
    final service = TestReaderService();

    test('should remove .caption elements', () {
      const html =
          '<div><p>Text</p><div class="caption">Image Caption</div></div>';
      final result = service.testCleanse(html);
      expect(result, isNot(contains('Image Caption')));
      expect(result, contains('<p>Text</p>'));
    });

    test('should remove .wp-caption-text elements', () {
      const html =
          '<div><p>Text</p><p class="wp-caption-text">WP Caption</p></div>';
      final result = service.testCleanse(html);
      expect(result, isNot(contains('WP Caption')));
    });

    test('should remove cite elements', () {
      const html = '<div><p>Text</p><cite>Citation</cite></div>';
      final result = service.testCleanse(html);
      expect(result, isNot(contains('Citation')));
    });

    test('should remove date elements', () {
      const html = '<div><p>Text</p><date>2023-01-01</date></div>';
      final result = service.testCleanse(html);
      expect(result, isNot(contains('2023-01-01')));
    });

    test('should remove figcaption elements', () {
      const html =
          '<div><figure><img src="foo.jpg"><figcaption>Fig Caption</figcaption></figure></div>';
      final result = service.testCleanse(html);
      expect(result, isNot(contains('Fig Caption')));
    });

    test('should remove img, video, audio, and figure elements', () {
      const html = '''
        <div>
          <figure><img src="a.jpg"></figure>
          <video src="b.mp4"></video>
          <audio src="c.mp3"></audio>
        </div>
      ''';
      final result = service.testCleanse(html);
      expect(result, isNot(contains('<img')));
      expect(result, isNot(contains('<video')));
      expect(result, isNot(contains('<audio')));
      expect(result, isNot(contains('<figure')));
    });

    test('should handle null content', () {
      expect(service.testCleanse(null), isNull);
    });
  });
}
