import 'dart:convert' show base64Decode, base64Encode;
import 'dart:convert' show JsonDecoder;
import 'dart:typed_data' show Uint8List;

import 'package:intl/intl.dart';

import 'annotations.dart';
import 'index.dart';

typedef SerializeObjectFunction = dynamic Function(Object object);
typedef DeserializeObjectFunction = dynamic Function(Object object, Type type);
typedef GetConverterFunction = ICustomConverter Function(
    JsonProperty jsonProperty, Type declarationType);

/// Abstract class for custom converters implementations
abstract class ICustomConverter<T> {
  dynamic toJSON(T object, [JsonProperty jsonProperty]);
  T fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]);
}

/// Abstract class for custom iterable converters implementations
abstract class ICustomIterableConverter {
  void setIterableInstance(Iterable instance);
}

/// Abstract class for custom map converters implementations
abstract class ICustomMapConverter {
  void setMapInstance(Map instance);
}

/// Abstract class for custom Enum converters implementations
abstract class ICustomEnumConverter {
  void setEnumValues(Iterable enumValues);
}

/// Abstract class for custom converters interested in TypeInfo
abstract class ITypeInfoConsumerConverter {
  void setTypeInfo(TypeInfo typeInfo);
}

/// Abstract class for composite converters relying on other converters
abstract class ICompositeConverter {
  void setGetConverterFunction(GetConverterFunction getConverter);
}

/// Abstract class for custom recursive converters implementations
abstract class IRecursiveConverter {
  void setSerializeObjectFunction(SerializeObjectFunction serializeObject);
  void setDeserializeObjectFunction(
      DeserializeObjectFunction deserializeObject);
}

/// Base class for custom type converter having access to parameters provided
/// by the [JsonProperty] meta
class BaseCustomConverter {
  const BaseCustomConverter() : super();
  dynamic getConverterParameter(String name, [JsonProperty jsonProperty]) {
    return jsonProperty != null && jsonProperty.converterParams != null
        ? jsonProperty.converterParams[name]
        : null;
  }
}

const dateConverter = DateConverter();

/// Default converter for [DateTime] type
class DateConverter extends BaseCustomConverter implements ICustomConverter {
  const DateConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    final format = getDateFormat(jsonProperty);

    if (jsonValue is String) {
      return format != null
          ? format.parse(jsonValue)
          : DateTime.parse(jsonValue);
    }

    return jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    final format = getDateFormat(jsonProperty);
    return format != null && object != null && !(object is String)
        ? format.format(object)
        : (object is List)
            ? object.map((item) => item.toString()).toList()
            : object != null
                ? object.toString()
                : null;
  }

  DateFormat getDateFormat([JsonProperty jsonProperty]) {
    String format = getConverterParameter('format', jsonProperty);
    return format != null ? DateFormat(format) : null;
  }
}

const numberConverter = NumberConverter();

/// Default converter for [num] type
class NumberConverter extends BaseCustomConverter implements ICustomConverter {
  const NumberConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    final format = getNumberFormat(jsonProperty);
    return format != null && (jsonValue is String)
        ? getNumberFormat(jsonProperty).parse(jsonValue)
        : (jsonValue is String)
            ? num.tryParse(jsonValue) ?? jsonValue
            : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    final format = getNumberFormat(jsonProperty);
    return object != null && format != null
        ? getNumberFormat(jsonProperty).format(object)
        : (object is String)
            ? num.tryParse(object)
            : object;
  }

  NumberFormat getNumberFormat([JsonProperty jsonProperty]) {
    String format = getConverterParameter('format', jsonProperty);
    return format != null ? NumberFormat(format) : null;
  }
}

const defaultEnumConverter = enumConverterShort;

final annotatedEnumConverter = AnnotatedEnumConverter();

/// Annotated Enum instance converter
class AnnotatedEnumConverter
    implements ICustomConverter, ICustomEnumConverter, ICompositeConverter {
  AnnotatedEnumConverter() : super();

  Iterable _enumValues = [];
  GetConverterFunction _getConverter;

  JsonProperty _getJsonProperty(JsonProperty jsonProperty) => JsonProperty(
      enumValues:
          (jsonProperty != null ? jsonProperty.enumValues : _enumValues));

  ICustomConverter get _enumConverter => _getConverter(null, Enum);

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) =>
      _enumConverter.fromJSON(
          jsonValue is String ? jsonValue.replaceAll('"', '') : jsonValue,
          _getJsonProperty(jsonProperty));

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) =>
      _enumConverter.toJSON(object, _getJsonProperty(jsonProperty));

  @override
  void setEnumValues(Iterable enumValues) {
    _enumValues = enumValues;
  }

  @override
  void setGetConverterFunction(GetConverterFunction getConverter) {
    _getConverter = getConverter;
  }
}

const enumConverter = EnumConverter();

/// Long converter for [enum] type
class EnumConverter implements ICustomConverter {
  const EnumConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    dynamic convert(value) => jsonProperty.enumValues.firstWhere(
        (eValue) => eValue.toString() == value.toString(),
        orElse: () => null);
    return jsonValue is Iterable
        ? jsonValue.map(convert).toList()
        : convert(jsonValue);
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    dynamic convert(value) => value.toString();
    return (object is Iterable)
        ? object.map(convert).toList()
        : convert(object);
  }
}

const enumConverterShort = EnumConverterShort();

/// Default converter for [enum] type
class EnumConverterShort implements ICustomConverter {
  const EnumConverterShort() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    dynamic convert(value) => jsonProperty.enumValues.firstWhere(
        (eValue) =>
            eValue.toString().split('.').last ==
            value.toString().split('.').last,
        orElse: () => null);
    return jsonValue is Iterable
        ? jsonValue.map(convert).toList()
        : convert(jsonValue);
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    dynamic convert(value) => value.toString().split('.').last;
    return (object is Iterable)
        ? object.map(convert).toList()
        : convert(object);
  }
}

const enumConverterNumeric = EnumConverterNumeric();

/// Numeric index based converter for [enum] type
class EnumConverterNumeric implements ICustomConverter {
  const EnumConverterNumeric() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is int ? jsonProperty.enumValues[jsonValue] : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return jsonProperty.enumValues.indexOf(object);
  }
}

const symbolConverter = SymbolConverter();

/// Default converter for [Symbol] type
class SymbolConverter implements ICustomConverter {
  const SymbolConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is String ? Symbol(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object != null
        ? RegExp('"(.+)"').allMatches(object.toString()).first.group(1)
        : null;
  }
}

const durationConverter = DurationConverter();

/// DurationConverter converter for [Duration] type
class DurationConverter implements ICustomConverter<Duration> {
  const DurationConverter() : super();

  @override
  Duration fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is num ? Duration(microseconds: jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Duration object, [JsonProperty jsonProperty]) {
    return object != null ? object.inMicroseconds : null;
  }
}

const uint8ListConverter = Uint8ListConverter();

/// [Uint8List] converter to base64 and back
class Uint8ListConverter implements ICustomConverter {
  const Uint8ListConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is String ? base64Decode(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object is Uint8List ? base64Encode(object) : object;
  }
}

const bigIntConverter = BigIntConverter();

/// [BigInt] converter
class BigIntConverter implements ICustomConverter {
  const BigIntConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is String ? BigInt.tryParse(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object is BigInt ? object.toString() : object;
  }
}

final mapConverter = MapConverter();

/// [Map<K, V>] converter
class MapConverter
    implements
        ICustomConverter<Map>,
        IRecursiveConverter,
        ICustomMapConverter,
        ITypeInfoConsumerConverter,
        ICompositeConverter {
  MapConverter() : super();

  SerializeObjectFunction _serializeObject;
  DeserializeObjectFunction _deserializeObject;
  TypeInfo _typeInfo;
  Map _instance;
  final _jsonDecoder = JsonDecoder();
  GetConverterFunction _getConverter;
  ICustomConverter get _enumConverter => _getConverter(null, Enum);

  dynamic from(item, Type type, JsonProperty jsonProperty) {
    var result;
    if (jsonProperty != null && jsonProperty.isEnumType(type)) {
      result = _enumConverter.fromJSON(item, jsonProperty);
    } else {
      result = _deserializeObject(item, type);
    }
    return result;
  }

  dynamic to(item, JsonProperty jsonProperty) {
    var result;
    if (jsonProperty != null && jsonProperty.isEnumType(item.runtimeType)) {
      result = _enumConverter.toJSON(item, jsonProperty);
    } else {
      result = _serializeObject(item);
    }
    return result;
  }

  @override
  Map fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    var result = jsonValue;
    if (jsonValue is String) {
      result = _jsonDecoder.convert(jsonValue);
    }
    if (_typeInfo != null && result is Map) {
      if (_instance != null && _instance is Map ||
          (_instance == null &&
              jsonProperty != null &&
              jsonProperty.enumValues != null) ||
          (_instance == null && jsonProperty == null)) {
        result = result.map((key, value) => MapEntry(
            from(key, _typeInfo.parameters.first, jsonProperty),
            from(value, _typeInfo.parameters.last, jsonProperty)));
      }
      if (_instance != null && _instance is Map) {
        result.forEach((key, value) => _instance[key] = value);
        result = _instance;
      }
    }
    return result;
  }

  @override
  dynamic toJSON(Map object, [JsonProperty jsonProperty]) =>
      object.map((key, value) =>
          MapEntry(to(key, jsonProperty).toString(), to(value, jsonProperty)));

  @override
  void setSerializeObjectFunction(SerializeObjectFunction serializeObject) {
    _serializeObject = serializeObject;
  }

  @override
  void setGetConverterFunction(GetConverterFunction getConverter) {
    _getConverter = getConverter;
  }

  @override
  void setDeserializeObjectFunction(
      DeserializeObjectFunction deserializeObject) {
    _deserializeObject = deserializeObject;
  }

  @override
  void setMapInstance(Map instance) {
    _instance = instance;
  }

  @override
  void setTypeInfo(TypeInfo typeInfo) {
    _typeInfo = typeInfo;
  }
}

final defaultIterableConverter = DefaultIterableConverter();

/// Default Iterable converter
class DefaultIterableConverter
    implements ICustomConverter, ICustomIterableConverter, ICompositeConverter {
  DefaultIterableConverter() : super();

  Iterable _instance;
  GetConverterFunction _getConverter;
  ICustomConverter get _enumConverter => _getConverter(null, Enum);

  @override
  dynamic fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    dynamic convert(item) =>
        jsonProperty != null && jsonProperty.enumValues != null
            ? _enumConverter.fromJSON(item, jsonProperty)
            : item;
    if (_instance != null && jsonValue is Iterable && jsonValue != _instance) {
      if (_instance is List) {
        (_instance as List).clear();
        jsonValue.forEach((item) => (_instance as List).add(convert(item)));
      }
      if (_instance is Set) {
        (_instance as Set).clear();
        jsonValue.forEach((item) => (_instance as Set).add(convert(item)));
      }
      return _instance;
    }
    return jsonValue;
  }

  @override
  dynamic toJSON(dynamic object, [JsonProperty jsonProperty]) {
    return object;
  }

  @override
  void setIterableInstance(Iterable instance) {
    _instance = instance;
  }

  @override
  void setGetConverterFunction(GetConverterFunction getConverter) {
    _getConverter = getConverter;
  }
}

const uriConverter = UriConverter();

/// Uri converter
class UriConverter implements ICustomConverter<Uri> {
  const UriConverter() : super();

  @override
  Uri fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) =>
      jsonValue is String ? Uri.tryParse(jsonValue) : jsonValue;

  @override
  String toJSON(Uri object, [JsonProperty jsonProperty]) => object.toString();
}

const regExpConverter = RegExpConverter();

/// RegExp converter
class RegExpConverter implements ICustomConverter<RegExp> {
  const RegExpConverter() : super();

  @override
  RegExp fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) =>
      jsonValue is String ? RegExp(jsonValue) : jsonValue;

  @override
  dynamic toJSON(RegExp object, [JsonProperty jsonProperty]) => object.pattern;
}

const defaultConverter = DefaultConverter();

/// Default converter for all types
class DefaultConverter implements ICustomConverter {
  const DefaultConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) => jsonValue;

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) => object;
}
