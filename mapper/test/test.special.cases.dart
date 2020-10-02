import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

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

      // when
      final target = JsonMapper.deserialize<A>(json);

      // then
      expect(target, TypeMatcher<A>());
      expect(target.content, TypeMatcher<B>());
      expect(target.content.content, TypeMatcher<List<A>>());
    });
  });
}
