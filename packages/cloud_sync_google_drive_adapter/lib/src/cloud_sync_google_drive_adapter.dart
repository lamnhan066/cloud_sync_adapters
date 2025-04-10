import 'package:cloud_sync/cloud_sync.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// A Google Drive implementation of the [SyncAdapter] interface.
///
/// This adapter handles synchronization of metadata and detailed data
/// with Google Drive.
class CloudSyncGoogleDriveAdapter
    implements SyncAdapter<SyncMetadata, List<int>> {
  final drive.DriveApi driveApi;
  final String spaces;

  /// Constructor for [CloudSyncGoogleDriveAdapter].
  ///
  /// Initializes the adapter with the provided [driveApi] instance for interacting
  /// with the Google Drive API and an optional [spaces] parameter, which specifies
  /// the storage space to operate in (defaulting to 'appDataFolder').
  const CloudSyncGoogleDriveAdapter({
    required this.driveApi,
    this.spaces = 'appDataFolder',
  });

  /// Factory constructor to create an instance of [CloudSyncGoogleDriveAdapter].
  ///
  /// This factory method accepts an HTTP [client] for making requests to Google Drive
  /// and an optional [spaces] parameter, which defaults to 'appDataFolder'.
  /// It initializes the [driveApi] using the provided [client].
  factory CloudSyncGoogleDriveAdapter.fromClient({
    required http.Client client,
    String spaces = 'appDataFolder',
  }) {
    return CloudSyncGoogleDriveAdapter(
      driveApi: drive.DriveApi(client),
      spaces: spaces,
    );
  }

  /// Generates a list of unique IDs for files in Google Drive.
  ///
  /// This method uses the Google Drive API to generate a specified number of IDs.
  /// The [count] parameter specifies how many IDs to generate, defaulting to 1.
  /// Returns a list of generated IDs.
  Future<List<String>> generateIds([int count = 1]) {
    return driveApi.files.generateIds(count: count).then((response) {
      return response.ids ?? [];
    });
  }

  /// Fetches a list of metadata from Google Drive.
  ///
  /// This method retrieves all files in the specified [spaces] that are
  /// not folders and maps their descriptions to [SyncMetadata] objects.
  @override
  Future<List<SyncMetadata>> fetchMetadataList() async {
    final results = <drive.File>[];
    String? nextPageToken;
    final q = "mimeType!='application/vnd.google-apps.folder'";
    do {
      final fileList = await driveApi.files.list(
        spaces: spaces,
        pageToken: nextPageToken,
        $fields: 'id, modifiedTime, description',
        q: q,
      );
      results.addAll(fileList.files ?? []);
      nextPageToken = fileList.nextPageToken;
    } while (nextPageToken != null);

    // Map the file descriptions to SyncMetadata objects.
    return results.map((file) {
      return SyncMetadataDeserialization.fromJson(file.description!);
    }).toList();
  }

  /// Fetches the detailed content of a file from Google Drive.
  ///
  /// Accepts a [SyncMetadata] object and retrieves the file's binary content
  /// as a list of integers.
  @override
  Future<List<int>> fetchDetail(SyncMetadata metadata) async {
    final file =
        await driveApi.files.get(
              metadata.id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    // Combine the streamed content into a single list of bytes.
    final contentMultipleList = await file.stream.toList();
    final List<int> contentList = <int>[];
    contentMultipleList.forEach(contentList.addAll);

    return contentList;
  }

  /// Saves a file to Google Drive.
  ///
  /// If the file already exists (based on its metadata ID), it updates the file.
  /// Otherwise, it creates a new file.
  @override
  Future<void> save(SyncMetadata metadata, List<int> detail) async {
    final metadataList = await fetchMetadataList();

    if (metadataList.any((e) => e.id == metadata.id)) {
      await _updateFile(metadata, detail);
    } else {
      await _createFile(metadata, detail);
    }
  }

  /// Creates a new file in Google Drive.
  ///
  /// Accepts [metadata] for the file's metadata and [detail] for its binary content.
  Future<void> _createFile(SyncMetadata metadata, List<int> detail) async {
    final file =
        drive.File()
          ..id = metadata.id
          ..name = metadata.id
          ..description = metadata.toJson()
          ..modifiedTime = metadata.modifiedAt
          ..mimeType = 'application/octet-stream'
          ..parents = [spaces];

    final media = drive.Media(Stream.fromIterable([detail]), detail.length);

    await driveApi.files.create(file, uploadMedia: media);
  }

  /// Updates an existing file in Google Drive.
  ///
  /// Accepts [metadata] for the updated metadata and [detail] for the updated binary content.
  Future<void> _updateFile(SyncMetadata metadata, List<int> detail) async {
    final file =
        drive.File()
          ..id = metadata.id
          ..name = metadata.id
          ..modifiedTime = metadata.modifiedAt
          ..description = metadata.toJson();
    final media = drive.Media(Stream.fromIterable([detail]), detail.length);

    await driveApi.files.update(file, metadata.id, uploadMedia: media);
  }
}
