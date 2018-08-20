library json_mapper.converters;

import 'package:dart_json_mapper/annotations.dart';
import 'package:intl/intl.dart';

abstract class ICustomConverter {
  dynamic toJSON(Object object, JsonProperty jsonProperty);
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty);
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
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty) {
    DateFormat format = getDateFormat(jsonProperty);

    if (jsonValue is String) {
      return format != null
          ? format.parse(jsonValue)
          : DateTime.parse(jsonValue);
    }

    return jsonValue;
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty) {
    DateFormat format = getDateFormat(jsonProperty);
    return format != null && !(object is String)
        ? format.format(object)
        : object.toString();
  }

  DateFormat getDateFormat(JsonProperty jsonProperty) {
    String format = getConverterParameter('format', jsonProperty);
    return format != null ? DateFormat(format) : null;
  }
}

const numberConverter = const NumberConverter();

class NumberConverter extends BaseCustomConverter implements ICustomConverter {
  const NumberConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty) {
    NumberFormat format = getNumberFormat(jsonProperty);
    return format != null
        ? getNumberFormat(jsonProperty).parse(jsonValue)
        : jsonValue;
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty) {
    NumberFormat format = getNumberFormat(jsonProperty);
    return object != null && format != null
        ? getNumberFormat(jsonProperty).format(object)
        : object;
  }

  NumberFormat getNumberFormat(JsonProperty jsonProperty) {
    String format = getConverterParameter('format', jsonProperty);
    return format != null ? NumberFormat(format) : null;
  }
}

const enumConverter = const EnumConverter();

class EnumConverter implements ICustomConverter {
  const EnumConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty) {
    return jsonProperty.enumValues.firstWhere(
        (eValue) => eValue.toString() == jsonValue.toString(),
        orElse: () => null);
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty) {
    return object.toString();
  }
}

const enumConverterNumeric = const EnumConverterNumeric();

class EnumConverterNumeric implements ICustomConverter {
  const EnumConverterNumeric() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty) {
    return jsonProperty.enumValues[jsonValue];
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty) {
    return jsonProperty.enumValues.indexOf(object);
  }
}

const defaultStringConverter = const StringConverter();

class StringConverter implements ICustomConverter {
  const StringConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty) {
    return jsonValue;
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty) {
    return object;
  }
}
