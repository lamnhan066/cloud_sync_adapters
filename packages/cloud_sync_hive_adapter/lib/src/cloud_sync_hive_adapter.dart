import 'package:cloud_sync/cloud_sync.dart';
import 'package:hive_ce/hive.dart';

/// A local implementation of the [SyncAdapter] interface using Hive for storage.
/// This adapter is responsible for syncing metadata and note content.
class CloudSyncHiveAdapter<M extends SyncMetadata>
    extends SerializableSyncAdapter<M, String> {
  /// Creates a [CloudSyncHiveAdapter] with the given Hive boxes for metadata and note content.
  CloudSyncHiveAdapter({
    required this.metadataBox,
    required this.detailBox,
    required super.metadataToJson,
    required super.metadataFromJson,
  });

  /// The Hive box used to store metadata as JSON strings.
  final Box<String> metadataBox;

  /// The Hive lazy box used to store note content as strings.
  final LazyBox<String> detailBox;

  /// Fetches the list of metadata stored in the metadata Hive box.
  ///
  /// This method iterates over all values in the metadata box, deserializing
  /// each JSON string into a `SyncMetadata` object using the provided [fromMetadataJson] function.
  ///
  /// Returns a list of deserialized `SyncMetadata` objects.
  @override
  Future<List<M>> fetchMetadataList() async {
    return metadataBox.values.map(metadataFromJson).toList();
  }

  /// Fetches the note content (detail) associated with the given metadata.
  ///
  /// [metadata] - The metadata object containing the ID of the note to fetch.
  ///
  /// Throws a [StateError] if the note content is not found in the detail box.
  ///
  /// Returns the note content as a string.
  @override
  Future<String> fetchDetail(SyncMetadata metadata) async {
    return (await detailBox.get(metadata.id))!;
  }

  /// Saves the given metadata and note content to their respective Hive boxes.
  ///
  /// [metadata] - The metadata object to save. It is serialized to a JSON string
  /// using the provided [toMetadataJson] function.
  /// [detail] - The note content to save. It is stored as a string in the detail box.
  ///
  /// This method ensures that both metadata and note content are saved atomically
  /// to maintain consistency.
  @override
  Future<void> save(M metadata, String detail) async {
    await detailBox.put(metadata.id, detail);
    await metadataBox.put(metadata.id, metadataToJson(metadata));
  }
}
