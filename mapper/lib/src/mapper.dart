import 'dart:convert' show JsonEncoder, JsonDecoder;
import 'dart:math';

import 'package:reflectable/reflectable.dart';

import 'errors.dart';
import 'model/index.dart';
import 'utils.dart';

/// Singleton class providing static methods for Dart objects conversion
/// from / to JSON string
class JsonMapper {
  static final JsonMapper instance = JsonMapper._internal();
  final JsonEncoder jsonEncoder = JsonEncoder.withIndent(' ');
  final JsonDecoder jsonDecoder = JsonDecoder();
  final serializable = const JsonSerializable();
  final Map<String, ClassMirror> classes = {};
  final Map<String, ProcessedObjectDescriptor> processedObjects = {};
  final Map<Type, ICustomConverter> converters = getDefaultConverters();
  final Map<Type, ValueDecoratorFunction> valueDecorators =
      getDefaultValueDecorators();
  final Map<int, ITypeInfoDecorator> typeInfoDecorators = {};

  /// Assign custom converter instance for certain type T
  static void registerConverter<T>(ICustomConverter converter) {
    instance.converters[T] = converter;
  }

  /// Assign custom value decorator function for certain type T
  static void registerValueDecorator<T>(ValueDecoratorFunction decorator) {
    instance.valueDecorators[T] = decorator;
  }

  /// Add custom typeInfo decorator
  static void registerTypeInfoDecorator(ITypeInfoDecorator decorator,
      [int priority]) {
    final nextPriority = priority ??
        instance.typeInfoDecorators.keys
                .reduce((value, item) => max(value, item)) +
            1;
    instance.typeInfoDecorators[nextPriority] = decorator;
  }

  /// Converts Dart object to JSON string
  static String toJson(Object object,
      [SerializationOptions options = defaultSerializationOptions]) {
    return serialize(object, options);
  }

  /// Converts Dart object to JSON string,
  static String serialize(Object object,
      [SerializationOptions options = defaultSerializationOptions]) {
    instance.processedObjects.clear();
    var encoder = instance.jsonEncoder;
    if (options.indent != null && options.indent.isEmpty) {
      encoder = JsonEncoder();
    } else {
      if (options.indent != null && options.indent.isNotEmpty) {
        encoder = JsonEncoder.withIndent(options.indent);
      }
    }
    return encoder.convert(instance.serializeObject(object, options));
  }

  /// Converts JSON string to Dart object of type T
  static T deserialize<T>(dynamic jsonValue,
      [DeserializationOptions options = defaultDeserializationOptions]) {
    assert(T != dynamic ? true : throw MissingTypeForDeserializationError());
    return instance.deserializeObject(jsonValue, T, null, options);
  }

  /// Converts JSON string to Dart object of type T
  static T fromJson<T>(dynamic jsonValue,
      [DeserializationOptions options = defaultDeserializationOptions]) {
    return deserialize<T>(jsonValue, options);
  }

  /// Converts Dart object to Map<String, dynamic>
  static Map<String, dynamic> toMap(Object object,
      [SerializationOptions options = defaultSerializationOptions]) {
    return deserialize<Map<String, dynamic>>(
        serialize(object, options), options);
  }

  /// Converts Map<String, dynamic> to Dart object instance
  static T fromMap<T>(Map<String, dynamic> map,
      [DeserializationOptions options = defaultDeserializationOptions]) {
    return deserialize<T>(instance.jsonEncoder.convert(map), options);
  }

  /// Clone Dart object of type T
  static T clone<T>(T object) {
    return fromJson<T>(toJson(object));
  }

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    for (var classMirror in serializable.annotatedClasses) {
      classes[classMirror.reflectedType.toString()] = classMirror;
    }

    registerDefaultTypeInfoDecorators();
  }

  void registerDefaultTypeInfoDecorators() {
    typeInfoDecorators[0] = defaultTypeInfoDecorator;
  }

  InstanceMirror safeGetInstanceMirror(Object object) {
    InstanceMirror result;
    try {
      result = serializable.reflect(object);
    } catch (error) {
      return result;
    }
    return result;
  }

  String getObjectKey(Object object) =>
      '${object.runtimeType}-${object.hashCode}';

  ProcessedObjectDescriptor getObjectProcessed(Object object) {
    ProcessedObjectDescriptor result;

    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
      return result;
    }

    final key = getObjectKey(object);
    if (processedObjects.containsKey(key)) {
      result = processedObjects[key];
      result.times++;
    } else {
      result = processedObjects[key] = ProcessedObjectDescriptor(object);
    }
    return result;
  }

  TypeInfo getTypeInfo(Type type) {
    var result = TypeInfo(type);
    typeInfoDecorators.values.forEach((ITypeInfoDecorator decorator) {
      result = decorator.decorate(result);
    });
    return result;
  }

  TypeInfo detectObjectType(
      dynamic objectInstance, Type objectType, JsonMap objectJsonMap) {
    final objectClassMirror = classes[objectType.toString()];
    final objectClassInfo = ClassInfo(objectClassMirror);
    final Json meta = objectClassInfo.metaData
        .firstWhere((m) => m is Json, orElse: () => null);

    if (objectInstance is Map<String, dynamic>) {
      objectJsonMap = JsonMap(objectInstance, meta);
    }
    final typeInfo = getTypeInfo(objectType ?? objectInstance.runtimeType);

    final String typeName = objectJsonMap != null &&
            meta != null &&
            meta.typeNameProperty != null &&
            objectJsonMap.hasProperty(meta.typeNameProperty)
        ? objectJsonMap.getPropertyValue(meta.typeNameProperty)
        : typeInfo.typeName;

    final type = classes[typeName] != null
        ? classes[typeName].reflectedType
        : typeInfo.type;
    return getTypeInfo(type);
  }

  Type getScalarType(Type type) {
    var result = dynamic;
    final typeInfo = getTypeInfo(type);
    final scalarTypeName = typeInfo.scalarTypeName;

    /// Known Types
    if (typeInfo.scalarType != null) {
      return typeInfo.scalarType;
    }

    /// Custom Types annotated with [@jsonSerializable]
    if (classes[scalarTypeName] != null) {
      return classes[scalarTypeName].reflectedType;
    }

    /// Search through value decorators for scalarType match
    valueDecorators.keys.forEach((Type type) {
      if (type.toString() == scalarTypeName) {
        result = type;
      }
    });

    return result;
  }

  ValueDecoratorFunction getValueDecorator(
      JsonProperty jsonProperty, Type type) {
    ValueDecoratorFunction result;
    if (result == null && valueDecorators[type] != null) {
      result = valueDecorators[type];
    }
    return result;
  }

  Type getDeclarationType(DeclarationMirror mirror) {
    var result = dynamic;
    VariableMirror variable;
    MethodMirror method;

    try {
      variable = mirror as VariableMirror;
      result = variable.hasReflectedType ? variable.reflectedType : null;
    } catch (error) {
      result = result;
    }

    try {
      method = mirror as MethodMirror;
      result =
          method.hasReflectedReturnType ? method.reflectedReturnType : null;
    } catch (error) {
      result = result;
    }

    return result ??= dynamic;
  }

  ICustomConverter getConverter(JsonProperty jsonProperty, Type declarationType,
      [Type valueType, InstanceMirror im]) {
    var result = jsonProperty != null ? jsonProperty.converter : null;
    if ((jsonProperty != null && jsonProperty.enumValues != null) &&
        result == null) {
      result = enumConverter;
    }

    var targetType = declarationType;
    if (declarationType == dynamic && valueType != null) {
      targetType = valueType;
    }

    final typeInfo = getTypeInfo(targetType);
    if (result == null && converters[targetType] != null) {
      result = converters[targetType];
    }
    if (result == null && typeInfo.isMap) {
      result = defaultConverter;
    }
    return result;
  }

  dynamic applyValueDecorator(dynamic value, TypeInfo typeInfo,
      [JsonProperty meta]) {
    final valueDecoratorFunction = getValueDecorator(meta, typeInfo.type);
    if (typeInfo.isSet && value is! Set && value is Iterable) {
      value = Set.from(value);
    }
    return valueDecoratorFunction != null && value != null
        ? valueDecoratorFunction(value)
        : value;
  }

  bool isFieldIgnored(Json classMeta, JsonProperty meta, dynamic value) =>
      (meta != null &&
          (meta.ignore == true ||
              meta.ignoreIfNull == true && value == null)) ||
      (classMeta != null &&
          classMeta.ignoreNullMembers == true &&
          value == null);

  void enumeratePublicFields(InstanceMirror instanceMirror, JsonMap jsonMap,
      DeserializationOptions options, Function visitor) {
    final classInfo = ClassInfo(instanceMirror.type);
    for (var name in classInfo.publicFieldNames) {
      var jsonName = name;
      final declarationMirror = classInfo.getDeclarationMirror(name);
      if (declarationMirror == null) {
        continue;
      }
      final declarationType = getDeclarationType(declarationMirror);
      final isGetterOnly = classInfo.isGetterOnly(name);
      final meta =
          classInfo.getDeclarationMeta(declarationMirror, options.scheme);
      final classMeta = classInfo.getMeta(options.scheme);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      jsonName = transformFieldName(jsonName, options.caseStyle);

      dynamic value = instanceMirror.invokeGetter(name);
      if (value == null && jsonMap != null) {
        if (isFieldIgnored(
            classMeta, meta, jsonMap.getPropertyValue(jsonName))) {
          continue;
        }
      } else {
        if (isFieldIgnored(classMeta, meta, value)) {
          continue;
        }
      }
      visitor(
          name,
          jsonName,
          value,
          isGetterOnly,
          meta,
          getConverter(
              meta, declarationType, value != null ? value.runtimeType : null),
          getScalarType(declarationType),
          getTypeInfo(declarationType));
    }
  }

  void enumerateConstructorParameters(ClassMirror classMirror,
      DeserializationOptions options, Function visitor) {
    final classInfo = ClassInfo(classMirror);
    final classMeta = classInfo.getMeta(options.scheme);
    final methodMirror = classInfo
        .getJsonConstructor(classMeta != null ? classMeta.scheme : null);
    if (methodMirror == null) {
      return;
    }
    methodMirror.parameters.forEach((ParameterMirror param) {
      final name = param.simpleName;
      final declarationMirror = classInfo.getDeclarationMirror(name) ?? param;
      var paramTypeInfo = getTypeInfo(param.reflectedType);
      paramTypeInfo = paramTypeInfo.isDynamic
          ? getTypeInfo(getDeclarationType(declarationMirror))
          : paramTypeInfo;
      var jsonName = name;
      final meta =
          classInfo.getDeclarationMeta(declarationMirror, options.scheme);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      jsonName = transformFieldName(jsonName, options.caseStyle);
      visitor(param, name, jsonName, classMeta, meta, paramTypeInfo);
    });
  }

  void dumpTypeNameToObjectProperty(JsonMap object, ClassMirror classMirror) {
    final classInfo = ClassInfo(classMirror);
    final Json meta =
        classInfo.metaData.firstWhere((m) => m is Json, orElse: () => null);
    if (meta != null && meta.typeNameProperty != null) {
      final typeInfo = getTypeInfo(classMirror.reflectedType);
      object.setPropertyValue(meta.typeNameProperty, typeInfo.typeName);
    }
  }

  Map<Symbol, dynamic> getNamedArguments(ClassMirror cm, JsonMap jsonMap,
      [DeserializationOptions options]) {
    final result = <Symbol, dynamic>{};

    enumerateConstructorParameters(cm, options,
        (param, name, jsonName, classMeta, meta, TypeInfo typeInfo) {
      if (param.isNamed && jsonMap.hasProperty(jsonName)) {
        var value = jsonMap.getPropertyValue(jsonName);
        if (isFieldIgnored(classMeta, meta, value)) {
          return;
        }
        final parameterTypeInfo = detectObjectType(value, typeInfo.type, null);
        if (parameterTypeInfo.isIterable) {
          value = (value as List)
              .map((item) => deserializeObject(
                  item, getScalarType(parameterTypeInfo.type), meta, options))
              .toList();
        } else {
          value =
              deserializeObject(value, parameterTypeInfo.type, meta, options);
        }
        result[Symbol(name)] =
            applyValueDecorator(value, parameterTypeInfo, meta);
      }
    });

    return result;
  }

  List getPositionalArguments(ClassMirror cm, JsonMap jsonMap,
      [DeserializationOptions options]) {
    final result = [];

    enumerateConstructorParameters(cm, options, (param, name, jsonName,
        classMeta, JsonProperty meta, TypeInfo typeInfo) {
      if (!param.isOptional &&
          !param.isNamed &&
          jsonMap.hasProperty(jsonName)) {
        var value = jsonMap.getPropertyValue(jsonName);
        final parameterTypeInfo = detectObjectType(value, typeInfo.type, null);
        if (parameterTypeInfo.isIterable) {
          value = (value as List)
              .map((item) => deserializeObject(
                  item, getScalarType(parameterTypeInfo.type), meta, options))
              .toList();
        } else {
          value =
              deserializeObject(value, parameterTypeInfo.type, meta, options);
        }
        value = applyValueDecorator(value, parameterTypeInfo, meta);
        if (isFieldIgnored(classMeta, meta, value)) {
          value = null;
        }
        result.add(value);
      }
    });

    return result;
  }

  dynamic serializeObject(Object object, [SerializationOptions options]) {
    if (object == null) {
      return object;
    }

    final im = safeGetInstanceMirror(object);
    final converter = getConverter(null, object.runtimeType, null, im);
    if (converter != null) {
      return converter.toJSON(object, null);
    }

    if (object is Iterable) {
      return object.map((item) => serializeObject(item, options)).toList();
    }

    if (im == null || im.type == null) {
      if (im != null) {
        throw MissingEnumValuesError(object.runtimeType);
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
      }
    }

    final jsonMeta = ClassInfo(im.type).getMeta(options.scheme);
    final result = JsonMap(options.template ?? {}, jsonMeta);
    final processedObjectDescriptor = getObjectProcessed(object);
    if (processedObjectDescriptor != null &&
        processedObjectDescriptor.times >= 1) {
      final allowanceIsSet =
          (jsonMeta != null && jsonMeta.allowCircularReferences > 0);
      final allowanceExceeded = (allowanceIsSet &&
              processedObjectDescriptor.times >
                  jsonMeta.allowCircularReferences)
          ? true
          : null;
      if (allowanceExceeded == true) {
        return null;
      }
      if (allowanceIsSet == false) {
        throw CircularReferenceError(object);
      }
    }
    dumpTypeNameToObjectProperty(result, im.type);
    enumeratePublicFields(im, null, options, (name, jsonName, value,
        isGetterOnly, meta, converter, scalarType, TypeInfo typeInfo) {
      if (converter != null) {
        final valueTypeInfo = getTypeInfo(value.runtimeType);
        dynamic convert(item) => converter.toJSON(item, meta);
        if (valueTypeInfo.isList) {
          result.setPropertyValue(jsonName, value.map(convert).toList());
        } else {
          result.setPropertyValue(jsonName, convert(value));
        }
      } else {
        result.setPropertyValue(jsonName, serializeObject(value, options));
      }
    });
    return result.map;
  }

  Object deserializeObject(dynamic jsonValue, Type instanceType,
      [JsonProperty parentMeta, DeserializationOptions options]) {
    if (jsonValue == null) {
      return null;
    }
    var typeInfo = getTypeInfo(instanceType);
    final converter = getConverter(parentMeta, typeInfo.type);
    if (converter != null) {
      return converter.fromJSON(jsonValue, parentMeta);
    }

    if (typeInfo.isIterable) {
      List<dynamic> jsonList =
          (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
      var value = jsonList
          .map((item) => deserializeObject(
              item, getScalarType(typeInfo.type), null, options))
          .toList();
      return applyValueDecorator(value, typeInfo, parentMeta);
    }

    JsonMap jsonMap;
    try {
      jsonMap = JsonMap(
          (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue);
    } on FormatException {
      throw MissingEnumValuesError(typeInfo.type);
    }
    typeInfo = detectObjectType(null, instanceType, jsonMap);
    final cm = classes[typeInfo.typeName];
    if (cm == null) {
      throw MissingAnnotationOnTypeError(typeInfo.type);
    }
    final classInfo = ClassInfo(cm);
    jsonMap.jsonMeta = classInfo.getMeta(options.scheme);

    final objectInstance = cm.isEnum
        ? null
        : cm.newInstance(
            classInfo.getJsonConstructor(options.scheme).constructorName,
            getPositionalArguments(cm, jsonMap, options),
            getNamedArguments(cm, jsonMap, options));
    final im = safeGetInstanceMirror(objectInstance);

    enumeratePublicFields(im, jsonMap, options, (name,
        jsonName,
        value,
        isGetterOnly,
        JsonProperty meta,
        converter,
        scalarType,
        TypeInfo typeInfo) {
      if (!jsonMap.hasProperty(jsonName)) {
        return;
      }
      var fieldValue = jsonMap.getPropertyValue(jsonName);
      if (fieldValue is List) {
        fieldValue = fieldValue
            .map((item) => deserializeObject(item, scalarType, meta, options))
            .toList();
      } else {
        fieldValue =
            deserializeObject(fieldValue, typeInfo.type, meta, options);
      }
      if (converter != null) {
        dynamic convert(item) => converter.fromJSON(item, meta);
        final valueTypeInfo = getTypeInfo(fieldValue.runtimeType);
        if (valueTypeInfo.isList) {
          fieldValue = fieldValue.map(convert).toList();
        } else {
          fieldValue = convert(fieldValue);
        }
      }
      if (!isGetterOnly) {
        fieldValue = applyValueDecorator(fieldValue, typeInfo, meta);
        im.invokeSetter(name, fieldValue);
      }
    });
    return objectInstance;
  }
}
