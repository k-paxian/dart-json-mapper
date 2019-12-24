part of json_mapper.test;

enum Scheme { A, B }

@jsonSerializable
@Json(name: 'default')
@Json(name: '_', scheme: Scheme.B)
@Json(name: 'root', scheme: Scheme.A)
class Object {
  @JsonProperty(name: 'title_test', scheme: Scheme.B)
  String title;

  Object(this.title);
}

void testScheme() {
  group('[Verify scheme processing]', () {
    test('Verify scheme A serialize', () {
      // given
      final instance = Object('Scheme A');
      // when
      final json = JsonMapper.serialize(
          instance, SerializationOptions(indent: '', scheme: Scheme.A));
      // then
      expect(json, '''{"root":{"title":"Scheme A"}}''');
    });

    test('Verify scheme A deserialize', () {
      // given
      final json = '''{"root":{"title":"Scheme A"}}''';
      // when
      final instance = JsonMapper.deserialize<Object>(
          json, DeserializationOptions(scheme: Scheme.A));
      // then
      expect(instance, TypeMatcher<Object>());
      expect(instance.title, 'Scheme A');
    });

    test('Verify scheme B serialize', () {
      // given
      final instance = Object('Scheme B');
      // when
      final json = JsonMapper.serialize(
          instance, SerializationOptions(indent: '', scheme: Scheme.B));
      // then
      expect(json, '''{"_":{"title_test":"Scheme B"}}''');
    });

    test('Verify scheme B deserialize', () {
      // given
      final json = '''{"_":{"title_test":"Scheme B"}}''';
      // when
      final instance = JsonMapper.deserialize<Object>(
          json, DeserializationOptions(scheme: Scheme.B));
      // then
      expect(instance, TypeMatcher<Object>());
      expect(instance.title, 'Scheme B');
    });

    test('Verify NO scheme serialize', () {
      // given
      final instance = Object('No Scheme');
      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(json, '''{"default":{"title":"No Scheme"}}''');
    });

    test('Verify NO scheme deserialize', () {
      // given
      final json = '''{"default":{"title":"No Scheme"}}''';
      // when
      final instance = JsonMapper.deserialize<Object>(json);
      // then
      expect(instance, TypeMatcher<Object>());
      expect(instance.title, 'No Scheme');
    });
  });
}
