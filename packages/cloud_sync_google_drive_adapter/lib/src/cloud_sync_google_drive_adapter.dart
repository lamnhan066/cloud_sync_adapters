import 'dart:async';
import 'dart:convert';

import 'package:cloud_sync/cloud_sync.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

const String _kDefaultSpaces = 'appDataFolder';
const String _kDefaultFileName = '\$CloudSyncGoogleDriveAdapter';

/// A [SyncAdapter] implementation that uses Google Drive for synchronization.
///
/// This adapter handles the storage and retrieval of both metadata and detailed
/// content using the Google Drive API, specifically within the provided [spaces],
/// typically the `appDataFolder`.
class CloudSyncGoogleDriveAdapter<M>
    extends SerializableSyncAdapter<M, String> {
  final drive.DriveApi driveApi;
  final String spaces;
  final String fileName;

  /// Creates a [CloudSyncGoogleDriveAdapter] instance using an existing [DriveApi] client.
  ///
  /// - [driveApi]: An authenticated instance of [drive.DriveApi].
  /// - [spaces]: The Drive space to use (defaults to `'appDataFolder'`).
  /// - [fileName]: The name of the file used to store data (defaults to `'$CloudSyncGoogleDriveAdapter'`).
  /// - [metadataToJson] / [metadataFromJson]: Functions for serializing and deserializing metadata.
  const CloudSyncGoogleDriveAdapter({
    required this.driveApi,
    this.spaces = _kDefaultSpaces,
    this.fileName = _kDefaultFileName,
    required super.getMetadataId,
    required super.isCurrentMetadataBeforeOther,
    required super.metadataToJson,
    required super.metadataFromJson,
  });

  /// Creates a [CloudSyncGoogleDriveAdapter] from an HTTP client.
  ///
  /// This is a convenience constructor that creates the [DriveApi] instance internally.
  ///
  /// - [client]: The authenticated HTTP client for Google APIs.
  /// - [spaces]: The Drive space to use (defaults to `'appDataFolder'`).
  /// - [fileName]: The name of the file used to store data.
  CloudSyncGoogleDriveAdapter.fromClient({
    required http.Client client,
    this.spaces = _kDefaultSpaces,
    this.fileName = _kDefaultFileName,
    required super.getMetadataId,
    required super.isCurrentMetadataBeforeOther,
    required super.metadataToJson,
    required super.metadataFromJson,
  }) : driveApi = drive.DriveApi(client);

  /// Generates one or more unique file IDs from Google Drive.
  ///
  /// - [count]: Number of IDs to generate (defaults to 1).
  /// Returns a list of newly generated file IDs.
  Future<List<String>> generateIds([int count = 1]) async {
    final response = await driveApi.files.generateIds(count: count);
    return response.ids ?? [];
  }

  /// Fetches a list of all metadata entries stored in Google Drive.
  ///
  /// Searches for all files (non-folders) within the specified [spaces]
  /// and returns those whose name matches [fileName].
  ///
  /// Returns a list of deserialized metadata objects.
  @override
  Future<List<M>> fetchMetadataList() async {
    final results = <drive.File>[];
    String? nextPageToken;
    const query = "mimeType != 'application/vnd.google-apps.folder'";

    do {
      final fileList = await driveApi.files.list(
        spaces: spaces,
        pageToken: nextPageToken,
        $fields: '*',
        q: query,
      );

      for (final file in fileList.files ?? <drive.File>[]) {
        if (file.name == fileName) {
          results.add(file);
        }
      }

      nextPageToken = fileList.nextPageToken;
    } while (nextPageToken != null);

    return results.map((file) => metadataFromJson(file.description!)).toList();
  }

  /// Downloads the content of a file associated with the given [metadata].
  ///
  /// Returns the file content as a UTF-8 decoded [String].
  @override
  Future<String> fetchDetail(M metadata) async {
    final file =
        await driveApi.files.get(
              getMetadataId(metadata),
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final byteChunks = await file.stream.toList();
    return utf8.decode(byteChunks.expand((e) => e).toList());
  }

  /// Saves metadata and associated detail to Google Drive.
  ///
  /// If a file with the same metadata ID already exists, it is updated.
  /// Otherwise, a new file is created.
  @override
  Future<void> save(M metadata, String detail) async {
    final metadataList = await fetchMetadataList();

    if (metadataList.any((e) => getMetadataId(e) == getMetadataId(metadata))) {
      await _updateFile(metadata, detail);
    } else {
      await _createFile(metadata, detail);
    }
  }

  /// Creates a new file in Google Drive with the given [metadata] and [detail].
  Future<void> _createFile(M metadata, String detail) async {
    final file =
        drive.File()
          ..id = getMetadataId(metadata)
          ..name = fileName
          ..description = metadataToJson(metadata)
          ..mimeType = 'application/octet-stream'
          ..parents = [spaces];

    final bytes = utf8.encode(detail);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    await driveApi.files.create(file, uploadMedia: media);
  }

  /// Updates an existing file in Google Drive with new [metadata] and [detail].
  Future<void> _updateFile(M metadata, String detail) async {
    final file = drive.File()..description = metadataToJson(metadata);

    final bytes = utf8.encode(detail);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    await driveApi.files.update(
      file,
      getMetadataId(metadata),
      uploadMedia: media,
    );
  }
}
