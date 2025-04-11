# CloudSyncSharedPreferencesAdapter

A local implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) interface from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package, using [`SharedPreferences`](https://pub.dev/packages/shared_preferences) for simple key-value storage.

This adapter allows apps to persist note metadata and content directly on the device — perfect for quick sync flows, offline caching, or prototyping.

---

## ✨ Features

- 📝 Stores note metadata (`SyncMetadata`) and content (`String`) in `SharedPreferences`.
- ⚡ Quick and lightweight — no setup or database needed.
- 🧪 Great for prototyping, fallback storage, or minimal local sync solutions.

---

## 📦 Installation

Add the required dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  shared_preferences: ^latest
  cloud_sync: ^latest
  cloud_sync_shared_preferences_adapter: ^latest
```

---

## 🚀 Usage

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_sync_shared_preferences_adapter/cloud_sync_shared_preferences_adapter.dart';
import 'your_models/sync_metadata.dart'; // Your custom SyncMetadata

void main() async {
  final prefs = await SharedPreferences.getInstance();

  final adapter = CloudSyncSharedPreferencesAdapter<MyMetadata>(
    preferences: prefs,
    metadataToJson: (meta) => jsonEncode(meta.toJson()),
    metadataFromJson: (json) => MyMetadata.fromJson(jsonDecode(json)),
  );

  // Use the adapter with your CloudSync logic
}
```

---

## 📁 Class Overview

```dart
class CloudSyncSharedPreferencesAdapter<M extends SyncMetadata>
  extends SerializableSyncAdapter<M, String>
```

### Constructor parameters

- `preferences`: An instance of `SharedPreferences`.
- `metadataToJson`: Function to serialize metadata to `String`.
- `metadataFromJson`: Function to deserialize metadata from `String`.
- `prefix`: Optional key prefix for namespacing (default: `"$CloudSyncSharedPreferencesAdapter"`).

---

## ✅ When to Use

- 🧪 Prototype sync flows or quick demos.
- 🗂 Store small amounts of structured content locally.
- 📴 Enable basic offline persistence.
- 🔙 Fallback adapter alongside a cloud-based adapter (e.g., Google Drive).

---

## ⚠️ Limitations

- **Not suitable for large or binary data** – use `Hive` or `File`-based adapters instead.
- SharedPreferences may have storage limits depending on platform.

---

## 📄 License

MIT (or your project’s license).

---

## 📚 Related

- [`cloud_sync`](https://pub.dev/packages/cloud_sync) – The base sync framework.
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) – Simple local key-value storage.
