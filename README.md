# Omit RSS Reader

Omit is a minimal RSS reader app built with Flutter following Clean Architecture principles. It is designed for Android with offline-first capabilities.

## Features

- **Feed Subscription**: Easily add and manage RSS/Atom feeds
- **Offline Reading**: Articles are saved locally for offline access using Hive
- **Bookmarks**: Save articles to read later
- **Clean Architecture**: Separation of concerns with Repositories and Notifiers
- **Material Design**: Clean, light-themed interface

## Technology Stack

- **Framework**: Flutter
- **State Management**: Provider + ChangeNotifier
- **Local Storage**: Hive
- **Networking**: http client & dart_rss parser
- **WebView**: webview_flutter

## Getting Started

1.  **Get dependencies**
    ```bash
    flutter pub get
    ```

2.  **Generate adapters (if needed)**
    ```bash
    dart run build_runner build
    ```

3.  **Run the app**
    ```bash
    flutter run
    ```

## Documentation

For detailed architecture and project structure, see [ARCHITECTURE.md](ARCHITECTURE.md).