part of json_mapper.test;

void testExtensions() {
  group('[Verify extensions processing]', () {
    test('Color extension ColorModifier', () {
      // given
      final color = Color.Gray;
      // when
      final metallicColorJson = JsonMapper.serialize(color.metallic);
      // then
      expect(metallicColorJson, '''"Color.GrayMetallic"''');
    });
  });
}
