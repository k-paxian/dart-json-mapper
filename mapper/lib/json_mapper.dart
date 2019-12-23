library json_mapper;

import 'dart:convert' show JsonEncoder, JsonDecoder;
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import 'package:dart_json_mapper/errors.dart';
import 'package:dart_json_mapper/type_info.dart';
import 'package:dart_json_mapper/utils.dart';
import 'package:reflectable/reflectable.dart';

/// Singleton class providing static methods for Dart objects conversion
/// from / to JSON string
class JsonMapper {
  static final JsonMapper instance = JsonMapper._internal();
  final JsonEncoder jsonEncoder = JsonEncoder.withIndent(' ');
  final JsonDecoder jsonDecoder = JsonDecoder();
  final serializable = const JsonSerializable();
  final Map<String, ClassMirror> classes = {};
  final Map<String, Object> processedObjects = {};
  final Map<Type, ICustomConverter> converters = {};
  final Map<Type, ValueDecoratorFunction> valueDecorators = {};
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

  /// Converts Dart object to JSON string, indented by `indent`, according to specified `scheme`
  static String toJson(Object object, [String indent, dynamic scheme]) {
    return serialize(object, indent, scheme);
  }

  /// Converts Dart object to JSON string, indented by `indent`, according to specified `scheme`
  static String serialize(Object object, [String indent, dynamic scheme]) {
    instance.processedObjects.clear();
    var encoder = instance.jsonEncoder;
    if (indent != null && indent.isEmpty) {
      encoder = JsonEncoder();
    } else {
      if (indent != null && indent.isNotEmpty) {
        encoder = JsonEncoder.withIndent(indent);
      }
    }
    return encoder.convert(instance.serializeObject(object, scheme));
  }

  /// Converts JSON string to Dart object of type T, according to specified `scheme`
  static T deserialize<T>(dynamic jsonValue, [dynamic scheme]) {
    assert(T != dynamic ? true : throw MissingTypeForDeserializationError());
    return instance.deserializeObject(jsonValue, T, null, scheme);
  }

  /// Converts JSON string to Dart object of type T, according to specified `scheme`
  static T fromJson<T>(dynamic jsonValue, [dynamic scheme]) {
    return deserialize<T>(jsonValue, scheme);
  }

  /// Clone Dart object of type T
  static T clone<T>(T object) {
    return fromJson<T>(toJson(object));
  }

  /// Converts Dart object to Map<String, dynamic>, according to specified `scheme`
  static Map<String, dynamic> toMap(Object object, [dynamic scheme]) {
    return deserialize<Map<String, dynamic>>(
        serialize(object, null, scheme), scheme);
  }

  /// Converts Map<String, dynamic> to Dart object instance, according to specified `scheme`
  static T fromMap<T>(Map<String, dynamic> map, [dynamic scheme]) {
    return deserialize<T>(instance.jsonEncoder.convert(map), scheme);
  }

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    for (var classMirror in serializable.annotatedClasses) {
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
    var result = false;

    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
      return result;
    }

    final key = getObjectKey(object);
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
    if ((jsonProperty != null && jsonProperty.enumValues != null ||
            isEnumInstance(im)) &&
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
      dynamic scheme, Function visitor) {
    final classInfo = ClassInfo(instanceMirror.type);
    for (var name in classInfo.publicFieldNames) {
      var jsonName = name;
      final declarationMirror = classInfo.getDeclarationMirror(name);
      if (declarationMirror == null) {
        continue;
      }
      final declarationType = getDeclarationType(declarationMirror);
      final isGetterOnly = classInfo.isGetterOnly(name);
      final meta = classInfo.getDeclarationMeta(declarationMirror, scheme);
      final classMeta = classInfo.getMeta(scheme);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
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

  void enumerateConstructorParameters(
      ClassMirror classMirror, dynamic scheme, Function visitor) {
    final classInfo = ClassInfo(classMirror);
    final classMeta = classInfo.getMeta(scheme);
    final methodMirror = classInfo.publicConstructor;
    if (methodMirror == null) {
      return;
    }
    methodMirror.parameters.forEach((ParameterMirror param) {
      final name = param.simpleName;
      final declarationMirror = classInfo.getDeclarationMirror(name);
      var paramTypeInfo = getTypeInfo(param.reflectedType);
      if (declarationMirror == null) {
        return;
      }
      paramTypeInfo = paramTypeInfo.isDynamic
          ? getTypeInfo(getDeclarationType(declarationMirror))
          : paramTypeInfo;
      var jsonName = name;
      final meta = classInfo.getDeclarationMeta(declarationMirror, scheme);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }

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
      [dynamic scheme]) {
    final result = <Symbol, dynamic>{};

    enumerateConstructorParameters(cm, scheme,
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

  List getPositionalArguments(ClassMirror cm, JsonMap jsonMap,
      [dynamic scheme]) {
    final result = [];

    enumerateConstructorParameters(cm, scheme, (param, name, jsonName,
        classMeta, JsonProperty meta, TypeInfo typeInfo) {
      if (!param.isOptional &&
          !param.isNamed &&
          jsonMap.hasProperty(jsonName)) {
        var value = jsonMap.getPropertyValue(jsonName);
        final parameterTypeInfo = detectObjectType(value, typeInfo.type, null);
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

  dynamic serializeObject(Object object, [dynamic scheme]) {
    if (object == null) {
      return object;
    }

    if (isObjectAlreadyProcessed(object)) {
      throw CircularReferenceError(object);
    }

    final im = safeGetInstanceMirror(object);

    final converter = getConverter(null, object.runtimeType, null, im);
    if (converter != null) {
      return converter.toJSON(object, null);
    }

    if (object is Iterable) {
      return object.map((item) => serializeObject(item, scheme)).toList();
    }

    if (im == null || im.type == null) {
      if (im != null) {
        throw MissingEnumValuesError(object.runtimeType);
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
      }
    }

    final result = JsonMap({}, ClassInfo(im.type).getMeta(scheme));
    dumpTypeNameToObjectProperty(result, im.type);
    enumeratePublicFields(im, null, scheme, (name, jsonName, value,
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
        result.setPropertyValue(jsonName, serializeObject(value, scheme));
      }
    });
    return result.map;
  }

  Object deserializeObject(dynamic jsonValue, Type instanceType,
      [JsonProperty parentMeta, dynamic scheme]) {
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
              item, getScalarType(typeInfo.type), null, scheme))
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
    jsonMap.jsonMeta = ClassInfo(cm).getMeta(scheme);

    final objectInstance = cm.isEnum
        ? null
        : cm.newInstance('', getPositionalArguments(cm, jsonMap, scheme),
            getNamedArguments(cm, jsonMap, scheme));
    final im = safeGetInstanceMirror(objectInstance);

    enumeratePublicFields(im, jsonMap, scheme, (name,
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
            .map((item) => deserializeObject(item, scalarType, meta, scheme))
            .toList();
      } else {
        fieldValue = deserializeObject(fieldValue, typeInfo.type, meta, scheme);
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
