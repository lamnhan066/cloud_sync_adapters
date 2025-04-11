import 'package:cloud_sync/cloud_sync.dart';
import 'package:cloud_sync_hive_adapter/cloud_sync_hive_adapter.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockMetadataBox extends Mock implements Box<String> {}

class MockDetailBox extends Mock implements LazyBox<String> {}

void main() {
  late MockMetadataBox metadataBox;
  late MockDetailBox detailBox;
  late CloudSyncHiveAdapter<SerializableSyncMetadata> adapter;

  final testMetadata = SerializableSyncMetadata(
    id: 'note1',
    modifiedAt: DateTime.now(),
  );
  const testDetail = 'This is the detail of note1';

  setUp(() {
    metadataBox = MockMetadataBox();
    detailBox = MockDetailBox();
    adapter = CloudSyncHiveAdapter<SerializableSyncMetadata>(
      metadataBox: metadataBox,
      detailBox: detailBox,
      metadataToJson: (metadata) => metadata.toJson(),
      metadataFromJson: (json) => SerializableSyncMetadata.fromJson(json),
    );
  });

  group('CloudSyncHiveAdapter', () {
    test('fetchMetadataList returns metadata list from metadataBox', () async {
      final metadataList = [testMetadata];
      when(
        () => metadataBox.values,
      ).thenReturn(metadataList.map((e) => e.toJson()));

      final result = await adapter.fetchMetadataList();

      expect(result, isA<List<SyncMetadata>>());
      expect(result.length, equals(1));
      verify(() => metadataBox.values).called(1);
    });

    test('fetchDetail returns correct detail from detailBox', () async {
      when(
        () => detailBox.get(testMetadata.id),
      ).thenAnswer((_) async => testDetail);

      final result = await adapter.fetchDetail(testMetadata);

      expect(result, equals(testDetail));
      verify(() => detailBox.get(testMetadata.id)).called(1);
    });

    test('fetchDetail throws when note not found', () async {
      when(() => detailBox.get(testMetadata.id)).thenAnswer((_) async => null);

      expect(
        () => adapter.fetchDetail(testMetadata),
        throwsA(isA<TypeError>()),
      );
    });

    test('save stores metadata and detail in their respective boxes', () async {
      when(
        () => detailBox.put(testMetadata.id, testDetail),
      ).thenAnswer((_) async {});
      when(
        () => metadataBox.put(testMetadata.id, testMetadata.toJson()),
      ).thenAnswer((_) async {});

      await adapter.save(testMetadata, testDetail);

      verify(() => detailBox.put(testMetadata.id, testDetail)).called(1);
      verify(
        () => metadataBox.put(testMetadata.id, testMetadata.toJson()),
      ).called(1);
    });
  });
}
