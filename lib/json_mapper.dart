library json_mapper;

import 'dart:convert';

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import "package:reflectable/reflectable.dart";

class JsonMapper {
  static final JsonMapper instance = new JsonMapper._internal();
  final JsonEncoder jsonEncoder = new JsonEncoder.withIndent(" ");
  final JsonDecoder jsonDecoder = new JsonDecoder();
  final serializable = const JsonSerializable();
  final Map<String, ClassMirror> classes = <String, ClassMirror>{};

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    for (ClassMirror classMirror in serializable.annotatedClasses) {
      classes[classMirror.simpleName] = classMirror;
    }
  }

  List<String> getPublicFieldNames(ClassMirror classMirror) {
    Map<String, MethodMirror> instanceMembers = classMirror.instanceMembers;
    return instanceMembers.values
        .where((MethodMirror method) {
          return method.isGetter &&
              method.isSynthetic &&
              instanceMembers[method.simpleName + '='] != null &&
              !method.isPrivate;
        })
        .map((MethodMirror method) => method.simpleName)
        .toList();
  }

  InstanceMirror safeGetInstanceMirror(Object object) {
    InstanceMirror result;
    try {
      result = serializable.reflect(object);
    } catch (e) {}
    return result;
  }

  ICustomConverter getConverter(JsonProperty jsonProperty) {
    ICustomConverter result =
        jsonProperty != null ? jsonProperty.converter : null;
    if (jsonProperty != null &&
        jsonProperty.enumValues != null &&
        result == null) {
      result = enumConverter;
    }
    return result;
  }

  enumeratePublicFields(InstanceMirror instanceMirror, Function visitor) {
    for (String name in getPublicFieldNames(instanceMirror.type)) {
      String jsonName = name;
      JsonProperty meta = instanceMirror.type.declarations[name].metadata
          .firstWhere((m) => m is JsonProperty, orElse: () => null);
      if (meta != null && meta.ignore == true) {
        continue;
      }
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      visitor(name, jsonName, instanceMirror.invokeGetter(name), meta,
          getConverter(meta));
    }
  }

  bool isScalarType(Object object) {
    if (object == null) {
      return true;
    }
    if (object is num) {
      return true;
    }
    if (object is bool) {
      return true;
    }
    if (object is String) {
      return true;
    }
    return false;
  }

  dynamic serializeObject(Object o) {
    if (isScalarType(o)) {
      return o;
    }
    if (o is List) {
      return o.map(serializeObject).toList();
    }
    InstanceMirror im = safeGetInstanceMirror(o);

    if (im == null) {
      return null;
    }

    Map result = {};
    enumeratePublicFields(im, (name, jsonName, value, meta, converter) {
      if (converter != null) {
        convert(item) =>
            converter.toJSON(item, meta, safeGetInstanceMirror(item));
        if (value is List) {
          result[jsonName] = value.map(convert).toList();
        } else {
          result[jsonName] = convert(value);
        }
      } else {
        result[jsonName] = serializeObject(value);
      }
    });
    return result;
  }

  static dynamic serialize(Object o) {
    return instance.jsonEncoder.convert(instance.serializeObject(o));
  }

  static Object deserialize(dynamic jsonValue, dynamic instanceType) {
    ClassMirror cm = instance.classes[instanceType.toString()];
    Object objectInstance = cm.isEnum ? null : cm.newInstance("", []);
    InstanceMirror im = instance.safeGetInstanceMirror(objectInstance);
    Map<String, dynamic> m = (jsonValue is String)
        ? instance.jsonDecoder.convert(jsonValue)
        : jsonValue;

    instance.enumeratePublicFields(im,
        (name, jsonName, value, meta, converter) {
      var fieldValue = m[jsonName];
      if (meta != null) {
        if (meta.type != null) {
          if (fieldValue is List) {
            fieldValue =
                fieldValue.map((item) => deserialize(item, meta.type)).toList();
          } else {
            if (!instance.isScalarType(fieldValue)) {
              fieldValue = deserialize(fieldValue, meta.type);
            }
          }
        }
        if (converter != null) {
          convert(item) =>
              converter.fromJSON(item, meta, im.type.declarations[name]);
          if (fieldValue is List) {
            fieldValue = fieldValue.map(convert).toList();
          } else {
            fieldValue = convert(fieldValue);
          }
        }
      }
      im.invokeSetter(name, fieldValue);
    });
    return objectInstance;
  }
}
