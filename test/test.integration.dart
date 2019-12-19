part of json_mapper.test;

testIntegration() {
  group("[Verify end to end serialization <=> deserialization]", () {
    test("toMap/fromMap", () {
      // given
      final car = Car('Tesla S3', Color.Black);
      // when
      final Map<String, dynamic> targetMap = JsonMapper.toMap(car);
      final Car targetCar = JsonMapper.fromMap(targetMap);

      // then
      expect(targetMap, TypeMatcher<Map<String, dynamic>>());
      expect(targetMap['modelName'], 'Tesla S3');
      expect(targetMap['color'], 'Color.Black');

      expect(targetCar, TypeMatcher<Car>());
      expect(targetCar.model, 'Tesla S3');
      expect(targetCar.color, Color.Black);
    });

    test("Object clone", () {
      // given
      final car = Car('Tesla S3', Color.Black);
      // when
      final clone = JsonMapper.clone(car);

      // then
      expect(clone == car, false);
      expect(clone.color == car.color, true);
      expect(clone.model == car.model, true);
    });

    test("Serialization", () {
      // given
      // when
      final String json = JsonMapper.serialize(Person());
      // then
      expect(json, personJson);
    });

    test("Serialization <=> Deserialization", () {
      // given
      JsonMapper.registerValueDecorator<List<Color>>(
          (value) => value.cast<Color>());
      // when
      Stopwatch stopwatch = Stopwatch()..start();
      final Person person = JsonMapper.deserialize(personJson);
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
