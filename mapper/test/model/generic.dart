import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'model.dart';

@jsonSerializable
class Foo {}

@jsonSerializable
class BarBase<T> {
  T foo;

  BarBase({this.foo});

  BarBase<T> fromJson(dynamic json) => JsonMapper.deserialize<BarBase<T>>(json);

  dynamic toJson() =>
      JsonMapper.serialize(this, SerializationOptions(indent: ''));
}

@jsonSerializable
@Json(valueDecorators: Bar.valueDecorators)
class Bar extends BarBase<Foo> {
  static Map<Type, ValueDecoratorFunction> valueDecorators() =>
      {typeOf<BarBase<Foo>>(): (value) => Bar.of(value)};

  Bar();

  factory Bar.of(BarBase other) => Bar()..foo = other.foo;
}

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
