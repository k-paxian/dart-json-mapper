part of json_mapper.test;

testValueDecorators() {
  group("[Verify value decorators]", () {
    test("Custom List<Car> value decorator", () {
      // given
      // when
      JsonMapper.registerValueDecorator(
          List<Car>().runtimeType, (value) => value.cast<Car>());

      List<Car> target = JsonMapper.deserialize(
          '[{"modelName": "Audi", "color": "Color.Green"}]');

      // then
      expect(target.length, 1);
      expect(target[0], TypeMatcher<Car>());
      expect(target[0].model, "Audi");
      expect(target[0].color, Color.Green);
    });
  });
}
