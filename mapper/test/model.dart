part of json_mapper.test;

final compactOptions = SerializationOptions(indent: '');

enum Color { Red, Blue, Gray, GrayMetallic, Green, Brown, Yellow, Black, White }

@jsonSerializable
class Car {
  @JsonProperty(name: 'modelName')
  String model;

  @JsonProperty(enumValues: Color.values)
  Color color;

  @JsonProperty(ignoreIfNull: true)
  Car replacement;

  Car(this.model, this.color);
}

extension TitledCar on Car {
  String get title => '${model}-${color}';
}

@jsonSerializable
class Person {
  List<String> skills = ['Go', 'Dart', 'Flutter'];

  List<DateTime> specialDates = [
    DateTime(2013, 02, 28),
    DateTime(2023, 02, 28),
    DateTime(2003, 02, 28)
  ];

  @JsonProperty(
      name: 'last_promotion_date',
      converterParams: {'format': 'MM-dd-yyyy H:m:s'})
  DateTime lastPromotionDate = DateTime(2008, 05, 13, 22, 33, 44);

  @JsonProperty(name: 'hire_date', converterParams: {'format': 'MM/dd/yyyy'})
  DateTime hireDate = DateTime(2003, 02, 28);

  @JsonProperty(ignore: true)
  bool married = true;

  bool active = true;

  String name = 'Forest';

  @JsonProperty(converterParams: {'format': '##.##'})
  num salary = 1200000.246;
  num dob;
  num age = 36;

  var lastName = 'Gump';

  dynamic dyn = 'dyn';
  dynamic dynNum = 9;
  dynamic dynBool = false;

  Map properties = {'first': 'partridge', 'cash': 23000, 'required': true};

  Map<String, dynamic> map = {
    'first': 'partridge',
    'cash': 23000,
    'required': true
  };

  Symbol sym = Symbol('foo');

  @JsonProperty(enumValues: Color.values)
  List<Color> favouriteColours = [Color.Black, Color.White];

  @JsonProperty(name: 'eye_color', enumValues: Color.values)
  Color eyeColor = Color.Blue;

  @JsonProperty(enumValues: Color.values, converter: enumConverterNumeric)
  Color hairColor = Color.Brown;

  List<Car> vehicles = [Car('Tesla', Color.Black), Car('BMW', Color.Red)];

  String get fullName => '${name} ${lastName}';

  Person();
}

enum BusinessType { Private, Public }

@jsonSerializable
@Json(typeNameProperty: 'typeName')
abstract class Business {
  String name;
  @JsonProperty(enumValues: BusinessType.values)
  BusinessType type = BusinessType.Private;
}

@jsonSerializable
class Hotel extends Business {
  int stars;

  Hotel(this.stars);
}

@jsonSerializable
class Startup extends Business {
  int userCount;

  Startup(this.userCount);
}

@jsonSerializable
class Stakeholder {
  String fullName;
  List<Business> businesses;

  Stakeholder(this.fullName, this.businesses);
}

@jsonSerializable
class GettersOnly {
  int _nextId = 0;
  String get nextCatId => 'c${_nextId++}';
  String get nextDogId => 'h${_nextId++}';
}
