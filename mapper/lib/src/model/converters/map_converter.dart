import 'dart:convert' show JsonDecoder;

import '../index.dart';

final mapConverter = MapConverter();

/// [Map<K, V>] converter
class MapConverter
    implements
        ICustomConverter<Map?>,
        IRecursiveConverter,
        ICustomMapConverter {
  MapConverter() : super();

  late SerializeObjectFunction _serializeObject;
  late DeserializeObjectFunction _deserializeObject;
  Map? _instance;
  final _jsonDecoder = JsonDecoder();

  @override
  Map? fromJSON(dynamic jsonValue, DeserializationContext context) {
    var result = jsonValue;
    final typeInfo = context.typeInfo;
    if (jsonValue is String) {
      result = _jsonDecoder.convert(jsonValue);
    }
    if (typeInfo != null && result is Map) {
      if (_instance != null && _instance is Map || _instance == null) {
        result = result.map((key, value) => MapEntry(
            _deserializeObject(
                key,
                context,
                typeInfo.parameters.isEmpty
                    ? String
                    : typeInfo.parameters.first),
            _deserializeObject(
                value,
                context,
                typeInfo.parameters.isEmpty
                    ? dynamic
                    : typeInfo.parameters.last)));
      }
      if (_instance != null && _instance is Map) {
        result.forEach((key, value) => _instance![key] = value);
        result = _instance;
      }
    }
    return result;
  }

  @override
  dynamic toJSON(Map? object, SerializationContext context) =>
      object?.map((key, value) => MapEntry(
          _serializeObject(key, context).toString(),
          _serializeObject(value, context)));

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
  void setMapInstance(Map? instance) {
    _instance = instance;
  }
}
