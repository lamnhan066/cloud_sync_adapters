import 'dart:async';
import 'dart:convert';

import 'package:cloud_sync/cloud_sync.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

const String _kDefaultSpaces = 'appDataFolder';
const String _kDefaultFileName = '\$CloudSyncGoogleDriveAdapter';

/// A [SyncAdapter] implementation that uses Google Drive for synchronization.
///
/// This adapter provides functionality to store and retrieve metadata and detailed
/// content using the Google Drive API. It operates within the specified [spaces],
/// typically the `appDataFolder`, and uses a specific file name for storage.
///
/// The adapter supports creating, updating, and fetching files, as well as generating
/// unique file IDs using the Google Drive API.
class CloudSyncGoogleDriveAdapter<M>
    extends SerializableSyncAdapter<M, String> {
  /// The authenticated Google Drive API client.
  final drive.DriveApi driveApi;

  /// The Google Drive space to use (e.g., `appDataFolder`).
  final String spaces;

  /// The name of the file used to store data in Google Drive.
  final String fileName;

  /// Creates a [CloudSyncGoogleDriveAdapter] instance using an existing [DriveApi] client.
  ///
  /// - [driveApi]: An authenticated instance of [drive.DriveApi].
  /// - [spaces]: The Drive space to use (defaults to `'appDataFolder'`).
  /// - [fileName]: The name of the file used to store data (defaults to `'$CloudSyncGoogleDriveAdapter'`).
  /// - [metadataToJson] / [metadataFromJson]: Functions for serializing and deserializing metadata.
  const CloudSyncGoogleDriveAdapter({
    required this.driveApi,
    required super.getMetadataId,
    required super.isCurrentMetadataBeforeOther,
    required super.metadataToJson,
    required super.metadataFromJson,
    this.spaces = _kDefaultSpaces,
    this.fileName = _kDefaultFileName,
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

  /// Fetches a list of all metadata entries stored in Google Drive.
  ///
  /// Searches for all files (non-folders) within the specified [spaces]
  /// and returns those whose name matches [fileName].
  ///
  /// Returns a list of deserialized metadata objects.
  @override
  Future<List<M>> fetchMetadataList() async {
    final results = await _fetchFileList();

    // Convert the file descriptions (JSON strings) into metadata objects.
    return results.map((file) => metadataFromJson(file.description!)).toList();
  }

  /// Downloads the content of a file associated with the given [metadata].
  ///
  /// - [metadata]: The metadata object representing the file to download.
  /// Returns the file content as a UTF-8 decoded [String].
  @override
  Future<String> fetchDetail(M metadata) async {
    final file =
        await driveApi.files.get(
              getMetadataId(metadata),
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    // Combine all byte chunks into a single list and decode as UTF-8.
    final byteChunks = await file.stream.toList();
    return utf8.decode(byteChunks.expand((e) => e).toList());
  }

  /// Saves metadata and associated detail to Google Drive.
  ///
  /// If a file with the same metadata ID already exists, it is updated.
  /// Otherwise, a new file is created.
  ///
  /// - [metadata]: The metadata object to save.
  /// - [detail]: The detailed content to associate with the metadata.
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
  ///
  /// - [metadata]: The metadata object to associate with the new file.
  /// - [detail]: The detailed content to store in the new file.
  Future<void> _createFile(M metadata, String detail) async {
    final file =
        drive.File()
          ..name = fileName
          ..description = metadataToJson(metadata)
          ..mimeType = 'application/octet-stream'
          ..parents = [spaces];

    // Encode the detail content as bytes and create a media stream.
    final bytes = utf8.encode(detail);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    // Create the file in Google Drive.
    await driveApi.files.create(file, uploadMedia: media);
  }

  /// Updates an existing file in Google Drive with new [metadata] and [detail].
  ///
  /// - [metadata]: The updated metadata object.
  /// - [detail]: The updated detailed content to store in the file.
  Future<void> _updateFile(M metadata, String detail) async {
    final metadataList = await _fetchFileList();
    String? fileId;
    for (final file in metadataList) {
      final fileMetadata = metadataFromJson(file.description!);
      if (getMetadataId(metadata) == getMetadataId(fileMetadata)) {
        fileId = file.id!;
        break;
      }
    }

    final file = drive.File()..description = metadataToJson(metadata);

    // Encode the detail content as bytes and create a media stream.
    final bytes = utf8.encode(detail);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    // Update the file in Google Drive.
    await driveApi.files.update(file, fileId!, uploadMedia: media);
  }

  Future<List<drive.File>> _fetchFileList() async {
    final results = <drive.File>[];
    String? nextPageToken;
    const query = "mimeType!='application/vnd.google-apps.folder'";

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

    return results;
  }
}
