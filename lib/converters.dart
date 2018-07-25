library json_mapper.converters;

import 'package:dart_json_mapper/annotations.dart';
import 'package:intl/intl.dart';
import 'package:reflectable/reflectable.dart';

abstract class ICustomConverter {
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]);

  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty,
      [VariableMirror variableMirror]);
}

class BaseCustomConverter {
  const BaseCustomConverter() : super();
  dynamic getConverterParameter(String name, JsonProperty jsonProperty) {
    return jsonProperty != null && jsonProperty.converterParams != null
        ? jsonProperty.converterParams[name]
        : null;
  }
}

const dateConverter = const DateConverter();

class DateConverter extends BaseCustomConverter implements ICustomConverter {
  const DateConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty,
      [VariableMirror variableMirror]) {
    DateFormat format = getDateFormat(jsonProperty);
    return format != null && jsonValue is String
        ? format.parse(jsonValue)
        : jsonValue;
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]) {
    DateFormat format = getDateFormat(jsonProperty);
    return format != null && !(object is String)
        ? format.format(object)
        : object;
  }

  DateFormat getDateFormat(JsonProperty jsonProperty) {
    String format = getConverterParameter('format', jsonProperty);
    if (format == null) {
      format = "yyyy-MM-dd";
    }
    return new DateFormat(format);
  }
}

const numberConverter = const NumberConverter();

class NumberConverter extends BaseCustomConverter implements ICustomConverter {
  const NumberConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty,
      [VariableMirror variableMirror]) {
    NumberFormat format = getNumberFormat(jsonProperty);
    return format != null
        ? getNumberFormat(jsonProperty).parse(jsonValue)
        : jsonValue;
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]) {
    NumberFormat format = getNumberFormat(jsonProperty);
    return object != null && format != null
        ? getNumberFormat(jsonProperty).format(object)
        : object;
  }

  NumberFormat getNumberFormat(JsonProperty jsonProperty) {
    String format = getConverterParameter('format', jsonProperty);
    return format != null ? new NumberFormat(format) : null;
  }
}

const enumConverter = const EnumConverter();

class EnumConverter implements ICustomConverter {
  const EnumConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty,
      [VariableMirror variableMirror]) {
    return jsonProperty.enumValues.firstWhere(
        (eValue) => eValue.toString() == jsonValue.toString(),
        orElse: () => null);
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]) {
    return object.toString();
  }
}

const enumConverterNumeric = const EnumConverterNumeric();

class EnumConverterNumeric implements ICustomConverter {
  const EnumConverterNumeric() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty,
      [VariableMirror variableMirror]) {
    return jsonProperty.enumValues[jsonValue];
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]) {
    return jsonProperty.enumValues.indexOf(object);
  }
}
