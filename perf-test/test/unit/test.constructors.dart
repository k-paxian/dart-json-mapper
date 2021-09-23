import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart'
    show compactOptions, Car, Color, Immutable;

@jsonSerializable
class BusinessObject {
  final bool logisticsChecked;
  final bool logisticsOK;

  BusinessObject()
      : logisticsChecked = false,
        logisticsOK = true;

  @jsonConstructor
  BusinessObject.fromJson(
      @JsonProperty(name: 'LogistikTeileInOrdnung') String? processed)
      : logisticsChecked = processed != null && processed != 'null',
        logisticsOK = processed == 'true';
}

@jsonSerializable
class LogisticsItem {
  final bool logisticsChecked;
  final bool logisticsOK;

  LogisticsItem(@JsonProperty(name: 'LogistikTeileInOrdnung') String? processed)
      : logisticsChecked = processed != null && processed != 'null',
        logisticsOK = processed == 'true';
}

@jsonSerializable
class User {
  String? email;
}

@jsonSerializable
class Fo {
  final Bar? bar;
  final String message;

  Fo(this.bar, this.message);
}

@jsonSerializable
class Bar {
  final Baz baz;

  Bar(this.baz);
}

@jsonSerializable
class Baz {}

@jsonSerializable
class Base<T> {
  final T value;

  Base(this.value);
}

@jsonSerializable
class Derived extends Base<String> {
  Derived(String value) : super(value);
}

@jsonSerializable
class Pt {
  Pt();
}

@jsonSerializable
class PtDerived extends Base<Pt> {
  PtDerived(Pt value) : super(value);
}

@jsonSerializable
class PtDerived2 extends Base<Pt?> {
  final Pt pt;
  PtDerived2(this.pt) : super(null);
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
  String? firstName;
  String? lastName;

  OptionalParametersClass([this.firstName, this.lastName]);
}

@jsonSerializable
class PartiallyOptionalParametersClass {
  String firstName;
  String? lastName;

  PartiallyOptionalParametersClass(this.firstName, [this.lastName]);
}

@jsonSerializable
class NamedParametersClass {
  String? firstName;
  String? lastName;

  NamedParametersClass({this.firstName, this.lastName});
}

@jsonSerializable
@Json(ignoreNullMembers: true)
class IgnoreNullMembersClass {
  String? firstName;
  String? lastName;
  String? middleName;

  IgnoreNullMembersClass({this.firstName, this.middleName, this.lastName});
}

@jsonSerializable
class IgnoreNullMembersFromOptionsClass {
  String? firstName;
  String? lastName;
  String? middleName;

  IgnoreNullMembersFromOptionsClass(
      {this.firstName, this.middleName, this.lastName});
}

@jsonSerializable
class IgnoredFieldClass {
  String? firstName;

  @JsonProperty(ignore: true)
  String? lastName;

  @JsonProperty(ignoreIfNull: true)
  String? middleName;

  IgnoredFieldClass({this.firstName, this.middleName, this.lastName});
}

@jsonSerializable
class IgnoredFieldClassWoConstructor {
  String? firstName;

  @JsonProperty(ignore: true)
  String? lastName;

  @JsonProperty(ignoreIfNull: true)
  String? middleName;
}

@jsonSerializable
@Json(processAnnotatedMembersOnly: true)
class ImmutableDefault2 {
  @JsonProperty(defaultValue: 1)
  final int? id;
  final String? name;
  final Car? car;

  const ImmutableDefault2({this.id, this.name, this.car});
}

const customConverter = CustomConverter();

class CustomConverter implements ICustomConverter {
  const CustomConverter();
  @override
  dynamic fromJSON(dynamic jsonValue, [DeserializationContext? context]) {
    return jsonValue + 1;
  }

  @override
  dynamic toJSON(dynamic object, [SerializationContext? context]) {
    throw UnimplementedError();
  }
}

@jsonSerializable
class Record {
  @JsonProperty(name: 'id')
  int id;

  int number;

  @jsonConstructor
  Record.json(this.id, @JsonProperty(converter: customConverter) this.number);

  @override
  String toString() {
    return '''{"id": $id, "number": $number}''';
  }
}

@jsonSerializable
class GrandParent {
  Parent? child;
}

@jsonSerializable
class Parent {
  String? lastName;
  List<Child> children = [];

  @JsonProperty(name: '..')
  GrandParent? parent;
}

@jsonSerializable
class Child {
  String? firstName;

  @JsonProperty(name: '..')
  Parent parent;

  Child(this.parent);
}

@jsonSerializable
class Parent2 {
  String? lastName;
  List<Child2> children = [];
}

@jsonSerializable
class Child2 {
  String? firstName;

  @JsonProperty(name: '..')
  Parent2 parent;

  @jsonConstructor
  Child2.json(this.parent);
}

@jsonSerializable
class Parent3 {
  String? lastName;
  List<Child3> children = [];
}

@jsonSerializable
class Child3 {
  String? firstName;

  @JsonProperty(name: '..')
  Parent3? parent;
}

void testConstructors() {
  group('[Verify class constructors support]', () {
    final json = '{"firstName":"Bob","lastName":"Marley"}';

    test('NamedParametersClass class', () {
      // given
      var instance = NamedParametersClass(firstName: 'Bob', lastName: 'Marley');

      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      final targetInstance = JsonMapper.deserialize<NamedParametersClass>(json);

      // then
      expect(target, json);
      expect(targetInstance, TypeMatcher<NamedParametersClass>());
    });

    test('PartiallyOptionalParametersClass class', () {
      // given
      var instance = PartiallyOptionalParametersClass('Bob', 'Marley');
      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, json);
    });

    test('OptionalParametersClass class', () {
      // given
      var instance = OptionalParametersClass('Bob', 'Marley');
      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, json);
    });

    test('PositionalParametersClass class', () {
      // given
      var instance = PositionalParametersClass('Bob', 'Marley');
      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, json);
    });

    test('Should pick up meta from constructor parameter', () {
      // given
      var json = '''{"id": 42,  "number": 2}''';
      // when
      final target = JsonMapper.deserialize<Record>(
          json, DeserializationOptions(processAnnotatedMembersOnly: true))!;
      // then
      expect(target.number, 3);
    });

    test('Nested null value object should be null w/o NPE', () {
      // given
      final json = '{"bar":null,"message":"hello world"}';
      final target = Fo(null, 'hello world');
      // when
      final instance = JsonMapper.deserialize<Fo>(json)!;
      final targetJson = JsonMapper.serialize(target, compactOptions);
      // then
      expect(instance.message, 'hello world');
      expect(targetJson, json);
    });

    test('Derived class', () {
      // given
      final json = '{"value":"Bob"}';
      final target = Derived('Bob');
      final pTarget = PtDerived(Pt());
      final ptTarget2 = PtDerived2(Pt());
      // when
      final instance = JsonMapper.deserialize<Derived>(json)!;
      final targetJson = JsonMapper.serialize(target, compactOptions);
      final pTargetJson = JsonMapper.serialize(pTarget, compactOptions);
      final ptTarget2Json = JsonMapper.serialize(ptTarget2, compactOptions);
      final pTargetBack = JsonMapper.deserialize<PtDerived>(pTargetJson)!;
      final ptTarget2Back = JsonMapper.deserialize<PtDerived2>(ptTarget2Json)!;
      // then
      expect(instance.value, 'Bob');
      expect(targetJson, json);
      expect(pTargetBack.value, TypeMatcher<Pt>());
      expect(pTargetJson, '{"value":{}}');
      expect(ptTarget2Json, '{"value":null,"pt":{}}');
      expect(ptTarget2Back.pt, TypeMatcher<Pt>());
      expect(ptTarget2Back.value, null);
    });

    test('User class, getter/setter property w/o constructor', () {
      // given
      final user = User();
      user.email = 'a@a.com';
      // when
      final json = JsonMapper.serialize(user, compactOptions);
      final target = JsonMapper.deserialize<User>(json)!;
      // then
      expect(json, '{"email":"a@a.com"}');
      expect(target, TypeMatcher<User>());
      expect(target.email, 'a@a.com');
    });

    test('Annotate constructor params', () {
      // given
      final json = '{"LogistikTeileInOrdnung":"true"}';
      // when
      final instance = JsonMapper.deserialize<LogisticsItem>(json)!;
      // then
      expect(instance.logisticsOK, true);
      expect(instance.logisticsChecked, true);
    });

    test('Annotate json constructor', () {
      // given
      final json = '{"LogistikTeileInOrdnung":"true"}';
      // when
      final instance = JsonMapper.deserialize<BusinessObject>(json)!;
      // then
      expect(instance.logisticsOK, true);
      expect(instance.logisticsChecked, true);
    });

    test('StringListClass class', () {
      // given
      // when
      final instance =
          JsonMapper.deserialize<StringListClass>('{"list":["Bob","Marley"]}')!;
      // then
      expect(instance.list.length, 2);
    });

    test('IgnoreNullMembers class', () {
      // given
      final instance = IgnoreNullMembersClass(firstName: 'Bob');
      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, '{"firstName":"Bob"}');
    });

    test('IgnoreNullMembers as serialization option', () {
      // given
      final instance = IgnoreNullMembersFromOptionsClass(firstName: 'Bob');
      // when
      final target = JsonMapper.serialize(
          instance, SerializationOptions(indent: '', ignoreNullMembers: true));
      // then
      expect(target, '{"firstName":"Bob"}');
    });

    test('processAnnotatedMembersOnly class annotation option', () {
      // given
      final instance = ImmutableDefault2();
      // when
      final target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, '{"id":1}');
    });

    test('IgnoredFieldClass class', () {
      // given
      final json = '{"firstName":"Bob","middleName":"Jr","lastName":"Marley"}';
      var instance = IgnoredFieldClass(
          firstName: 'Bob', middleName: null, lastName: 'Marley');
      // when
      var target = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(target, '{"firstName":"Bob"}');

      // when
      final instance2 = JsonMapper.deserialize<IgnoredFieldClass>(json)!;
      final instance3 =
          JsonMapper.deserialize<IgnoredFieldClassWoConstructor>(json)!;

      // then
      expect(instance2.firstName, 'Bob');
      expect(instance2.middleName, 'Jr');
      expect(instance2.lastName, null);

      expect(instance3.firstName, 'Bob');
      expect(instance3.middleName, 'Jr');
      expect(instance3.lastName, null);
    });

    test('Immutable class', () {
      // given
      final immutableJson = '''{
 "id": 1,
 "name": "Bob",
 "car": {
  "modelName": "Audi",
  "color": "green"
 }
}''';
      final i = Immutable(1, 'Bob', Car('Audi', Color.green));
      // when
      final target = JsonMapper.serialize(i);
      // then
      expect(target, immutableJson);

      // when
      final ic = JsonMapper.deserialize<Immutable>(immutableJson);
      // then
      expect(JsonMapper.serialize(ic), immutableJson);
    });

    test('Back referencing to parent/owner object', () {
      // given
      final gjson = '''{"child":{
  "lastName": "Doe",
  "children": [
    {"firstName": "Eve"},
    {"firstName": "Bob"},
    {"firstName": "Alice"}]
}}''';
      final json = '''{
  "lastName": "Doe",
  "children": [
    {"firstName": "Eve"},
    {"firstName": "Bob"},
    {"firstName": "Alice"}]
}''';
      // when
      final instance = JsonMapper.deserialize<GrandParent>(gjson)!;
      final instance2 = JsonMapper.deserialize<Parent2>(json)!;
      final instance3 = JsonMapper.deserialize<Parent3>(json)!;

      // then
      expect(instance.child!.lastName, "Doe");
      expect(instance.child!.children.length, 3);
      expect(instance.child!.parent, instance);
      expect(instance.child!.children[1].parent, instance.child);
      expect(instance.child!.children[2].parent, instance.child);
      expect(instance.child!.children[0].firstName, 'Eve');
      expect(instance.child!.children[1].firstName, 'Bob');
      expect(instance.child!.children[2].firstName, 'Alice');

      expect(instance2.children[0].parent, instance2);
      expect(instance2.children[1].parent, instance2);
      expect(instance2.children[2].parent, instance2);

      expect(instance3.children[0].parent, instance3);
      expect(instance3.children[1].parent, instance3);
      expect(instance3.children[2].parent, instance3);
    });
  });
}
