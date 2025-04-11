import 'package:cloud_sync/cloud_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefix = '\$CloudSyncSharedPreferencesAdapter';

/// A local implementation of the [SyncAdapter] interface using SharedPreferences for storage.
/// This adapter is responsible for syncing metadata and notes.
class CloudSyncSharedPreferencesAdapter<M extends SyncMetadata>
    extends SerializableSyncAdapter<M, String> {
  /// Creates a [CloudSyncSharedPreferencesAdapter] with the given SharedPreferences instance.
  const CloudSyncSharedPreferencesAdapter({
    required this.preferences,
    required super.metadataToJson,
    required super.metadataFromJson,
    this.prefix = _kPrefix,
  });

  /// A prefix used to namespace keys in SharedPreferences.
  final String prefix;

  /// The SharedPreferences instance used to store metadata and notes.
  final SharedPreferences preferences;

  /// Fetches the list of metadata from SharedPreferences.
  ///
  /// Returns a list of `SyncMetadata` objects. If no metadata is found, returns an empty list.
  @override
  Future<List<M>> fetchMetadataList() async {
    final listString = preferences.getStringList('$prefix.metadataList');
    final list = listString?.map(metadataFromJson).toList();

    return list ?? [];
  }

  /// Fetches the detail (note content) associated with the given metadata.
  ///
  /// Throws an exception if the note is not found.
  ///
  /// [metadata] - The metadata object containing the ID of the note to fetch.
  /// Returns the note content as a string.
  @override
  Future<String> fetchDetail(SyncMetadata metadata) async {
    return preferences.getString('$prefix.${metadata.id}')!;
  }

  /// Saves the given metadata and note content to SharedPreferences.
  ///
  /// [metadata] - The metadata object to save.
  /// [detail] - The note content to save.
  /// If the metadata already exists, it updates the note content and metadata.
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
