import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import 'model/model.dart';

@Json(typeNameProperty: 'type')
@jsonSerializable
abstract class A {}

@jsonSerializable
mixin B on A {}

@jsonSerializable
class C extends A with B {}

@jsonSerializable
class MixinContainer {
  final Set<int> ints;
  final B b;

  const MixinContainer(this.ints, this.b);
}

void testMixinCases() {
  group('[Verify Mixin cases]', () {
    test('class C extends A with B', () {
      // given
      final json = r'''{"ints":[1,2,3],"b":{"type":"C"}}''';
      final instance = MixinContainer(
        {1, 2, 3},
        C(),
      );

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<MixinContainer>(targetJson)!;

      // then
      expect(targetJson, json);
      expect(target, TypeMatcher<MixinContainer>());
      expect(target.b, TypeMatcher<C>());
    });
  });
}
