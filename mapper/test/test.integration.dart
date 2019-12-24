part of json_mapper.test;

void testIntegration() {
  group('[Verify end to end serialization <=> deserialization]', () {
    test('toMap/fromMap', () {
      // given
      final car = Car('Tesla S3', Color.Black);
      // when
      final targetMap = JsonMapper.toMap(car);
      final targetCar = JsonMapper.fromMap<Car>(targetMap);

      // then
      expect(targetMap, TypeMatcher<Map<String, dynamic>>());
      expect(targetMap['modelName'], 'Tesla S3');
      expect(targetMap['color'], 'Color.Black');

      expect(targetCar, TypeMatcher<Car>());
      expect(targetCar.model, 'Tesla S3');
      expect(targetCar.color, Color.Black);
    });

    test('Object clone', () {
      // given
      final car = Car('Tesla S3', Color.Black);
      // when
      final clone = JsonMapper.clone(car);

      // then
      expect(clone == car, false);
      expect(clone.color == car.color, true);
      expect(clone.model == car.model, true);
    });

    test('Serialize to target template map', () {
      // given
      final template = {'a': 'a', 'b': true};
      // when
      final json = JsonMapper.serialize(
          Car('Tesla S3', Color.Black), '', null, template);

      // then
      expect(json,
          '''{"a":"a","b":true,"modelName":"Tesla S3","color":"Color.Black"}''');
    });

    test('Serialization', () {
      // given
      // when
      final json = JsonMapper.serialize(Person());
      // then
      expect(json, personJson);
    });

    test('Serialization <=> Deserialization', () {
      // given
      JsonMapper.registerValueDecorator<List<Color>>(
          (value) => value.cast<Color>());
      // when
      final stopwatch = Stopwatch()..start();
      final person = JsonMapper.deserialize<Person>(personJson);
      final deserializationMs = stopwatch.elapsedMilliseconds;
      final json = JsonMapper.serialize(person);
      print('Deserialization executed in ${deserializationMs} ms');
      print(
          'Serialization executed in ${stopwatch.elapsedMilliseconds - deserializationMs} ms');
      // then
      expect(json, personJson);
    });
  });
}
