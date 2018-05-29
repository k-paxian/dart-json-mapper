library json_mapper.test;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import 'package:dart_json_mapper/json_mapper.dart';
import "package:test/test.dart";

import 'test.reflectable.dart'; // Import generated code.

enum Color { Red, Blue, Green, Brown, Yellow, Black, White }

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

  @JsonProperty(
      name: 'last_promotion_date',
      converter: dateConverter,
      converterParams: {'format': 'MM-dd-yyyy H:m:s'})
  DateTime lastPromotionDate = new DateTime(2008, 05, 13, 22, 33, 44);

  @JsonProperty(
      name: 'hire_date',
      converter: dateConverter,
      converterParams: {'format': 'MM/dd/yyyy'})
  DateTime hireDate = new DateTime(2003, 02, 28);

  @JsonProperty(ignore: true)
  bool married = true;

  String name = "Forest";

  @JsonProperty(converter: numberConverter)
  num salary = 1200000;

  num dob;
  num age = 36;
  var lastName = "Gump";

  @JsonProperty(name: 'eye_color', enumValues: Color.values)
  Color eyeColor = Color.Blue;

  @JsonProperty(enumValues: Color.values, converter: enumConverterNumeric)
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
 "last_promotion_date": "05-13-2008 22:33:44",
 "hire_date": "02/28/2003",
 "name": "Forest",
 "salary": "1,200,000",
 "dob": null,
 "age": 36,
 "lastName": "Gump",
 "eye_color": "Color.Blue",
 "hairColor": 3,
 "vehicles": [
  {
   "modelName": "Tesla",
   "color": "Color.Black"
  },
  {
   "modelName": "BMW",
   "color": "Color.Red"
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
    String json = '''{"modelName":"Tesla","color":"Color.Black"}''';
    Car etalonCar = new Car("Tesla", Color.Black);
    // when
    Car targetCar = JsonMapper.deserialize(json, Car);
    // then
    expect(targetCar.model, etalonCar.model);
    expect(targetCar.color, etalonCar.color);
  });
}
