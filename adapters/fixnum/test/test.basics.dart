part of json_mapper_fixnum.test;

@jsonSerializable
class Int32IntData {
  Int32 int32;

  Int32IntData(this.int32);
}

@jsonSerializable
class Int64IntData {
  Int64 int64;

  Int64IntData(this.int64);
}

final compactOptions = SerializationOptions(indent: '');

void testBasics() {
  test('Int32 converter', () {
    // given
    final rawString = '1234567890';
    final json = '{"int32":${rawString}}';

    // when
    final targetJson = JsonMapper.serialize(
        Int32IntData(Int32.parseInt(rawString)), compactOptions);
    // then
    expect(targetJson, json);

    // when
    final target = JsonMapper.deserialize<Int32IntData>(json);
    // then
    expect(rawString, target.int32.toString());
  });

  test('Int64 converter', () {
    // given
    final rawString = '1234567890123456789';
    final json = '{"int64":${rawString}}';

    // when
    final targetJson = JsonMapper.serialize(
        Int64IntData(Int64.parseInt(rawString)), compactOptions);
    // then
    expect(targetJson, json);

    // when
    final target = JsonMapper.deserialize<Int64IntData>(json);
    // then
    expect(rawString, target.int64.toString());
  });

  test('List<Int32>', () {
    // given
    final json = '[2112454933,2112454934]';

    // when
    final instance = JsonMapper.deserialize<List<Int32>>(json);
    // then
    expect(instance, TypeMatcher<List<Int32>>());
    expect(instance[0], Int32(2112454933));
    expect(instance[1], Int32(2112454934));

    // when
    final targetJson = JsonMapper.serialize(instance, compactOptions);
    // then
    expect(targetJson, json);
  });

  test('Set<Int32>', () {
    // given
    final json = '[2112454933,2112454934]';

    // when
    final instance = JsonMapper.deserialize<Set<Int32>>(json);
    // then
    expect(instance, TypeMatcher<Set<Int32>>());
    expect(instance.elementAt(0), Int32(2112454933));
    expect(instance.elementAt(1), Int32(2112454934));

    // when
    final targetJson = JsonMapper.serialize(instance, compactOptions);
    // then
    expect(targetJson, json);
  });

  test('List<Int64>', () {
    // given
    final json = '[1234567890123456789,1234567890123456787]';

    // when
    final instance = JsonMapper.deserialize<List<Int64>>(json);
    // then
    expect(instance, TypeMatcher<List<Int64>>());
    expect(instance[0], Int64(1234567890123456789));
    expect(instance[1], Int64(1234567890123456787));

    // when
    final targetJson = JsonMapper.serialize(instance, compactOptions);
    // then
    expect(targetJson, json);
  });

  test('Set<Int64>', () {
    // given
    final json = '[1234567890123456789,1234567890123456787]';

    // when
    final instance = JsonMapper.deserialize<Set<Int64>>(json);
    // then
    expect(instance, TypeMatcher<Set<Int64>>());
    expect(instance.elementAt(0), Int64(1234567890123456789));
    expect(instance.elementAt(1), Int64(1234567890123456787));

    // when
    final targetJson = JsonMapper.serialize(instance, compactOptions);
    // then
    expect(targetJson, json);
  });
}
