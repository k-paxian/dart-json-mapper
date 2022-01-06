import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart'
    show
        MyCarModel,
        Color,
        EntityModel,
        Car,
        Foo,
        Bar,
        ApiResultUserModel,
        ApiResult,
        UserModel;

void testGenerics() {
  group('[Verify generics<T> cases]', () {
    test('ApiResult<UserModel>', () {
      // given
      final json = '''{"Success":true,"Result":{"Id":1,"Name":"aa"}}''';

      // when
      final target = ApiResult<UserModel>().fromJson(json);
      // or
      final target2 = JsonMapper.deserialize<ApiResultUserModel>(json);

      // then
      expect(target!.Result!.Id, 1);
      expect(target.Result!.Name, 'aa');
      expect(target.Success, true);

      expect(target2!.Result!.Id, 1);
      expect(target2.Result!.Name, 'aa');
      expect(target2.Success, true);

      expect(target.toJson(), json);
      expect(target.toJson(), target2.toJson());
    });

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
          color: Color.black);

      // when
      final json = carModel.toJson();

      // then
      expect(json, <String, dynamic>{
        'technicalName': 'MyCarModel',
        'parentUuid': 'parentUid',
        'uuid': 'uid',
        'model': 'Tesla S3',
        'color': 'black'
      });
    });

    test('Generic Entity Model, composition', () {
      /// https://en.wikipedia.org/wiki/Composition_over_inheritance
      /// In this case class Car is `composed` with generic EntityModel<T> as `EntityModel<Car>`
      /// Car is a useful payload, EntityModel<T> is a generic information container for payload T

      // given
      final carModel = EntityModel<Car>(
          uuid: 'uid', parentUuid: 'parentUid', entity: Car('x', Color.blue));
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
        'color': 'blue'
      });

      expect(entityJson, <String, dynamic>{'modelName': 'x', 'color': 'blue'});

      expect(entityInstance, TypeMatcher<Car>());
      expect(entityInstance.model, 'x');
      expect(entityInstance.color, Color.blue);

      JsonMapper().removeAdapter(adapter);
    });
  });
}
