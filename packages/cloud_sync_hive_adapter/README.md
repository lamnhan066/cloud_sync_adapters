# CloudSyncHiveAdapter

A local implementation of the [`SyncAdapter`](https://pub.dev/documentation/cloud_sync/latest/cloud_sync/SyncAdapter-class.html) interface from the [`cloud_sync`](https://pub.dev/packages/cloud_sync) package, using [Hive](https://pub.dev/packages/hive_ce) for local storage. This adapter enables synchronization of notes and their associated metadata between your app and a local Hive database.

## ✨ Features

- Stores note metadata (`SyncMetadata`) and detail content (`String`) using Hive.
- Supports fetching and saving notes with metadata.
- Designed for local use within a sync system (e.g., to back Google Drive or other sync sources).

## 📦 Installation

Add dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  hive_ce:
  cloud_sync:
  cloud_sync_hive_adapter:
```

## 🚀 Usage

```dart
import 'package:hive_ce/hive.dart';
import 'package:cloud_sync/cloud_sync.dart';

void main() async {
  final metadataBox = await Hive.openBox<SyncMetadata>('metadataBox');
  final detailBox = await Hive.openBox<String>('detailBox');

  final adapter = CloudSyncHiveAdapter(metadataBox, detailBox);
  
  // Now you can use the adapter with a CloudSync
}
```

## 📁 Class Overview

```dart
class CloudSyncHiveAdapter implements SyncAdapter<SyncMetadata, String>
```

- `metadataBox`: Hive box that stores `SyncMetadata`.
- `detailBox`: Hive box that stores note details as `String`.

## 📄 License

MIT (or your project's license).
