library json_mapper.converters;

import 'package:dart_json_mapper/annotations.dart';
import 'package:reflectable/reflectable.dart';

abstract class ICustomConverter {
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]);

  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty,
      [VariableMirror variableMirror]);
}

const dateConverter = const DateConverter();

class DateConverter implements ICustomConverter {
  const DateConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty,
      [VariableMirror variableMirror]) {
    return DateTime.parse(jsonValue);
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]) {
    DateTime dt = (object as DateTime);
    return "${dt.year.toString()}-${dt.month.toString().padLeft(2, '0')
    }-${dt.day.toString().padLeft(2, '0')}";
  }
}

const enumConverter = const EnumConverter();

class EnumConverter implements ICustomConverter {
  const EnumConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty,
      [VariableMirror variableMirror]) {
    return jsonProperty.enumValues[jsonValue];
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty,
      [InstanceMirror objectMirror]) {
    var result = object.toString();
    if (objectMirror != null && objectMirror.type.isEnum) {
      result = objectMirror.invokeGetter('index');
    }
    return result;
  }
}
