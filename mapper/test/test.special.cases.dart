part of json_mapper.test;

@jsonSerializable
class A {
  B content;
}

@jsonSerializable
class B {
  List<A> content;
}

void testSpecialCases() {
  group('[Verify special cases]', () {
    test('A/B inception deserialization', () {
      // given
      final json = '{"content":{"content":[]}}';
      final adapter = JsonMapperAdapter(
          valueDecorators: {typeOf<List<A>>(): (value) => value.cast<A>()});
      JsonMapper().useAdapter(adapter);

      // when
      final target = JsonMapper.deserialize<A>(json);

      // then
      expect(target, TypeMatcher<A>());
      expect(target.content, TypeMatcher<B>());
      expect(target.content.content, TypeMatcher<List<A>>());

      JsonMapper().removeAdapter(adapter);
    });
  });
}
