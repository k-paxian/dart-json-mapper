part of json_mapper.test;

testValueDecorators() {
  final String carListJson = '[{"modelName":"Audi","color":"Color.Green"}]';
  final String intListJson = '[1,3,5]';
  final iterableCarDecorator = (value) => value.cast<Car>();

  group("[Verify value decorators]", () {
    test("Set<int> / List<int> using default value decorators", () {
      // when
      Set<int> targetSet = JsonMapper.deserialize(intListJson);
      List<int> targetList = JsonMapper.deserialize(intListJson);

      // then
      expect(targetSet.length, 3);
      expect(targetSet.first, TypeMatcher<int>());
      expect(targetList.length, 3);
      expect(targetList.first, TypeMatcher<int>());
    });

    test("Custom Set<Car> value decorator", () {
      // given
      final Set<Car> set = Set<Car>();
      set.add(Car("Audi", Color.Green));

      // when
      String json = JsonMapper.serialize(set, '');

      // then
      expect(json, carListJson);

      // given
      JsonMapper.registerValueDecorator<Set<Car>>(iterableCarDecorator);

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
      JsonMapper.registerValueDecorator<List<Car>>(iterableCarDecorator);

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
