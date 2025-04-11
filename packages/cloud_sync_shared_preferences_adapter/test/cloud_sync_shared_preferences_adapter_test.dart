import 'package:cloud_sync/cloud_sync.dart';
import 'package:cloud_sync_shared_preferences_adapter/cloud_sync_shared_preferences_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SharedPreferences preferences;
  late CloudSyncSharedPreferencesAdapter<SerializableSyncMetadata> adapter;
  const prefix = 'CloudSyncSharedPreferencesAdapter';

  final testMetadata = SerializableSyncMetadata(
    id: 'note-1',
    modifiedAt: DateTime.now(),
  );
  final jsonMetadata = testMetadata.toJson();
  final detail = 'Note content for note-1';

  setUp(() {
    preferences = MockSharedPreferences();
    adapter = CloudSyncSharedPreferencesAdapter(
      preferences: preferences,
      metadataToJson: (metadata) => metadata.toJson(),
      metadataFromJson: (json) => SerializableSyncMetadata.fromJson(json),
    );
  });

  group('CloudSyncSharedPreferencesAdapter', () {
    test('fetchMetadataList returns deserialized metadata list', () async {
      when(
        () => preferences.getStringList('$prefix.metadataList'),
      ).thenReturn([jsonMetadata]);

      final result = await adapter.fetchMetadataList();

      expect(result.length, 1);
      expect(result.first.id, testMetadata.id);
    });

    test('fetchMetadataList returns empty list when null', () async {
      when(
        () => preferences.getStringList('$prefix.metadataList'),
      ).thenReturn(null);

      final result = await adapter.fetchMetadataList();

      expect(result, isEmpty);
    });

    test('fetchDetail returns correct note content', () async {
      when(
        () => preferences.getString('$prefix.${testMetadata.id}'),
      ).thenReturn(detail);

      final result = await adapter.fetchDetail(testMetadata);

      expect(result, detail);
    });

    test('save stores metadata and detail when metadata exists', () async {
      // Existing metadata
      when(
        () => preferences.getStringList('$prefix.metadataList'),
      ).thenReturn([jsonMetadata]);
      when(
        () => preferences.setString('$prefix.${testMetadata.id}', detail),
      ).thenAnswer((_) async => true);
      when(
        () => preferences.setStringList(any(), any()),
      ).thenAnswer((_) async => true);

      await adapter.save(testMetadata, detail);

      verify(
        () => preferences.setString('$prefix.${testMetadata.id}', detail),
      ).called(1);
      verify(
        () => preferences.setStringList(
          '$prefix.metadataList',
          any(that: contains(jsonMetadata)),
        ),
      ).called(1);
    });

    test(
      'save stores metadata and detail when metadata does not exist',
      () async {
        // No metadata yet
        when(
          () => preferences.getStringList('$prefix.metadataList'),
        ).thenReturn([]);
        when(
          () => preferences.setString('$prefix.${testMetadata.id}', detail),
        ).thenAnswer((_) async => true);
        when(
          () => preferences.setStringList(any(), any()),
        ).thenAnswer((_) async => true);

        await adapter.save(testMetadata, detail);

        verify(
          () => preferences.setString('$prefix.${testMetadata.id}', detail),
        ).called(1);
        verify(
          () => preferences.setStringList(
            '$prefix.metadataList',
            any(that: contains(jsonMetadata)),
          ),
        ).called(1);
      },
    );
  });
}
