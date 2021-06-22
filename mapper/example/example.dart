import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable, JsonProperty, enumConverterNumeric;

import 'example.mapper.g.dart' show initializeJsonMapper;

@jsonSerializable
enum Color { red, blue, green, brown, yellow, black, white }

@jsonSerializable
class Car {
  @JsonProperty(name: 'modelName')
  String model;

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
  DateTime? lastPromotionDate;

  @JsonProperty(name: 'hire_date')
  DateTime hireDate = DateTime(2003, 02, 28);

  bool married = true;
  String name = 'Forest';

  @JsonProperty(ignore: true)
  num? salary;

  num? dob;
  num age = 36;
  var lastName = 'Gump';

  @JsonProperty(name: 'eye_color')
  Color eyeColor = Color.blue;

  @JsonProperty(converter: enumConverterNumeric)
  Color hairColor = Color.brown;

  List<Car> vehicles = [Car('Tesla', Color.black), Car('BMW', Color.red)];

  String get fullName => '$name $lastName';
}

void main() {
  initializeJsonMapper();

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
 "eye_color": "Blue",
 "hairColor": 3,
 "vehicles": [
  {
   "modelName": "Tesla",
   "color": "Black"
  },
  {
   "modelName": "BMW",
   "color": "Red"
  }
 ]
}''';

  // Serialize
  print(JsonMapper.serialize(Person()));

  // Deserialize
  print(JsonMapper.deserialize<Person>(personJson));
}
