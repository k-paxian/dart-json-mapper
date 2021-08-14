import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import './model/index.dart';

@jsonSerializable
class CropArea {
  num? top;
  num? left;
  num? right;
  num? bottom;
}

@jsonSerializable
class ImmutableDefault {
  @JsonProperty(
      defaultValue: {'top': 0.0, 'left': 1.0, 'right': 1.0, 'bottom': 0.0})
  final CropArea? cropArea;

  @JsonProperty(defaultValue: 1)
  final int? id;
  final String? name;
  final Car? car;

  const ImmutableDefault({this.cropArea, this.id, this.name, this.car});
}

@jsonSerializable
class DefaultFields {
  @JsonProperty(
      defaultValue: {'top': 0.0, 'left': 1.0, 'right': 1.0, 'bottom': 0.0},
      ignoreIfDefault: true)
  CropArea? cropArea;

  @JsonProperty(defaultValue: 1)
  int? id;
}

@jsonSerializable
@Json(ignoreDefaultMembers: true)
class ManyDefaultFields {
  @JsonProperty(
      defaultValue: {'top': 0.0, 'left': 1.0, 'right': 1.0, 'bottom': 0.0})
  CropArea? cropArea;

  @JsonProperty(defaultValue: 1)
  int? id;
}

@jsonSerializable
class GlobalDefaultFields {
  @JsonProperty(
      defaultValue: {'top': 0.0, 'left': 1.0, 'right': 1.0, 'bottom': 0.0})
  CropArea? cropArea;

  @JsonProperty(defaultValue: 1)
  int? id;
}

void testDefaultValue() {
  group('[Verify default value cases]', () {
    test('Ignore default field via field annotation', () {
      // given
      final instance = DefaultFields();
      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, '{"id":1}');
    });

    test('Ignore default fields via class annotation', () {
      // given
      final instance = ManyDefaultFields();
      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, '{}');
    });

    test('Ignore default fields via serialization options', () {
      // given
      final instance = GlobalDefaultFields();
      // when
      final target = JsonMapper.serialize(instance,
          SerializationOptions(indent: '', ignoreDefaultMembers: true));
      // then
      expect(target, '{}');
    });

    test('processAnnotatedMembersOnly global option', () {
      // given
      final instance = ImmutableDefault();
      // when
      final target = JsonMapper.serialize(instance,
          SerializationOptions(indent: '', processAnnotatedMembersOnly: true));
      // then
      expect(target,
          '{"cropArea":{"top":0.0,"left":1.0,"right":1.0,"bottom":0.0},"id":1}');
    });

    test('Serialize Immutable class with DefaultValue provided', () {
      // given
      final immutableJson = '''{
 "cropArea": {
  "top": 0.0,
  "left": 1.0,
  "right": 1.0,
  "bottom": 0.0
 },
 "id": 1,
 "name": "Bob",
 "car": {
  "modelName": "Audi",
  "color": "green"
 }
}''';

      final json = '''{
 "name": "Bob",
 "car": {
  "modelName": "Audi",
  "color": "Green"
 }
}''';
      final i = ImmutableDefault(name: 'Bob', car: Car('Audi', Color.green));

      // when
      final targetJson = JsonMapper.serialize(i);
      final target = JsonMapper.deserialize<ImmutableDefault>(json)!;

      // then
      expect(targetJson, immutableJson);

      expect(target.id, 1);
      expect(target.cropArea, TypeMatcher<CropArea>());
      expect(target.cropArea!.left, 1);
      expect(target.cropArea!.right, 1);
      expect(target.cropArea!.bottom, 0);
    });
  });
}
