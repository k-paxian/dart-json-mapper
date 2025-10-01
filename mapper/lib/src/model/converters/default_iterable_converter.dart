import '../index.dart';
import 'base_converter.dart';

final defaultIterableConverter = DefaultIterableConverter();

/// Default Iterable converter
class DefaultIterableConverter extends BaseCustomConverter
    implements ICustomConverter, ICustomIterableConverter, IRecursiveConverter {
  DefaultIterableConverter() : super();

  Iterable? _instance;
  late SerializeObjectFunction _serializeObject;
  late DeserializeObjectFunction _deserializeObject;

  @override
  dynamic fromJSON(dynamic jsonValue, DeserializationContext context) {
    final delimiter =
        getConverterParameter('delimiter', context.jsonPropertyMeta);
    if (delimiter != null && jsonValue is String) {
      jsonValue = jsonValue.split(delimiter);
    }
    if (_instance != null && jsonValue is Iterable && jsonValue != _instance) {
      if (_instance is List) {
        (_instance as List).clear();
        for (var item in jsonValue) {
          (_instance as List)
              .add(_deserializeObject(item, context, context.typeInfo!.type!));
        }
      }
      if (_instance is Set) {
        (_instance as Set).clear();
        for (var item in jsonValue) {
          (_instance as Set)
              .add(_deserializeObject(item, context, context.typeInfo!.type!));
        }
      }
      return _instance;
    } else if (jsonValue is Iterable) {
      return jsonValue
          .map((item) => _deserializeObject(
              item, context, context.typeInfo!.parameters.first))
          .toList();
    }
    return jsonValue;
  }

  @override
  dynamic toJSON(dynamic object, SerializationContext context) {
    final delimiter =
        getConverterParameter('delimiter', context.jsonPropertyMeta);
    final result =
        object?.map((item) => _serializeObject(item, context)).toList();
    if (delimiter != null && result != null) {
      return result.join(delimiter);
    }
    return result;
  }

  @override
  void setSerializeObjectFunction(SerializeObjectFunction serializeObject) {
    _serializeObject = serializeObject;
  }

  @override
  void setDeserializeObjectFunction(
      DeserializeObjectFunction deserializeObject) {
    _deserializeObject = deserializeObject;
  }

  @override
  void setIterableInstance(Iterable? instance) {
    _instance = instance;
  }
}