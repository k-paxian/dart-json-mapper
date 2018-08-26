part of json_mapper.test;

testIntegration() {
  group("[Verify end to end serialization <=> deserialization]", () {
    test("Serialization", () {
      // given
      // when
      final String target = JsonMapper.serialize(Person());
      // then
      expect(target, personJson);
    });

    test("Serialization <=> Deserialization", () {
      // given
      // when
      final Person target = JsonMapper.deserialize(personJson, Person);
      // then
      expect(JsonMapper.serialize(target), personJson);
    });
  });
}
