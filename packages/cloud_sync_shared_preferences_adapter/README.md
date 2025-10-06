# CloudSyncSharedPreferencesAdapter

A lightweight local implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package, powered by [`SharedPreferences`](https://pub.dev/packages/shared_preferences).

Perfect for simple sync needs, offline caching, prototypes, or fallback storage — no database required.

---

## ✨ Features

- 📝 Persists metadata (`SyncMetadata`) and detail content (`String`) in `SharedPreferences`.
- ⚡ Lightweight and fast — ideal for prototyping or minimal sync flows.
- 📴 Supports offline storage with zero setup.
- 🔄 Fully compatible with the `cloud_sync` framework.

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cloud_sync: ^latest
  shared_preferences: ^latest
  cloud_sync_shared_preferences_adapter: ^latest
```

---

## 🚀 Usage

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_sync_shared_preferences_adapter/cloud_sync_shared_preferences_adapter.dart';
import 'your_models/my_metadata.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();

  final adapter = CloudSyncSharedPreferencesAdapter<MyMetadata>(
    preferences: prefs,
    metadataToJson: (meta) => jsonEncode(meta.toJson()),
    metadataFromJson: (json) => MyMetadata.fromJson(jsonDecode(json)),
    getMetadataId: (meta) => meta.id,
    isCurrentMetadataBeforeOther: (a, b) => a.updatedAt.isBefore(b.updatedAt),
  );

  // Use this adapter with CloudSync to persist your data locally.
}
```

---

## 🧠 Class Overview

```dart
class CloudSyncSharedPreferencesAdapter<M extends SyncMetadata>
  extends SerializableSyncAdapter<M, String>
```

---

## 🛠️ Constructor Parameters

| Parameter                      | Description                                         | Required | Default                                |
| ------------------------------ | --------------------------------------------------- | -------- | -------------------------------------- |
| `preferences`                  | Instance of `SharedPreferences`.                    | ✅        | –                                      |
| `metadataToJson`               | Serializes metadata to a `String`.                  | ✅        | –                                      |
| `metadataFromJson`             | Deserializes a `String` into metadata.              | ✅        | –                                      |
| `getMetadataId`                | Extracts the unique ID from a metadata object.      | ✅        | –                                      |
| `isCurrentMetadataBeforeOther` | Compares two metadata objects for version ordering. | ✅        | –                                      |
| `prefix`                       | Optional prefix for namespacing stored keys.        | ❌        | `"$CloudSyncSharedPreferencesAdapter"` |

---

## ✅ When to Use

- ⚡ Quick local sync for small apps or offline features.
- 🧪 Ideal for demos, prototypes, or testing sync logic.
- 🔙 Acts as a fallback when a cloud adapter is unavailable.

---

## 🛠 Methods

| Method                | Description                                     |
| --------------------- | ----------------------------------------------- |
| `fetchMetadataList()` | Lists all files matching the given file name.   |
| `fetchDetail()`       | Downloads and decodes file content from Drive.  |
| `save()`              | Creates or updates a file based on metadata ID. |

If you want to remove a file by only modifying the `metadata`, you can use `save(metadata, null)`.

---

## ⚠️ Limitations

- **Not suitable for large or binary data** — use file or database-based adapters instead.
- SharedPreferences has platform-specific size limits (~1–2MB).

---

## 📚 Related Packages

- [`cloud_sync`](https://pub.dev/packages/cloud_sync) – Core sync logic.
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) – Simple local key-value store.

---

## 📄 License

MIT (or match your project’s license).
