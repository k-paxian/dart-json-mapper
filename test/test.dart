library json_mapper.test;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import 'package:dart_json_mapper/json_mapper.dart';
import "package:test/test.dart";

import 'test.reflectable.dart';

@JsonSerializable()
enum Color {
  Red,
  Blue,
  Green,
  Brown,
  Yellow,
  Black,
  White
}

@JsonSerializable()
class Car {
  @JsonProperty(name: 'modelName')
  String model;

  @JsonProperty(enumValues: Color.values)
  Color color;

  Car([this.model, this.color]);
}

@JsonSerializable()
class Person {
  List<String> skills = ['Go', 'Dart', 'Flutter'];

  @JsonProperty(name: 'last_promotion_date', ignore: true)
  DateTime lastPromotionDate;

  @JsonProperty(name: 'hire_date', converter: dateConverter)
  DateTime hireDate = new DateTime(2003, 02, 28);

  bool married = true;
  String name = "Forest";

  @JsonProperty(ignore: true)
  num salary;

  num dob;
  num age = 36;
  var lastName = "Gump";

  @JsonProperty(name: 'eye_color', enumValues: Color.values)
  Color eyeColor = Color.Blue;

  @JsonProperty(enumValues: Color.values)
  Color hairColor = Color.Brown;

  @JsonProperty(type: Car)
  List<Car> vehicles = [
    new Car("Tesla", Color.Black),
    new Car("BMW", Color.Red)
  ];

  String get fullName => "${name} ${lastName}";

  Person();
}

void main() {
  initializeReflectable();

  final String personJson = '''{
 "skills": [
  "Go",
  "Dart",
  "Flutter"
 ],
 "hire_date": "2003-02-28",
 "married": true,
 "name": "Forest",
 "dob": null,
 "age": 36,
 "lastName": "Gump",
 "eye_color": 1,
 "hairColor": 3,
 "vehicles": [
  {
   "modelName": "Tesla",
   "color": 5
  },
  {
   "modelName": "BMW",
   "color": 0
  }
 ]
}''';

  test("Verify serialization to JSON", () {
    // given
    // when
    String targetJson = JsonMapper.serialize(new Person());
    // then
    expect(targetJson, personJson);
  });

  test("Verify deserialization from JSON", () {
    // given
    Person etalon = new Person();
    // when
    Person target = JsonMapper.deserialize(personJson, Person);
    // then
    expect(target.fullName, etalon.fullName);
    expect(target.eyeColor, etalon.eyeColor);
    expect(JsonMapper.serialize(target), personJson);
  });

  test("Verify simple deserialization from JSON", () {
    // given
    String json = '''{"modelName":"Tesla","color":5}''';
    Car etalonCar = new Car("Tesla", Color.Black);
    // when
    Car targetCar = JsonMapper.deserialize(json, Car);
    // then
    expect(targetCar.model, etalonCar.model);
    expect(targetCar.color, etalonCar.color);
  });
}