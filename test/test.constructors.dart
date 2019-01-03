part of json_mapper.test;

class Base<T> {
  final T value;
  Base(this.value);
}

@jsonSerializable
class Derived extends Base<String> {
  Derived(String value) : super(value);
}

@jsonSerializable
class StringListClass {
  List<String> list;
  StringListClass(this.list);
}

@jsonSerializable
class PositionalParametersClass {
  String firstName;
  String lastName;
  PositionalParametersClass(this.firstName, this.lastName);
}

@jsonSerializable
class OptionalParametersClass {
  String firstName;
  String lastName;
  OptionalParametersClass([this.firstName, this.lastName]);
}

@jsonSerializable
class PartiallyOptionalParametersClass {
  String firstName;
  String lastName;
  PartiallyOptionalParametersClass(this.firstName, [this.lastName]);
}

@jsonSerializable
class NamedParametersClass {
  String firstName;
  String lastName;
  NamedParametersClass({this.firstName, this.lastName});
}

@jsonSerializable
class IgnoredFieldClass {
  String firstName;

  @JsonProperty(ignore: true)
  String lastName;

  IgnoredFieldClass(this.firstName, this.lastName);
}

@jsonSerializable
class Immutable {
  final int id;
  final String name;
  final Car car;

  const Immutable(this.id, this.name, this.car);
}

testConstructors() {
  group("[Verify class constructors support]", () {
    final String json = '{"firstName":"Bob","lastName":"Marley"}';

    test("NamedParametersClass class", () {
      // given
      var instance = NamedParametersClass(firstName: "Bob", lastName: "Marley");
      // when
      final String target = JsonMapper.serialize(instance, '');
      // then
      expect(target, json);
    });

    test("PartiallyOptionalParametersClass class", () {
      // given
      var instance = PartiallyOptionalParametersClass("Bob", "Marley");
      // when
      final String target = JsonMapper.serialize(instance, '');
      // then
      expect(target, json);
    });

    test("OptionalParametersClass class", () {
      // given
      var instance = OptionalParametersClass("Bob", "Marley");
      // when
      final String target = JsonMapper.serialize(instance, '');
      // then
      expect(target, json);
    });

    test("PositionalParametersClass class", () {
      // given
      var instance = PositionalParametersClass("Bob", "Marley");
      // when
      final String target = JsonMapper.serialize(instance, '');
      // then
      expect(target, json);
    });

    test("Derived class", () {
      // given
      final String json = '{"value":"Bob"}';
      final Derived target = Derived("Bob");
      // when
      Derived instance = JsonMapper.deserialize(json);
      String targetJson = JsonMapper.serialize(target, '');
      // then
      expect(instance.value, "Bob");
      expect(targetJson, json);
    });

    test("StringListClass class", () {
      // given
      // when
      StringListClass instance =
          JsonMapper.deserialize('{"list":["Bob","Marley"]}');
      // then
      expect(instance.list.length, 2);
    });

    test("IgnoredFieldClass class", () {
      // given
      var instance = IgnoredFieldClass("Bob", "Marley");
      // when
      var target = JsonMapper.serialize(instance, '');
      // then
      expect(target, '{"firstName":"Bob"}');

      // when
      IgnoredFieldClass instance2 = JsonMapper.deserialize(json);
      // then
      expect(instance2.firstName, "Bob");
      expect(instance2.lastName, null);
    });

    test("Immutable class", () {
      // given
      final String immutableJson = '''{
 "id": 1,
 "name": "Bob",
 "car": {
  "modelName": "Audi",
  "color": "Color.Green"
 }
}''';
      Immutable i = Immutable(1, 'Bob', Car('Audi', Color.Green));
      // when
      final String target = JsonMapper.serialize(i);
      // then
      expect(target, immutableJson);

      // when
      final Immutable ic = JsonMapper.deserialize(immutableJson);
      // then
      expect(JsonMapper.serialize(ic), immutableJson);
    });
  });
}
