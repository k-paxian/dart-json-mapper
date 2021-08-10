import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

class ParentInjected1 {
  String? lastName;
  List<ChildInjected1> children = [];
}

@jsonSerializable
class ChildInjected1 {
  String? firstName;

  @JsonProperty(inject: true)
  ParentInjected1? parent;

  @JsonProperty(inject: true)
  String? nickname;
}

class ParentInjected2 {
  String? lastName;
  List<ChildInjected2> children = [];
}

@jsonSerializable
class ChildInjected2 {
  String? firstName;

  @JsonProperty(inject: true)
  ParentInjected2? parent;

  @JsonProperty(name: 'data/nick', inject: true)
  String? nickname;

  ChildInjected2(this.parent);
}

class ParentInjected3 {
  String? lastName;
  List<ChildInjected3> children = [];
}

@jsonSerializable
class ChildInjected3 {
  String? firstName;

  @JsonProperty(inject: true)
  ParentInjected3? parent;

  @JsonProperty(inject: true)
  String? nickname;

  ChildInjected3(this.parent);
}

void testInjection() {
  group('[Verify injected fields]', () {
    test('Referencing to injected object', () {
      // given
      final json1 = '''{"firstName": "Alice"}''';
      final json2 = '''{"firstName": "Bob"}''';
      final json3 = '''{"firstName": "Eve"}''';

      // when
      ParentInjected1 parentInstance1 = ParentInjected1()..lastName = "Doe";
      final childInstance1 = JsonMapper.deserialize<ChildInjected1>(
        json1,
        DeserializationOptions(
            injectableValues: {'parent': parentInstance1, 'nickname': "Ally"}),
      )!;
      parentInstance1.children.add(childInstance1);

      ParentInjected2 parentInstance2 = ParentInjected2()..lastName = "Doe";
      final childInstance2 = JsonMapper.deserialize<ChildInjected2>(
          json2,
          DeserializationOptions(injectableValues: {
            'parent': parentInstance2,
            'data': {'nick': "Bobby"}
          }))!;
      parentInstance2.children.add(childInstance2);

      ParentInjected3 parentInstance3 = ParentInjected3()..lastName = "Doe";
      final childInstance3 = JsonMapper.deserialize<ChildInjected3>(
          json3,
          DeserializationOptions(
              injectableValues: {'parent': parentInstance3}))!;
      parentInstance3.children.add(childInstance3);

      // then
      expect(parentInstance1.lastName, "Doe");
      expect(childInstance1.parent, parentInstance1);
      expect(childInstance1.firstName, "Alice");
      expect(childInstance1.nickname, "Ally");

      expect(parentInstance2.lastName, "Doe");
      expect(childInstance2.parent, parentInstance2);
      expect(childInstance2.firstName, "Bob");
      expect(childInstance2.nickname, "Bobby");

      expect(parentInstance3.lastName, "Doe");
      expect(childInstance3.parent, parentInstance3);
      expect(childInstance3.firstName, "Eve");
      expect(childInstance3.nickname, null);
    });
  });
}
