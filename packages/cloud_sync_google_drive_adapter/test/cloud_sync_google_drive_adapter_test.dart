import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_sync/cloud_sync.dart';
import 'package:cloud_sync_google_drive_adapter/cloud_sync_google_drive_adapter.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// === Mocks ===
class MockDriveApi extends Mock implements drive.DriveApi {}

class MockFilesResource extends Mock implements drive.FilesResource {}

class MockGeneratedIds extends Mock implements drive.GeneratedIds {}

class MockFileList extends Mock implements drive.FileList {}

class MockDriveFile extends Mock implements drive.File {}

class MockMedia extends Mock implements drive.Media {}

class FakeDriveFile extends Fake implements drive.File {}

void main() {
  late MockDriveApi mockDriveApi;
  late MockFilesResource mockFiles;
  late CloudSyncGoogleDriveAdapter<SerializableSyncMetadata> adapter;

  final testMetadata = SerializableSyncMetadata(
    id: 'test-id',
    modifiedAt: DateTime.now(),
  );
  final jsonDescription = testMetadata.toJson();

  setUpAll(() {
    registerFallbackValue(FakeDriveFile());
  });

  setUp(() {
    mockDriveApi = MockDriveApi();
    mockFiles = MockFilesResource();

    when(() => mockDriveApi.files).thenReturn(mockFiles);
    adapter = CloudSyncGoogleDriveAdapter<SerializableSyncMetadata>(
      driveApi: mockDriveApi,
      metadataToJson: (metadata) => metadata.toJson(),
      metadataFromJson: (json) => SerializableSyncMetadata.fromJson(json),
      getMetadataId: (SerializableSyncMetadata metadata) {
        return metadata.id;
      },
      isCurrentMetadataBeforeOther: (
        SerializableSyncMetadata current,
        SerializableSyncMetadata other,
      ) {
        return current.modifiedAt.isBefore(other.modifiedAt);
      },
    );
  });

  test('fetchMetadataList returns list of SyncMetadata', () async {
    final mockFileList = MockFileList();
    final file =
        drive.File()
          ..id = testMetadata.id
          ..name = adapter.fileName
          ..description = jsonDescription
          ..modifiedTime = testMetadata.modifiedAt;

    when(() => mockFileList.files).thenReturn([file]);
    when(() => mockFileList.nextPageToken).thenReturn(null);
    when(
      () => mockFiles.list(
        spaces: any(named: 'spaces'),
        pageToken: any(named: 'pageToken'),
        $fields: any(named: '\$fields'),
        q: any(named: 'q'),
      ),
    ).thenAnswer((_) async => mockFileList);

    final metadataList = await adapter.fetchMetadataList();

    expect(metadataList.length, 1);
    expect(metadataList.first.id, testMetadata.id);
  });

  test('fetchDetail returns list of bytes from Media stream', () async {
    final mockMedia = MockMedia();
    final fileBytes = [
      Uint8List.fromList([1, 2]),
      Uint8List.fromList([3]),
    ];

    when(
      () => mockMedia.stream,
    ).thenAnswer((_) => Stream.fromIterable(fileBytes));
    when(
      () => mockFiles.get(
        testMetadata.id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ),
    ).thenAnswer((_) async => mockMedia);

    final bytes = await adapter.fetchDetail(testMetadata);

    final expected = fileBytes.expand((e) => e).toList();
    final decodedBytes = utf8.decode(expected);

    expect(bytes, decodedBytes);
  });

  test('save creates file if metadata not found', () async {
    final mockFileList = MockFileList();
    when(() => mockFileList.files).thenReturn([]);
    when(() => mockFileList.nextPageToken).thenReturn(null);
    when(
      () => mockFiles.list(
        spaces: any(named: 'spaces'),
        pageToken: any(named: 'pageToken'),
        $fields: any(named: '\$fields'),
        q: any(named: 'q'),
      ),
    ).thenAnswer((_) async => mockFileList);

    when(
      () => mockFiles.create(any(), uploadMedia: any(named: 'uploadMedia')),
    ).thenAnswer((_) async => drive.File());

    await adapter.save(testMetadata, '1 2 3');

    verify(
      () => mockFiles.create(any(), uploadMedia: any(named: 'uploadMedia')),
    ).called(1);
  });

  test('save updates file if metadata found', () async {
    final mockFileList = MockFileList();
    final driveFile =
        drive.File()
          ..id = testMetadata.id
          ..name = adapter.fileName
          ..description = jsonDescription;

    when(() => mockFileList.files).thenReturn([driveFile]);
    when(() => mockFileList.nextPageToken).thenReturn(null);
    when(
      () => mockFiles.list(
        spaces: any(named: 'spaces'),
        pageToken: any(named: 'pageToken'),
        $fields: any(named: '\$fields'),
        q: any(named: 'q'),
      ),
    ).thenAnswer((_) async => mockFileList);

    when(
      () => mockFiles.update(
        any(),
        testMetadata.id,
        uploadMedia: any(named: 'uploadMedia'),
      ),
    ).thenAnswer((_) async => drive.File());

    await adapter.save(testMetadata, '4 5 6');

    verify(
      () => mockFiles.update(
        any(),
        testMetadata.id,
        uploadMedia: any(named: 'uploadMedia'),
      ),
    ).called(1);
  });
}
