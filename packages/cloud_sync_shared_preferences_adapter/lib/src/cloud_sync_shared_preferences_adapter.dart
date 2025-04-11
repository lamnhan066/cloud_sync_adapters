import 'package:cloud_sync/cloud_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefix = '\$CloudSyncSharedPreferencesAdapter';

/// A [SyncAdapter] implementation that uses [SharedPreferences] for local storage.
///
/// This adapter handles the persistence of metadata and associated detail content (e.g., notes)
/// using simple key-value storage via SharedPreferences.
class CloudSyncSharedPreferencesAdapter<M extends SyncMetadata>
    extends SerializableSyncAdapter<M, String> {
  /// Creates an instance of [CloudSyncSharedPreferencesAdapter].
  ///
  /// - [preferences]: The SharedPreferences instance for storing metadata and detail content.
  /// - [metadataToJson]: Function to serialize metadata to JSON.
  /// - [metadataFromJson]: Function to deserialize metadata from JSON.
  /// - [prefix]: (Optional) A prefix used to namespace keys to avoid collisions. Defaults to [_kPrefix].
  const CloudSyncSharedPreferencesAdapter({
    required this.preferences,
    required super.metadataToJson,
    required super.metadataFromJson,
    this.prefix = _kPrefix,
  });

  /// A string prefix to namespace all stored keys in SharedPreferences.
  final String prefix;

  /// The [SharedPreferences] instance used for reading and writing data.
  final SharedPreferences preferences;

  /// Retrieves the list of stored metadata from SharedPreferences.
  ///
  /// The metadata is expected to be stored under the key `'<prefix>.metadataList'`
  /// as a list of JSON strings.
  ///
  /// Returns a list of deserialized metadata objects. Returns an empty list if none are found.
  @override
  Future<List<M>> fetchMetadataList() async {
    final listString = preferences.getStringList('$prefix.metadataList');
    final list = listString?.map(metadataFromJson).toList();

    return list ?? [];
  }

  /// Fetches the detail content associated with the given [metadata] from SharedPreferences.
  ///
  /// - [metadata]: The metadata object containing the ID used to locate the stored detail.
  ///
  /// Returns the associated detail string.
  ///
  /// Throws a [StateError] if the content is not found.
  @override
  Future<String> fetchDetail(SyncMetadata metadata) async {
    return preferences.getString('$prefix.${metadata.id}')!;
  }

  /// Saves metadata and its associated detail content to SharedPreferences.
  ///
  /// - [metadata]: The metadata object to store.
  /// - [detail]: The string content associated with the metadata.
  ///
  /// If the metadata already exists, it is updated; otherwise, it is added.
  /// The metadata list is maintained under the key `'<prefix>.metadataList'`.
  @override
  Future<void> save(M metadata, String detail) async {
    final metadataList = await fetchMetadataList();

    await preferences.setString('$prefix.${metadata.id}', detail);

    metadataList.removeWhere((e) => e.id == metadata.id);
    metadataList.add(metadata);

    final metadataListString = metadataList.map(metadataToJson).toList();
    await preferences.setStringList('$prefix.metadataList', metadataListString);
  }
}
