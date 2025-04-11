import 'dart:convert';

import 'package:cloud_sync/cloud_sync.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

const String _kDefaultSpaces = 'appDataFolder';
const String _kDefaultFileName = '\$CloudSyncGoogleDriveAdapter';

/// A Google Drive implementation of the [SyncAdapter] interface.
///
/// This adapter handles synchronization of metadata and detailed data
/// with Google Drive.
class CloudSyncGoogleDriveAdapter<M extends SyncMetadata>
    extends SerializableSyncAdapter<M, String> {
  final drive.DriveApi driveApi;
  final String spaces;
  final String fileName;

  /// Constructor for [CloudSyncGoogleDriveAdapter].
  ///
  /// Initializes the adapter with the provided [driveApi] instance for interacting
  /// with the Google Drive API and an optional [spaces] parameter, which specifies
  /// the storage space to operate in (defaulting to 'appDataFolder').
  const CloudSyncGoogleDriveAdapter({
    required this.driveApi,
    this.spaces = _kDefaultSpaces,
    this.fileName = _kDefaultFileName,
    required super.metadataToJson,
    required super.metadataFromJson,
  });

  /// Factory constructor to create an instance of [CloudSyncGoogleDriveAdapter].
  ///
  /// This factory method accepts an HTTP [client] for making requests to Google Drive
  /// and an optional [spaces] parameter, which defaults to 'appDataFolder'.
  /// It initializes the [driveApi] using the provided [client].
  CloudSyncGoogleDriveAdapter.fromClient({
    required http.Client client,
    this.spaces = _kDefaultSpaces,
    this.fileName = _kDefaultFileName,
    required super.metadataToJson,
    required super.metadataFromJson,
  }) : driveApi = drive.DriveApi(client);

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
  Future<List<M>> fetchMetadataList() async {
    final results = <drive.File>[];
    String? nextPageToken;
    final q = "mimeType!='application/vnd.google-apps.folder'";
    do {
      final fileList = await driveApi.files.list(
        spaces: spaces,
        pageToken: nextPageToken,
        $fields: '*',
        q: q,
      );

      for (final file in fileList.files ?? <drive.File>[]) {
        if (file.name == fileName) results.add(file);
      }

      nextPageToken = fileList.nextPageToken;
    } while (nextPageToken != null);

    // Map the file descriptions to SyncMetadata objects.
    return results.map((file) => metadataFromJson(file.description!)).toList();
  }

  /// Fetches the detailed content of a file from Google Drive.
  ///
  /// Accepts a [SyncMetadata] object and retrieves the file's binary content
  /// as a list of integers.
  @override
  Future<String> fetchDetail(SyncMetadata metadata) async {
    final file =
        await driveApi.files.get(
              metadata.id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    // Combine the streamed content into a single list of bytes.
    final contentMultipleList = await file.stream.toList();

    return utf8.decode(contentMultipleList.expand((e) => e).toList());
  }

  /// Saves a file to Google Drive.
  ///
  /// If the file already exists (based on its metadata ID), it updates the file.
  /// Otherwise, it creates a new file.
  @override
  Future<void> save(M metadata, String detail) async {
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
  Future<void> _createFile(M metadata, String detail) async {
    final file =
        drive.File()
          ..id = metadata.id
          ..name = fileName
          ..description = metadataToJson(metadata)
          ..modifiedTime = metadata.modifiedAt
          ..mimeType = 'application/octet-stream'
          ..parents = [spaces];

    final bytes = utf8.encode(detail);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    await driveApi.files.create(file, uploadMedia: media);
  }

  /// Updates an existing file in Google Drive.
  ///
  /// Accepts [metadata] for the updated metadata and [detail] for the updated binary content.
  Future<void> _updateFile(M metadata, String detail) async {
    final file =
        drive.File()
          ..modifiedTime = metadata.modifiedAt
          ..description = metadataToJson(metadata);

    final bytes = utf8.encode(detail);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    await driveApi.files.update(file, metadata.id, uploadMedia: media);
  }
}
