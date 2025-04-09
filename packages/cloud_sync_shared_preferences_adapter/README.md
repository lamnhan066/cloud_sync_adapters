# CloudSyncSharedPreferencesAdapter

A local implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) interface from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package, using [`SharedPreferences`](https://pub.dev/packages/shared_preferences) for lightweight key-value storage. This adapter enables basic note syncing and metadata storage directly on the device.

## ✨ Features

- Stores note metadata (`SyncMetadata`) and note content (`String`) using `SharedPreferences`.
- Ideal for quick local persistence and prototyping.
- Lightweight and easy to integrate with local sync flows.

## 📦 Installation

Add dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  shared_preferences:
  cloud_sync:
  cloud_sync_shared_preferences_adapter:
```

## 🚀 Usage

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_sync/cloud_sync.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  final adapter = CloudSyncSharedPreferencesAdapter(prefs);
}
```

## 📁 Class Overview

```dart
class CloudSyncSharedPreferencesAdapter
    implements SyncAdapter<SyncMetadata, String>
```

- `fetchMetadataList()`: Retrieves a list of `SyncMetadata` stored in preferences.
- `fetchDetail(metadata)`: Returns the note content (`String`) for the given metadata ID.
- `save(metadata, detail)`: Adds or updates a note and its metadata.

## ⚠️ Notes

- Uses a key prefix (`CloudSyncSharedPreferencesAdapter`) to namespace stored keys.
- Not suited for storing large files or binary data.
- Ideal for testing, offline-first apps, or as a fallback sync layer.

## 📄 License

MIT (or your project’s license).
