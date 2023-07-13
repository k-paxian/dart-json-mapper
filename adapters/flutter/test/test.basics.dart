part of json_mapper_flutter.test;

/// Sample flutter data class container
@jsonSerializable
class ColorfulItem {
  String name;
  Color color;

  ColorfulItem(this.name, this.color);
}

/// Shorthand for serialization options instance
final compactOptions = SerializationOptions(indent: '');

void testBasics() {
  test('Color type', () {
    // given
    final color = Color(0x003f4f5f);

    // when
    final json = JsonMapper.serialize(ColorfulItem('Item 1', color));
    final target = JsonMapper.deserialize<ColorfulItem>(json)!;

    // then
    expect(target.color, color);
  });
}
