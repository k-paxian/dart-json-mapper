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
    return jsonProperty.converterParams != null
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
    return getDateFormat(jsonProperty).parse(jsonValue);
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]) {
    return getDateFormat(jsonProperty).format(object);
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
    return getNumberFormat(jsonProperty).parse(jsonValue);
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]) {
    return getNumberFormat(jsonProperty).format(object);
  }

  NumberFormat getNumberFormat(JsonProperty jsonProperty) {
    String format = getConverterParameter('format', jsonProperty);
    return new NumberFormat(format);
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
