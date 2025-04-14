import 'package:cloud_sync/cloud_sync.dart';
import 'package:hive_ce/hive.dart';

/// A Hive-based implementation of the [SyncAdapter] interface for local storage.
///
/// This adapter uses Hive as the local persistence layer to manage the synchronization
/// of metadata and associated content (e.g., notes). It provides methods to fetch, save,
/// and manage data in a structured and efficient manner.
class CloudSyncHiveAdapter<M extends SyncMetadata>
    extends SerializableSyncAdapter<M, String> {
  /// Creates an instance of [CloudSyncHiveAdapter].
  ///
  /// - [metadataBox]: The Hive box used to store serialized metadata as JSON strings.
  /// - [detailBox]: The Hive lazy box used to store detailed content as plain strings.
  /// - [getMetadataId]: A function to extract the unique identifier from metadata.
  /// - [isCurrentMetadataBeforeOther]: A function to compare two metadata objects.
  /// - [metadataToJson]: A function to serialize metadata into a JSON string.
  /// - [metadataFromJson]: A function to deserialize a JSON string into metadata.
  CloudSyncHiveAdapter({
    required this.metadataBox,
    required this.detailBox,
    required super.getMetadataId,
    required super.isCurrentMetadataBeforeOther,
    required super.metadataToJson,
    required super.metadataFromJson,
  });

  /// The Hive box used to store serialized metadata as JSON strings.
  final Box<String> metadataBox;

  /// The Hive lazy box used to store detailed content as plain strings.
  final LazyBox<String> detailBox;

  /// Retrieves a list of all stored metadata from the [metadataBox].
  ///
  /// This method iterates over all values in the [metadataBox], deserializes each JSON string
  /// into a [SyncMetadata] object using the [metadataFromJson] function, and returns the
  /// resulting list of metadata objects.
  ///
  /// Returns:
  /// - A [Future] that resolves to a list of deserialized metadata objects.
  @override
  Future<List<M>> fetchMetadataList() async {
    return metadataBox.values.map(metadataFromJson).toList();
  }

  /// Retrieves the detailed content associated with the given [metadata].
  ///
  /// - [metadata]: The metadata object containing the identifier of the content to fetch.
  ///
  /// This method fetches the content stored in the [detailBox] using the metadata's ID.
  /// If the content is not found, a [StateError] is thrown.
  ///
  /// Returns:
  /// - A [Future] that resolves to the stored string content for the given metadata ID.
  ///
  /// Throws:
  /// - [StateError] if the corresponding detail content is not found.
  @override
  Future<String> fetchDetail(SyncMetadata metadata) async {
    return (await detailBox.get(metadata.id))!;
  }

  /// Saves metadata and its associated detailed content to Hive.
  ///
  /// - [metadata]: The metadata object to persist. It is serialized into a JSON string
  ///   using the [metadataToJson] function and stored in the [metadataBox].
  /// - [detail]: The associated detailed content to persist. It is stored as a plain string
  ///   in the [detailBox].
  ///
  /// This method ensures that both the metadata and its corresponding detail content
  /// are saved under the same key (ID) to maintain synchronization between them.
  ///
  /// Returns:
  /// - A [Future] that completes when both metadata and detail content are successfully saved.
  @override
  Future<void> save(M metadata, String detail) async {
    await detailBox.put(metadata.id, detail);
    await metadataBox.put(metadata.id, metadataToJson(metadata));
  }
}
