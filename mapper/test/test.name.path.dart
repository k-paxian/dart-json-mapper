import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import './model/index.dart';

@jsonSerializable
@Json(name: 'root/foo/bar')
class RootObject {
  @JsonProperty(name: 'baz/items')
  List<String> items;

  RootObject({this.items});
}

@jsonSerializable
class DeepNestedList {
  @JsonProperty(name: 'root/foo/bar/items')
  List<String> items;

  DeepNestedList({this.items});
}

@jsonSerializable
class DeepNestedInt {
  @JsonProperty(name: 'root/foo/bar/count')
  int count;

  DeepNestedInt({this.count});
}

@jsonSerializable
class NestedListItem {
  @JsonProperty(name: 'root/0/bar')
  int count;

  @JsonProperty(name: 'root/1/bar')
  int count2;

  @JsonProperty(name: '#/root/2/c%25d')
  int cd;

  @JsonProperty(name: 'root/3/bar')
  int count3;

  NestedListItem({this.count, this.count2, this.count3, this.cd});
}

void testNamePath() {
  group('[Verify name path processing]', () {
    test('Verify root nested list deserialization', () {
      // given
      final json = '''{
          "root": {
            "foo": {
              "bar": {
                "baz": {
                  "items": [
                    "a",
                    "b",
                    "c"
                  ]
                }
              }
            }
          }
      }''';
      // when
      final instance = JsonMapper.deserialize<RootObject>(json);
      // then
      expect(instance.items.length, 3);
      expect(instance.items, ['a', 'b', 'c']);
    });

    test('Verify deep nested list deserialization', () {
      // given
      final json = '''{
      "root": {
      "foo": {
      "bar": {
        "items": [
        "a",
        "b",
        "c"
        ]
      }
      }
      }
      }''';
      // when
      final instance = JsonMapper.deserialize<DeepNestedList>(json);
      // then
      expect(instance.items.length, 3);
      expect(instance.items, ['a', 'b', 'c']);
    });

    test('Verify deep nested list serialization', () {
      // given
      final instance = DeepNestedList(items: ['1', '2', '3']);
      final json = '''{"root":{"foo":{"bar":{"items":["1","2","3"]}}}}''';
      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(targetJson, json);
    });

    test('Verify deep nested int deserialization', () {
      // given
      final json = '''{
      "root": {
      "foo": {
      "bar": {
        "count": 33
      }
      }
      }
      }''';
      // when
      final instance = JsonMapper.deserialize<DeepNestedInt>(json);
      // then
      expect(instance.count, 33);
    });

    test('Verify nested list item deserialization', () {
      // given
      final json = '''{
        "root": [
          {
            "bar": 33
          },
          {
            "bar": 22
          },
          {
            "c%d": 42
          }
        ]
      }''';
      // when
      final instance = JsonMapper.deserialize<NestedListItem>(json);
      // then
      expect(instance.count, 33);
      expect(instance.count2, 22);
      expect(instance.cd, 42);
      expect(instance.count3, null);
    });
  });
}
