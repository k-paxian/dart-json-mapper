import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

@jsonSerializable
class AA {
  BB? content;
}

@jsonSerializable
class BB {
  List<AA>? content;
}

void testSpecialCases() {
  group('[Verify special cases]', () {
    test('A/B inception deserialization', () {
      // given
      final json = '{"content":{"content":[]}}';

      // when
      final target = JsonMapper.deserialize<AA>(json)!;

      // then
      expect(target, TypeMatcher<AA>());
      expect(target.content, TypeMatcher<BB>());
      expect(target.content!.content, TypeMatcher<List<AA>>());
    });
  });
}
