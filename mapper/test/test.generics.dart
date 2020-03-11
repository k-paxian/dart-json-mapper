part of json_mapper.test;

@jsonSerializable
@Json(typeNameProperty: 'technicalName', ignoreNullMembers: true)
abstract class EntityModel<T> {
  final String parentUuid;
  final String uuid;

  const EntityModel({this.parentUuid, this.uuid});

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
class MyCarModel extends EntityModel<Car> {
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
    test('Generic Entity Model', () {
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
  });
}
