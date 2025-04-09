import 'package:cloud_sync/cloud_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A local implementation of the [SyncAdapter] interface using SharedPreferences for storage.
/// This adapter is responsible for syncing metadata and notes.
class CloudSyncSharedPreferencesAdapter
    implements SyncAdapter<SyncMetadata, String> {
  /// Creates a [CloudSyncSharedPreferencesAdapter] with the given SharedPreferences instance.
  const CloudSyncSharedPreferencesAdapter(this.preferences);

  /// The SharedPreferences instance used to store metadata and notes.
  final SharedPreferences preferences;

  /// A prefix used to namespace keys in SharedPreferences.
  final String prefix = 'CloudSyncSharedPreferencesAdapter';

  /// Fetches the list of metadata from SharedPreferences.
  ///
  /// Returns a list of `SyncMetadata` objects. If no metadata is found, returns an empty list.
  @override
  Future<List<SyncMetadata>> fetchMetadataList() async {
    final listString = preferences.getStringList('$prefix.metadataList');
    final list =
        listString
            ?.map((element) => SyncMetadataDeserialization.fromJson(element))
            .toList();

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
  Future<void> save(SyncMetadata metadata, String detail) async {
    final metadataList = await fetchMetadataList();

    await preferences.setString('$prefix.${metadata.id}', detail);

    metadataList.removeWhere((e) => e.id == metadata.id);
    metadataList.add(metadata);

    final metadataListString = metadataList.map((e) => e.toJson()).toList();
    await preferences.setStringList('$prefix.metadataList', metadataListString);
  }
}
