import 'dart:typed_data';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import './model/model.dart';
import 'model/generic.dart';
import 'model/immutable.dart';

enum NumericEnumTestColor {
  Red,
  Blue,
  Gray,
  GrayMetallic,
  Green,
  Brown,
  Yellow,
  Black,
  White
}

class Timestamp {
  num stamp;
  num i;
  Timestamp(this.stamp, this.i);
}

class CustomStringConverter implements ICustomConverter<String> {
  const CustomStringConverter() : super();

  @override
  String fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue;
  }

  @override
  dynamic toJSON(String object, [JsonProperty jsonProperty]) {
    return '_${object}_';
  }
}

@jsonSerializable
class BinaryData {
  Uint8List data;

  BinaryData(this.data);
}

@jsonSerializable
class BigIntData {
  BigInt bigInt;

  BigIntData(this.bigInt);
}

@jsonSerializable
class Model {
  DateTime data;
}

@jsonSerializable
class NumericEnum {
  @JsonProperty(enumValues: NumericEnumTestColor.values)
  NumericEnumTestColor color;

  NumericEnum(this.color);
}

@jsonSerializable
class ListItem {}

@jsonSerializable
class CustomListContainer {
  List<ListItem> list = [];
  Set<ListItem> set = {};
}

@jsonSerializable
class InlineJsonContainer {
  Map<String, dynamic> dataHash;
}

void testConverters() {
  group('[Verify converters]', () {
    test('Map<String, dynamic> converter', () {
      // given
      final json = '{"a":"abc","b":3}';

      // when
      final target = JsonMapper.deserialize<Map<String, dynamic>>(json);

      // then
      expect(target, TypeMatcher<Map<String, dynamic>>());
      expect(target['a'], TypeMatcher<String>());
      expect(target['b'], TypeMatcher<num>());
    });

    test('Map converter - Inline JSON value', () {
      // given
      final json = r'''{
          "id": 15989,
      "title": "xxx",
      "body": "xxx",
      "type": "abc",
      "dataHash": "{\"id\":\"3098\",\"number\":1}"
    }''';

      // when
      final target = JsonMapper.deserialize<InlineJsonContainer>(json);

      // then
      expect(target, TypeMatcher<InlineJsonContainer>());
      expect(target.dataHash['id'], '3098');
      expect(target.dataHash['number'], 1);
    });

    test('DateConverter', () {
      // given
      final instance = Model();

      // when
      final json = JsonMapper.toJson(instance);
      final target = JsonMapper.fromJson<Model>(json);

      // then
      expect(target.data, instance.data);
    });

    test('BigInt converter', () {
      // given
      final rawString = '1234567890000000012345678900';
      final json = '{"bigInt":"${rawString}"}';

      // when
      final targetJson = JsonMapper.serialize(
          BigIntData(BigInt.parse(rawString)), compactOptions);
      // then
      expect(targetJson, json);

      // when
      final target = JsonMapper.deserialize<BigIntData>(json);
      // then
      expect(rawString, target.bigInt.toString());
    });

    test('Uint8List converter', () {
      // given
      final json = '{"data":"QmFzZTY0IGlzIHdvcmtpbmch"}';
      final rawString = 'Base64 is working!';

      // when
      final targetJson = JsonMapper.serialize(
          BinaryData(Uint8List.fromList(rawString.codeUnits)), compactOptions);
      // then
      expect(targetJson, json);

      // when
      final target = JsonMapper.deserialize<BinaryData>(json);
      // then
      expect(rawString, String.fromCharCodes(target.data));
    });

    test('Default Map<K, V> converter', () {
      // given
      final targetJson =
          '''{"bar":{"modelName":"Tesla S3","color":"Color.Black"}}''';
      final foo = <String, Car>{};
      foo['bar'] = Car('Tesla S3', Color.Black);

      // when
      final json = JsonMapper.serialize(foo, compactOptions);

      // then
      expect(json, targetJson);
    });

    test('Custom String converter', () {
      // given
      final json = '''{
 "id": 1,
 "name": "_Bob_",
 "car": {
  "modelName": "_Audi_",
  "color": "Color.Green"
 }
}''';
      final adapter =
          JsonMapperAdapter(converters: {String: CustomStringConverter()});
      JsonMapper().useAdapter(adapter);

      final i = Immutable(1, 'Bob', Car('Audi', Color.Green));
      // when
      final target = JsonMapper.serialize(i);
      // then
      expect(target, json);

      JsonMapper().removeAdapter(adapter);
    });

    test('Custom Iterable converter', () {
      // given
      final json = '''{"list":[{}, {}],"set":[{}, {}]}''';

      // when
      final target = JsonMapper.deserialize<CustomListContainer>(json);

      // then
      expect(target.list, TypeMatcher<List<ListItem>>());
      expect(target.list.first, TypeMatcher<ListItem>());
      expect(target.list.length, 2);

      expect(target.set, TypeMatcher<Set<ListItem>>());
      expect(target.set.first, TypeMatcher<ListItem>());
      expect(target.set.length, 2);
    });

    test('Unknown types .fromMap', () {
      // given
      final json = <String, dynamic>{
        'model': 'Tesla',
        'DateFacturation': Timestamp(1568465485, 0),
      };

      // when
      final myModel = JsonMapper.fromMap<MyCarModel>(
          json, SerializationOptions(ignoreUnknownTypes: true));

      // then
      expect(myModel.model, 'Tesla');
    });

    test('Numeric Enum converter', () {
      // given
      final json = '''{"color":3}''';
      final adapter =
          JsonMapperAdapter(converters: {Enum: enumConverterNumeric});
      JsonMapper().useAdapter(adapter);

      final instance = NumericEnum(NumericEnumTestColor.GrayMetallic);
      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, json);

      JsonMapper().removeAdapter(adapter);
    });
  });
}
