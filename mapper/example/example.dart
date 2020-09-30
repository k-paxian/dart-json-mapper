import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable, JsonProperty, enumConverterNumeric;

import 'example.mapper.g.dart' show initializeReflectable;

enum Color { Red, Blue, Green, Brown, Yellow, Black, White }

@jsonSerializable
class Car {
  @JsonProperty(name: 'modelName')
  String model;

  @JsonProperty(enumValues: Color.values)
  Color color;

  Car(this.model, this.color);

  @override
  String toString() {
    return 'Car{model: $model, color: $color}';
  }
}

@jsonSerializable
class Person {
  List<String> skills = ['Go', 'Dart', 'Flutter'];

  @JsonProperty(name: 'last_promotion_date', ignore: true)
  DateTime lastPromotionDate;

  @JsonProperty(name: 'hire_date')
  DateTime hireDate = DateTime(2003, 02, 28);

  bool married = true;
  String name = 'Forest';

  @JsonProperty(ignore: true)
  num salary;

  num dob;
  num age = 36;
  var lastName = 'Gump';

  @JsonProperty(name: 'eye_color', enumValues: Color.values)
  Color eyeColor = Color.Blue;

  @JsonProperty(enumValues: Color.values, converter: enumConverterNumeric)
  Color hairColor = Color.Brown;

  List<Car> vehicles = [Car('Tesla', Color.Black), Car('BMW', Color.Red)];

  String get fullName => '${name} ${lastName}';

  @override
  String toString() {
    return 'Person{skills: $skills, lastPromotionDate: '
        '$lastPromotionDate, hireDate: $hireDate, married: $married, name: '
        '$name, salary: $salary, dob: $dob, age: $age, lastName: $lastName, '
        'eyeColor: $eyeColor, hairColor: $hairColor, vehicles: $vehicles}';
  }
}

void main() {
  initializeReflectable();

  final personJson = '''{
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

  // Serialize
  print(JsonMapper.serialize(Person()));

  // Deserialize
  print(JsonMapper.deserialize<Person>(personJson));
}
