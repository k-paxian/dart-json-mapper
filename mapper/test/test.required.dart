import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import 'model/index.dart';

@jsonSerializable
class MyNullableFieldsExample {
  List<int>? myList;
  Map<int, int>? myMap;
  Set<int>? mySet;
}

@jsonSerializable
class TransactionsRequestModel {
  final String? accountType;

  TransactionsRequestModel({
    this.accountType,
  });
}

@jsonSerializable
class Preferences {
  final String defaultCountryIsoCode;

  /// can be null if user didn't specify his will yet
  final bool? autoImportContacts;
  final Metadata metadata;

  Preferences({
    required this.metadata,
    required this.defaultCountryIsoCode,
    required this.autoImportContacts,
  });

  @override
  String toString() =>
      'Preferences(countryIsoCode: $defaultCountryIsoCode, autoImportContacts: $autoImportContacts, metadata: $metadata)';
}

@jsonSerializable
class Metadata {
  @JsonProperty(ignoreForSerialization: true)
  final String id;
  final String createdBy;
  @JsonProperty(defaultValue: false)
  final bool deleted;

  Metadata({
    required this.id,
    required this.createdBy,
    this.deleted = false,
  });

  @override
  String toString() {
    return 'Metadata(id: $id, createdBy: $createdBy)';
  }
}

void testRequired() {
  group('[Verify required fields]', () {
    test('ignoreForSerialization:true vs required annotated field', () {
      // given
      final json = r'''
{
  "defaultCountryIsoCode": "US",
    "metadata": {
      "createdBy": "e5PPxnqulIgBslobDZPXVweoTCC2",
      "id": "e5PPxnqulIgBslobDZPXVweoTCC2"
    }
}
''';

      // when
      final target = JsonMapper.deserialize<Preferences>(json)!;
      final targetJson = JsonMapper.serialize(target, compactOptions);

      // then
      expect(target.metadata.id, 'e5PPxnqulIgBslobDZPXVweoTCC2');
      expect(targetJson,
          '{"defaultCountryIsoCode":"US","autoImportContacts":null,"metadata":{"createdBy":"e5PPxnqulIgBslobDZPXVweoTCC2","deleted":false}}');
    });

    test('Should handle null fields', () {
      // given
      final json = r'''{"myList":null,"myMap":null,"mySet":null}''';

      // when
      final targetJson =
          JsonMapper.toJson(MyNullableFieldsExample(), compactOptions);

      // then
      expect(targetJson, json);
    });

    test('toMap vs toJson parity', () {
      // given
      final json = r'''{"accountType":null}''';

      // when
      final targetJson = JsonMapper.toJson(
          TransactionsRequestModel(accountType: null), compactOptions);
      final target =
          JsonMapper.toMap(TransactionsRequestModel(accountType: null));

      // then
      expect(targetJson, json);
      expect(target!.containsKey('accountType'), true);
      expect(target.containsValue(null), true);
    });
  });
}
