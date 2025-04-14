import 'package:cloud_sync/cloud_sync.dart';
import 'package:hive_ce/hive.dart';

/// A Hive-based implementation of the [SyncAdapter] interface for local storage.
///
/// This adapter manages synchronization of metadata and associated content (e.g., notes)
/// using Hive as the local persistence layer.
class CloudSyncHiveAdapter<M extends SyncMetadata>
    extends SerializableSyncAdapter<M, String> {
  /// Creates an instance of [CloudSyncHiveAdapter].
  ///
  /// - [metadataBox]: The Hive box used to store serialized metadata.
  /// - [detailBox]: The Hive lazy box used to store detailed content as strings.
  /// - [metadataToJson]: Function to serialize metadata to JSON.
  /// - [metadataFromJson]: Function to deserialize metadata from JSON.
  CloudSyncHiveAdapter({
    required this.metadataBox,
    required this.detailBox,
    required super.getMetadataId,
    required super.isCurrentMetadataBeforeOther,
    required super.metadataToJson,
    required super.metadataFromJson,
  });

  /// The Hive box used to store metadata as JSON strings.
  final Box<String> metadataBox;

  /// The Hive lazy box used to store detailed content as strings.
  final LazyBox<String> detailBox;

  /// Retrieves a list of all stored metadata from the metadata box.
  ///
  /// Iterates over all values in the [metadataBox] and deserializes each JSON string
  /// into a [SyncMetadata] object using [metadataFromJson].
  ///
  /// Returns a list of deserialized metadata objects.
  @override
  Future<List<M>> fetchMetadataList() async {
    return metadataBox.values.map(metadataFromJson).toList();
  }

  /// Retrieves the detail content associated with the given [metadata].
  ///
  /// - [metadata]: The metadata object containing the identifier of the content to fetch.
  ///
  /// Returns the stored string content for the given metadata ID.
  ///
  /// Throws a [StateError] if the corresponding detail is not found.
  @override
  Future<String> fetchDetail(SyncMetadata metadata) async {
    return (await detailBox.get(metadata.id))!;
  }

  /// Saves metadata and detail content to Hive.
  ///
  /// - [metadata]: The metadata object to persist. It is serialized to a JSON string.
  /// - [detail]: The associated content to persist. It is stored as a plain string.
  ///
  /// This method ensures that both the metadata and its corresponding detail
  /// are saved under the same key (ID) to keep them in sync.
  @override
  Future<void> save(M metadata, String detail) async {
    await detailBox.put(metadata.id, detail);
    await metadataBox.put(metadata.id, metadataToJson(metadata));
  }
}
