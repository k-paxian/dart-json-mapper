import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart'
    show compactOptions, Car, GettersOnly, Person;

@jsonSerializable
class IgnoreMembers {
  @JsonProperty(ignoreForDeserialization: true)
  String? name;

  @JsonProperty(ignoreForSerialization: true)
  String? title;

  IgnoreMembers({this.name, this.title});
}

@jsonSerializable
class FieldAliasObject {
  // alias ?? fullName ?? name
  @JsonProperty(name: ['alias', 'fullName', 'name'])
  final String? name;

  const FieldAliasObject({
    this.name,
  });
}

@jsonSerializable
abstract class AnyObject {
  @JsonProperty(name: 'in')
  final String? location;

  @jsonConstructor
  AnyObject({
    this.location,
  });
}

@jsonSerializable
class UnmappedProperties extends AnyObject {
  String? name;

  @JsonProperty(ignore: true)
  Map<String, dynamic> extraPropsMap = {};

  @jsonProperty
  void unmappedSet(String name, dynamic value) {
    if (name == 'in') {
      throw Error();
    }

    extraPropsMap[name] = value;
  }

  @jsonProperty
  Map<String, dynamic> unmappedGet() {
    return extraPropsMap;
  }
}

@jsonSerializable
class AllPrivateFields {
  String? _name;
  String? _lastName;

  set name(dynamic value) {
    _name = value;
  }

  String? get name => _name;

  @JsonProperty(name: 'lastName')
  void setLastName(dynamic value) {
    _lastName = value;
  }

  @JsonProperty(name: 'lastName')
  String? getLastName() => _lastName;
}

@jsonSerializable
class Pagination {
  num? limit;
  num? offset;
  num? total;
}

@jsonSerializable
class Cars {
  @JsonProperty(flatten: true)
  Pagination? pagination;

  List<Car>? cars;
}

void testPartialDeserialization() {
  group('[Verify partial processing]', () {
    test('Cars deserialization + flattening pagination info', () {
      // given
      final json = '''{
 "limit": 100,
 "offset": 200,
 "total": 1053,
 "cars": [
  {
   "modelName": "Tesla X",
   "color": "red"
  }
 ]
}''';
      // when
      final target = JsonMapper.deserialize<Cars>(json)!;
      final targetJson = JsonMapper.serialize(target);

      // then
      expect(targetJson, json);
      expect(target.pagination!.limit, 100);
      expect(target.pagination!.offset, 200);
      expect(target.pagination!.total, 1053);
      expect(target.cars!.length, 1);
    });

    test('Person deserialization', () {
      // given
      final partialPersonJson = '''{
 "name": "Bob",
 "lastName": "Marley"
}''';
      // when
      final target = JsonMapper.deserialize<Person>(partialPersonJson)!;
      // then
      expect(target.name, 'Bob'); // set from JSON
      expect(target.lastName, 'Marley'); // set from JSON
      expect(target.fullName, 'Bob Marley'); // set from JSON
      expect(target.skills, ['Go', 'Dart', 'Flutter']); // default value
      expect(target.sym, Symbol('foo')); // default value
    });

    test('Getters only serialization', () {
      // given
      final instance = GettersOnly();
      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(json, '''{"nextCatId":"c0","nextDogId":"h1"}''');
    });

    test('Field aliases, main ?? alias1 ?? alias2 ?? ...', () {
      // given
      final json = '''{"alias":"007"}''';
      final json2 = '''{"alias":null,"fullName":"James Bond"}''';
      final json3 = '''{"name":"Bond"}''';
      final json4 = '''{"name":"Bond","fullName":"James Bond"}''';
      final instance = FieldAliasObject(name: '007');
      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<FieldAliasObject>(json)!;
      final target2 = JsonMapper.deserialize<FieldAliasObject>(json2)!;
      final target3 = JsonMapper.deserialize<FieldAliasObject>(json3)!;
      final target4 = JsonMapper.deserialize<FieldAliasObject>(json4)!;
      // then
      expect(targetJson, json);
      expect(target.name, '007');
      expect(target2.name, 'James Bond');
      expect(target3.name, 'Bond');
      expect(target4.name, 'James Bond');
    });

    test('Unmapped properties deserialization & serialization', () {
      // given
      final json = '''{"in":null,"name":"Bob","extra1":1,"extra2":"xxx"}''';

      // when
      final instance = JsonMapper.deserialize<UnmappedProperties>(json)!;

      // then
      expect(instance.name, 'Bob');
      expect(instance.extraPropsMap['name'], null);
      expect(instance.extraPropsMap['extra1'], 1);
      expect(instance.extraPropsMap['extra2'], 'xxx');

      // when
      final json2 = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(json2, json);
    });

    test('AllPrivateFields deserialization & serialization', () {
      // given
      final json = '''{"name":"Bob","lastName":"Marley"}''';

      // when
      final instance = JsonMapper.deserialize<AllPrivateFields>(json)!;

      // then
      expect(instance.name, 'Bob');
      expect(instance.getLastName(), 'Marley');

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);

      // then
      expect(targetJson, json);
    });

    test('Ignore members for deserialization / serialization', () {
      // given
      final json = '''{"name":"Bob","title":"Marley"}''';

      // when
      final instance = JsonMapper.deserialize<IgnoreMembers>(json)!;

      // then
      expect(instance.name, null);
      expect(instance.title, 'Marley');

      // given
      final expectedJson = '''{"name":"Bob"}''';

      // when
      final targetJson = JsonMapper.serialize(
          IgnoreMembers(name: 'Bob', title: 'Marley'), compactOptions);

      // then
      expect(targetJson, expectedJson);
    });
  });
}
