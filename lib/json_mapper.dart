library json_mapper;

import 'dart:convert';

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import "package:reflectable/reflectable.dart";

abstract class CircularReferenceError extends Error {
  factory CircularReferenceError(String message) = _CircularReferenceErrorImpl;
}

class _CircularReferenceErrorImpl extends Error
    implements CircularReferenceError {
  final String _message;

  _CircularReferenceErrorImpl(String message) : _message = message;

  toString() => _message;
}

class JsonMapper {
  static final JsonMapper instance = new JsonMapper._internal();
  final JsonEncoder jsonEncoder = new JsonEncoder.withIndent(" ");
  final JsonDecoder jsonDecoder = new JsonDecoder();
  final serializable = const JsonSerializable();
  final Map<String, ClassMirror> classes = {};
  final Map<String, Object> processedObjects = {};

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
    } catch (error) {}
    return result;
  }

  String getObjectKey(Object object) {
    return '${object.runtimeType}-${object.hashCode}';
  }

  bool isObjectAlreadyProcessed(Object object) {
    bool result = false;

    if (object.runtimeType.toString() == 'Null') {
      return result;
    }

    String key = getObjectKey(object);
    if (processedObjects.containsKey(key)) {
      result = true;
    } else {
      processedObjects[key] = object;
    }
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

  dynamic serializeObject(Object object) {
    if (isObjectAlreadyProcessed(object)) {
      throw new CircularReferenceError(
          "Circular reference detected. ${getObjectKey(object)}, ${object.toString()}");
    }

    if (isScalarType(object)) {
      return object;
    }
    if (object is List) {
      return object.map(serializeObject).toList();
    }
    InstanceMirror im = safeGetInstanceMirror(object);

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

  Object deserializeObject(dynamic jsonValue, dynamic instanceType) {
    ClassMirror cm = classes[instanceType.toString()];
    Object objectInstance = cm.isEnum ? null : cm.newInstance("", []);
    InstanceMirror im = safeGetInstanceMirror(objectInstance);
    Map<String, dynamic> m =
        (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;

    enumeratePublicFields(im, (name, jsonName, value, meta, converter) {
      var fieldValue = m[jsonName];
      if (meta != null) {
        if (meta.type != null) {
          if (fieldValue is List) {
            fieldValue = fieldValue
                .map((item) => deserializeObject(item, meta.type))
                .toList();
          } else {
            if (!isScalarType(fieldValue)) {
              fieldValue = deserializeObject(fieldValue, meta.type);
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

  static dynamic serialize(Object object) {
    instance.processedObjects.clear();
    return instance.jsonEncoder.convert(instance.serializeObject(object));
  }

  static Object deserialize(dynamic jsonValue, dynamic instanceType) {
    return instance.deserializeObject(jsonValue, instanceType);
  }
}
