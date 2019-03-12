library json_mapper;

import 'dart:convert' show JsonEncoder, JsonDecoder;
import 'dart:typed_data' show Uint8List;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import 'package:dart_json_mapper/errors.dart';
import "package:fixnum/fixnum.dart" show Int32, Int64;
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

  /// Customize name for Json property to store class type name
  static String typeNameProperty = DEFAULT_TYPE_NAME_PROPERTY;

  /// Assign custom converter instance for certain Type
  static void registerConverter<T>(ICustomConverter converter) {
    instance.converters[T] = converter;
  }

  /// Assign custom value decorator function for certain Type
  static void registerValueDecorator<T>(ValueDecoratorFunction valueDecorator) {
    instance.valueDecorators[T] = valueDecorator;
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
      classes[classMirror.simpleName] = classMirror;
    }
    registerDefaultConverters();
    registerDefaultValueDecorators();
  }

  Type _typeOf<T>() {
    return T;
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

    // fixnum
    converters[Int32] = int32Converter;
    converters[Int64] = int64Converter;
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
          final isGetterAndSetter = method.isGetter &&
              classMirror.instanceMembers[method.simpleName + '='] != null;
          return (method.isGetter &&
                  (method.isSynthetic || isGetterAndSetter)) &&
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

  Type getScalarType(Type type) {
    TypeInfo typeInfo = TypeInfo(type);
    String scalarTypeName = typeInfo.scalarTypeName;

    /// Dart Built-in Types
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
    ValueDecoratorFunction result =
        jsonProperty != null ? jsonProperty.valueDecoratorFunction : null;
    if (result == null && valueDecorators[type] != null) {
      result = valueDecorators[type];
    }
    return result;
  }

  Type getDeclarationType(DeclarationMirror mirror) {
    Type result;
    VariableMirror variable;
    MethodMirror method;

    try {
      variable = mirror as VariableMirror;
      result = variable.hasReflectedType ? variable.reflectedType : null;
    } catch (error) {}

    try {
      method = mirror as MethodMirror;
      result =
          method.hasReflectedReturnType ? method.reflectedReturnType : null;
    } catch (error) {}

    if (result == null) {
      result = dynamic;
    }
    return result;
  }

  DeclarationMirror getDeclarationMirror(ClassMirror classMirror, String name) {
    DeclarationMirror result;
    try {
      result = classMirror.declarations[name] as VariableMirror;
    } catch (error) {}
    if (result == null) {
      classMirror.instanceMembers
          .forEach((memberName, MethodMirror methodMirror) {
        if (memberName == name) {
          result = methodMirror;
        }
      });
    }
    return result;
  }

  ICustomConverter getConverter(JsonProperty jsonProperty, Type declarationType,
      [Type valueType]) {
    ICustomConverter result =
        jsonProperty != null ? jsonProperty.converter : null;
    if (jsonProperty != null &&
        jsonProperty.enumValues != null &&
        result == null) {
      result = enumConverter;
    }

    Type targetType = declarationType;
    if (declarationType == dynamic && valueType != null) {
      targetType = valueType;
    }

    TypeInfo typeInfo = TypeInfo(targetType);
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
    return valueDecoratorFunction != null
        ? valueDecoratorFunction(value)
        : value;
  }

  ClassMirror safeGetParentClassMirror(DeclarationMirror declarationMirror) {
    ClassMirror result;
    try {
      result = declarationMirror.owner;
    } catch (error) {}
    return result;
  }

  List<Object> lookupMetaData(DeclarationMirror declarationMirror) {
    final result = []..addAll(declarationMirror.metadata);
    final ClassMirror parentClassMirror =
        safeGetParentClassMirror(declarationMirror);
    if (parentClassMirror == null) {
      return result;
    }
    final DeclarationMirror parentDeclarationMirror =
        getDeclarationMirror(parentClassMirror, declarationMirror.simpleName);
    result.addAll(parentClassMirror.isTopLevel
        ? parentDeclarationMirror.metadata
        : lookupMetaData(parentDeclarationMirror));
    return result;
  }

  bool isFieldIgnored(JsonProperty meta, dynamic value) {
    return meta != null &&
        (meta.ignore == true || meta.ignoreIfNull == true && value == null);
  }

  enumeratePublicFields(InstanceMirror instanceMirror, Function visitor) {
    ClassMirror classMirror = instanceMirror.type;
    for (String name in getPublicFieldNames(classMirror)) {
      String jsonName = name;
      DeclarationMirror declarationMirror =
          getDeclarationMirror(classMirror, name);
      if (declarationMirror == null) {
        continue;
      }
      Type variableScalarType =
          getScalarType(getDeclarationType(declarationMirror));
      bool isGetterOnly = classMirror.instanceMembers[name + '='] == null;
      JsonProperty meta = lookupMetaData(declarationMirror)
          .firstWhere((m) => m is JsonProperty, orElse: () => null);
      dynamic value = instanceMirror.invokeGetter(name);
      if (isFieldIgnored(meta, value)) {
        continue;
      }
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      visitor(
          name,
          jsonName,
          value,
          isGetterOnly,
          meta,
          getConverter(meta, variableScalarType,
              value != null ? value.runtimeType : null),
          variableScalarType,
          TypeInfo(getDeclarationType(declarationMirror)));
    }
  }

  enumerateConstructorParameters(ClassMirror classMirror, Function visitor) {
    MethodMirror methodMirror = getPublicConstructor(classMirror);
    if (methodMirror == null) {
      return;
    }
    methodMirror.parameters.forEach((ParameterMirror param) {
      String name = param.simpleName;
      DeclarationMirror declarationMirror =
          getDeclarationMirror(classMirror, name);
      if (declarationMirror == null) {
        return;
      }
      String jsonName = name;
      JsonProperty meta = declarationMirror.metadata
          .firstWhere((m) => m is JsonProperty, orElse: () => null);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }

      visitor(param, name, jsonName, meta,
          TypeInfo(getDeclarationType(declarationMirror)));
    });
  }

  dumpTypeNameToObjectProperty(dynamic object, ClassMirror classMirror) {
    final Json meta =
        classMirror.metadata.firstWhere((m) => m is Json, orElse: () => null);
    if (meta != null && meta.includeTypeName == true) {
      final typeInfo = TypeInfo(classMirror.reflectedType);
      object[typeNameProperty] = typeInfo.typeName;
    }
  }

  TypeInfo detectObjectType(dynamic objectInstance, Type objectType,
      Map<String, dynamic> objectJsonMap) {
    if (objectInstance is Map<String, dynamic>) {
      objectJsonMap = objectInstance;
    }
    TypeInfo typeInfo =
        TypeInfo(objectType != null ? objectType : objectInstance.runtimeType);
    String typeName =
        objectJsonMap != null && objectJsonMap.containsKey(typeNameProperty)
            ? objectJsonMap[typeNameProperty]
            : typeInfo.typeName;
    Type type = classes[typeName] != null
        ? classes[typeName].reflectedType
        : typeInfo.type;
    return TypeInfo(type);
  }

  Map<Symbol, dynamic> getNamedArguments(
      ClassMirror cm, Map<String, dynamic> jsonMap) {
    Map<Symbol, dynamic> result = Map();

    enumerateConstructorParameters(cm,
        (param, name, jsonName, meta, TypeInfo typeInfo) {
      if (param.isNamed && jsonMap.containsKey(jsonName)) {
        var value = jsonMap[jsonName];
        if (isFieldIgnored(meta, value)) {
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

    enumerateConstructorParameters(cm,
        (param, name, jsonName, JsonProperty meta, TypeInfo typeInfo) {
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
        if (isFieldIgnored(meta, value)) {
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

    ICustomConverter converter = getConverter(null, object.runtimeType);
    if (converter != null) {
      return converter.toJSON(object, null);
    }

    if (object is Iterable) {
      return object.map(serializeObject).toList();
    }
    InstanceMirror im = safeGetInstanceMirror(object);

    if (im == null || im.type == null) {
      if (im != null) {
        throw MissingEnumValuesError(object.runtimeType);
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
      }
    }

    Map result = {};
    dumpTypeNameToObjectProperty(result, im.type);
    enumeratePublicFields(im, (name, jsonName, value, isGetterOnly, meta,
        converter, scalarType, TypeInfo typeInfo) {
      if (converter != null) {
        TypeInfo valueTypeInfo = TypeInfo(value.runtimeType);
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
    TypeInfo typeInfo = TypeInfo(instanceType);
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

    Map<String, dynamic> jsonMap =
        (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
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

    enumeratePublicFields(im, (name, jsonName, value, isGetterOnly,
        JsonProperty meta, converter, scalarType, TypeInfo typeInfo) {
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
        TypeInfo valueTypeInfo = TypeInfo(fieldValue.runtimeType);
        if (valueTypeInfo.isList) {
          fieldValue = fieldValue.map(convert).toList();
        } else {
          fieldValue = convert(fieldValue);
        }
      }
      if (!isGetterOnly) {
        fieldValue = applyValueDecorator(fieldValue, typeInfo, meta);
        var l = im.invokeGetter(name);
        if (l is List && fieldValue is List) {
          fieldValue.forEach((item) => l.add(item));
        } else {
          im.invokeSetter(name, fieldValue);
        }
      }
    });
    return objectInstance;
  }
}

/// Provides enhanced type information based on `Type.toString()` value
class TypeInfo {
  Type type;

  TypeInfo(this.type);

  String get typeName {
    return type != null ? type.toString() : '';
  }

  bool get isIterable {
    return isList || isSet;
  }

  bool get isList {
    return typeName.indexOf("List<") == 0;
  }

  bool get isSet {
    return typeName.indexOf("Set<") == 0;
  }

  bool get isMap {
    return typeName.indexOf("Map<") == 0;
  }

  /// Returns scalar type out of [Iterable<E>] type
  Type get scalarType {
    final String typeName = scalarTypeName;
    if (typeName == "DateTime") {
      return DateTime;
    }
    if (typeName == "num") {
      return num;
    }
    if (typeName == "int") {
      return int;
    }
    if (typeName == "double") {
      return double;
    }
    if (typeName == "BigInt") {
      return BigInt;
    }
    if (typeName == "Int32") {
      return Int32;
    }
    if (typeName == "Int64") {
      return Int64;
    }
    if (typeName == "bool") {
      return bool;
    }
    if (typeName == "String") {
      return String;
    }
    if (typeName == "Symbol") {
      return Symbol;
    }
    if (typeName == "dynamic") {
      return dynamic;
    }
    return null;
  }

  /// Returns scalar type name out of [Iterable<E>] type
  String get scalarTypeName {
    String result = '';
    if (isIterable) {
      result = RegExp('<(.+)>')
          .allMatches(typeName)
          .first
          .group(0)
          .replaceAll("<", '')
          .replaceAll(">", '');
    }
    return result;
  }

  @override
  String toString() {
    return 'TypeInfo{scalarTypeName: $scalarTypeName}';
  }
}
