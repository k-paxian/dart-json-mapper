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

  MethodMirror getPublicConstructor(ClassMirror classMirror) {
    return classMirror.declarations.values.where((DeclarationMirror dm) {
      return !dm.isPrivate && dm is MethodMirror && dm.isConstructor;
    }).first;
  }

  List<String> getPublicFieldNames(ClassMirror classMirror) {
    Map<String, MethodMirror> instanceMembers = classMirror.instanceMembers;
    return instanceMembers.values
        .where((MethodMirror method) {
          return method.isGetter && method.isSynthetic && !method.isPrivate;
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

  String safeGetParameterTypeName(ParameterMirror p) {
    String result;
    try {
      result = p.type.simpleName;
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
      bool isGetterOnly =
          instanceMirror.type.instanceMembers[name + '='] == null;
      JsonProperty meta = instanceMirror.type.declarations[name].metadata
          .firstWhere((m) => m is JsonProperty, orElse: () => null);
      if (meta != null && meta.ignore == true) {
        continue;
      }
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      visitor(name, jsonName, instanceMirror.invokeGetter(name), isGetterOnly,
          meta, getConverter(meta));
    }
  }

  Map<Symbol, dynamic> getNamedArguments(
      ClassMirror cm, Map<String, dynamic> jsonMap) {
    Map<Symbol, dynamic> result = new Map();
    MethodMirror constructorMirror = getPublicConstructor(cm);
    if (constructorMirror == null) {
      return result;
    }
    constructorMirror.parameters.forEach((ParameterMirror param) {
      String typeName = safeGetParameterTypeName(param);
      String paramName = param.simpleName;
      if (param.isNamed && jsonMap.containsKey(paramName)) {
        dynamic value = jsonMap[paramName];
        if (classes[typeName] != null) {
          value = deserializeObject(value, typeName);
        }
        result[new Symbol(paramName)] = value;
      }
    });
    return result;
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
    enumeratePublicFields(im,
        (name, jsonName, value, isGetterOnly, meta, converter) {
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
    Map<String, dynamic> jsonMap =
        (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
    Object objectInstance = cm.isEnum
        ? null
        : cm.newInstance("", [], getNamedArguments(cm, jsonMap));
    InstanceMirror im = safeGetInstanceMirror(objectInstance);

    enumeratePublicFields(im,
        (name, jsonName, value, isGetterOnly, meta, converter) {
      var fieldValue = jsonMap[jsonName];
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
      if (!isGetterOnly) {
        im.invokeSetter(name, fieldValue);
      }
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
