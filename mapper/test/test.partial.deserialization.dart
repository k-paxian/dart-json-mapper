part of json_mapper.test;

@jsonSerializable
class UnmappedProperties {
  String name;

  @JsonProperty(ignore: true)
  Map<String, dynamic> extraPropsMap = {};

  @jsonProperty
  void unmappedSet(String name, dynamic value) {
    extraPropsMap[name] = value;
  }

  @jsonProperty
  Map<String, dynamic> unmappedGet() {
    return extraPropsMap;
  }

  UnmappedProperties();
}

void testPartialDeserialization() {
  group('[Verify partial processing]', () {
    test('Person deserialization', () {
      // given
      final partialPersonJson = '''{
 "name": "Bob",
 "lastName": "Marley"
}''';
      // when
      final target = JsonMapper.deserialize<Person>(partialPersonJson);
      // then
      expect(target.name, 'Bob'); // set from JSON
      expect(target.lastName, 'Marley'); // set from JSON
      expect(target.fullName, 'Bob Marley'); // set from JSON
      expect(target.skills, ['Go', 'Dart', 'Flutter']); // default value
      expect(target.sym, Symbol('foo')); // default value
    });

    test('Getters only serialization', () {
      // given
      final instance = GettersOnly();
      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(json, '''{"nextCatId":"c0","nextDogId":"h1"}''');
    });

    test('Unmapped properties deserialization & serialization', () {
      // given
      final json = '''{"name":"Bob","extra1":1,"extra2":"xxx"}''';

      // when
      final instance = JsonMapper.deserialize<UnmappedProperties>(json);

      // then
      expect(instance.name, 'Bob');
      expect(instance.extraPropsMap['name'], null);
      expect(instance.extraPropsMap['extra1'], 1);
      expect(instance.extraPropsMap['extra2'], 'xxx');

      // when
      final json2 = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(json2, json);
    });
  });
}
