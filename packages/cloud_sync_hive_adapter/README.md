# CloudSyncHiveAdapter

A Hive-powered implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package.

This adapter enables fast, offline-first local persistence of metadata and content using [Hive](https://pub.dev/packages/hive_ce). Great for syncing notes, logs, or custom data structures locally with cloud fallback support.

---

## ✨ Features

- 💾 Stores metadata (`SyncMetadata`) and detailed content (`String`) using Hive.
- ⚡ Fast and efficient with Hive's key-value storage.
- 🔄 Compatible with `cloud_sync` for hybrid local/cloud sync.
- 📴 Fully offline-capable — ideal for mobile, embedded, or disconnected use cases.

---

## 📦 Installation

Add dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  hive_ce: ^latest
  cloud_sync: ^latest
  cloud_sync_hive_adapter: ^latest
```

> ✅ Make sure you initialize Hive and register any needed adapters before use.

---

## 🚀 Usage Example

```dart
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:cloud_sync_hive_adapter/cloud_sync_hive_adapter.dart';
import 'your_models/my_metadata.dart'; // Define your SyncMetadata model

void main() async {
  await Hive.initFlutter(); // or Hive.init('path')

  // Optionally register your custom metadata adapter, if needed
  // Hive.registerAdapter(MyMetadataAdapter());

  final metadataBox = await Hive.openBox<String>('metadataBox');
  final detailBox = await Hive.openLazyBox<String>('detailBox');

  final adapter = CloudSyncHiveAdapter<MyMetadata>(
    metadataBox: metadataBox,
    detailBox: detailBox,
    metadataToJson: (meta) => jsonEncode(meta.toJson()),
    metadataFromJson: (json) => MyMetadata.fromJson(jsonDecode(json)),
    getMetadataId: (meta) => meta.id,
    isCurrentMetadataBeforeOther: (a, b) => a.updatedAt.isBefore(b.updatedAt),
  );

  // Use with CloudSync:
  // final cloudSync = CloudSync(adapter: adapter);
}
```

---

## 🧱 Class Overview

```dart
class CloudSyncHiveAdapter<M extends SyncMetadata>
  extends SerializableSyncAdapter<M, String>
```

### 🔧 Constructor Parameters

| Parameter                      | Description                                                            |
| ------------------------------ | ---------------------------------------------------------------------- |
| `metadataBox`                  | `Box<String>` for serialized metadata (`JSON`).                        |
| `detailBox`                    | `LazyBox<String>` for detailed string content.                         |
| `metadataToJson`               | Converts metadata to JSON `String`.                                    |
| `metadataFromJson`             | Parses JSON `String` into metadata.                                    |
| `getMetadataId`                | Returns the unique ID for a metadata object.                           |
| `isCurrentMetadataBeforeOther` | Compares metadata objects for version ordering (e.g., by `updatedAt`). |

---

## ✅ When to Use

- 📲 Need fast, reliable local sync for mobile or desktop.
- 📴 Want offline-first functionality for notes, logs, tasks, etc.
- 🌩️ Plan to combine Hive storage with cloud sync (e.g., Google Drive or Firebase).
- 🧪 Prototyping or testing sync logic locally.

---

## 🛠 Methods

| Method                | Description                                     |
| --------------------- | ----------------------------------------------- |
| `fetchMetadataList()` | Lists all files matching the given file name.   |
| `fetchDetail()`       | Downloads and decodes file content from Drive.  |
| `save()`              | Creates or updates a file based on metadata ID. |

If you want to remove a file by only modifying the `metadata`, you can use `save(metadata, null)`.

---

## ⚠️ Notes

- Store only `String` data in Hive boxes with this adapter.
- For complex object storage, use Hive’s custom type adapters directly or extend the adapter.
- Avoid storing large binary data — Hive is optimized for structured key-value data.

---

## 📚 Related Packages

- [`cloud_sync`](https://pub.dev/packages/cloud_sync) – Sync core and abstraction layer.
- [`hive_ce`](https://pub.dev/packages/hive_ce) – Lightweight, blazing-fast NoSQL database for Flutter/Dart.

---

## 📄 License

MIT (or your project’s license).
