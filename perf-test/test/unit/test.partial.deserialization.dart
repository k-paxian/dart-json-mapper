import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart'
    show defaultOptions, Car, GettersOnly, Person;

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
  @JsonProperty(
    name: ['id', 'id_a', 'id_b', 'id_test'],
  )
  int id = 0;
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

@jsonSerializable
class CarsPrefix {
  @JsonProperty(name: 'pagination', flatten: true)
  Pagination? pagination;

  List<Car>? cars;
}

@jsonSerializable
@Json(caseStyle: CaseStyle.snake)
class CarsPrefixSnake {
  @JsonProperty(name: 'pagination', flatten: true)
  Pagination? pagination;

  List<Car>? cars;
}

void testPartialDeserialization() {
  group('[Verify partial processing]', () {
    test('Flattening pagination info with properties prefix - camel by default',
        () {
      // given
      final json = '''{
 "paginationLimit": 100,
 "paginationOffset": 200,
 "paginationTotal": 1053,
 "cars": [
  {
   "modelName": "Tesla X",
   "color": "red"
  }
 ]
}''';
      // when
      final target = JsonMapper.deserialize<CarsPrefix>(json)!;
      final targetJson = JsonMapper.serialize(target, defaultOptions);

      // then
      expect(targetJson, json);
      expect(target.pagination!.limit, 100);
      expect(target.pagination!.offset, 200);
      expect(target.pagination!.total, 1053);
      expect(target.cars!.length, 1);
      expect(target.cars!.first.model, 'Tesla X');
    });

    test(
        'Flattening pagination info with properties prefix - kebab as global option',
        () {
      // given
      final json = '''{
 "pagination-limit": 100,
 "pagination-offset": 200,
 "pagination-total": 1053,
 "cars": [
  {
   "model-name": "Tesla X",
   "color": "red"
  }
 ]
}''';
      // when
      final target = JsonMapper.deserialize<CarsPrefix>(
          json, DeserializationOptions(caseStyle: CaseStyle.kebab))!;
      final targetJson = JsonMapper.serialize(target,
          SerializationOptions(caseStyle: CaseStyle.kebab, indent: ' '));

      // then
      expect(targetJson, json);
      expect(target.pagination!.limit, 100);
      expect(target.pagination!.offset, 200);
      expect(target.pagination!.total, 1053);
      expect(target.cars!.length, 1);
      expect(target.cars!.first.model, 'Tesla X');
    });

    test(
        'Flattening pagination info with properties prefix - snake as class option',
        () {
      // given
      final json = '''{
 "pagination_limit": 100,
 "pagination_offset": 200,
 "pagination_total": 1053,
 "cars": [
  {
   "model_name": "Tesla X",
   "color": "red"
  }
 ]
}''';
      // when
      final target = JsonMapper.deserialize<CarsPrefixSnake>(json)!;
      final targetJson = JsonMapper.serialize(target, defaultOptions);

      // then
      expect(targetJson, json);
      expect(target.pagination!.limit, 100);
      expect(target.pagination!.offset, 200);
      expect(target.pagination!.total, 1053);
      expect(target.cars!.length, 1);
      expect(target.cars!.first.model, 'Tesla X');
    });

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
      final targetJson = JsonMapper.serialize(target, defaultOptions);

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
      final json = JsonMapper.serialize(instance);
      // then
      expect(json, '''{"nextCatId":"c0","nextDogId":"h1"}''');
    });

    test('Field aliases, main ?? alias1 ?? alias2 ?? ...', () {
      // given
      List<List<dynamic>> cases = [
        ['''{}''', 0],
        ['''{"id": 90}''', 90],
        ['''{"id": 90, "id_a": 91}''', 90],
        ['''{"id_a": 90, "id_b": 91, "id_test": 92}''', 90],
        ['''{"id_b": 90, "id_test": 91}''', 90],
        ['''{"id_a": 91}''', 91],
        ['''{"id_test": 92}''', 92],
        ['''{"id_b": 93}''', 93],
      ];
      for (final testCase in cases) {
        // when
        final target = JsonMapper.deserialize<FieldAliasObject>(testCase.first);

        // then
        expect(target!.id, testCase.last);
      }
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
      final json2 = JsonMapper.serialize(instance);
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
      final targetJson = JsonMapper.serialize(instance);

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
      final targetJson =
          JsonMapper.serialize(IgnoreMembers(name: 'Bob', title: 'Marley'));

      // then
      expect(targetJson, expectedJson);
    });
  });
}
