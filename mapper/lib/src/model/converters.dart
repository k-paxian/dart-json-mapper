import 'dart:convert' show base64Decode, base64Encode;
import 'dart:convert' show JsonDecoder;
import 'dart:typed_data' show Uint8List;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:intl/intl.dart';

import 'index.dart';

typedef SerializeObjectFunction = dynamic Function(
    Object object, SerializationContext context);
typedef DeserializeObjectFunction = dynamic Function(
    dynamic object, DeserializationContext context, Type type);
typedef GetConverterFunction = ICustomConverter? Function(
    JsonProperty? jsonProperty, TypeInfo typeInfo);
typedef GetConvertedValueFunction = dynamic Function(
    ICustomConverter converter, dynamic value, DeserializationContext context);

/// Abstract class for custom converters implementations
abstract class ICustomConverter<T> {
  dynamic toJSON(T object, SerializationContext context);
  T fromJSON(dynamic jsonValue, DeserializationContext context);
}

/// Abstract class for custom iterable converters implementations
abstract class ICustomIterableConverter {
  void setIterableInstance(Iterable? instance);
}

/// Abstract class for custom map converters implementations
abstract class ICustomMapConverter {
  void setMapInstance(Map? instance);
}

/// Abstract class for custom Enum converters implementations
abstract class ICustomEnumConverter {
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor);
}

/// Abstract class for composite converters relying on other converters
abstract class ICompositeConverter {
  void setGetConverterFunction(GetConverterFunction getConverter);
  void setGetConvertedValueFunction(
      GetConvertedValueFunction getConvertedValue);
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
  dynamic getConverterParameter(String name, [JsonProperty? jsonProperty]) {
    return jsonProperty != null && jsonProperty.converterParams != null
        ? jsonProperty.converterParams![name]
        : null;
  }
}

const dateConverter = DateConverter();

/// Default converter for [DateTime] type
class DateConverter extends BaseCustomConverter implements ICustomConverter {
  const DateConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    final format = getDateFormat(context.jsonPropertyMeta);

    if (jsonValue is String) {
      return format != null
          ? format.parse(jsonValue)
          : DateTime.parse(jsonValue);
    }

    return jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    final format = getDateFormat(context.jsonPropertyMeta);
    return format != null && object != null && object is! String
        ? format.format(object as DateTime)
        : (object is List)
            ? object.map((item) => item.toString()).toList()
            : object?.toString();
  }

  DateFormat? getDateFormat([JsonProperty? jsonProperty]) {
    String? format = getConverterParameter('format', jsonProperty);
    return format != null ? DateFormat(format) : null;
  }
}

const numberConverter = NumberConverter();

/// Default converter for [num] type
class NumberConverter extends BaseCustomConverter implements ICustomConverter {
  const NumberConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    final format = getNumberFormat(context.jsonPropertyMeta);
    return format != null && (jsonValue is String)
        ? getNumberFormat(context.jsonPropertyMeta)!.parse(jsonValue)
        : (jsonValue is String)
            ? num.tryParse(jsonValue) ?? jsonValue
            : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    final format = getNumberFormat(context.jsonPropertyMeta);
    return object != null && format != null
        ? getNumberFormat(context.jsonPropertyMeta)!.format(object)
        : (object is String)
            ? num.tryParse(object)
            : object;
  }

  NumberFormat? getNumberFormat([JsonProperty? jsonProperty]) {
    String? format = getConverterParameter('format', jsonProperty);
    return format != null ? NumberFormat(format) : null;
  }
}

final defaultEnumConverter = enumConverterShort;

final enumConverter = EnumConverter();

/// Long converter for [enum] type
class EnumConverter implements ICustomConverter, ICustomEnumConverter {
  EnumConverter() : super();

  IEnumDescriptor? _enumDescriptor;

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    dynamic convert(value) => _enumDescriptor!.values.firstWhere(
        (eValue) => eValue.toString() == value.toString(),
        orElse: () => null);
    return jsonValue is Iterable
        ? jsonValue.map(convert).toList()
        : convert(jsonValue);
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    dynamic convert(value) => value.toString();
    return (object is Iterable)
        ? object.map(convert).toList()
        : convert(object);
  }

  @override
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor) {
    _enumDescriptor = enumDescriptor;
  }
}

final enumConverterShort = EnumConverterShort();

/// Default converter for [enum] type
class EnumConverterShort implements ICustomConverter, ICustomEnumConverter {
  EnumConverterShort() : super();

  IEnumDescriptor? _enumDescriptor;

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    dynamic convert(value) =>
        _enumDescriptor!.values.firstWhereOrNull((eValue) =>
            _enumDescriptor!.caseInsensitive == true
                ? _transformValue(value, context).toLowerCase() ==
                    _transformValue(eValue, context, doubleMapping: true)
                        .toLowerCase()
                : _transformValue(value, context) ==
                    _transformValue(eValue, context, doubleMapping: true)) ??
        _enumDescriptor!.defaultValue;
    return jsonValue is Iterable
        ? jsonValue.map(convert).toList()
        : convert(jsonValue);
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    dynamic convert(value) =>
        value != null ? _transformValue(value, context) : null;
    return (object is Iterable)
        ? object.map(convert).toList()
        : convert(object);
  }

  @override
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor) {
    _enumDescriptor = enumDescriptor;
  }

  dynamic _transformValue(dynamic value, DeserializationContext context,
      {bool doubleMapping = false}) {
    final mapping = {};
    mapping.addAll(_enumDescriptor!.mapping);
    if (context.jsonPropertyMeta != null &&
        context.jsonPropertyMeta!.converterParams != null) {
      mapping.addAll(context.jsonPropertyMeta!.converterParams!);
    }
    value = _mapValue(value, mapping);
    if (doubleMapping) {
      value = _mapValue(value, mapping);
    }
    if (value is String) {
      value = transformFieldName(value, context.caseStyle);
    }
    return value;
  }

  dynamic _mapValue(dynamic value, Map mapping) => mapping.containsKey(value)
      ? mapping[value]
      : value.toString().split('.').last;
}

const enumConverterNumeric = ConstEnumConverterNumeric();

/// Const wrapper for [EnumConverterNumeric]
class ConstEnumConverterNumeric
    implements ICustomConverter, ICustomEnumConverter {
  const ConstEnumConverterNumeric();

  @override
  Object? fromJSON(jsonValue, DeserializationContext context) =>
      _enumConverterNumeric.fromJSON(jsonValue, context);

  @override
  dynamic toJSON(object, SerializationContext context) =>
      _enumConverterNumeric.toJSON(object, context);

  @override
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor) {
    _enumConverterNumeric.setEnumDescriptor(enumDescriptor);
  }
}

final _enumConverterNumeric = EnumConverterNumeric();

/// Numeric index based converter for [enum] type
class EnumConverterNumeric implements ICustomConverter, ICustomEnumConverter {
  EnumConverterNumeric() : super();

  IEnumDescriptor? _enumDescriptor;

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is int
        ? jsonValue < _enumDescriptor!.values.length && jsonValue >= 0
            ? (_enumDescriptor!.values as List)[jsonValue]
            : _enumDescriptor!.defaultValue
        : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    final valueIndex = (_enumDescriptor!.values as List).indexOf(object);
    return valueIndex >= 0 ? valueIndex : _enumDescriptor!.defaultValue;
  }

  @override
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor) {
    _enumDescriptor = enumDescriptor;
  }
}

const symbolConverter = SymbolConverter();

/// Default converter for [Symbol] type
class SymbolConverter implements ICustomConverter {
  const SymbolConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is String ? Symbol(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    return object != null
        ? RegExp('"(.+)"').allMatches(object.toString()).first.group(1)
        : null;
  }
}

const durationConverter = DurationConverter();

/// DurationConverter converter for [Duration] type
class DurationConverter implements ICustomConverter<Duration?> {
  const DurationConverter() : super();

  @override
  Duration? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is num
        ? Duration(microseconds: jsonValue as int)
        : jsonValue;
  }

  @override
  dynamic toJSON(Duration? object, SerializationContext context) {
    return object?.inMicroseconds;
  }
}

const uint8ListConverter = Uint8ListConverter();

/// [Uint8List] converter to base64 and back
class Uint8ListConverter implements ICustomConverter {
  const Uint8ListConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is String ? base64Decode(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    return object is Uint8List ? base64Encode(object) : object;
  }
}

const bigIntConverter = BigIntConverter();

/// [BigInt] converter
class BigIntConverter implements ICustomConverter {
  const BigIntConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is String ? BigInt.tryParse(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    return object is BigInt ? object.toString() : object;
  }
}

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

const uriConverter = UriConverter();

/// Uri converter
class UriConverter implements ICustomConverter<Uri?> {
  const UriConverter() : super();

  @override
  Uri? fromJSON(dynamic jsonValue, DeserializationContext context) =>
      jsonValue is String ? Uri.tryParse(jsonValue) : jsonValue;

  @override
  String? toJSON(Uri? object, SerializationContext context) =>
      object?.toString();
}

const regExpConverter = RegExpConverter();

/// RegExp converter
class RegExpConverter implements ICustomConverter<RegExp?> {
  const RegExpConverter() : super();

  @override
  RegExp? fromJSON(dynamic jsonValue, DeserializationContext context) =>
      jsonValue is String ? RegExp(jsonValue) : jsonValue;

  @override
  dynamic toJSON(RegExp? object, SerializationContext context) =>
      object?.pattern;
}

const defaultConverter = DefaultConverter();

/// Default converter for all types
class DefaultConverter implements ICustomConverter {
  const DefaultConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) =>
      jsonValue;

  @override
  dynamic toJSON(Object? object, SerializationContext context) => object;
}
