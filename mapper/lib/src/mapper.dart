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
  static final JsonDecoder _jsonDecoder = JsonDecoder();
  final _serializable = const JsonSerializable();
  final Map<String, ClassMirror> classes = {};
  final Map<int, IAdapter> adapters = {};
  final Map<String, ProcessedObjectDescriptor> _processedObjects = {};
  final Map<Type, ValueDecoratorFunction> _inlineValueDecorators = {};
  final Map<Type, TypeInfo> _typeInfoCache = {};
  final Map<
          ICustomConverter,
          Map<ConversionDirection,
              Map<DeserializationContext, Map<dynamic, dynamic>>>>
      _convertedValuesCache = {};

  Map<Type, ICustomConverter> converters = {};
  Map<int, ITypeInfoDecorator> typeInfoDecorators = {};
  Map<Type, ValueDecoratorFunction> valueDecorators = {};
  Map<Type, List> enumValues = {};

  /// Converts Dart object to JSON String
  static String toJson(Object object,
          [SerializationOptions options = defaultSerializationOptions]) =>
      serialize(object, options);

  /// Converts Dart object to JSON String
  static String serialize(Object object,
      [SerializationOptions options = defaultSerializationOptions]) {
    final context = SerializationContext(
        options: options, typeInfo: instance._getTypeInfo(object.runtimeType));
    instance._processedObjects.clear();
    return _getJsonEncoder(context)
        .convert(instance._serializeObject(object, context));
  }

  /// Converts JSON String to Dart object of type T
  static T deserialize<T>(String jsonValue,
      [DeserializationOptions options = defaultDeserializationOptions]) {
    final targetType = T != dynamic
        ? T
        : options.template != null
            ? options.template.runtimeType
            : dynamic;
    assert(targetType != dynamic
        ? true
        : throw MissingTypeForDeserializationError());
    return instance._deserializeObject(
        jsonValue != null ? _jsonDecoder.convert(jsonValue) : null,
        DeserializationContext(
            options: options, typeInfo: instance._getTypeInfo(targetType)));
  }

  /// Converts JSON String to Dart object of type T
  static T fromJson<T>(String jsonValue,
          [DeserializationOptions options = defaultDeserializationOptions]) =>
      deserialize<T>(jsonValue, options);

  /// Converts Dart object to Map<String, dynamic>
  static Map<String, dynamic> toMap(Object object,
          [SerializationOptions options = defaultSerializationOptions]) =>
      deserialize<Map<String, dynamic>>(serialize(object, options), options);

  /// Converts Map<String, dynamic> to Dart object instance
  static T fromMap<T>(Map<String, dynamic> map,
          [SerializationOptions options = defaultSerializationOptions]) =>
      deserialize<T>(
          _getJsonEncoder(SerializationContext(options: options)).convert(map),
          options);

  /// Clone Dart object of type T
  static T clone<T>(T object) => fromJson<T>(toJson(object));

  /// Alias for clone method to copy Dart object of type T
  static T copy<T>(T object) => clone(object);

  /// Copy Dart object of type T & merge it with Map<String, dynamic>
  static T copyWith<T>(T object, Map<String, dynamic> map) =>
      fromMap<T>(toMap(object)..addAll(map));

  static JsonEncoder _getJsonEncoder(SerializationContext context) =>
      context.serializationOptions.indent != null &&
              context.serializationOptions.indent.isNotEmpty
          ? JsonEncoder.withIndent(
              context.serializationOptions.indent, _toEncodable(context))
          : JsonEncoder(_toEncodable(context));

  static dynamic _toEncodable(SerializationContext context) =>
      (Object object) => instance._serializeObject(object, context);

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    useAdapter(dartCoreAdapter);
    useAdapter(dartCollectionAdapter);
  }

  JsonMapper useAdapter(IAdapter adapter, [int priority]) {
    if (adapters.containsValue(adapter)) {
      return this;
    }
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
    _enumerateAnnotatedClasses((ClassInfo classInfo) {
      final jsonMeta = classInfo.getMeta();
      if (jsonMeta != null && jsonMeta.valueDecorators != null) {
        _inlineValueDecorators.addAll(jsonMeta.valueDecorators());
      }
      if (classInfo.reflectedType != null) {
        classes[classInfo.reflectedType.toString()] = classInfo.classMirror;
      }
    });

    enumValues = _enumValues;
    converters = _converters;
    typeInfoDecorators = _typeInfoDecorators;
    valueDecorators = _valueDecorators;

    _enumerateAnnotatedClasses((ClassInfo classInfo) {
      if (classInfo.superClass != null) {
        final superClassInfo = ClassInfo(classInfo.superClass);
        final superClassTypeInfo = _getTypeInfo(superClassInfo.reflectedType);
        if (superClassTypeInfo.isWithMixin) {
          classes[superClassTypeInfo.mixinTypeName] =
              classes[superClassTypeInfo.typeName];
        }
      }
    });
  }

  void info() =>
      adapters.forEach((priority, adapter) => print('$priority : $adapter'));

  Map<Type, List> get _enumValues {
    final result = {};
    adapters.values.forEach((IAdapter adapter) {
      result.addAll(adapter.enumValues);
    });
    return result.cast<Type, List>();
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

  InstanceMirror _safeGetInstanceMirror(Object object) {
    InstanceMirror result;
    try {
      result = _serializable.reflect(object);
    } catch (error) {
      return result;
    }
    return result;
  }

  String _getObjectKey(Object object) =>
      '${object.runtimeType}-${object.hashCode}';

  ProcessedObjectDescriptor _getObjectProcessed(Object object, int level) {
    ProcessedObjectDescriptor result;

    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
      return result;
    }

    final key = _getObjectKey(object);
    if (_processedObjects.containsKey(key)) {
      result = _processedObjects[key];
      result.logUsage(level);
    } else {
      result = _processedObjects[key] = ProcessedObjectDescriptor(object);
    }
    return result;
  }

  TypeInfo _getTypeInfo(Type type) {
    if (_typeInfoCache[type] != null) {
      return _typeInfoCache[type];
    }
    var result = TypeInfo(type);
    typeInfoDecorators.values.forEach((ITypeInfoDecorator decorator) {
      decorator.init(classes, valueDecorators, enumValues);
      result = decorator.decorate(result);
    });
    _typeInfoCache[type] = result;
    return result;
  }

  Type _getGenericParameterTypeByIndex(
      num parameterIndex, TypeInfo genericType) {
    return genericType.isGeneric &&
            genericType.parameters.length - 1 >= parameterIndex
        ? genericType.parameters.elementAt(parameterIndex)
        : null;
  }

  TypeInfo _detectObjectType(dynamic objectInstance, Type objectType,
      JsonMap objectJsonMap, DeserializationContext context) {
    final objectClassMirror = classes[objectType.toString()];
    final objectClassInfo = ClassInfo(objectClassMirror);
    final Json meta = objectClassInfo.metaData
        .firstWhere((m) => m is Json, orElse: () => null);

    if (objectInstance is Map<String, dynamic>) {
      objectJsonMap = JsonMap(objectInstance, meta);
    }
    final typeInfo = _getTypeInfo(objectType ?? objectInstance.runtimeType);

    final typeNameProperty = _getTypeNameProperty(meta, context.options);
    final String typeName = objectJsonMap != null &&
            typeNameProperty != null &&
            objectJsonMap.hasProperty(typeNameProperty)
        ? objectJsonMap.getPropertyValue(typeNameProperty)
        : typeInfo.typeName;

    final type = classes[typeName] != null
        ? classes[typeName].reflectedType
        : typeInfo.type;
    return _getTypeInfo(type);
  }

  Type _getScalarType(Type type) {
    var result = dynamic;
    final typeInfo = _getTypeInfo(type);
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

  Type _getDeclarationType(DeclarationMirror mirror) {
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

  ICustomConverter _getConverter(
      JsonProperty jsonProperty, Type declarationType,
      [Type valueType, InstanceMirror im]) {
    var result = jsonProperty != null ? jsonProperty.converter : null;
    var targetType = declarationType;
    if (declarationType == dynamic && valueType != null) {
      targetType = valueType;
    }

    final typeInfo = _getTypeInfo(targetType);
    if (result == null && converters[typeInfo.type] != null) {
      result = converters[typeInfo.type];
    }
    if (result == null && converters[typeInfo.genericType] != null) {
      result = converters[typeInfo.genericType];
    }
    if (result == null && enumValues[targetType] != null) {
      result = converters[Enum];
    }
    if (result is ICustomEnumConverter) {
      (result as ICustomEnumConverter).setEnumValues(enumValues[targetType]);
    }
    return result;
  }

  dynamic _getConvertedValue(ICustomConverter converter, dynamic value,
      [SerializationContext serializationContext,
      DeserializationContext deserializationContext]) {
    final context = serializationContext ?? deserializationContext;
    final direction = serializationContext != null
        ? ConversionDirection.toJson
        : ConversionDirection.fromJson;
    if (_convertedValuesCache.containsKey(converter) &&
        _convertedValuesCache[converter].containsKey(direction) &&
        _convertedValuesCache[converter][direction].containsKey(context) &&
        _convertedValuesCache[converter][direction][context]
            .containsKey(value)) {
      return _convertedValuesCache[converter][direction][context][value];
    }

    final computedValue = converter == null
        ? value
        : direction == ConversionDirection.fromJson
            ? converter.fromJSON(value, deserializationContext)
            : converter.toJSON(value, serializationContext);
    _convertedValuesCache.putIfAbsent(
        converter,
        () => {
              direction: {
                context: {value: computedValue}
              }
            });
    _convertedValuesCache[converter].putIfAbsent(
        direction,
        () => {
              context: {value: computedValue}
            });
    _convertedValuesCache[converter][direction]
        .putIfAbsent(context, () => {value: computedValue});
    _convertedValuesCache[converter][direction][context]
        .putIfAbsent(value, () => computedValue);
    return computedValue;
  }

  dynamic _applyValueDecorator(dynamic value, TypeInfo typeInfo) {
    if (valueDecorators[typeInfo.genericType] != null) {
      value = valueDecorators[typeInfo.genericType](value);
    }
    if (valueDecorators[typeInfo.type] != null) {
      value = valueDecorators[typeInfo.type](value);
    }
    return value;
  }

  bool _isFieldIgnored(
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

  void _enumerateAnnotatedClasses(Function visitor) {
    _serializable.annotatedClasses.forEach((classMirror) {
      visitor(ClassInfo(classMirror));
    });
  }

  void _enumeratePublicProperties(InstanceMirror instanceMirror,
      JsonMap jsonMap, DeserializationOptions options, Function visitor) {
    final classInfo = ClassInfo(instanceMirror.type);
    final classMeta = classInfo.getMeta(options.scheme);

    for (var name in classInfo.publicFieldNames) {
      var jsonName = name;
      final declarationMirror = classInfo.getDeclarationMirror(name);
      if (declarationMirror == null) {
        continue;
      }
      final declarationType = _getDeclarationType(declarationMirror);
      final isGetterOnly = classInfo.isGetterOnly(name);
      final meta =
          classInfo.getDeclarationMeta(declarationMirror, options.scheme);
      if (meta == null &&
          _getProcessAnnotatedMembersOnly(classMeta, options) == true) {
        continue;
      }
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      jsonName =
          transformFieldName(jsonName, _getCaseStyle(classMeta, options));

      dynamic value = instanceMirror.invokeGetter(name);
      if (value == null && jsonMap != null) {
        if (_isFieldIgnored(
            jsonMap.getPropertyValue(jsonName), classMeta, meta, options)) {
          continue;
        }
      } else {
        if (_isFieldIgnored(value, classMeta, meta, options)) {
          continue;
        }
      }
      visitor(
          name,
          jsonName,
          value,
          isGetterOnly,
          meta,
          _getConverter(
              meta, declarationType, value != null ? value.runtimeType : null),
          _getScalarType(declarationType),
          _getTypeInfo(declarationType));
    }

    classInfo.enumerateJsonGetters((MethodMirror mm, JsonProperty meta) {
      final name = mm.simpleName;
      final value = instanceMirror.invoke(mm.simpleName, []);
      final jsonName =
          transformFieldName(meta.name, _getCaseStyle(classMeta, options));
      final declarationType = _getDeclarationType(mm);

      if (value == null && jsonMap != null) {
        if (_isFieldIgnored(
            jsonMap.getPropertyValue(jsonName), classMeta, meta, options)) {
          return;
        }
      } else {
        if (_isFieldIgnored(value, classMeta, meta, options)) {
          return;
        }
      }

      visitor(
          name,
          jsonName,
          value,
          true,
          meta,
          _getConverter(
              meta, declarationType, value != null ? value.runtimeType : null),
          _getScalarType(declarationType),
          _getTypeInfo(declarationType));
    }, options.scheme);
  }

  void _enumerateConstructorParameters(ClassMirror classMirror, JsonMap jsonMap,
      DeserializationContext context, Function filter, Function visitor) {
    final classInfo = ClassInfo(classMirror);
    final classMeta = classInfo.getMeta(context.options.scheme);
    final scheme =
        classMeta != null ? classMeta.scheme : context.options.scheme;
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
              : _getGenericParameterTypeByIndex(
                      methodMirror.parameters.indexOf(param),
                      context.typeInfo) ??
                  dynamic;
      var paramTypeInfo = _getTypeInfo(paramType);
      paramTypeInfo = paramTypeInfo.isDynamic
          ? _getTypeInfo(_getDeclarationType(declarationMirror))
          : paramTypeInfo;
      var jsonName = name;
      final meta = classInfo.getDeclarationMeta(
              declarationMirror, context.options.scheme) ??
          classInfo.getDeclarationMeta(param, context.options.scheme);
      if (meta != null && meta.name != null) {
        jsonName = meta.name;
      }
      jsonName = transformFieldName(
          jsonName, _getCaseStyle(classMeta, context.options));
      final defaultValue = meta != null ? meta.defaultValue : null;
      var value = jsonMap.hasProperty(jsonName)
          ? jsonMap.getPropertyValue(jsonName) ?? defaultValue
          : defaultValue;
      value = _deserializeObject(
          value,
          DeserializationContext(
              options: context.options,
              typeInfo: paramTypeInfo,
              jsonPropertyMeta: meta,
              classMeta: context.classMeta));
      visitor(param, name, jsonName, classMeta, meta, value ?? defaultValue,
          paramTypeInfo);
    });
  }

  CaseStyle _getCaseStyle(Json meta, DeserializationOptions options) =>
      meta != null && meta.caseStyle != null
          ? meta.caseStyle
          : options.caseStyle;

  String _getTypeNameProperty(Json meta, DeserializationOptions options) =>
      meta != null && meta.typeNameProperty != null
          ? meta.typeNameProperty
          : options.typeNameProperty;

  bool _getProcessAnnotatedMembersOnly(
          Json meta, DeserializationOptions options) =>
      meta != null && meta.processAnnotatedMembersOnly != null
          ? meta.processAnnotatedMembersOnly
          : options.processAnnotatedMembersOnly;

  void _dumpTypeNameToObjectProperty(
      JsonMap object, ClassMirror classMirror, DeserializationOptions options) {
    final classInfo = ClassInfo(classMirror);
    final Json meta =
        classInfo.metaData.firstWhere((m) => m is Json, orElse: () => null);
    final typeNameProperty = _getTypeNameProperty(meta, options);
    if (typeNameProperty != null) {
      final typeInfo = _getTypeInfo(classMirror.reflectedType);
      object.setPropertyValue(typeNameProperty, typeInfo.typeName);
    }
  }

  Map<Symbol, dynamic> _getNamedArguments(ClassMirror cm, JsonMap jsonMap,
      [DeserializationContext context]) {
    final result = <Symbol, dynamic>{};

    _enumerateConstructorParameters(
        cm, jsonMap, context, (param) => param.isNamed,
        (param, name, jsonName, classMeta, meta, value, TypeInfo typeInfo) {
      if (!_isFieldIgnored(value, classMeta, meta, context.options)) {
        result[Symbol(name)] = value;
      }
    });
    return result;
  }

  List _getPositionalArguments(ClassMirror cm, JsonMap jsonMap,
      [DeserializationContext context]) {
    final result = [];

    _enumerateConstructorParameters(
        cm, jsonMap, context, (param) => !param.isOptional && !param.isNamed,
        (param, name, jsonName, classMeta, JsonProperty meta, value,
            TypeInfo typeInfo) {
      result.add(_isFieldIgnored(value, classMeta, meta, context.options)
          ? null
          : value);
    });

    return result;
  }

  void _configureConverter(ICustomConverter converter,
      {dynamic value,
      SerializationContext serializationContext,
      DeserializationContext deserializationContext}) {
    if (converter is ICompositeConverter) {
      (converter as ICompositeConverter).setGetConverterFunction(_getConverter);
      (converter as ICompositeConverter)
          .setGetConvertedValueFunction(_getConvertedValue);
    }
    if (converter is ICustomIterableConverter) {
      (converter as ICustomIterableConverter).setIterableInstance(value);
    }
    if (converter is ICustomMapConverter) {
      final instance = value ??
          (deserializationContext != null
              ? deserializationContext.options.template
              : null);
      (converter as ICustomMapConverter).setMapInstance(instance);
    }
    if (converter is IRecursiveConverter) {
      (converter as IRecursiveConverter).setSerializeObjectFunction(
          (o) => _serializeObject(o, serializationContext));
      (converter as IRecursiveConverter).setDeserializeObjectFunction(
          (o, type) => _deserializeObject(
              o,
              DeserializationContext(
                  options: deserializationContext.options,
                  typeInfo: _getTypeInfo(type),
                  jsonPropertyMeta: deserializationContext.jsonPropertyMeta,
                  classMeta: deserializationContext.classMeta)));
    }
  }

  dynamic _serializeIterable(Iterable object, SerializationContext context) {
    return object != null
        ? object.map((item) => _serializeObject(item, context)).toList()
        : null;
  }

  dynamic _serializeObject(Object object, SerializationContext context) {
    if (object == null) {
      return object;
    }

    final im = _safeGetInstanceMirror(object);
    final converter =
        _getConverter(context.jsonPropertyMeta, object.runtimeType, null, im);
    if (converter != null) {
      _configureConverter(converter,
          value: object, serializationContext: context);
      var convertedValue = _getConvertedValue(converter, object, context);
      if (object is Iterable && convertedValue == object) {
        convertedValue = _serializeIterable(object, context);
      }
      return convertedValue;
    }

    if (object is Iterable) {
      return _serializeIterable(object, context);
    }

    if (im == null || im.type == null) {
      if (im != null) {
        throw MissingEnumValuesError(object.runtimeType);
      } else {
        if (context.serializationOptions.ignoreUnknownTypes == true) {
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
    final processedObjectDescriptor =
        _getObjectProcessed(object, context.level);
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
    _dumpTypeNameToObjectProperty(result, im.type, context.options);
    _enumeratePublicProperties(im, null, context.options, (name,
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
        final newContext = SerializationContext(
            options: context.options,
            level: context.level + 1,
            jsonPropertyMeta: meta,
            classMeta: jsonMeta,
            typeInfo: typeInfo);
        if (converter != null) {
          _configureConverter(converter,
              value: value, serializationContext: newContext);
          final valueTypeInfo = _getTypeInfo(value.runtimeType);
          dynamic convert(item) =>
              _getConvertedValue(converter, item, newContext);
          if (valueTypeInfo.isIterable) {
            convertedValue = convert(value);
            if (convertedValue == value) {
              convertedValue = _serializeIterable(value, newContext);
            }
          } else {
            convertedValue = convert(value);
          }
        } else {
          convertedValue = _serializeObject(value, newContext);
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

  Object _deserializeIterable(
      dynamic jsonValue, DeserializationContext context) {
    Iterable jsonList =
        (jsonValue is String) ? _jsonDecoder.convert(jsonValue) : jsonValue;
    final value = jsonList != null
        ? jsonList
            .map((item) => _deserializeObject(
                item,
                DeserializationContext(
                    options: context.options,
                    typeInfo:
                        _getTypeInfo(_getScalarType(context.typeInfo.type)),
                    jsonPropertyMeta: context.jsonPropertyMeta,
                    classMeta: context.classMeta)))
            .toList()
        : null;
    return _applyValueDecorator(value, context.typeInfo);
  }

  Object _deserializeObject(dynamic jsonValue, DeserializationContext context) {
    if (jsonValue == null) {
      return null;
    }
    var typeInfo = context.typeInfo;
    final converter = _getConverter(context.jsonPropertyMeta, typeInfo.type);
    if (converter != null) {
      _configureConverter(converter, deserializationContext: context);
      var convertedValue =
          _getConvertedValue(converter, jsonValue, null, context);
      if (typeInfo.isIterable && jsonValue == convertedValue) {
        convertedValue = _deserializeIterable(jsonValue, context);
      }
      return _applyValueDecorator(convertedValue, typeInfo);
    }

    var convertedJsonValue;
    try {
      convertedJsonValue =
          (jsonValue is String) ? _jsonDecoder.convert(jsonValue) : jsonValue;
    } on FormatException {
      throw MissingEnumValuesError(typeInfo.type);
    }

    if (typeInfo.isIterable ||
        (convertedJsonValue != null && convertedJsonValue is Iterable)) {
      return _deserializeIterable(jsonValue, context);
    }

    if (convertedJsonValue is! Map<String, dynamic>) {
      return convertedJsonValue;
    }

    final jsonMap = JsonMap(convertedJsonValue);
    typeInfo = _detectObjectType(null, context.typeInfo.type, jsonMap, context);
    final cm = classes[typeInfo.typeName] ?? classes[typeInfo.genericTypeName];
    if (cm == null) {
      throw MissingAnnotationOnTypeError(typeInfo.type);
    }
    final classInfo = ClassInfo(cm);
    jsonMap.jsonMeta = classInfo.getMeta(context.options.scheme);

    final namedArguments = _getNamedArguments(cm, jsonMap, context);
    final objectInstance = context.options.template ??
        (cm.isEnum
            ? null
            : cm.newInstance(
                classInfo
                    .getJsonConstructor(context.options.scheme)
                    .constructorName,
                _getPositionalArguments(cm, jsonMap, context),
                namedArguments));
    final im = _safeGetInstanceMirror(objectInstance);
    final inheritedPublicFieldNames = classInfo.inheritedPublicFieldNames;
    final mappedFields = namedArguments.keys
        .map((Symbol symbol) =>
            RegExp('"(.+)"').allMatches(symbol.toString()).first.group(1))
        .toList();

    _enumeratePublicProperties(im, jsonMap, context.options, (name,
        jsonName,
        value,
        isGetterOnly,
        JsonProperty meta,
        converter,
        scalarType,
        TypeInfo typeInfo) {
      final defaultValue = meta?.defaultValue;
      final hasJsonProperty = jsonMap.hasProperty(jsonName);
      var fieldValue = jsonMap.getPropertyValue(jsonName);
      if (JsonProperty.isNotNull(meta) &&
          (!hasJsonProperty || (fieldValue == null))) {
        throw FieldCannotBeNullError(name, message: meta.notNullMessage);
      }
      if (!hasJsonProperty || mappedFields.contains(name)) {
        if (!hasJsonProperty && JsonProperty.isRequired(meta)) {
          throw FieldIsRequiredError(name, message: meta.requiredMessage);
        }
        if (defaultValue != null && !isGetterOnly) {
          im.invokeSetter(name, defaultValue);
        }
        return;
      }
      final newContext = DeserializationContext(
          options: context.options,
          typeInfo: typeInfo,
          jsonPropertyMeta: meta,
          classMeta: context.classMeta);
      if (fieldValue is Iterable) {
        fieldValue = fieldValue
            .map((item) => _deserializeObject(
                item,
                DeserializationContext(
                    options: context.options,
                    typeInfo: _getTypeInfo(scalarType),
                    jsonPropertyMeta: meta,
                    classMeta: context.classMeta)))
            .toList();
      } else {
        fieldValue = _deserializeObject(fieldValue, newContext);
      }
      if (converter != null) {
        final originalValue = im.invokeGetter(name);
        _configureConverter(converter,
            value: originalValue ?? fieldValue,
            deserializationContext: newContext);
        fieldValue =
            _getConvertedValue(converter, fieldValue, null, newContext);
      }
      if (isGetterOnly) {
        if (inheritedPublicFieldNames.contains(name) &&
            !mappedFields.contains(jsonName)) {
          mappedFields.add(jsonName);
        }
      } else {
        fieldValue = _applyValueDecorator(fieldValue, typeInfo) ?? defaultValue;
        im.invokeSetter(name, fieldValue);
        mappedFields.add(jsonName);
      }
    });

    final typeNameProperty =
        _getTypeNameProperty(jsonMap.jsonMeta, context.options);
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

    return _applyValueDecorator(objectInstance, typeInfo);
  }
}
