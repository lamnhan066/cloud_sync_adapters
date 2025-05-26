import 'package:cloud_sync/cloud_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefix = '\$CloudSyncSharedPreferencesAdapter';

/// A [SyncAdapter] implementation that uses [SharedPreferences] for local storage.
///
/// This adapter provides a mechanism to persist metadata and associated detail content
/// (e.g., notes) using key-value storage via SharedPreferences. It ensures that metadata
/// and their corresponding details are stored and retrieved efficiently.
class CloudSyncSharedPreferencesAdapter<M>
    extends SerializableSyncAdapter<M, String> {
  /// Creates an instance of [CloudSyncSharedPreferencesAdapter].
  ///
  /// - [preferences]: The SharedPreferences instance used for storing metadata and detail content.
  /// - [getMetadataId]: Function to extract the unique ID from a metadata object.
  /// - [isCurrentMetadataBeforeOther]: Function to compare two metadata objects for ordering.
  /// - [metadataToJson]: Function to serialize metadata objects into JSON strings.
  /// - [metadataFromJson]: Function to deserialize JSON strings into metadata objects.
  /// - [prefix]: (Optional) A prefix used to namespace keys in SharedPreferences to avoid collisions.
  ///   Defaults to [_kPrefix].
  const CloudSyncSharedPreferencesAdapter({
    required this.preferences,
    required super.getMetadataId,
    required super.isCurrentMetadataBeforeOther,
    required super.metadataToJson,
    required super.metadataFromJson,
    this.prefix = _kPrefix,
  });

  /// A string prefix used to namespace all keys stored in SharedPreferences.
  final String prefix;

  /// The [SharedPreferences] instance used for reading and writing data.
  final SharedPreferences preferences;

  /// Retrieves the list of stored metadata from SharedPreferences.
  ///
  /// The metadata is stored under the key `'<prefix>.metadataList'` as a list of JSON strings.
  /// Each JSON string represents a serialized metadata object.
  ///
  /// Returns a list of deserialized metadata objects. If no metadata is found, an empty list is returned.
  @override
  Future<List<M>> fetchMetadataList() async {
    final listString = preferences.getStringList('$prefix.metadataList');
    final list = listString?.map(metadataFromJson).toList();

    return list ?? [];
  }

  /// Fetches the detail content associated with the given [metadata] from SharedPreferences.
  ///
  /// - [metadata]: The metadata object containing the unique ID used to locate the stored detail content.
  ///
  /// Returns the associated detail string.
  ///
  /// Throws a [StateError] if the detail content is not found in SharedPreferences.
  @override
  Future<String> fetchDetail(M metadata) async {
    return preferences.getString('$prefix.${getMetadataId(metadata)}')!;
  }

  /// Saves metadata and its associated detail content to SharedPreferences.
  ///
  /// - [metadata]: The metadata object to be stored.
  /// - [detail]: The string content associated with the metadata.
  ///
  /// If the metadata already exists, it is updated. Otherwise, it is added to the metadata list.
  /// The metadata list is maintained under the key `'<prefix>.metadataList'` and is stored as
  /// a list of JSON strings.
  @override
  Future<void> save(M metadata, String detail) async {
    // Save the detail content associated with the metadata.
    final metadataId = getMetadataId(metadata);
    await preferences.setString('$prefix.$metadataId', detail);

    final metadataList = await fetchMetadataList();

    // Remove any existing metadata with the same ID and add the new metadata.
    metadataList.removeWhere((e) => getMetadataId(e) == metadataId);
    metadataList.add(metadata);

    // Serialize the updated metadata list and save it to SharedPreferences.
    final metadataListString = metadataList.map(metadataToJson).toList();
    await preferences.setStringList('$prefix.metadataList', metadataListString);
  }
}
