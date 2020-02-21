import 'dart:convert' show base64Decode, base64Encode;
import 'dart:convert' show JsonDecoder;
import 'dart:typed_data' show Uint8List;

import 'package:intl/intl.dart';

import '../errors.dart';
import 'annotations.dart';

/// Abstract class for custom converters implementations
abstract class ICustomConverter<T> {
  dynamic toJSON(T object, [JsonProperty jsonProperty]);
  T fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]);
}

/// Abstract class for custom iterable converters implementations
abstract class ICustomIterableConverter {
  void setIterableInstance(Iterable instance);
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
            : object != null ? object.toString() : null;
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
        : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    final format = getNumberFormat(jsonProperty);
    return object != null && format != null
        ? getNumberFormat(jsonProperty).format(object)
        : object;
  }

  NumberFormat getNumberFormat([JsonProperty jsonProperty]) {
    String format = getConverterParameter('format', jsonProperty);
    return format != null ? NumberFormat(format) : null;
  }
}

const enumConverter = EnumConverter();

/// Default converter for [enum] type
class EnumConverter implements ICustomConverter {
  const EnumConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    dynamic convert(value) => jsonProperty.enumValues.firstWhere((eValue) {
          if (value != null && jsonProperty.isEnumValuesValid(value) != true) {
            throw MissingEnumValuesError(value.runtimeType);
          }
          return eValue.toString() == value.toString();
        }, orElse: () => null);
    return jsonValue is Iterable
        ? jsonValue.map(convert).toList()
        : convert(jsonValue);
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return (object is List)
        ? object.map((item) => item.toString()).toList()
        : object.toString();
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
    return jsonValue is String ? BigInt.parse(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object is BigInt ? object.toString() : object;
  }
}

const mapStringDynamicConverter = MapStringDynamicConverter();

/// [Map<String, dynamic>] converter
class MapStringDynamicConverter
    implements ICustomConverter<Map<String, dynamic>> {
  const MapStringDynamicConverter() : super();

  static JsonDecoder jsonDecoder = JsonDecoder();

  @override
  Map<String, dynamic> fromJSON(dynamic jsonValue,
      [JsonProperty jsonProperty]) {
    return (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Map<String, dynamic> object, [JsonProperty jsonProperty]) {
    return object;
  }
}

const mapStringStringConverter = MapStringStringConverter();

/// [Map<String, String>] converter
class MapStringStringConverter
    implements ICustomConverter<Map<String, String>> {
  const MapStringStringConverter() : super();

  static JsonDecoder jsonDecoder = JsonDecoder();

  @override
  Map<String, String> fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Map<String, String> object, [JsonProperty jsonProperty]) {
    return object;
  }
}

final defaultIterableConverter = DefaultIterableConverter();

/// Default Iterable converter
class DefaultIterableConverter
    implements ICustomConverter, ICustomIterableConverter {
  DefaultIterableConverter() : super();

  static JsonDecoder jsonDecoder = JsonDecoder();

  Iterable _instance;

  @override
  dynamic fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    if (_instance != null && jsonValue is Iterable) {
      if (_instance is List) {
        (_instance as List).clear();
        jsonValue.forEach((item) => (_instance as List).add(item));
      }
      if (_instance is Set) {
        (_instance as Set).clear();
        jsonValue.forEach((item) => (_instance as Set).add(item));
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
}

const defaultConverter = DefaultConverter();

/// Default converter for all types
class DefaultConverter implements ICustomConverter {
  const DefaultConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object;
  }
}
