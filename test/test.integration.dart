part of json_mapper.test;

testIntegration() {
  group("[Verify e2e serialization <=> deserialization]", () {
    test("Serialization to JSON", () {
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

    test("Immutable class serialization <=> deserialization", () {
      // given
      final String immutableJson = '''{
 "id": 1,
 "name": "Bob",
 "car": {
  "modelName": "Audi",
  "color": "Color.Green"
 }
}''';
      Immutable i =
          Immutable(id: 1, name: 'Bob', car: Car('Audi', Color.Green));
      // when
      final String target = JsonMapper.serialize(i);
      // then
      expect(target, immutableJson);

      // when
      final Immutable ic = JsonMapper.deserialize(immutableJson, Immutable);
      // then
      expect(JsonMapper.serialize(ic), immutableJson);
    });
  });
}
