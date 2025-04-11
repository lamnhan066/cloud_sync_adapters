# CloudSyncHiveAdapter

A local storage implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) interface from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package, built on top of [Hive](https://pub.dev/packages/hive_ce).  
This adapter allows your app to store and sync note metadata and content locally using the Hive database.

---

## ✨ Features

- 💾 Persists metadata (`SyncMetadata`) and detailed content (`String`) locally using Hive.
- 🔄 Supports reading, writing, and syncing note data.
- 🧱 Ideal for offline-first apps or local caching alongside cloud sync (e.g., Google Drive).
- 🚀 Fast, lightweight, and key-value based local database.

---

## 📦 Installation

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  hive_ce: ^latest
  cloud_sync: ^latest
  cloud_sync_hive_adapter: ^latest
```

> ⚠️ Note: Be sure to initialize Hive before usage and register any adapters needed for your metadata class.

---

## 🚀 Usage

```dart
import 'package:hive_ce/hive.dart';
import 'package:cloud_sync_hive_adapter/cloud_sync_hive_adapter.dart';
import 'your_models/sync_metadata.dart'; // Your custom SyncMetadata

void main() async {
  await Hive.initFlutter();
  
  // Optionally register Hive adapters if needed
  // Hive.registerAdapter(MyMetadataAdapter());

  final metadataBox = await Hive.openBox<String>('metadataBox');
  final detailBox = await Hive.openLazyBox<String>('detailBox');

  final adapter = CloudSyncHiveAdapter<MyMetadata>(
    metadataBox: metadataBox,
    detailBox: detailBox,
    metadataToJson: (meta) => jsonEncode(meta.toJson()),
    metadataFromJson: (json) => MyMetadata.fromJson(jsonDecode(json)),
  );

  // Use the adapter with a CloudSync instance
}
```

---

## 📁 Class Overview

```dart
class CloudSyncHiveAdapter<M extends SyncMetadata>
  extends SerializableSyncAdapter<M, String>
```

### Parameters

- `metadataBox`: A `Box<String>` used to store serialized metadata.
- `detailBox`: A `LazyBox<String>` for storing note content.
- `metadataToJson` / `metadataFromJson`: Serialization logic for your metadata type.

---

## ✅ When to Use

- 📱 You need local storage for notes, logs, or structured data.
- 📴 Offline-first behavior is important.
- 🔄 You want to combine local persistence with cloud sync (e.g., Google Drive).

---

## 📄 License

MIT (or your project's license)

---

## 📚 Related

- [`cloud_sync`](https://pub.dev/packages/cloud_sync) – Core sync abstraction
- [`hive_ce`](https://pub.dev/packages/hive_ce) – Lightweight key-value database
