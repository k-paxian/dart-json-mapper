library json_mapper;

import 'dart:convert';

import "package:reflectable/reflectable.dart";
import 'package:json_mapper/annotations.dart';

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
      return method.isGetter && method.isSynthetic &&
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
    } catch (e) {
    }
    return result;
  }

  JsonProperty getFieldMetaData(String fieldName, ClassMirror classMirror) {
    JsonProperty result;
    classMirror.declarations.forEach(
            (key, v) => v.metadata.forEach((m) => fieldName == key ? result = m : null)
    );
    return result;
  }

  dynamic serializeObject(Object o) {
    if (o == null) {
      return null;
    }
    if (o is DateTime) {
      return o.toUtc().toIso8601String();
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

    if (im.type.isEnum) {
      return im.invokeGetter('index');
    }

    Map result = {};
    for (String fieldName in instance.getPublicFieldNames(im.type)) {
         var jsonFieldName = fieldName;
         JsonProperty fieldMeta = instance.getFieldMetaData(fieldName, im.type);
         var fieldValue = im.invokeGetter(fieldName);
         if (fieldMeta != null) {
           if (fieldMeta.name != null) {
             jsonFieldName = fieldMeta.name;
           }
           if (fieldMeta.ignore == true) {
             continue;
           }
           if (fieldMeta.converter != null) {
             result[jsonFieldName] = fieldMeta.converter.toJSON(
                 fieldValue, fieldMeta, safeGetInstanceMirror(fieldValue)
             );
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

  static Object deserialize(String jsonString, dynamic instanceType) {
    ClassMirror cm = instance.classes[instanceType.toString()];
    Object objectInstance = cm.newInstance("", []);
    InstanceMirror im = instance.safeGetInstanceMirror(objectInstance);
    Map<String, dynamic> m = instance.jsonDecoder.convert(jsonString);

    for (String fieldName in instance.getPublicFieldNames(im.type)) {
      var fieldValue = m[fieldName];
      JsonProperty fieldMeta = instance.getFieldMetaData(fieldName, im.type);
      if (fieldMeta != null) {
        if (fieldMeta.name != null) {
          fieldValue = m[fieldMeta.name];
        }
        if (fieldMeta.ignore == true) {
          continue;
        }
        if (fieldMeta.converter != null) {
          im.invokeSetter(fieldName, fieldMeta.converter.fromJSON(
              fieldValue, fieldMeta, im.type.declarations[fieldName]
          ));
          continue;
        }
      }
      im.invokeSetter(fieldName, fieldValue);
    }
    return objectInstance;
  }
}