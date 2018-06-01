library json_mapper.test;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import 'package:dart_json_mapper/json_mapper.dart';
import "package:test/test.dart";

import 'test.reflectable.dart'; // Import generated code.

enum Color { Red, Blue, Green, Brown, Yellow, Black, White }

@jsonSerializable
class Car {
  @JsonProperty(name: 'modelName')
  String model;

  @JsonProperty(enumValues: Color.values)
  Color color;

  @JsonProperty(type: Car)
  Car replacement;

  Car([this.model, this.color]);
}

@jsonSerializable
class Person {
  List<String> skills = ['Go', 'Dart', 'Flutter'];

  @JsonProperty(converter: dateConverter)
  List<DateTime> specialDates = [
    new DateTime(2013, 02, 28),
    new DateTime(2023, 02, 28),
    new DateTime(2003, 02, 28)
  ];

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

  bool active = true;

  String name = "Forest";

  @JsonProperty(converter: numberConverter)
  num salary = 1200000;

  num dob;
  num age = 36;
  var lastName = "Gump";

  @JsonProperty(enumValues: Color.values)
  List<Color> favouriteColours = [Color.Black, Color.White];

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
 "specialDates": [
  "2013-02-28",
  "2023-02-28",
  "2003-02-28"
 ],
 "last_promotion_date": "05-13-2008 22:33:44",
 "hire_date": "02/28/2003",
 "active": true,
 "name": "Forest",
 "salary": "1,200,000",
 "dob": null,
 "age": 36,
 "lastName": "Gump",
 "favouriteColours": [
  "Color.Black",
  "Color.White"
 ],
 "eye_color": "Color.Blue",
 "hairColor": 3,
 "vehicles": [
  {
   "modelName": "Tesla",
   "color": "Color.Black",
   "replacement": null
  },
  {
   "modelName": "BMW",
   "color": "Color.Red",
   "replacement": null
  }
 ]
}''';

  test("Verify serialization to JSON", () {
    // given
    // when
    final String target = JsonMapper.serialize(new Person());
    // then
    expect(target, personJson);
  });

  test("Verify serialization <=> deserialization", () {
    // given
    // when
    final Person target = JsonMapper.deserialize(personJson, Person);
    // then
    expect(JsonMapper.serialize(target), personJson);
  });

  test("Verify circular reference detection during serialization", () {
    // given
    final Car car = new Car('VW', Color.Blue);
    car.replacement = car;
    try {
      // when
      JsonMapper.serialize(car);
    } catch (error) {
      // then
      expect(error, new isInstanceOf<CircularReferenceError>());
    }
  });
}
