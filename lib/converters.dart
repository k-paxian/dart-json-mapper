library json_mapper.converters;

import 'dart:convert' show base64Decode, base64Encode;
import 'dart:convert' show JsonDecoder;
import 'dart:typed_data' show Uint8List;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/errors.dart';
import 'package:fixnum/fixnum.dart' show Int32, Int64;
import 'package:intl/intl.dart';

/// Abstract class for custom converters implementations
abstract class ICustomConverter<T> {
  dynamic toJSON(T object, [JsonProperty jsonProperty]);
  T fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]);
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
    DateFormat format = getDateFormat(jsonProperty);

    if (jsonValue is String) {
      return format != null
          ? format.parse(jsonValue)
          : DateTime.parse(jsonValue);
    }

    return jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    DateFormat format = getDateFormat(jsonProperty);
    return format != null && !(object is String)
        ? format.format(object)
        : object.toString();
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
    NumberFormat format = getNumberFormat(jsonProperty);
    return format != null && (jsonValue is String)
        ? getNumberFormat(jsonProperty).parse(jsonValue)
        : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    NumberFormat format = getNumberFormat(jsonProperty);
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
    if (jsonProperty.isEnumValuesValid(jsonValue) != true) {
      throw MissingEnumValuesError(jsonValue.runtimeType);
    }
    return jsonProperty.enumValues.firstWhere(
        (eValue) => eValue.toString() == jsonValue.toString(),
        orElse: () => null);
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object.toString();
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
    return RegExp('"(.+)"')
        .allMatches(object.toString())
        .first
        .group(0)
        .replaceAll("\"", '');
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

const int32Converter = Int32Converter();

/// [Int32] converter
class Int32Converter implements ICustomConverter {
  const Int32Converter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is String ? Int32.parseInt(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object is Int32 ? object.toString() : object;
  }
}

const int64Converter = Int64Converter();

/// [Int64] converter
class Int64Converter implements ICustomConverter {
  const Int64Converter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is String ? Int64.parseInt(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object is Int64 ? object.toString() : object;
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
