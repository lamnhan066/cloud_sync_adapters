# CloudSyncGoogleDriveAdapter

A Google Drive-based implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) interface from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package.  
This adapter enables two-way synchronization of metadata and string-based detail content using **Google Drive**, storing metadata in the file's description and detailed content as file content.

---

## ✨ Features

- 🔄 Syncs metadata (`SyncMetadata`) and detail (`String`) via Google Drive files.
- 🔍 Fetches all metadata entries with a matching file name.
- 💾 Reads and writes file contents using Google Drive's API.
- 📤 Automatically creates or updates files based on metadata ID.
- 🔐 Uses `appDataFolder` by default for secure, app-specific storage.
- ✅ Supports both `DriveApi` injection and creation via an HTTP client.

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  cloud_sync: ^latest
  cloud_sync_google_drive_adapter: ^latest
  googleapis: ^latest
  google_sign_in: ^latest
  http: ^latest
```

---

## 🚀 Usage

### With Authenticated HTTP Client

```dart
import 'package:cloud_sync_google_drive_adapter/cloud_sync_google_drive_adapter.dart';
import 'package:http/http.dart' as http;
import 'your_models/sync_metadata.dart'; // Your custom metadata model

final adapter = CloudSyncGoogleDriveAdapter<MyMetadata>.fromClient(
  client: authClient,
  metadataToJson: (meta) => jsonEncode(meta.toJson()),
  metadataFromJson: (json) => MyMetadata.fromJson(jsonDecode(json)),
  getMetadataId: (meta) => meta.id,
  isCurrentMetadataBeforeOther: (a, b) => a.updatedAt.isBefore(b.updatedAt),
);
```

### With an Existing Drive API Instance

```dart
final adapter = CloudSyncGoogleDriveAdapter<MyMetadata>(
  driveApi: driveApiInstance,
  metadataToJson: ...,
  metadataFromJson: ...,
  getMetadataId: ...,
  isCurrentMetadataBeforeOther: ...,
);
```

---

## 📁 Class Overview

```dart
class CloudSyncGoogleDriveAdapter<M extends SyncMetadata>
  extends SerializableSyncAdapter<M, String>
```

### Constructors

- `CloudSyncGoogleDriveAdapter` – for using an existing `DriveApi` instance.
- `CloudSyncGoogleDriveAdapter.fromClient` – for creating `DriveApi` from an authenticated `http.Client`.

### Key Parameters

| Parameter                      | Description                                 | Default                          |
| ------------------------------ | ------------------------------------------- | -------------------------------- |
| `driveApi` / `client`          | Authenticated API or client                 | *(required)*                     |
| `metadataToJson` / `FromJson`  | Serialization logic for metadata            | *(required)*                     |
| `getMetadataId`                | Extracts unique ID from metadata            | *(required)*                     |
| `isCurrentMetadataBeforeOther` | Comparison function for metadata versioning | *(required)*                     |
| `spaces`                       | Google Drive space (`appDataFolder`, etc.)  | `'appDataFolder'`                |
| `fileName`                     | Name of file used for storing data          | `'$CloudSyncGoogleDriveAdapter'` |

---

## ✅ When to Use

- ☁️ You want **cloud-based synchronization** for structured content.
- 📱 Ideal for syncing **notes, tasks, logs, or encrypted app data**.
- 🔁 Supports **multi-device sync**, **offline cache + recovery**, etc.

---

## 🛠 Methods

| Method                | Description                                     |
| --------------------- | ----------------------------------------------- |
| `fetchMetadataList()` | Lists all files matching the given file name.   |
| `fetchDetail()`       | Downloads and decodes file content from Drive.  |
| `save()`              | Creates or updates a file based on metadata ID. |

If you want to remove a file by only modifying the `metadata`, you can use `save(metadata, null)`.

---

## 🧠 Notes

- Metadata is stored in the file's `description` field.
- File content (detail) is stored as binary `application/octet-stream`.
- Only files matching the `fileName` are read or written.

---

## 📄 License

MIT (or your project’s license)

---

## 📚 Related

- [`cloud_sync`](https://pub.dev/packages/cloud_sync) – Core sync abstraction
- [`googleapis`](https://pub.dev/packages/googleapis) – Google Drive API wrapper
- [`google_sign_in`](https://pub.dev/packages/google_sign_in) – For authentication
