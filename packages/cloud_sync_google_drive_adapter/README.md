# CloudSyncGoogleDriveAdapter

A cloud-based implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) interface from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package, using the [Google Drive API](https://pub.dev/packages/googleapis) for file synchronization. This adapter enables syncing metadata and binary content with the user's Google Drive storage.

## ✨ Features

- Syncs note metadata (`SyncMetadata`) and binary detail content (`List<int>`) to and from Google Drive.
- Supports reading metadata lists, downloading file content, and uploading or updating files.
- Ideal for use in apps that need cloud synchronization, backup, or multi-device data sharing.

## 📦 Installation

Add dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  cloud_sync:
  cloud_sync_google_drive_adapter:
```

## 🚀 Usage

```dart
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:cloud_sync/cloud_sync.dart';

void main() async {
  // Use `google_sign_in` to retrieve the `authClient`

  final adapter = CloudSyncGoogleDriveAdapter(client: authClient);
}
```

## 📁 Class Overview

```dart
class CloudSyncGoogleDriveAdapter implements SyncAdapter<SyncMetadata, List<int>>
```

- `spaces`: Specify which Drive space to use (default: `'appDataFolder'`).
- Designed to work with binary content, suitable for encrypted notes, media, or complex objects.

## 📄 License

MIT (or your project’s license).
