import 'package:cloud_sync/cloud_sync.dart';
import 'package:hive_ce/hive.dart';

/// A local implementation of the [SyncAdapter] interface using Hive for storage.
/// This adapter is responsible for syncing metadata and notes.
class CloudSyncHiveAdapter implements SyncAdapter<SyncMetadata, String> {
  /// Creates a [CloudSyncHiveAdapter] with the given Hive boxes for notes and metadata.
  const CloudSyncHiveAdapter({
    required this.metadataBox,
    required this.detailBox,
  });

  /// The Hive box used to store metadata.
  final Box<SyncMetadata> metadataBox;

  /// The Hive box used to store notes.
  final LazyBox<String> detailBox;

  /// Fetches the list of metadata from the metadata Hive box.
  ///
  /// Returns a list of `SyncMetadata` objects.
  @override
  Future<List<SyncMetadata>> fetchMetadataList() async {
    return metadataBox.values.toList();
  }

  /// Fetches the detail (note content) associated with the given metadata.
  ///
  /// Throws an exception if the note is not found.
  ///
  /// [metadata] - The metadata object containing the ID of the note to fetch.
  /// Returns the note content as a string.
  @override
  Future<String> fetchDetail(SyncMetadata metadata) async {
    return (await detailBox.get(metadata.id))!;
  }

  /// Saves the given metadata and note content to their respective Hive boxes.
  ///
  /// [metadata] - The metadata object to save.
  /// [detail] - The note content to save.
  @override
  Future<void> save(SyncMetadata metadata, String detail) async {
    await detailBox.put(metadata.id, detail);
    await metadataBox.put(metadata.id, metadata);
  }
}
