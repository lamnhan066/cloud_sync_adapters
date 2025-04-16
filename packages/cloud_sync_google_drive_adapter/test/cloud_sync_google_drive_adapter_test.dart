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

  const testFileName = '_test_file_name';
  const testSpaces = '_test_spaces';

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
      fileName: testFileName,
      spaces: testSpaces,
    );
  });

  group('fetchMetadataList', () {
    test('returns empty list when no files match', () async {
      final mockFileList = MockFileList();
      final wrongNameFile =
          drive.File()
            ..id = 'wrong-name-file'
            ..name = 'wrong-name'
            ..description = jsonDescription;

      when(() => mockFileList.files).thenReturn([wrongNameFile]);
      when(() => mockFileList.nextPageToken).thenReturn(null);
      when(
        () => mockFiles.list(
          spaces: testSpaces,
          pageToken: any(named: 'pageToken'),
          $fields: any(named: '\$fields'),
          q: any(named: 'q'),
        ),
      ).thenAnswer((_) async => mockFileList);

      final metadataList = await adapter.fetchMetadataList();

      expect(metadataList, isEmpty);
    });

    test('returns list of SyncMetadata from matching files', () async {
      final mockFileList = MockFileList();
      final file =
          drive.File()
            ..id = 'file-id-1'
            ..name = testFileName
            ..description = jsonDescription;

      final anotherFile =
          drive.File()
            ..id = 'file-id-2'
            ..name = testFileName
            ..description = jsonDescription;

      final wrongNameFile =
          drive.File()
            ..id = 'wrong-name-file'
            ..name = 'wrong-name'
            ..description = jsonDescription;

      when(
        () => mockFileList.files,
      ).thenReturn([file, anotherFile, wrongNameFile]);
      when(() => mockFileList.nextPageToken).thenReturn(null);
      when(
        () => mockFiles.list(
          spaces: testSpaces,
          pageToken: any(named: 'pageToken'),
          $fields: any(named: '\$fields'),
          q: any(named: 'q'),
        ),
      ).thenAnswer((_) async => mockFileList);

      final metadataList = await adapter.fetchMetadataList();

      expect(metadataList.length, 2);
      expect(
        metadataList.every((element) => element.id == testMetadata.id),
        isTrue,
      );
    });

    test('handles pagination correctly', () async {
      final firstPageList = MockFileList();
      final secondPageList = MockFileList();

      final firstPageFile =
          drive.File()
            ..id = 'file-id-1'
            ..name = testFileName
            ..description = jsonDescription;

      final secondPageFile =
          drive.File()
            ..id = 'file-id-2'
            ..name = testFileName
            ..description = jsonDescription;

      when(() => firstPageList.files).thenReturn([firstPageFile]);
      when(() => firstPageList.nextPageToken).thenReturn('next-page-token');

      when(() => secondPageList.files).thenReturn([secondPageFile]);
      when(() => secondPageList.nextPageToken).thenReturn(null);

      when(
        () => mockFiles.list(
          spaces: testSpaces,
          pageToken: null,
          $fields: any(named: '\$fields'),
          q: any(named: 'q'),
        ),
      ).thenAnswer((_) async => firstPageList);

      when(
        () => mockFiles.list(
          spaces: testSpaces,
          pageToken: 'next-page-token',
          $fields: any(named: '\$fields'),
          q: any(named: 'q'),
        ),
      ).thenAnswer((_) async => secondPageList);

      final metadataList = await adapter.fetchMetadataList();

      expect(metadataList.length, 2);
    });
  });

  group('fetchDetail', () {
    test('returns content from file matching metadata id', () async {
      final mockFileList = MockFileList();
      final mockMedia = MockMedia();
      final fileBytes = [Uint8List.fromList(utf8.encode('test content'))];

      final file =
          drive.File()
            ..id = 'file-id-1'
            ..name = testFileName
            ..description = jsonDescription;

      when(() => mockFileList.files).thenReturn([file]);
      when(() => mockFileList.nextPageToken).thenReturn(null);
      when(
        () => mockFiles.list(
          spaces: testSpaces,
          pageToken: any(named: 'pageToken'),
          $fields: any(named: '\$fields'),
          q: any(named: 'q'),
        ),
      ).thenAnswer((_) async => mockFileList);

      when(
        () => mockMedia.stream,
      ).thenAnswer((_) => Stream.fromIterable(fileBytes));

      when(
        () => mockFiles.get(
          'file-id-1',
          downloadOptions: drive.DownloadOptions.fullMedia,
        ),
      ).thenAnswer((_) async => mockMedia);

      final content = await adapter.fetchDetail(testMetadata);

      expect(content, 'test content');
    });

    test('throws SyncError when file with metadata id not found', () async {
      final mockFileList = MockFileList();
      final differentMetadata = SerializableSyncMetadata(
        id: 'different-id',
        modifiedAt: DateTime.now(),
      );

      final file =
          drive.File()
            ..id = 'file-id-1'
            ..name = testFileName
            ..description = jsonDescription; // Contains 'test-id'

      when(() => mockFileList.files).thenReturn([file]);
      when(() => mockFileList.nextPageToken).thenReturn(null);
      when(
        () => mockFiles.list(
          spaces: testSpaces,
          pageToken: any(named: 'pageToken'),
          $fields: any(named: '\$fields'),
          q: any(named: 'q'),
        ),
      ).thenAnswer((_) async => mockFileList);

      expect(
        () => adapter.fetchDetail(differentMetadata),
        throwsA(
          isA<SyncError>().having(
            (e) => e.error,
            'message',
            contains('different-id'),
          ),
        ),
      );
    });
  });

  group('save', () {
    test('creates file if metadata not found', () async {
      final mockFileList = MockFileList();
      when(() => mockFileList.files).thenReturn([]);
      when(() => mockFileList.nextPageToken).thenReturn(null);
      when(
        () => mockFiles.list(
          spaces: testSpaces,
          pageToken: any(named: 'pageToken'),
          $fields: any(named: '\$fields'),
          q: any(named: 'q'),
        ),
      ).thenAnswer((_) async => mockFileList);

      when(
        () => mockFiles.create(any(), uploadMedia: any(named: 'uploadMedia')),
      ).thenAnswer((_) async => drive.File());

      await adapter.save(testMetadata, 'test content');

      verify(
        () => mockFiles.create(
          any(
            that: predicate((drive.File file) {
              expect(file.name, equals(testFileName));
              expect(file.description, equals(jsonDescription));
              expect(file.parents, equals([testSpaces]));
              return true;
            }),
          ),
          uploadMedia: any(named: 'uploadMedia'),
        ),
      ).called(1);
    });

    test('updates file if metadata found', () async {
      final mockFileList = MockFileList();
      final driveFile =
          drive.File()
            ..id = 'file-id-1'
            ..name = testFileName
            ..description = jsonDescription;

      when(() => mockFileList.files).thenReturn([driveFile]);
      when(() => mockFileList.nextPageToken).thenReturn(null);
      when(
        () => mockFiles.list(
          spaces: testSpaces,
          pageToken: any(named: 'pageToken'),
          $fields: any(named: '\$fields'),
          q: any(named: 'q'),
        ),
      ).thenAnswer((_) async => mockFileList);

      when(
        () => mockFiles.update(
          any(),
          'file-id-1',
          uploadMedia: any(named: 'uploadMedia'),
        ),
      ).thenAnswer((_) async => drive.File());

      await adapter.save(testMetadata, 'updated content');

      verify(
        () => mockFiles.update(
          any(
            that: predicate(
              (drive.File file) => file.description == jsonDescription,
            ),
          ),
          'file-id-1',
          uploadMedia: any(named: 'uploadMedia'),
        ),
      ).called(1);
    });
  });
}
