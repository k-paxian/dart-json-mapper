part of json_mapper_flutter.test;

@jsonSerializable
class FlutterData {
  Color color;

  FlutterData(this.color);
}

final compactOptions = SerializationOptions(indent: '');

void testBasics() {
  test('Color type', () {
    // given
    final color = Color(0x3f4f5f);
    final rawString = '#3F4F5F';
    final json = '{"color":"${rawString}"}';

    // when
    final targetJson = JsonMapper.serialize(FlutterData(color), compactOptions);
    // then
    expect(targetJson, json);

    // when
    final target = JsonMapper.deserialize<FlutterData>(json);
    // then
    expect(target.color, color);
  });
}
