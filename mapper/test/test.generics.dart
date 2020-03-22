part of json_mapper.test;

@jsonSerializable
@Json(typeNameProperty: 'technicalName', ignoreNullMembers: true)
class EntityModel<T> {
  final String parentUuid;
  final String uuid;

  @JsonProperty(ignore: true)
  final T entity;

  static Map<String, dynamic> entityProperties = {};

  const EntityModel({this.parentUuid, this.uuid, this.entity});

  factory EntityModel.of(EntityModel<dynamic> other) => EntityModel<T>(
      parentUuid: other.parentUuid, uuid: other.uuid, entity: other.entity);

  @jsonProperty
  Map<String, dynamic> entityToJson() => JsonMapper.toMap(entity);

  @jsonProperty
  void setEntityPropertyFromJson(String name, dynamic value) {
    entityProperties[name] = value;
  }

  T newEntityFromModelJson(Map<String, dynamic> entityModelJson) {
    fromJson(entityModelJson);
    return JsonMapper.fromMap<T>(entityProperties);
  }

  T newEntityFromJson(Map<String, dynamic> entityJson) =>
      JsonMapper.fromMap<T>(entityJson);

  EntityModel<T> fromJson(Map<String, dynamic> modelJson) =>
      JsonMapper.fromMap<EntityModel<T>>(modelJson);

  Map<String, dynamic> toJson() => JsonMapper.toMap(this);
}

@jsonSerializable
@Json(typeNameProperty: 'technicalName', ignoreNullMembers: true)
abstract class AbstractEntityModel<T> {
  final String parentUuid;
  final String uuid;

  const AbstractEntityModel({this.parentUuid, this.uuid});

  T copyWith();

  T merge(T other);

  T fromJson(Map<String, dynamic> jsonData) {
    return JsonMapper.fromMap<T>(jsonData);
  }

  Map<String, dynamic> toJson() {
    return JsonMapper.toMap(this);
  }
}

@jsonSerializable
class MyCarModel extends AbstractEntityModel<Car> {
  final String model;

  @JsonProperty(enumValues: Color.values)
  final Color color;

  const MyCarModel({String parentUuid, String uuid, this.model, this.color})
      : super(parentUuid: parentUuid, uuid: uuid);

  @override
  Car copyWith() {
    return Car(model, color);
  }

  @override
  Car merge(Car other) {
    return Car(model ?? other.model, color ?? other.color);
  }
}

void testGenerics() {
  group('[Verify generics<T> cases]', () {
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
        'color': 'Color.Black'
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
      final entityInstance = carModel.newEntityFromModelJson(modelJson);

      // then
      expect(modelJson, <String, dynamic>{
        'technicalName': 'EntityModel<Car>',
        'parentUuid': 'parentUid',
        'uuid': 'uid',
        'modelName': 'x',
        'color': 'Color.Blue'
      });

      expect(entityJson,
          <String, dynamic>{'modelName': 'x', 'color': 'Color.Blue'});

      expect(entityInstance, TypeMatcher<Car>());
      expect(entityInstance.model, 'x');
      expect(entityInstance.color, Color.Blue);

      JsonMapper().removeAdapter(adapter);
    });
  });
}
