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
  final JsonDecoder jsonDecoder = JsonDecoder();
  final serializable = const JsonSerializable();
  final Map<String, ClassMirror> classes = {};
  final Map<int, IAdapter> adapters = {};
  final Map<String, ProcessedObjectDescriptor> processedObjects = {};
  final Map<Type, ValueDecoratorFunction> _inlineValueDecorators = {};

  Map<Type, ICustomConverter> converters = {};
  Map<int, ITypeInfoDecorator> typeInfoDecorators = {};
  Map<Type, ValueDecoratorFunction> valueDecorators = {};
  Map<Type, TypeInfo> typeInfoCache = {};

  /// Converts Dart object to JSON string
  static String toJson(Object object,
      [SerializationOptions options = defaultSerializationOptions]) {
    return serialize(object, options);
  }

  /// Converts Dart object to JSON string
  static String serialize(Object object,
      [SerializationOptions options = defaultSerializationOptions]) {
    final context = SerializationContext(options);
    instance.processedObjects.clear();
    return _getJsonEncoder(context)
        .convert(instance.serializeObject(object, context));
  }

  /// Converts JSON string to Dart object of type T
  static T deserialize<T>(dynamic jsonValue,
      [DeserializationOptions options = defaultDeserializationOptions]) {
    final targetType = T != dynamic
        ? T
        : options.template != null ? options.template.runtimeType : dynamic;
    assert(targetType != dynamic
        ? true
        : throw MissingTypeForDeserializationError());
    return instance.deserializeObject(
        jsonValue, DeserializationContext(options, targetType));
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
      [SerializationOptions options = defaultSerializationOptions]) {
    return deserialize<T>(
        _getJsonEncoder(SerializationContext(options)).convert(map), options);
  }

  /// Clone Dart object of type T
  static T clone<T>(T object) {
    return fromJson<T>(toJson(object));
  }

  /// Copy Dart object of type T & merge it with Map<String, dynamic>
  static T copyWith<T>(T object, Map<String, dynamic> map) {
    return fromMap<T>(toMap(object)..addAll(map));
  }

  static JsonEncoder _getJsonEncoder(SerializationContext context) =>
      context.options.indent != null && context.options.indent.isNotEmpty
          ? JsonEncoder.withIndent(
              context.options.indent, _toEncodable(context))
          : JsonEncoder(_toEncodable(context));

  static dynamic _toEncodable(SerializationContext context) =>
      (Object object) => instance.serializeObject(object, context);

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    for (var classMirror in serializable.annotatedClasses) {
      final jsonMeta = ClassInfo(classMirror).getMeta();
      if (jsonMeta != null && jsonMeta.valueDecorators != null) {
        _inlineValueDecorators.addAll(jsonMeta.valueDecorators());
      }
      if (classMirror.hasReflectedType) {
        classes[classMirror.reflectedType.toString()] = classMirror;
      } else if (classMirror.hasDynamicReflectedType) {
        classes[classMirror.dynamicReflectedType.toString()] = classMirror;
      }
    }
    useAdapter(defaultJsonMapperAdapter);
  }

  JsonMapper useAdapter(IAdapter adapter, [int priority]) {
    final nextPriority = priority ?? adapters.keys.isNotEmpty
        ? adapters.keys.reduce((value, item) => max(value, item)) + 1
        : 0;
    adapters[nextPriority] = adapter;
    _updateInternalMaps();
    return this;
  }

  JsonMapper removeAdapter(IAdapter adapter) {
    adapters.removeWhere((priority, x) => x == adapter);
    _updateInternalMaps();
    return this;
  }

  void _updateInternalMaps() {
    converters = _converters;
    typeInfoDecorators = _typeInfoDecorators;
    valueDecorators = _valueDecorators;
  }

  void info() {
    adapters.forEach((priority, adapter) => print('$priority : $adapter'));
  }

  Map<Type, ICustomConverter> get _converters {
    final result = {};
    adapters.values.forEach((IAdapter adapter) {
      result.addAll(adapter.converters);
    });
    return result.cast<Type, ICustomConverter>();
  }

  Map<Type, ValueDecoratorFunction> get _valueDecorators {
    final result = {};
    result.addAll(_inlineValueDecorators);
    adapters.values.forEach((IAdapter adapter) {
      result.addAll(adapter.valueDecorators);
    });
    return result.cast<Type, ValueDecoratorFunction>();
  }

  Map<int, ITypeInfoDecorator> get _typeInfoDecorators {
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
    if (typeInfoCache[type] != null) {
      return typeInfoCache[type];
    }
    var result = TypeInfo(type);
    typeInfoDecorators.values.forEach((ITypeInfoDecorator decorator) {
      decorator.init(classes, valueDecorators);
      result = decorator.decorate(result);
    });
    typeInfoCache[type] = result;
    return result;
  }

  TypeInfo detectObjectType(dynamic objectInstance, Type objectType,
      JsonMap objectJsonMap, DeserializationOptions options) {
    final objectClassMirror = classes[objectType.toString()];
    final objectClassInfo = ClassInfo(objectClassMirror);
    final Json meta = objectClassInfo.metaData
        .firstWhere((m) => m is Json, orElse: () => null);

    if (objectInstance is Map<String, dynamic>) {
      objectJsonMap = JsonMap(objectInstance, meta);
    }
    final typeInfo = getTypeInfo(objectType ?? objectInstance.runtimeType);

    final typeNameProperty = getTypeNameProperty(meta, options);
    final String typeName = objectJsonMap != null &&
            typeNameProperty != null &&
            objectJsonMap.hasProperty(typeNameProperty)
        ? objectJsonMap.getPropertyValue(typeNameProperty)
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
    var targetType = declarationType;
    if (declarationType == dynamic && valueType != null) {
      targetType = valueType;
    }

    final typeInfo = getTypeInfo(targetType);
    if (result == null && converters[targetType] != null) {
      result = converters[targetType];
    }
    if (result == null &&
        (im != null && im.type != null && im.type.isEnum ||
            typeInfo.isEnum == true)) {
      result = annotatedEnumConverter;
      if (im != null && im.type != null) {
        annotatedEnumConverter.setEnumValues(ClassInfo(im.type).enumValues);
      }
    }
    if (result == null && converters[typeInfo.genericType] != null) {
      result = converters[typeInfo.genericType];
    }
    if (result == null &&
        (jsonProperty != null && jsonProperty.isEnumType(targetType))) {
      result = converters[Enum];
    }
    return result;
  }

  dynamic applyValueDecorator(dynamic value, TypeInfo typeInfo,
      [JsonProperty meta]) {
    final valueDecoratorFunction = getValueDecorator(meta, typeInfo.type);
    // TODO: Relocate Set handling out of mapper to converter/value decorator/etc.
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
          ((meta.ignore == true ||
                  (meta.ignoreForSerialization == true &&
                      options is SerializationOptions) ||
                  (meta.ignoreForDeserialization == true &&
                      options is! SerializationOptions)) ||
              meta.ignoreIfNull == true && value == null)) ||
      ((classMeta != null && classMeta.ignoreNullMembers == true ||
              options is SerializationOptions &&
                  options.ignoreNullMembers == true) &&
          value == null);

  void enumeratePublicProperties(InstanceMirror instanceMirror, JsonMap jsonMap,
      DeserializationOptions options, Function visitor) {
    final classInfo = ClassInfo(instanceMirror.type);
    final classMeta = classInfo.getMeta(options.scheme);

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
      if (meta == null &&
          getProcessAnnotatedMembersOnly(classMeta, options) == true) {
        continue;
      }
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      jsonName = transformFieldName(jsonName, getCaseStyle(classMeta, options));

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

    classInfo.enumerateJsonGetters((MethodMirror mm, JsonProperty meta) {
      final name = mm.simpleName;
      final value = instanceMirror.invoke(mm.simpleName, []);
      final jsonName =
          transformFieldName(meta.name, getCaseStyle(classMeta, options));
      final declarationType = getDeclarationType(mm);

      if (value == null && jsonMap != null) {
        if (isFieldIgnored(
            jsonMap.getPropertyValue(jsonName), classMeta, meta, options)) {
          return;
        }
      } else {
        if (isFieldIgnored(value, classMeta, meta, options)) {
          return;
        }
      }

      visitor(
          name,
          jsonName,
          value,
          true,
          meta,
          getConverter(
              meta, declarationType, value != null ? value.runtimeType : null),
          getScalarType(declarationType),
          getTypeInfo(declarationType));
    }, options.scheme);
  }

  void enumerateConstructorParameters(ClassMirror classMirror, JsonMap jsonMap,
      DeserializationOptions options, Function filter, Function visitor) {
    final classInfo = ClassInfo(classMirror);
    final classMeta = classInfo.getMeta(options.scheme);
    final scheme = classMeta != null ? classMeta.scheme : options.scheme;
    final methodMirror = classInfo.getJsonConstructor(scheme);
    if (methodMirror == null) {
      return;
    }
    methodMirror.parameters.forEach((ParameterMirror param) {
      if (!filter(param)) {
        return;
      }
      final name = param.simpleName;
      final declarationMirror = classInfo.getDeclarationMirror(name) ?? param;
      final paramType = param.hasReflectedType
          ? param.reflectedType
          : param.hasDynamicReflectedType
              ? param.dynamicReflectedType
              : dynamic;
      var paramTypeInfo = getTypeInfo(paramType);
      paramTypeInfo = paramTypeInfo.isDynamic
          ? getTypeInfo(getDeclarationType(declarationMirror))
          : paramTypeInfo;
      var jsonName = name;
      final meta =
          classInfo.getDeclarationMeta(declarationMirror, options.scheme) ??
              classInfo.getDeclarationMeta(param, options.scheme);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      jsonName = transformFieldName(jsonName, getCaseStyle(classMeta, options));
      final defaultValue = meta != null ? meta.defaultValue : null;
      var value = jsonMap.hasProperty(jsonName)
          ? jsonMap.getPropertyValue(jsonName) ?? defaultValue
          : defaultValue;
      value = deserializeObject(
          value, DeserializationContext(options, paramTypeInfo.type, meta));
      visitor(param, name, jsonName, classMeta, meta, value, paramTypeInfo);
    });
  }

  CaseStyle getCaseStyle(Json meta, DeserializationOptions options) =>
      meta != null && meta.caseStyle != null
          ? meta.caseStyle
          : options.caseStyle;

  String getTypeNameProperty(Json meta, DeserializationOptions options) =>
      meta != null && meta.typeNameProperty != null
          ? meta.typeNameProperty
          : options.typeNameProperty;

  bool getProcessAnnotatedMembersOnly(
          Json meta, DeserializationOptions options) =>
      meta != null && meta.processAnnotatedMembersOnly != null
          ? meta.processAnnotatedMembersOnly
          : options.processAnnotatedMembersOnly;

  void dumpTypeNameToObjectProperty(
      JsonMap object, ClassMirror classMirror, DeserializationOptions options) {
    final classInfo = ClassInfo(classMirror);
    final Json meta =
        classInfo.metaData.firstWhere((m) => m is Json, orElse: () => null);
    final typeNameProperty = getTypeNameProperty(meta, options);
    if (typeNameProperty != null) {
      final typeInfo = getTypeInfo(classMirror.reflectedType);
      object.setPropertyValue(typeNameProperty, typeInfo.typeName);
    }
  }

  Map<Symbol, dynamic> getNamedArguments(ClassMirror cm, JsonMap jsonMap,
      [DeserializationOptions options]) {
    final result = <Symbol, dynamic>{};

    enumerateConstructorParameters(
        cm, jsonMap, options, (param) => param.isNamed,
        (param, name, jsonName, classMeta, meta, value, TypeInfo typeInfo) {
      if (!isFieldIgnored(value, classMeta, meta, options)) {
        result[Symbol(name)] = value;
      }
    });
    return result;
  }

  List getPositionalArguments(ClassMirror cm, JsonMap jsonMap,
      [DeserializationOptions options]) {
    final result = [];

    enumerateConstructorParameters(
        cm, jsonMap, options, (param) => !param.isOptional && !param.isNamed,
        (param, name, jsonName, classMeta, JsonProperty meta, value,
            TypeInfo typeInfo) {
      result
          .add(isFieldIgnored(value, classMeta, meta, options) ? null : value);
    });

    return result;
  }

  void configureConverter(ICustomConverter converter,
      {dynamic value,
      SerializationContext serializationContext,
      DeserializationContext deserializationContext}) {
    final typeInfo = deserializationContext != null
        ? getTypeInfo(deserializationContext.instanceType)
        : null;

    if (converter is ICustomIterableConverter) {
      (converter as ICustomIterableConverter)
          .setIterableInstance(value, typeInfo);
    }
    if (converter is ICustomMapConverter) {
      final instance = value ??
          (deserializationContext != null
              ? deserializationContext.options.template
              : null);
      (converter as ICustomMapConverter).setMapInstance(instance, typeInfo);
    }
    if (converter is IRecursiveConverter) {
      (converter as IRecursiveConverter).setSerializeObjectFunction(
          (o) => serializeObject(o, serializationContext));
      (converter as IRecursiveConverter).setDeserializeObjectFunction(
          (o, type) => deserializeObject(
              o,
              DeserializationContext(deserializationContext.options, type,
                  deserializationContext.parentMeta)));
    }
  }

  dynamic serializeIterable(Iterable object, SerializationContext context) {
    return object != null
        ? object.map((item) => serializeObject(item, context)).toList()
        : null;
  }

  dynamic serializeObject(Object object, SerializationContext context) {
    if (object == null) {
      return object;
    }

    final im = safeGetInstanceMirror(object);
    final converter =
        getConverter(context.parentMeta, object.runtimeType, null, im);
    if (converter != null) {
      configureConverter(converter,
          value: object, serializationContext: context);
      var convertedValue = converter.toJSON(object, null);
      if (object is Iterable && convertedValue == object) {
        convertedValue = serializeIterable(object, context);
      }
      return convertedValue;
    }

    if (object is Iterable) {
      return serializeIterable(object, context);
    }

    if (im == null || im.type == null) {
      if (im != null) {
        throw MissingEnumValuesError(object.runtimeType);
      } else {
        if (context.options.ignoreUnknownTypes == true) {
          return null;
        } else {
          throw MissingAnnotationOnTypeError(object.runtimeType);
        }
      }
    }

    final classInfo = ClassInfo(im.type);
    final jsonMeta = classInfo.getMeta(context.options.scheme);
    final initialMap = context.level == 0
        ? context.options.template ?? <String, dynamic>{}
        : <String, dynamic>{};
    final result = JsonMap(initialMap, jsonMeta);
    final processedObjectDescriptor = getObjectProcessed(object, context.level);
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
    dumpTypeNameToObjectProperty(result, im.type, context.options);
    enumeratePublicProperties(im, null, context.options, (name,
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
        final newContext =
            SerializationContext(context.options, context.level + 1, meta);
        if (converter != null) {
          configureConverter(converter,
              value: value, serializationContext: context);
          final valueTypeInfo = getTypeInfo(value.runtimeType);
          dynamic convert(item) => converter.toJSON(item, meta);
          if (valueTypeInfo.isIterable) {
            convertedValue = converter.toJSON(value, meta);
            if (convertedValue == value) {
              convertedValue = serializeIterable(value, newContext);
            }
          } else {
            convertedValue = convert(value);
          }
        } else {
          convertedValue = serializeObject(value, newContext);
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

  Object deserializeIterable(
      dynamic jsonValue, DeserializationContext context) {
    Iterable jsonList =
        (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
    final value = jsonList != null
        ? jsonList
            .map((item) => deserializeObject(
                item,
                DeserializationContext(
                    context.options, getScalarType(context.instanceType))))
            .toList()
        : null;
    return applyValueDecorator(
        value, getTypeInfo(context.instanceType), context.parentMeta);
  }

  Object deserializeObject(dynamic jsonValue, DeserializationContext context) {
    if (jsonValue == null) {
      return null;
    }
    var typeInfo = getTypeInfo(context.instanceType);
    final converter = getConverter(context.parentMeta, typeInfo.type);
    if (converter != null) {
      configureConverter(converter, deserializationContext: context);
      var convertedValue = converter.fromJSON(jsonValue, context.parentMeta);
      if (typeInfo.isIterable && jsonValue == convertedValue) {
        convertedValue = deserializeIterable(jsonValue, context);
      }
      return applyValueDecorator(convertedValue, typeInfo, context.parentMeta);
    }

    var convertedJsonValue;
    try {
      convertedJsonValue =
          (jsonValue is String) ? jsonDecoder.convert(jsonValue) : jsonValue;
    } on FormatException {
      throw MissingEnumValuesError(typeInfo.type);
    }

    if (typeInfo.isIterable ||
        (convertedJsonValue != null && convertedJsonValue is Iterable)) {
      return deserializeIterable(jsonValue, context);
    }

    if (convertedJsonValue is! Map<String, dynamic>) {
      return convertedJsonValue;
    }

    final jsonMap = JsonMap(convertedJsonValue);
    typeInfo =
        detectObjectType(null, context.instanceType, jsonMap, context.options);
    final cm = classes[typeInfo.typeName] ?? classes[typeInfo.genericTypeName];
    if (cm == null) {
      throw MissingAnnotationOnTypeError(typeInfo.type);
    }
    final classInfo = ClassInfo(cm);
    jsonMap.jsonMeta = classInfo.getMeta(context.options.scheme);

    final namedArguments = getNamedArguments(cm, jsonMap, context.options);
    final objectInstance = context.options.template ??
        (cm.isEnum
            ? null
            : cm.newInstance(
                classInfo
                    .getJsonConstructor(context.options.scheme)
                    .constructorName,
                getPositionalArguments(cm, jsonMap, context.options),
                namedArguments));
    final im = safeGetInstanceMirror(objectInstance);
    final mappedFields = namedArguments.keys
        .map((Symbol symbol) =>
            RegExp('"(.+)"').allMatches(symbol.toString()).first.group(1))
        .toList();

    enumeratePublicProperties(im, jsonMap, context.options, (name,
        jsonName,
        value,
        isGetterOnly,
        JsonProperty meta,
        converter,
        scalarType,
        TypeInfo typeInfo) {
      if (!jsonMap.hasProperty(jsonName) || mappedFields.contains(name)) {
        if (meta != null && meta.defaultValue != null && !isGetterOnly) {
          im.invokeSetter(name, meta.defaultValue);
        }
        return;
      }
      var fieldValue = jsonMap.getPropertyValue(jsonName);
      if (fieldValue is Iterable) {
        fieldValue = fieldValue
            .map((item) => deserializeObject(item,
                DeserializationContext(context.options, scalarType, meta)))
            .toList();
      } else {
        fieldValue = deserializeObject(fieldValue,
            DeserializationContext(context.options, typeInfo.type, meta));
      }
      if (converter != null) {
        final originalValue = im.invokeGetter(name);
        configureConverter(converter,
            value: originalValue ?? fieldValue,
            deserializationContext:
                DeserializationContext(context.options, typeInfo.type, meta));
        fieldValue = converter.fromJSON(fieldValue, meta);
      }
      if (!isGetterOnly) {
        fieldValue = applyValueDecorator(fieldValue, typeInfo, meta);
        im.invokeSetter(name, fieldValue);
        mappedFields.add(jsonName);
      }
    });

    final typeNameProperty =
        getTypeNameProperty(jsonMap.jsonMeta, context.options);
    final unmappedFields = jsonMap.map.keys
        .where((field) =>
            !mappedFields.contains(field) && field != typeNameProperty)
        .toList();
    if (unmappedFields.isNotEmpty) {
      final jsonAnySetter = classInfo.getJsonAnySetter(context.options.scheme);
      unmappedFields.forEach((field) {
        final jsonSetter =
            classInfo.getJsonSetter(field, context.options.scheme) ??
                jsonAnySetter;
        final params = jsonSetter == jsonAnySetter
            ? [field, jsonMap.map[field]]
            : [jsonMap.map[field]];
        if (jsonSetter != null) {
          im.invoke(jsonSetter.simpleName, params);
        }
      });
    }

    return applyValueDecorator(objectInstance, typeInfo, context.parentMeta);
  }
}
