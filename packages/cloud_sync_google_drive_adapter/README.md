# CloudSyncGoogleDriveAdapter

A Google Drive-based implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) interface from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package.  
This adapter enables two-way synchronization of metadata and string-based detail content with the user's **Google Drive**, using file descriptions and binary content for storage.

---

## ✨ Features

- 🔄 Syncs metadata (`SyncMetadata`) and string detail content (`String`) via Google Drive files.
- 📥 Fetches a list of metadata from Drive.
- 📤 Uploads new files or updates existing ones using metadata ID.
- 💾 Stores detail as file content and metadata as file description.
- 📦 Operates in `appDataFolder` by default to isolate app-specific files.

---

## 📦 Installation

Add dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  cloud_sync: ^latest
  cloud_sync_google_drive_adapter: ^latest
  google_sign_in: ^latest
```

---

## 🚀 Usage

```dart
import 'package:cloud_sync_google_drive_adapter/cloud_sync_google_drive_adapter.dart';
import 'package:http/http.dart' as http;
import 'your_models/sync_metadata.dart'; // Your custom metadata model

final adapter = CloudSyncGoogleDriveAdapter<MyMetadata>.fromClient(
  client: authClient, // Use authenticated client
  metadataToJson: (meta) => jsonEncode(meta.toJson()),
  metadataFromJson: (json) => MyMetadata.fromJson(jsonDecode(json)),
);
```

To create with a client only:

```dart
final adapter = CloudSyncGoogleDriveAdapter<MyMetadata>.fromClient(
  client: authClient,
  metadataToJson: ...,
  metadataFromJson: ...,
);
```

---

## 📁 Class Overview

```dart
class CloudSyncGoogleDriveAdapter<M extends SyncMetadata>
  extends SerializableSyncAdapter<M, String>
```

- `spaces`: Google Drive spaces to use (default: `'appDataFolder'`)
- `fileName`: Drive file name used to identify synced data
- Implements:
  - `fetchMetadataList()` → List of files with metadata in descriptions
  - `fetchDetail()` → Decoded file content
  - `save()` → Create or update file in Drive

---

## ✅ When to Use

- ☁️ You want **cloud backup** or **multi-device sync**.
- 🔒 You’re storing **encrypted data** or **structured content**.
- 📱 Perfect for apps syncing notes, tasks, logs, or media references.

---

## 📄 License

MIT (or your project’s license)

---

## 📚 Related

- [`cloud_sync`](https://pub.dev/packages/cloud_sync) – Core sync abstraction
- [`googleapis`](https://pub.dev/packages/googleapis) – Google Drive API
