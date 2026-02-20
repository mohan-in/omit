/// Utility class containing JavaScript snippets for Reader Mode.
class ReaderJsScripts {
  /// Generates the JS to dynamically update the active
  /// stylesheet in the WebView.
  static String updateStyles({
    required String bgColor,
    required String textColor,
    required String fontSize,
    required String fontFamily,
  }) {
    return '''
      (function() {
        try {
          document.body.style.backgroundColor = '$bgColor';
          document.body.style.color = '$textColor';
          document.body.style.fontSize = '$fontSize';
          document.body.style.fontFamily = '"$fontFamily", system-ui, -apple-system, sans-serif';
          document.documentElement.style.backgroundColor = '$bgColor';
        } catch(e) {
          console.error('Style update error: ' + e);
        }
      })();
    ''';
  }

  /// Generates the JS to parse the page with Readability and
  /// inject a stylized HTML framework.
  static String injectReadability({
    required String fontFamily,
    required String fontSize,
    required String textColor,
    required String bgColor,
    required String primaryColorHtml,
    required String authorLine,
  }) {
    return '''
      (function() {
        try {
          if (typeof Readability === 'undefined') {
            return "ERROR: Readability is undefined after injection";
          }
          var documentClone = document.cloneNode(true);
          var reader = new Readability(documentClone);
          var article = reader.parse();
          
          if (article != null) {
            var newDoc = `
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <title>\${article.title}</title>
                <style>
                  body {
                    font-family: "$fontFamily", system-ui, -apple-system, sans-serif;
                    font-size: $fontSize;
                    line-height: 1.6;
                    color: $textColor;
                    background-color: $bgColor;
                    padding: 20px;
                    max-width: 800px;
                    margin: 0 auto;
                    overflow-x: hidden;
                  }
                  img { max-width: 100%; height: auto; border-radius: 8px; margin: 16px 0; }
                  figure { margin: 16px 0; }
                  figcaption { font-size: 0.85em; opacity: 0.8; margin-top: 8px; text-align: center; }
                  pre, code { background: rgba(128, 128, 128, 0.1); padding: 2px 4px; border-radius: 4px; overflow-x: auto; }
                  a { color: $primaryColorHtml; text-decoration: none; }
                  blockquote { border-left: 4px solid $primaryColorHtml; margin: 16px 0; padding-left: 16px; font-style: italic; opacity: 0.8; }
                  h1 { font-size: 1.6em; margin-bottom: 0.5em; line-height: 1.3; }
                  h2 { font-size: 1.4em; margin-top: 1.5em; margin-bottom: 0.5em; }
                  h3 { font-size: 1.2em; margin-top: 1.2em; margin-bottom: 0.5em; }
                  p { margin-bottom: 1.2em; }
                </style>
              </head>
              <body>
                <h1>\${article.title}</h1>
                $authorLine
                \${article.content}
              </body>
              </html>
            `;
            
            try {
              document.open();
              document.write(newDoc);
              document.close();
            } catch (e) {
              return "ERROR: document.write failed: " + e.toString();
            }
            
            return "SUCCESS";
          } else {
            return "NULL_ARTICLE";
          }
        } catch (e) {
          return "ERROR: " + e.toString();
        }
      })();
    ''';
  }
}
