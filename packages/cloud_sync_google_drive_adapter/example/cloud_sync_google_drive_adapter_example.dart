import 'dart:convert'; // For JSON encoding

import 'package:cloud_sync/cloud_sync.dart';
import 'package:cloud_sync_google_drive_adapter/cloud_sync_google_drive_adapter.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart'; // For mocking HTTP client

void main() async {
  // Mock HTTP Client for testing
  final mockClient = MockClient((request) async {
    if (request.url.toString().contains('files?spaces=appDataFolder')) {
      return Response(
        jsonEncode({
          'files': [
            {
              'id': 'file1',
              'modifiedTime': DateTime.now().toIso8601String(),
              'description': jsonEncode({
                'id': 'file1',
                'modifiedAt': DateTime.now().toIso8601String(),
                'isDeleted': false,
              }),
            },
            {
              'id': 'file2',
              'modifiedTime': DateTime.now().toIso8601String(),
              'description': jsonEncode({
                'id': 'file2',
                'modifiedAt': DateTime.now().toIso8601String(),
                'isDeleted': false,
              }),
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    } else if (request.url.toString().contains('files/file1?')) {
      return Response(
        'Hello, world!',
        200,
        headers: {'content-type': 'application/octet-stream'},
      );
    } else if (request.url.toString().contains('files/file2?')) {
      return Response(
        'Another test!',
        200,
        headers: {'content-type': 'application/octet-stream'},
      );
    } else if (request.url.toString().contains('files/file3')) {
      return Response(
        jsonEncode({
          'id': 'file3',
          'name': 'file3',
          'description': jsonEncode({
            'id': 'file3',
            'modifiedAt': DateTime.now().toIso8601String(),
            'isDeleted': false,
          }),
        }),
        200,
      );
    } else if (request.url.toString().contains('files/file1')) {
      return Response(
        jsonEncode({
          'id': 'file1',
          'name': 'file1',
          'description': jsonEncode({
            'id': 'file1',
            'modifiedAt': DateTime.now().toIso8601String(),
            'isDeleted': false,
          }),
        }),
        200,
      );
    }

    return Response('Not Found', 404);
  });

  final adapter = CloudSyncGoogleDriveAdapter(driveApi: DriveApi(mockClient));

  // Example usage:
  try {
    final metadataList = await adapter.fetchMetadataList();
    print('Metadata List: $metadataList');

    if (metadataList.isNotEmpty) {
      final detail = await adapter.fetchDetail(metadataList.first);
      print(
        'Detail for ${metadataList.first.id}: ${String.fromCharCodes(detail)}',
      );
    }

    final newMetadata = SyncMetadata(id: 'file3', modifiedAt: DateTime.now());
    final newData = utf8.encode('This is new data');

    await adapter.save(newMetadata, newData);
    print('File saved/created successfully');

    final updatedMetadata = SyncMetadata(
      id: 'file1',
      modifiedAt: DateTime.now(),
    );
    final updatedData = utf8.encode('file1 updated data');

    await adapter.save(updatedMetadata, updatedData);
    print('file updated successfully');
  } catch (e) {
    print('Error during synchronization: $e');
  }
}
