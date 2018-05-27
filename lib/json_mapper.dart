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

  JsonProperty getFieldMetaData(String fieldName, ClassMirror classMirror) {
    JsonProperty result;
    classMirror.declarations.forEach((key, v) =>
        v.metadata.forEach((m) => fieldName == key ? result = m : null));
    return result;
  }

  ICustomConverter getConverter(JsonProperty jsonProperty) {
    ICustomConverter result = jsonProperty.converter;
    if (jsonProperty.enumValues != null && result == null) {
      result = enumConverter;
    }
    return result;
  }

  bool isScalarType(Object object) {
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
    if (o == null) {
      return null;
    }
    if (o is DateTime) {
      return o.toIso8601String();
    }
    if (o is num) {
      return o;
    }
    if (o is List) {
      return o.map(serializeObject).toList();
    }
    if (o is String) {
      return o;
    }
    if (o is bool) {
      return o;
    }
    InstanceMirror im = safeGetInstanceMirror(o);

    if (im == null) {
      return null;
    }

    if (im.type.isEnum) {
      return im.invokeGetter('index');
    }

    Map result = {};
    for (String fieldName in instance.getPublicFieldNames(im.type)) {
      var jsonFieldName = fieldName;
      JsonProperty fieldMeta = instance.getFieldMetaData(fieldName, im.type);
      final fieldValue = im.invokeGetter(fieldName);
      if (fieldMeta != null) {
        if (fieldMeta.ignore == true) {
          continue;
        }
        if (fieldMeta.name != null) {
          jsonFieldName = fieldMeta.name;
        }
        ICustomConverter converter = instance.getConverter(fieldMeta);
        if (converter != null) {
          result[jsonFieldName] = converter.toJSON(
              fieldValue, fieldMeta, safeGetInstanceMirror(fieldValue));
          continue;
        }
      }
      result[jsonFieldName] = serializeObject(fieldValue);
    }
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

    for (String fieldName in instance.getPublicFieldNames(im.type)) {
      var fieldValue = m[fieldName];
      JsonProperty fieldMeta = instance.getFieldMetaData(fieldName, im.type);
      if (fieldMeta != null) {
        if (fieldMeta.ignore == true) {
          continue;
        }
        if (fieldMeta.name != null) {
          fieldValue = m[fieldMeta.name];
        }
        if (fieldMeta.type != null) {
          if (fieldValue is List) {
            fieldValue = fieldValue
                .map((item) => deserialize(item, fieldMeta.type))
                .toList();
          } else {
            if (!instance.isScalarType(fieldValue)) {
              fieldValue = deserialize(fieldValue, fieldMeta.type);
            }
          }
        }
        ICustomConverter converter = instance.getConverter(fieldMeta);
        if (converter != null) {
          im.invokeSetter(
              fieldName,
              converter.fromJSON(
                  fieldValue, fieldMeta, im.type.declarations[fieldName]));
          continue;
        }
      }
      im.invokeSetter(fieldName, fieldValue);
    }
    return objectInstance;
  }
}
