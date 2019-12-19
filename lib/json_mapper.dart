library json_mapper;

import 'dart:convert' show JsonEncoder, JsonDecoder;
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import 'package:dart_json_mapper/errors.dart';
import 'package:dart_json_mapper/type_info.dart';
import 'package:dart_json_mapper/utils.dart';
import "package:reflectable/reflectable.dart";

/// Singleton class providing static methods for Dart objects conversion
/// from / to JSON string
class JsonMapper {
  static final JsonMapper instance = JsonMapper._internal();
  final JsonEncoder jsonEncoder = JsonEncoder.withIndent(" ");
  final JsonDecoder jsonDecoder = JsonDecoder();
  final serializable = const JsonSerializable();
  final Map<String, ClassMirror> classes = {};
  final Map<String, Object> processedObjects = {};
  final Map<Type, ICustomConverter> converters = {};
  final Map<Type, ValueDecoratorFunction> valueDecorators = {};
  final Map<int, ITypeInfoDecorator> typeInfoDecorators = {};

  /// Assign custom converter instance for certain Type
  static void registerConverter<T>(ICustomConverter converter) {
    instance.converters[T] = converter;
  }

  /// Assign custom value decorator function for certain Type
  static void registerValueDecorator<T>(ValueDecoratorFunction decorator) {
    instance.valueDecorators[T] = decorator;
  }

  /// Add custom typeInfo decorator
  static void registerTypeInfoDecorator(ITypeInfoDecorator decorator,
      [int priority]) {
    int nextPriority = priority != null
        ? priority
        : instance.typeInfoDecorators.keys
                .reduce((value, item) => max(value, item)) +
            1;
    instance.typeInfoDecorators[nextPriority] = decorator;
  }

  /// Converts Dart object to JSON string, indented by `indent`
  static String toJson(Object object, [String indent]) {
    return serialize(object, indent);
  }

  /// Converts Dart object to JSON string, indented by `indent`
  static String serialize(Object object, [String indent]) {
    instance.processedObjects.clear();
    JsonEncoder encoder = instance.jsonEncoder;
    if (indent != null && indent.isEmpty) {
      encoder = JsonEncoder();
    } else {
      if (indent != null && indent.isNotEmpty) {
        encoder = JsonEncoder.withIndent(indent);
      }
    }
    return encoder.convert(instance.serializeObject(object));
  }

  /// Converts JSON string to Dart object of type T
  static T deserialize<T>(String jsonValue) {
    assert(T != dynamic ? true : throw MissingTypeForDeserializationError());
    return instance.deserializeObject(jsonValue, T);
  }

  /// Converts JSON string to Dart object of type T
  static T fromJson<T>(String jsonValue) {
    return deserialize<T>(jsonValue);
  }

  /// Clone Dart object of type T
  static T clone<T>(T object) {
    return fromJson<T>(toJson(object));
  }

  /// Converts Dart object to Map<String, dynamic>
  static Map<String, dynamic> toMap(Object object) {
    return deserialize(serialize(object));
  }

  /// Converts Map<String, dynamic> to Dart object instance
  static T fromMap<T>(Map<String, dynamic> map) {
    return deserialize<T>(instance.jsonEncoder.convert(map));
  }

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    for (ClassMirror classMirror in serializable.annotatedClasses) {
      classes[classMirror.reflectedType.toString()] = classMirror;
    }
    registerDefaultConverters();
    registerDefaultValueDecorators();
    registerDefaultTypeInfoDecorators();
  }

  Type _typeOf<T>() => T;

  void registerDefaultTypeInfoDecorators() {
    typeInfoDecorators[0] = defaultTypeInfoDecorator;
  }

  void registerDefaultValueDecorators() {
    // Dart built-in types
    // List
    valueDecorators[_typeOf<List<String>>()] = (value) => value.cast<String>();
    valueDecorators[_typeOf<List<DateTime>>()] =
        (value) => value.cast<DateTime>();
    valueDecorators[_typeOf<List<num>>()] = (value) => value.cast<num>();
    valueDecorators[_typeOf<List<int>>()] = (value) => value.cast<int>();
    valueDecorators[_typeOf<List<double>>()] = (value) => value.cast<double>();
    valueDecorators[_typeOf<List<bool>>()] = (value) => value.cast<bool>();
    valueDecorators[_typeOf<List<Symbol>>()] = (value) => value.cast<Symbol>();
    valueDecorators[_typeOf<List<BigInt>>()] = (value) => value.cast<BigInt>();

    // Set
    valueDecorators[_typeOf<Set<String>>()] = (value) => value.cast<String>();
    valueDecorators[_typeOf<Set<DateTime>>()] =
        (value) => value.cast<DateTime>();
    valueDecorators[_typeOf<Set<num>>()] = (value) => value.cast<num>();
    valueDecorators[_typeOf<Set<int>>()] = (value) => value.cast<int>();
    valueDecorators[_typeOf<Set<double>>()] = (value) => value.cast<double>();
    valueDecorators[_typeOf<Set<bool>>()] = (value) => value.cast<bool>();
    valueDecorators[_typeOf<Set<Symbol>>()] = (value) => value.cast<Symbol>();
    valueDecorators[_typeOf<Set<BigInt>>()] = (value) => value.cast<BigInt>();

    // Typed data
    valueDecorators[_typeOf<Uint8List>()] =
        (value) => Uint8List.fromList(value.cast<int>());
  }

  void registerDefaultConverters() {
    // Built-in types
    converters[dynamic] = defaultConverter;
    converters[String] = defaultConverter;
    converters[bool] = defaultConverter;
    converters[Symbol] = symbolConverter;
    converters[DateTime] = dateConverter;
    converters[num] = numberConverter;
    converters[int] = numberConverter;
    converters[double] = numberConverter;
    converters[BigInt] = bigIntConverter;
    converters[_typeOf<Map<String, dynamic>>()] = mapStringDynamicConverter;

    // Typed data
    converters[Uint8List] = uint8ListConverter;
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

  bool isObjectAlreadyProcessed(Object object) {
    bool result = false;

    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
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

  TypeInfo getTypeInfo(Type type) {
    var result = TypeInfo(type);
    typeInfoDecorators.values.forEach((ITypeInfoDecorator decorator) {
      result = decorator.decorate(result);
    });
    return result;
  }

  TypeInfo detectObjectType(dynamic objectInstance, Type objectType,
      Map<String, dynamic> objectJsonMap) {
    final ClassMirror objectClassMirror = classes[objectType.toString()];
    final ClassInfo objectClassInfo = ClassInfo(objectClassMirror);
    final Json meta = objectClassInfo.metaData
        .firstWhere((m) => m is Json, orElse: () => null);

    if (objectInstance is Map<String, dynamic>) {
      objectJsonMap = objectInstance;
    }
    final TypeInfo typeInfo = getTypeInfo(
        objectType != null ? objectType : objectInstance.runtimeType);

    final String typeName = objectJsonMap != null &&
            meta != null &&
            meta.typeNameProperty != null &&
            objectJsonMap.containsKey(meta.typeNameProperty)
        ? objectJsonMap[meta.typeNameProperty]
        : typeInfo.typeName;

    final Type type = classes[typeName] != null
        ? classes[typeName].reflectedType
        : typeInfo.type;
    return getTypeInfo(type);
  }

  Type getScalarType(Type type) {
    TypeInfo typeInfo = getTypeInfo(type);
    String scalarTypeName = typeInfo.scalarTypeName;

    /// Known Types
    if (typeInfo.scalarType != null) {
      return typeInfo.scalarType;
    }

    /// Custom Types annotated with [@jsonSerializable]
    if (classes[scalarTypeName] != null) {
      return classes[scalarTypeName].reflectedType;
    }

    return type;
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
    Type result = dynamic;
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

    if (result == null) {
      result = dynamic;
    }
    return result;
  }

  ICustomConverter getConverter(JsonProperty jsonProperty, Type declarationType,
      [Type valueType, InstanceMirror im]) {
    ICustomConverter result =
        jsonProperty != null ? jsonProperty.converter : null;
    if ((jsonProperty != null && jsonProperty.enumValues != null ||
            isEnumInstance(im)) &&
        result == null) {
      result = enumConverter;
    }

    Type targetType = declarationType;
    if (declarationType == dynamic && valueType != null) {
      targetType = valueType;
    }

    TypeInfo typeInfo = getTypeInfo(targetType);
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
    ValueDecoratorFunction valueDecoratorFunction =
        getValueDecorator(meta, typeInfo.type);
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

  enumeratePublicFields(InstanceMirror instanceMirror,
      Map<String, dynamic> jsonMap, Function visitor) {
    ClassInfo classInfo = ClassInfo(instanceMirror.type);
    for (String name in classInfo.publicFieldNames) {
      String jsonName = name;
      DeclarationMirror declarationMirror =
          classInfo.getDeclarationMirror(name);
      if (declarationMirror == null) {
        continue;
      }
      Type declarationType = getDeclarationType(declarationMirror);
      bool isGetterOnly = classInfo.isGetterOnly(name);
      JsonProperty meta = classInfo
          .lookupDeclarationMetaData(declarationMirror)
          .firstWhere((m) => m is JsonProperty, orElse: () => null);
      Json classMeta =
          classInfo.metaData.firstWhere((m) => m is Json, orElse: () => null);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      dynamic value = instanceMirror.invokeGetter(name);
      if (value == null && jsonMap != null) {
        if (isFieldIgnored(classMeta, meta, jsonMap[jsonName])) {
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

  enumerateConstructorParameters(ClassMirror classMirror, Function visitor) {
    ClassInfo classInfo = ClassInfo(classMirror);
    Json classMeta =
        classInfo.metaData.firstWhere((m) => m is Json, orElse: () => null);
    MethodMirror methodMirror = classInfo.publicConstructor;
    if (methodMirror == null) {
      return;
    }
    methodMirror.parameters.forEach((ParameterMirror param) {
      String name = param.simpleName;
      DeclarationMirror declarationMirror =
          ClassInfo(classMirror).getDeclarationMirror(name);
      TypeInfo paramTypeInfo = getTypeInfo(param.reflectedType);
      if (declarationMirror == null) {
        return;
      }
      paramTypeInfo = paramTypeInfo.isDynamic
          ? getTypeInfo(getDeclarationType(declarationMirror))
          : paramTypeInfo;
      String jsonName = name;
      JsonProperty meta = declarationMirror.metadata
          .firstWhere((m) => m is JsonProperty, orElse: () => null);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }

      visitor(param, name, jsonName, classMeta, meta, paramTypeInfo);
    });
  }

  dumpTypeNameToObjectProperty(dynamic object, ClassMirror classMirror) {
    ClassInfo classInfo = ClassInfo(classMirror);
    final Json meta =
        classInfo.metaData.firstWhere((m) => m is Json, orElse: () => null);
    if (meta != null && meta.typeNameProperty != null) {
      final typeInfo = getTypeInfo(classMirror.reflectedType);
      object[meta.typeNameProperty] = typeInfo.typeName;
    }
  }

  Map<Symbol, dynamic> getNamedArguments(
      ClassMirror cm, Map<String, dynamic> jsonMap) {
    Map<Symbol, dynamic> result = Map();

    enumerateConstructorParameters(cm,
        (param, name, jsonName, classMeta, meta, TypeInfo typeInfo) {
      if (param.isNamed && jsonMap.containsKey(jsonName)) {
        var value = jsonMap[jsonName];
        if (isFieldIgnored(classMeta, meta, value)) {
          return;
        }
        TypeInfo parameterTypeInfo =
            detectObjectType(value, typeInfo.type, null);
        if (parameterTypeInfo.isIterable) {
          value = (value as List)
              .map((item) => deserializeObject(
                  item, getScalarType(parameterTypeInfo.type), meta))
              .toList();
        } else {
          value = deserializeObject(value, parameterTypeInfo.type, meta);
        }
        result[Symbol(name)] =
            applyValueDecorator(value, parameterTypeInfo, meta);
      }
    });

    return result;
  }

  List getPositionalArguments(ClassMirror cm, Map<String, dynamic> jsonMap) {
    List result = [];

    enumerateConstructorParameters(cm, (param, name, jsonName, classMeta,
        JsonProperty meta, TypeInfo typeInfo) {
      if (!param.isOptional &&
          !param.isNamed &&
          jsonMap.containsKey(jsonName)) {
        var value = jsonMap[jsonName];
        TypeInfo parameterTypeInfo =
            detectObjectType(value, typeInfo.type, null);
        if (parameterTypeInfo.isIterable) {
          value = (value as List)
              .map((item) => deserializeObject(
                  item, getScalarType(parameterTypeInfo.type), meta))
              .toList();
        } else {
          value = deserializeObject(value, parameterTypeInfo.type, meta);
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

  dynamic serializeObject(Object object) {
    if (object == null) {
      return object;
    }

    if (isObjectAlreadyProcessed(object)) {
      throw CircularReferenceError(object);
    }

    InstanceMirror im = safeGetInstanceMirror(object);

    ICustomConverter converter =
        getConverter(null, object.runtimeType, null, im);
    if (converter != null) {
      return converter.toJSON(object, null);
    }

    if (object is Iterable) {
      return object.map(serializeObject).toList();
    }

    if (im == null || im.type == null) {
      if (im != null) {
        throw MissingEnumValuesError(object.runtimeType);
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
      }
    }

    Map result = {};
    dumpTypeNameToObjectProperty(result, im.type);
    enumeratePublicFields(im, null, (name, jsonName, value, isGetterOnly, meta,
        converter, scalarType, TypeInfo typeInfo) {
      if (converter != null) {
        TypeInfo valueTypeInfo = getTypeInfo(value.runtimeType);
        convert(item) => converter.toJSON(item, meta);
        if (valueTypeInfo.isList) {
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

  Object deserializeObject(dynamic jsonValue, Type instanceType,
      [JsonProperty parentMeta]) {
    if (jsonValue == null) {
      return null;
    }
    TypeInfo typeInfo = getTypeInfo(instanceType);
    ICustomConverter converter = getConverter(parentMeta, typeInfo.type);
    if (converter != null) {
      return converter.fromJSON(jsonValue, parentMeta);
    }

    if (typeInfo.isIterable) {
      List<dynamic> jsonList =
          (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
      var value = jsonList
          .map((item) => deserializeObject(item, getScalarType(typeInfo.type)))
          .toList();
      return applyValueDecorator(value, typeInfo, parentMeta);
    }

    Map<String, dynamic> jsonMap;
    try {
      jsonMap =
          (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
    } on FormatException {
      throw MissingEnumValuesError(typeInfo.type);
    }
    typeInfo = detectObjectType(null, instanceType, jsonMap);
    ClassMirror cm = classes[typeInfo.typeName];
    if (cm == null) {
      throw MissingAnnotationOnTypeError(typeInfo.type);
    }

    Object objectInstance = cm.isEnum
        ? null
        : cm.newInstance("", getPositionalArguments(cm, jsonMap),
            getNamedArguments(cm, jsonMap));
    InstanceMirror im = safeGetInstanceMirror(objectInstance);

    enumeratePublicFields(im, jsonMap, (name, jsonName, value, isGetterOnly,
        JsonProperty meta, converter, scalarType, TypeInfo typeInfo) {
      if (!jsonMap.containsKey(jsonName)) {
        return;
      }
      var fieldValue = jsonMap[jsonName];
      if (fieldValue is List) {
        fieldValue = fieldValue
            .map((item) => deserializeObject(item, scalarType, meta))
            .toList();
      } else {
        fieldValue = deserializeObject(fieldValue, typeInfo.type, meta);
      }
      if (converter != null) {
        convert(item) => converter.fromJSON(item, meta);
        TypeInfo valueTypeInfo = getTypeInfo(fieldValue.runtimeType);
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
