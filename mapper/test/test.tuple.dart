import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

@jsonSerializable
class Tuple<T, S> {
  final T value1;
  final S value2;

  Tuple(this.value1, this.value2);
}

@jsonSerializable
class ConcreteClass {
  final Tuple<int, DateTime> tuple1;
  final Tuple<Duration, BigInt> tuple2;

  ConcreteClass(this.tuple1, this.tuple2);
}

void testTupleCases() {
  group('[Verify Tuple<T,S> cases]', () {
    test('Tuple as part of concrete class', () {
      // given
      final json = r'''
{
 "tuple1": {
  "value1": 1,
  "value2": "1970-01-01 00:00:00.024Z"
 },
 "tuple2": {
  "value1": 42000000,
  "value2": "2"
 }
}''';
      final instance = ConcreteClass(
        Tuple(1, DateTime.fromMillisecondsSinceEpoch(24).toUtc()),
        Tuple(const Duration(seconds: 42), BigInt.two),
      );

      // when
      final targetJson = JsonMapper.serialize(instance);

      // then
      expect(targetJson, json);
    });
  });
}
