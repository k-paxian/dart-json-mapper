part of json_mapper.test;

testIntegration() {
  group("[Verify end to end serialization <=> deserialization]", () {
    test("Serialization", () {
      // given
      // when
      final String json = JsonMapper.serialize(Person());
      // then
      expect(json, personJson);
    });

    test("Serialization <=> Deserialization", () {
      // given
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
