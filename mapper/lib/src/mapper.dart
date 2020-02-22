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
  final Map<int, IAdapter> adapters = {};
  final Map<String, ProcessedObjectDescriptor> processedObjects = {};

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
    useAdapter(defaultJsonMapperAdapter);
  }

  JsonMapper useAdapter(IAdapter adapter, [int priority]) {
    final nextPriority = priority ?? adapters.keys.isNotEmpty
        ? adapters.keys.reduce((value, item) => max(value, item)) + 1
        : 0;
    adapters[nextPriority] = adapter;
    return this;
  }

  JsonMapper removeAdapter(IAdapter adapter) {
    adapters.removeWhere((priority, x) => x == adapter);
    return this;
  }

  void info() {
    adapters.forEach((priority, adapter) => print('$priority : $adapter'));
  }

  Map<Type, ICustomConverter> get converters {
    final result = {};
    adapters.values.forEach((IAdapter adapter) {
      result.addAll(adapter.converters);
    });
    return result.cast<Type, ICustomConverter>();
  }

  Map<Type, ValueDecoratorFunction> get valueDecorators {
    final result = {};
    adapters.values.forEach((IAdapter adapter) {
      result.addAll(adapter.valueDecorators);
    });
    return result.cast<Type, ValueDecoratorFunction>();
  }

  Map<int, ITypeInfoDecorator> get typeInfoDecorators {
    final result = [];
    adapters.values.forEach((IAdapter adapter) {
      result.addAll(adapter.typeInfoDecorators.values);
    });
    return Map.fromIterable(result).cast<int, ITypeInfoDecorator>();
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

  ProcessedObjectDescriptor getObjectProcessed(Object object, int level) {
    ProcessedObjectDescriptor result;

    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
      return result;
    }

    final key = getObjectKey(object);
    if (processedObjects.containsKey(key)) {
      result = processedObjects[key];
      result.logUsage(level);
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
    if (result == null &&
        converters[typeInfo.genericType] != null &&
        getValueDecorator(jsonProperty, typeInfo.type) == null) {
      result = converters[typeInfo.genericType];
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

  bool isFieldIgnored(
          [dynamic value,
          Json classMeta,
          JsonProperty meta,
          DeserializationOptions options]) =>
      (meta != null &&
          (meta.ignore == true ||
              meta.ignoreIfNull == true && value == null)) ||
      ((classMeta != null && classMeta.ignoreNullMembers == true ||
              options is SerializationOptions &&
                  options.ignoreNullMembers == true) &&
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
            jsonMap.getPropertyValue(jsonName), classMeta, meta, options)) {
          continue;
        }
      } else {
        if (isFieldIgnored(value, classMeta, meta, options)) {
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
        if (isFieldIgnored(value, classMeta, meta, options)) {
          return;
        }
        final parameterTypeInfo = detectObjectType(value, typeInfo.type, null);
        if (parameterTypeInfo.isIterable) {
          value = (value as Iterable)
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
          value = (value as Iterable)
              .map((item) => deserializeObject(
                  item, getScalarType(parameterTypeInfo.type), meta, options))
              .toList();
        } else {
          value =
              deserializeObject(value, parameterTypeInfo.type, meta, options);
        }
        value = applyValueDecorator(value, parameterTypeInfo, meta);
        if (isFieldIgnored(value, classMeta, meta, options)) {
          value = null;
        }
        result.add(value);
      }
    });

    return result;
  }

  dynamic serializeIterable(Iterable object,
      [SerializationOptions options, int level = 0]) {
    return object.map((item) => serializeObject(item, options, level)).toList();
  }

  dynamic serializeObject(Object object,
      [SerializationOptions options, int level = 0]) {
    if (object == null) {
      return object;
    }

    final im = safeGetInstanceMirror(object);
    final converter = getConverter(null, object.runtimeType, null, im);
    if (converter != null) {
      var convertedValue = converter.toJSON(object, null);
      if (object is Iterable && convertedValue == object) {
        convertedValue = serializeIterable(object, options, level);
      }
      return convertedValue;
    }

    if (object is Iterable) {
      return serializeIterable(object, options, level);
    }

    if (im == null || im.type == null) {
      if (im != null) {
        throw MissingEnumValuesError(object.runtimeType);
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
      }
    }

    final classInfo = ClassInfo(im.type);
    final jsonMeta = classInfo.getMeta(options.scheme);
    final initialMap = options.template ?? {};
    final result = JsonMap(initialMap, jsonMeta);
    final processedObjectDescriptor = getObjectProcessed(object, level);
    if (processedObjectDescriptor != null &&
        processedObjectDescriptor.levelsCount > 1) {
      final allowanceIsSet =
          (jsonMeta != null && jsonMeta.allowCircularReferences > 0);
      final allowanceExceeded = (allowanceIsSet &&
              processedObjectDescriptor.levelsCount >
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
    enumeratePublicFields(im, null, options, (name,
        jsonName,
        value,
        isGetterOnly,
        JsonProperty meta,
        converter,
        scalarType,
        TypeInfo typeInfo) {
      if (value == null && meta != null && meta.defaultValue != null) {
        result.setPropertyValue(jsonName, meta.defaultValue);
      } else {
        var convertedValue;
        if (converter != null) {
          final valueTypeInfo = getTypeInfo(value.runtimeType);
          dynamic convert(item) => converter.toJSON(item, meta);
          if (valueTypeInfo.isIterable) {
            convertedValue = converter.toJSON(value, meta);
            if (convertedValue == value) {
              convertedValue = serializeIterable(value, options, ++level);
            }
          } else {
            convertedValue = convert(value);
          }
        } else {
          convertedValue = serializeObject(value, options, ++level);
        }
        result.setPropertyValue(jsonName, convertedValue);
      }
    });

    final jsonAnyGetter = classInfo.getJsonAnyGetter();
    if (jsonAnyGetter != null) {
      final anyMap = im.invoke(jsonAnyGetter.simpleName, []);
      result.map.addAll(anyMap);
    }

    return result.map;
  }

  Object deserializeIterable(dynamic jsonValue, TypeInfo typeInfo,
      JsonProperty meta, DeserializationOptions options) {
    List jsonList =
        (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
    var value = jsonList
        .map((item) => deserializeObject(
            item, getScalarType(typeInfo.type), null, options))
        .toList();
    return applyValueDecorator(value, typeInfo, meta);
  }

  Object deserializeObject(dynamic jsonValue, Type instanceType,
      [JsonProperty parentMeta, DeserializationOptions options]) {
    if (jsonValue == null) {
      return null;
    }
    var typeInfo = getTypeInfo(instanceType);
    final converter = getConverter(parentMeta, typeInfo.type);
    if (converter != null) {
      var convertedValue = converter.fromJSON(jsonValue, parentMeta);
      if (typeInfo.isIterable && jsonValue == convertedValue) {
        convertedValue =
            deserializeIterable(jsonValue, typeInfo, parentMeta, options);
      }
      return convertedValue;
    }

    if (typeInfo.isIterable) {
      return deserializeIterable(jsonValue, typeInfo, parentMeta, options);
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
    final mappedFields = [];

    enumeratePublicFields(im, jsonMap, options, (name,
        jsonName,
        value,
        isGetterOnly,
        JsonProperty meta,
        converter,
        scalarType,
        TypeInfo typeInfo) {
      if (!jsonMap.hasProperty(jsonName)) {
        if (meta != null && meta.defaultValue != null && !isGetterOnly) {
          im.invokeSetter(name, meta.defaultValue);
        }
        return;
      }
      var fieldValue = jsonMap.getPropertyValue(jsonName);
      if (fieldValue is Iterable) {
        fieldValue = fieldValue
            .map((item) => deserializeObject(item, scalarType, meta, options))
            .toList();
      } else {
        fieldValue =
            deserializeObject(fieldValue, typeInfo.type, meta, options);
      }
      if (converter != null) {
        final originalValue = im.invokeGetter(name);
        if (converter is ICustomIterableConverter &&
            originalValue is Iterable) {
          converter.setIterableInstance(originalValue);
        }
        fieldValue = converter.fromJSON(fieldValue, meta);
      }
      if (!isGetterOnly) {
        fieldValue = applyValueDecorator(fieldValue, typeInfo, meta);
        im.invokeSetter(name, fieldValue);
        mappedFields.add(jsonName);
      }
    });

    final unmappedFields = jsonMap.map.keys
        .where((field) => !mappedFields.contains(field))
        .toList();
    if (unmappedFields.isNotEmpty) {
      final jsonAnySetter = classInfo.getJsonAnySetter();
      if (jsonAnySetter != null) {
        unmappedFields.forEach((field) =>
            im.invoke(jsonAnySetter.simpleName, [field, jsonMap.map[field]]));
      }
    }

    return objectInstance;
  }
}
