import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart'
    show Car, Color, Person, personJson, defaultOptions;

void testIntegration() {
  group('[Verify end to end serialization <=> deserialization]', () {
    test('toMap/fromMap', () {
      // given
      final car = Car('Tesla S3', Color.black);
      // when
      final targetMap = JsonMapper.toMap(car)!;
      final targetCar = JsonMapper.fromMap<Car>(targetMap)!;

      // then
      expect(targetMap, TypeMatcher<Map<String, dynamic>>());
      expect(targetMap['modelName'], 'Tesla S3');
      expect(targetMap['color'], 'black');

      expect(targetCar, TypeMatcher<Car>());
      expect(targetCar.model, 'Tesla S3');
      expect(targetCar.color, Color.black);
    });

    test('Object clone', () {
      // given
      final car = Car('Tesla S3', Color.black);
      // when
      final clone = JsonMapper.clone(car)!;

      // then
      expect(clone == car, false);
      expect(clone.color == car.color, true);
      expect(clone.model == car.model, true);
    });

    test('Object copyWith', () {
      // given
      final car = Car('Tesla S3', Color.black);

      // when
      final instance = JsonMapper.copyWith(car, {'color': 'blue'})!;

      // then
      expect(instance == car, false);
      expect(instance.color, Color.blue);
      expect(instance.model, car.model);
    });

    test('Serialize to target template map', () {
      // given
      final template = {'a': 'a', 'b': true};
      // when
      final json = JsonMapper.serialize(Car('Tesla S3', Color.black),
          SerializationOptions(indent: '', template: template));

      // then
      expect(json,
          '''{"a":"a","b":true,"modelName":"Tesla S3","color":"black"}''');
    });

    test('Serialization', () {
      // given
      // when
      final json = JsonMapper.serialize(Person(), defaultOptions);
      // then
      expect(json, personJson);
    });

    test('Serialization <=> Deserialization', () {
      // given
      // when
      final stopwatch = Stopwatch()..start();
      final person = JsonMapper.deserialize<Person>(personJson);
      final deserializationMs = stopwatch.elapsedMilliseconds;
      final json = JsonMapper.serialize(person, defaultOptions);
      print('Deserialization executed in $deserializationMs ms');
      print(
          'Serialization executed in ${stopwatch.elapsedMilliseconds - deserializationMs} ms');
      // then
      expect(json, personJson);
    });

    test('Deserialize with type property', () {
      // given
      final carJson = '{"modelName": "Tesla S3", "color": "black"}';
      final type = Car;

      // when
      final instance =
          JsonMapper.deserialize(carJson, DeserializationOptions(type: type));

      // then
      expect(instance.runtimeType, Car);
      expect(instance.color, Color.black);
      expect(instance.model, 'Tesla S3');
    });
  });
}
