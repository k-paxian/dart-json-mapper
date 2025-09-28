import 'package:test/test.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
// Import for initializeJsonMapper removed as per subtask

@jsonSerializable
class RawJsonTestModel {
  @JsonProperty(name: 'rawField', rawJson: true)
  String? rawField;

  @JsonProperty(name: 'normalField')
  String? normalField;

  String? noAnnotationField;

  RawJsonTestModel({this.rawField, this.normalField, this.noAnnotationField});
}

void main() {
  // setUpAll block removed as per subtask

  group('RawJson Serialization Tests', () {
    test('Serialization - rawJson with valid JSON object string', () {
      final model = RawJsonTestModel(rawField: '{"key": "value"}');
      final json = JsonMapper.serialize(model);
      expect(json, contains('"rawField":{"key":"value"}'));
      expect(json, isNot(contains('"rawField":"{\\"key\\":\\"value\\"}"')));
    });

    test('Serialization - rawJson with valid JSON array string', () {
      final model = RawJsonTestModel(rawField: '[1, 2, 3]');
      final json = JsonMapper.serialize(model);
      expect(json, contains('"rawField":[1,2,3]'));
      expect(json, isNot(contains('"rawField":"[1,2,3]"')));
    });

    test('Serialization - rawJson with invalid JSON string', () {
      final model = RawJsonTestModel(rawField: 'not actually json');
      final json = JsonMapper.serialize(model);
      expect(json, contains('"rawField":"not actually json"'));
    });

    test('Serialization - rawJson with null rawField', () {
      final model = RawJsonTestModel(rawField: null);
      final json = JsonMapper.serialize(model);
      expect(json, contains('"rawField":null'));
    });

    test('Serialization - normalField with string value', () {
      final model = RawJsonTestModel(normalField: 'a normal string');
      final json = JsonMapper.serialize(model);
      expect(json, contains('"normalField":"a normal string"'));
    });

    test('Serialization - noAnnotationField with string value', () {
      final model = RawJsonTestModel(noAnnotationField: 'no annotation');
      final json = JsonMapper.serialize(model);
      expect(json, contains('"noAnnotationField":"no annotation"'));
    });
  });

  group('RawJson Deserialization Tests', () {
    test('Deserialization - rawJson with JSON object', () {
      final json = '{"rawField": {"id": 2, "data": "content"}}';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.rawField, '{"id":2,"data":"content"}');
    });

    test('Deserialization - rawJson with JSON array', () {
      final json = '{"rawField": [1, 2, 3, "test"]}';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.rawField, '[1,2,3,"test"]');
    });

    test('Deserialization - rawJson with JSON string', () {
      final json = '{"rawField": "a string value"}';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.rawField, 'a string value');
    });

    test('Deserialization - rawJson with null', () {
      final json = '{"rawField": null}';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.rawField, isNull);
    });

    test('Deserialization - normalField with string value', () {
      final json = '{"normalField": "a normal string value"}';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.normalField, 'a normal string value');
    });

    test('Deserialization - noAnnotationField with string value', () {
      final json = '{"noAnnotationField": "no annotation value"}';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.noAnnotationField, 'no annotation value');
    });

    test('Deserialization - all fields', () {
      final json = '''
      {
        "rawField": {"complex": [1, {"nested": "object"}]},
        "normalField": "normal text",
        "noAnnotationField": "unannotated text"
      }
      ''';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.rawField, '{"complex":[1,{"nested":"object"}]}');
      expect(model.normalField, 'normal text');
      expect(model.noAnnotationField, 'unannotated text');
    });

    test('Deserialization - rawJson with number', () {
      final json = '{"rawField": 123}';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.rawField, '123');
    });

    test('Deserialization - rawJson with boolean', () {
      final json = '{"rawField": true}';
      final model = JsonMapper.deserialize<RawJsonTestModel>(json)!;
      expect(model.rawField, 'true');
    });
  });
}
