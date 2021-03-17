import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import 'model/index.dart';

void testGenerics() {
  group('[Verify generics<T> cases]', () {
    test('BarBase<T>', () {
      // given
      final json = '''{"foo":{}}''';
      final bar = Bar()..foo = Foo();

      // when
      final targetJson = bar.toJson();
      final target = Bar().fromJson(json)!;

      // then
      expect(targetJson, json);
      expect(target, TypeMatcher<Bar>());
      expect(target.foo, TypeMatcher<Foo>());
    });

    test('Generic AbstractEntityModel, OOP paradigm(inheritance)', () {
      // given
      const carModel = MyCarModel(
          uuid: 'uid',
          parentUuid: 'parentUid',
          model: 'Tesla S3',
          color: Color.Black);

      // when
      final json = carModel.toJson();

      // then
      expect(json, <String, dynamic>{
        'technicalName': 'MyCarModel',
        'parentUuid': 'parentUid',
        'uuid': 'uid',
        'model': 'Tesla S3',
        'color': 'Black'
      });
    });

    test('Generic Entity Model, composition', () {
      /// https://en.wikipedia.org/wiki/Composition_over_inheritance
      /// In this case class Car is `composed` with generic EntityModel<T> as `EntityModel<Car>`
      /// Car is a useful payload, EntityModel<T> is a generic information container for payload T

      // given
      final carModel = EntityModel<Car>(
          uuid: 'uid', parentUuid: 'parentUid', entity: Car('x', Color.Blue));
      final adapter = JsonMapperAdapter(valueDecorators: {
        // Value decorator is needed to convert generic instance
        // `EntityModel<dynamic>` to concrete type instance `EntityModel<Car>`
        typeOf<EntityModel<Car>>(): (value) => EntityModel<Car>.of(value)
      });
      JsonMapper().useAdapter(adapter);

      // when
      final modelJson = carModel.toJson();
      final entityJson = carModel.entityToJson();
      final entityInstance = carModel.newEntityFromModelJson(modelJson)!;

      // then
      expect(modelJson, <String, dynamic>{
        'technicalName': 'EntityModel<Car>',
        'parentUuid': 'parentUid',
        'uuid': 'uid',
        'modelName': 'x',
        'color': 'Blue'
      });

      expect(entityJson, <String, dynamic>{'modelName': 'x', 'color': 'Blue'});

      expect(entityInstance, TypeMatcher<Car>());
      expect(entityInstance.model, 'x');
      expect(entityInstance.color, Color.Blue);

      JsonMapper().removeAdapter(adapter);
    });
  });
}
