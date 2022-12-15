import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart'
    show
        TypedStringChild,
        TypedStringParent,
        TypedChild,
        TypedParent,
        AbstractUser,
        UserImpl,
        BusinessType,
        MySuperclass,
        Stakeholder,
        Stakeholder2,
        Hotel,
        Hotel2,
        Startup,
        Startup2;

void testInheritance() {
  group('[Verify inheritance cases]', () {
    test(
        'Should distinguish inherited classes by readonly discriminator property value',
        () {
      // given
      final jack = Stakeholder('Jack', [Startup(10), Hotel(4)]);

      // when
      final json = JsonMapper.serialize(jack);
      final target = JsonMapper.deserialize<Stakeholder>(json)!;

      // then
      expect(target.businesses[0], TypeMatcher<Startup>());
      expect(target.businesses[0].type, BusinessType.public);
      expect(target.businesses[1], TypeMatcher<Hotel>());
      expect(target.businesses[1].type, BusinessType.private);
    });

    test(
        'Should distinguish inherited classes by writable discriminator property value',
        () {
      // given
      final jack = Stakeholder2('Jack', [Startup2(10), Hotel2(4)]);

      // when
      final json = JsonMapper.serialize(jack);
      final target = JsonMapper.deserialize<Stakeholder2>(json)!;

      // then
      expect(target.businesses[0], TypeMatcher<Startup2>());
      expect(target.businesses[0].type, BusinessType.public2);
      expect(target.businesses[1], TypeMatcher<Hotel2>());
      expect(target.businesses[1].type, BusinessType.private2);
    });

    test('should inherit annotations from abstract class', () {
      // given
      final instance = MySuperclass();
      final json =
          '{"myCustomFieldName":"myFieldValue","myCustomGetterName":"myGetterValue"}';

      // when
      final targetJson = JsonMapper.serialize(instance);
      final target = JsonMapper.deserialize<MySuperclass>(targetJson)!;

      // then
      expect(targetJson, json);
      expect(target.myField, instance.myField);
      expect(target.myGetter, instance.myGetter);
    });

    test('implements AbstractUser', () {
      // given
      final user = UserImpl(id: 'xxx', email: 'x@x.com');

      // when
      final map = JsonMapper.toMap(user)!;
      final newUser = JsonMapper.fromMap<AbstractUser>(map)!;

      // then
      expect(map.containsKey('@type'), true);
      expect(map['@type'], 'UserImpl');

      expect(newUser.id, 'xxx');
      expect(newUser.email, 'x@x.com');
    });

    test('Discriminator as of Type type', () {
      // given
      final childInstance = TypedChild();

      // when
      final firstJson = JsonMapper.serialize(childInstance);
      final targetInstance = JsonMapper.deserialize<TypedParent>(firstJson);
      final secondJson = JsonMapper.serialize(targetInstance);

      // then
      expect(targetInstance, TypeMatcher<TypedChild>());
      expect(firstJson, secondJson);
    });

    test('Discriminator as of type String', () {
      // given
      final childInstance = TypedStringChild();

      // when
      final firstJson = JsonMapper.serialize(childInstance);
      final targetInstance =
          JsonMapper.deserialize<TypedStringParent>(firstJson);
      final secondJson = JsonMapper.serialize(targetInstance);

      // then
      expect(targetInstance, TypeMatcher<TypedStringChild>());
      expect(firstJson, secondJson);
    });
  });
}
