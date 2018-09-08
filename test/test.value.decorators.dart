part of json_mapper.test;

testValueDecorators() {
  final String carListJson = '[{"modelName":"Audi","color":"Color.Green"}]';

  group("[Verify value decorators]", () {
    test("Custom Set<Car> value decorator", () {
      // given
      var set = Set<Car>();
      set.add(Car("Audi", Color.Green));

      // when
      String json = JsonMapper.serialize(set, '');

      // then
      expect(json, carListJson);

      // given
      JsonMapper.registerValueDecorator<Set<Car>>(
          (value) => Set<Car>.from(value));

      // when
      Set<Car> target = JsonMapper.deserialize(carListJson);

      // then
      expect(target.length, 1);
      expect(target.first, TypeMatcher<Car>());
      expect(target.first.model, "Audi");
      expect(target.first.color, Color.Green);
    });

    test("Custom List<Car> value decorator", () {
      // given
      JsonMapper.registerValueDecorator<List<Car>>(
          (value) => value.cast<Car>());

      // when
      List<Car> target = JsonMapper.deserialize(carListJson);

      // then
      expect(target.length, 1);
      expect(target[0], TypeMatcher<Car>());
      expect(target[0].model, "Audi");
      expect(target[0].color, Color.Green);
    });
  });
}
