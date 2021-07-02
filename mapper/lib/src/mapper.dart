import 'dart:convert' show JsonEncoder, JsonDecoder;
import 'dart:math';

import 'package:reflectable/reflectable.dart'
    show
        ClassMirror,
        InstanceMirror,
        DeclarationMirror,
        VariableMirror,
        MethodMirror;

import 'errors.dart';
import 'model/index.dart';
import 'utils.dart';

/// Singleton class providing mostly static methods for conversion of previously
/// annotated by [JsonSerializable] Dart objects from / to JSON string
class JsonMapper {
  /// Converts an instance of Dart object to JSON String
  static String serialize(Object? object,
      [SerializationOptions options = defaultSerializationOptions]) {
    final context = SerializationContext(options,
        typeInfo: instance._getTypeInfo(object.runtimeType));
    instance._processedObjects.clear();
    return _getJsonEncoder(context)
        .convert(instance._serializeObject(object, context));
  }

  /// Converts JSON [String] Or [Object] to Dart object instance of type T
  /// [jsonValue] could be as of [String] type, then it will be parsed internally
  /// [jsonValue] could be as of [Object] type, then it will be processed as is
  static T? deserialize<T>(dynamic jsonValue,
      [DeserializationOptions options = defaultDeserializationOptions]) {
    final targetType = T != dynamic
        ? T
        : options.template != null
            ? options.template.runtimeType
            : options.type ?? dynamic;
    assert(targetType != dynamic
        ? true
        : throw MissingTypeForDeserializationError());
    return instance._deserializeObject(
        jsonValue != null
            ? jsonValue is String
                ? _jsonDecoder.convert(jsonValue)
                : jsonValue
            : null,
        DeserializationContext(options,
            typeInfo: instance._getTypeInfo(targetType))) as T?;
  }

  /// Converts Dart object to JSON String
  static String toJson(Object? object,
          [SerializationOptions options = defaultSerializationOptions]) =>
      serialize(object, options);

  /// Converts JSON String to Dart object of type T
  static T? fromJson<T>(String jsonValue,
          [DeserializationOptions options = defaultDeserializationOptions]) =>
      deserialize<T>(jsonValue, options);

  /// Converts Dart object to Map<String, dynamic>
  static Map<String, dynamic>? toMap(Object? object,
          [SerializationOptions options = defaultSerializationOptions]) =>
      deserialize<Map<String, dynamic>>(serialize(object, options), options);

  /// Converts Map<String, dynamic> to Dart object instance of type T
  static T? fromMap<T>(Map<String, dynamic>? map,
          [SerializationOptions options = defaultSerializationOptions]) =>
      deserialize<T>(
          _getJsonEncoder(SerializationContext(options)).convert(map), options);

  /// Clone Dart object of type T
  static T? clone<T>(T object) => fromJson<T>(toJson(object));

  /// Alias for clone method to copy Dart object of type T
  static T? copy<T>(T object) => clone(object);

  /// Copy Dart object of type T & merge it with Map<String, dynamic>
  static T? copyWith<T>(T object, Map<String, dynamic> map) =>
      fromMap<T>(toMap(object)?..addAll(map));

  /// Registers an instance of [IAdapter] with the mapper engine
  /// Adapters are meant to be used as a pluggable extensions, widening
  /// the number of supported types to be seamlessly converted to/from JSON
  JsonMapper useAdapter(IAdapter adapter, [int? priority]) {
    if (_adapters.containsValue(adapter)) {
      return this;
    }
    final nextPriority = priority ??
        (_adapters.keys.isNotEmpty
            ? _adapters.keys.reduce((value, item) => max(value, item)) + 1
            : 0);
    _adapters[nextPriority] = adapter;
    _updateInternalMaps();
    return this;
  }

  /// De-registers previously registered adapter using [useAdapter] method
  JsonMapper removeAdapter(IAdapter adapter) {
    _adapters.removeWhere((priority, x) => x == adapter);
    _updateInternalMaps();
    return this;
  }

  /// Prints out current mapper configuration to the console
  /// List of currently registered adapters and their priorities
  void info() =>
      _adapters.forEach((priority, adapter) => print('$priority : $adapter'));

  /// Private implementation area onwards /////////////////////////////////////

  static final JsonMapper instance = JsonMapper._internal();
  static final JsonDecoder _jsonDecoder = JsonDecoder();
  final _serializable = const JsonSerializable();
  final Map<String, ClassMirror?> _classes = {};
  final Map<int, IAdapter> _adapters = {};
  final Map<String, ProcessedObjectDescriptor> _processedObjects = {};
  final Map<Type, ValueDecoratorFunction> _inlineValueDecorators = {};
  final Map<Type, TypeInfo> _typeInfoCache = {};
  final Map<dynamic, Type> _discriminatorToType = {};
  final Map<
          ICustomConverter?,
          Map<ConversionDirection,
              Map<DeserializationContext?, Map<dynamic, dynamic>>>>
      _convertedValuesCache = {};

  Map<Type, ICustomConverter> converters = {};
  Map<int, ITypeInfoDecorator> typeInfoDecorators = {};
  Map<Type, ValueDecoratorFunction> valueDecorators = {};
  Map<Type, dynamic> enumValues = {};

  static JsonEncoder _getJsonEncoder(SerializationContext context) =>
      context.serializationOptions.indent != null &&
              context.serializationOptions.indent!.isNotEmpty
          ? JsonEncoder.withIndent(
              context.serializationOptions.indent, _toEncodable(context))
          : JsonEncoder(_toEncodable(context));

  static dynamic _toEncodable(SerializationContext context) =>
      (Object? object) => instance._serializeObject(object, context);

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    useAdapter(dartCoreAdapter);
    useAdapter(dartCollectionAdapter);
  }

  void _updateInternalMaps() {
    _convertedValuesCache.clear();
    _discriminatorToType.clear();
    _enumerateAnnotatedClasses((ClassInfo classInfo) {
      final jsonMeta = classInfo.getMeta();
      if (jsonMeta != null && jsonMeta.valueDecorators != null) {
        _inlineValueDecorators.addAll(jsonMeta.valueDecorators!());
      }
      if (classInfo.reflectedType != null) {
        _classes[classInfo.reflectedType.toString()] = classInfo.classMirror;
      }
      if (jsonMeta != null &&
          jsonMeta.discriminatorValue != null &&
          classInfo.reflectedType != null) {
        _discriminatorToType.putIfAbsent(
            jsonMeta.discriminatorValue, () => classInfo.reflectedType!);
      }
    });

    enumValues = _enumValues;
    converters = _converters;
    typeInfoDecorators = _typeInfoDecorators;
    valueDecorators = _valueDecorators;

    _enumerateAnnotatedClasses((ClassInfo classInfo) {
      if (classInfo.superClass != null) {
        final superClassInfo = ClassInfo(classInfo.superClass);
        final superClassTypeInfo = superClassInfo.reflectedType != null
            ? _getTypeInfo(superClassInfo.reflectedType!)
            : null;
        if (superClassTypeInfo != null && superClassTypeInfo.isWithMixin) {
          _classes[superClassTypeInfo.mixinTypeName!] =
              _classes[superClassTypeInfo.typeName];
        }
      }
    });
  }

  Map<Type, dynamic> get _enumValues {
    final result = <Type, dynamic>{};
    for (var adapter in _adapters.values) {
      result.addAll(adapter.enumValues);
    }
    return result;
  }

  Map<Type, ICustomConverter> get _converters {
    final result = <Type, ICustomConverter>{};
    for (var adapter in _adapters.values) {
      result.addAll(adapter.converters);
    }
    return result;
  }

  Map<Type, ValueDecoratorFunction> get _valueDecorators {
    final result = <Type, ValueDecoratorFunction>{};
    result.addAll(_inlineValueDecorators);
    for (var adapter in _adapters.values) {
      result.addAll(adapter.valueDecorators);
    }
    return result;
  }

  Map<int, ITypeInfoDecorator> get _typeInfoDecorators {
    final result = <int, ITypeInfoDecorator>{};
    for (var adapter in _adapters.values) {
      result.addAll(adapter.typeInfoDecorators);
    }
    return result;
  }

  InstanceMirror? _safeGetInstanceMirror(Object object) {
    InstanceMirror? result;
    try {
      result = _serializable.reflect(object);
    } catch (error) {
      return result;
    }
    return result;
  }

  String _getObjectKey(Object object) =>
      '${object.runtimeType}-${object.hashCode}';

  ProcessedObjectDescriptor? _getObjectProcessed(Object object, int level) {
    ProcessedObjectDescriptor? result;

    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
      return result;
    }

    final key = _getObjectKey(object);
    if (_processedObjects.containsKey(key)) {
      result = _processedObjects[key];
      result!.logUsage(level);
    } else {
      result = _processedObjects[key] = ProcessedObjectDescriptor(object);
    }
    return result;
  }

  TypeInfo _getDeclarationTypeInfo(Type declarationType, Type? valueType) =>
      _getTypeInfo((declarationType == dynamic && valueType != null)
          ? valueType
          : declarationType);

  TypeInfo _getTypeInfo(Type type) {
    if (_typeInfoCache[type] != null) {
      return _typeInfoCache[type]!;
    }
    var result = TypeInfo(type);
    for (var decorator in typeInfoDecorators.values) {
      decorator.init(_classes, valueDecorators, enumValues);
      result = decorator.decorate(result);
    }
    _typeInfoCache[type] = result;
    return result;
  }

  Type? _getGenericParameterTypeByIndex(
          num parameterIndex, TypeInfo genericType) =>
      genericType.isGeneric &&
              genericType.parameters.length - 1 >= parameterIndex
          ? genericType.parameters.elementAt(parameterIndex as int)
          : null;

  TypeInfo? _detectObjectType(dynamic objectInstance, Type? objectType,
      JsonMap objectJsonMap, DeserializationContext context) {
    final objectClassInfo = ClassInfo(_classes[objectType.toString()]);
    final meta = objectClassInfo.getMeta(context.options.scheme);

    if (objectInstance is Map<String, dynamic>) {
      objectJsonMap = JsonMap(objectInstance, meta);
    }
    final typeInfo = _getTypeInfo(objectType ?? objectInstance.runtimeType);

    final discriminatorProperty =
        _getDiscriminatorProperty(objectClassInfo, context.options);
    final discriminatorValue = discriminatorProperty != null &&
            objectJsonMap.hasProperty(discriminatorProperty)
        ? objectJsonMap.getPropertyValue(discriminatorProperty)
        : null;
    if (discriminatorProperty != null && discriminatorValue != null) {
      final declarationMirror =
          objectClassInfo.getDeclarationMirror(discriminatorProperty);
      if (declarationMirror != null) {
        final discriminatorType = _getDeclarationType(declarationMirror);
        final value = _deserializeObject(
            discriminatorValue,
            DeserializationContext(context.options,
                typeInfo: _getTypeInfo(discriminatorType)));
        return _getTypeInfo(_discriminatorToType[value]!);
      }
    }
    final String? typeName = discriminatorValue ?? typeInfo.typeName;

    final type = _classes[typeName] != null
        ? _classes[typeName]!.reflectedType
        : typeInfo.type;
    return type != null ? _getTypeInfo(type) : null;
  }

  Type? _getScalarType(Type type) {
    var result = dynamic;
    final typeInfo = _getTypeInfo(type);
    final scalarTypeName = typeInfo.scalarTypeName;

    /// Known Types
    if (typeInfo.scalarType != null) {
      return typeInfo.scalarType;
    }

    /// Custom Types annotated with [@jsonSerializable]
    if (_classes[scalarTypeName] != null) {
      return _classes[scalarTypeName]!.reflectedType;
    }

    /// Search through value decorators for scalarType match
    for (var type in valueDecorators.keys) {
      if (type.toString() == scalarTypeName) {
        result = type;
      }
    }

    return result;
  }

  Type _getDeclarationType(DeclarationMirror mirror) {
    Type? result = dynamic;
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

  ICustomConverter? _getConverter(
      JsonProperty? jsonProperty, TypeInfo typeInfo) {
    final result = jsonProperty?.converter ??
        converters[typeInfo.type!] ??
        converters[typeInfo.genericType] ??
        (enumValues[typeInfo.type!] != null ? converters[Enum] : null);

    if (result is ICustomEnumConverter) {
      (result as ICustomEnumConverter).setEnumValues(
          _getEnumValues(enumValues[typeInfo.type!]),
          defaultValue: _getEnumDefaultValue(enumValues[typeInfo.type!]),
          mapping: _getEnumMapping(enumValues[typeInfo.type!]));
    }
    return result;
  }

  Map<dynamic, dynamic>? _getEnumMapping(dynamic descriptor) =>
      descriptor is IEnumDescriptor ? descriptor.mapping : null;

  dynamic _getEnumDefaultValue(dynamic descriptor) =>
      descriptor is IEnumDescriptor ? descriptor.defaultValue : null;

  Iterable? _getEnumValues(dynamic descriptor) {
    if (descriptor is Iterable) {
      return descriptor;
    }
    final enumDescriptor = descriptor as IEnumDescriptor?;
    return enumDescriptor?.values;
  }

  dynamic _getConvertedValue(ICustomConverter converter, dynamic value,
      DeserializationContext context) {
    final direction = context.direction;
    if (_convertedValuesCache.containsKey(converter) &&
        _convertedValuesCache[converter]!.containsKey(direction) &&
        _convertedValuesCache[converter]![direction]!.containsKey(context) &&
        _convertedValuesCache[converter]![direction]![context]!
            .containsKey(value)) {
      return _convertedValuesCache[converter]![direction]![context]![value];
    }

    final computedValue = direction == ConversionDirection.fromJson
        ? converter.fromJSON(value, context)
        : converter.toJSON(value, context as SerializationContext);
    _convertedValuesCache.putIfAbsent(
        converter,
        () => {
              direction: {
                context: {value: computedValue}
              }
            });
    _convertedValuesCache[converter]!.putIfAbsent(
        direction,
        () => {
              context: {value: computedValue}
            });
    _convertedValuesCache[converter]![direction]!
        .putIfAbsent(context, () => {value: computedValue});
    _convertedValuesCache[converter]![direction]![context]!
        .putIfAbsent(value, () => computedValue);
    return computedValue;
  }

  dynamic _applyValueDecorator(dynamic value, TypeInfo typeInfo) {
    if (value == null) {
      return null;
    }
    if (valueDecorators[typeInfo.genericType] != null) {
      value = valueDecorators[typeInfo.genericType]!(value);
    }
    if (valueDecorators[typeInfo.type!] != null) {
      value = valueDecorators[typeInfo.type!]!(value);
    }
    return value;
  }

  bool _isFieldIgnored(
          [dynamic value,
          Json? classMeta,
          JsonProperty? meta,
          DeserializationOptions? options]) =>
      ((meta != null &&
              ((meta.ignore == true ||
                      (meta.ignoreForSerialization == true &&
                          options is SerializationOptions) ||
                      (meta.ignoreForDeserialization == true &&
                          options is! SerializationOptions)) ||
                  meta.ignoreIfNull == true && value == null)) ||
          ((classMeta != null && classMeta.ignoreNullMembers == true ||
                  options is SerializationOptions &&
                      options.ignoreNullMembers == true) &&
              value == null)) &&
      !(JsonProperty.isRequired(meta) || JsonProperty.isNotNull(meta));

  void _enumerateAnnotatedClasses(Function visitor) {
    for (var classMirror in _serializable.annotatedClasses) {
      visitor(ClassInfo(classMirror));
    }
  }

  void _checkFieldConstraints(dynamic value, String name,
      dynamic hasJsonProperty, JsonProperty? fieldMeta) {
    if (JsonProperty.isNotNull(fieldMeta) &&
        (hasJsonProperty == false || (value == null))) {
      throw FieldCannotBeNullError(name, message: fieldMeta!.notNullMessage);
    }
    if (hasJsonProperty == false && JsonProperty.isRequired(fieldMeta)) {
      throw FieldIsRequiredError(name, message: fieldMeta!.requiredMessage);
    }
  }

  void _enumeratePublicProperties(InstanceMirror instanceMirror,
      JsonMap? jsonMap, DeserializationOptions options, Function visitor) {
    final classInfo = ClassInfo(instanceMirror.type);
    final classMeta = classInfo.getMeta(options.scheme);

    for (var name in classInfo.publicFieldNames) {
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

      final property = _resolveProperty(name, jsonMap, options, classMeta, meta,
          (name, jsonName, _) {
        var result = instanceMirror.invokeGetter(name);
        if (result == null && jsonMap != null) {
          result = jsonMap.getPropertyValue(jsonName);
        }
        return result;
      });
      final jsonName = property.name!;
      final value = property.value;

      _checkFieldConstraints(value, name, jsonMap?.hasProperty(jsonName), meta);

      if (_isFieldIgnored(value, classMeta, meta, options)) {
        continue;
      }
      final typeInfo =
          _getDeclarationTypeInfo(declarationType, value?.runtimeType);
      visitor(
          name,
          jsonName,
          value,
          isGetterOnly,
          meta,
          _getConverter(meta, typeInfo),
          _getScalarType(declarationType),
          typeInfo);
    }

    classInfo.enumerateJsonGetters((MethodMirror mm, JsonProperty meta) {
      final name = mm.simpleName;
      final jsonName = transformFieldName(JsonProperty.getPrimaryName(meta),
          _getCaseStyle(classMeta, options))!;
      final declarationType = _getDeclarationType(mm);

      var value = instanceMirror.invoke(mm.simpleName, []);
      if (value == null && jsonMap != null) {
        value = jsonMap.getPropertyValue(jsonName);
      }
      _checkFieldConstraints(value, name, jsonMap?.hasProperty(jsonName), meta);
      if (_isFieldIgnored(value, classMeta, meta, options)) {
        return;
      }
      final typeInfo =
          _getDeclarationTypeInfo(declarationType, value?.runtimeType);
      visitor(name, jsonName, value, true, meta, _getConverter(meta, typeInfo),
          _getScalarType(declarationType), _getTypeInfo(declarationType));
    }, options.scheme);
  }

  PropertyDescriptor _resolveProperty(
      String name,
      JsonMap? jsonMap,
      DeserializationOptions? options,
      Json? classMeta,
      JsonProperty? meta,
      Function getValueByName) {
    String? jsonName = name;

    if (meta != null && meta.name != null) {
      jsonName = JsonProperty.getPrimaryName(meta);
    }
    jsonName = transformFieldName(jsonName, _getCaseStyle(classMeta, options));
    var value = getValueByName(name, jsonName, meta?.defaultValue);
    if (jsonMap != null &&
        meta != null &&
        (value == null || !jsonMap.hasProperty(jsonName!))) {
      for (var alias in JsonProperty.getAliases(meta)!) {
        jsonName = transformFieldName(alias, _getCaseStyle(classMeta, options));
        if (value != null || !jsonMap.hasProperty(jsonName!)) {
          continue;
        }
        value = jsonMap.getPropertyValue(jsonName);
      }
    }

    return PropertyDescriptor(jsonName, value);
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
    for (var param in methodMirror.parameters) {
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
                      context.typeInfo!) ??
                  dynamic;
      var paramTypeInfo = _getTypeInfo(paramType);
      paramTypeInfo = paramTypeInfo.isDynamic
          ? _getTypeInfo(_getDeclarationType(declarationMirror))
          : paramTypeInfo;
      final meta = classInfo.getDeclarationMeta(
              declarationMirror, context.options.scheme) ??
          classInfo.getDeclarationMeta(param, context.options.scheme);

      final property = _resolveProperty(
          name,
          jsonMap,
          context.options,
          classMeta,
          meta,
          (_, jsonName, defaultValue) => jsonMap.hasProperty(jsonName)
              ? jsonMap.getPropertyValue(jsonName) ?? defaultValue
              : defaultValue);
      final jsonName = property.name;
      var value = property.value;

      value = _deserializeObject(
          value,
          DeserializationContext(context.options,
              typeInfo: paramTypeInfo,
              jsonPropertyMeta: meta,
              parentJsonMaps: <JsonMap>[
                ...(context.parentJsonMaps ?? []),
                jsonMap
              ],
              classMeta: context.classMeta));
      visitor(param, name, jsonName, classMeta, meta, value, paramTypeInfo);
    }
  }

  CaseStyle? _getCaseStyle(Json? meta, DeserializationOptions? options) =>
      meta != null && meta.caseStyle != null
          ? meta.caseStyle
          : options!.caseStyle;

  String? _getDiscriminatorProperty(
          ClassInfo classInfo, DeserializationOptions? options) =>
      classInfo
          .getMetaWhere((Json meta) => meta.discriminatorProperty != null,
              options?.scheme)
          ?.discriminatorProperty;

  bool? _getProcessAnnotatedMembersOnly(
          Json? meta, DeserializationOptions options) =>
      meta != null && meta.processAnnotatedMembersOnly != null
          ? meta.processAnnotatedMembersOnly
          : options.processAnnotatedMembersOnly;

  void _dumpDiscriminatorToObjectProperty(JsonMap object,
      ClassMirror classMirror, DeserializationOptions? options) {
    final classInfo = ClassInfo(classMirror);
    final discriminatorProperty = _getDiscriminatorProperty(classInfo, options);
    if (discriminatorProperty != null) {
      final typeInfo = _getTypeInfo(classMirror.reflectedType);
      final lastMeta = classInfo.getMeta(options?.scheme);
      final discriminatorValue =
          (lastMeta != null && lastMeta.discriminatorValue != null
                  ? lastMeta.discriminatorValue
                  : typeInfo.typeName) ??
              typeInfo.typeName;
      object.setPropertyValue(discriminatorProperty, discriminatorValue);
    }
  }

  Map<Symbol, dynamic> _getNamedArguments(
      ClassMirror cm, JsonMap jsonMap, DeserializationContext context) {
    if (kIsWeb) {
      // No named arguments in JS :(
      return <Symbol, dynamic>{};
    }

    final result = <Symbol, dynamic>{};

    _enumerateConstructorParameters(
        cm, jsonMap, context, (param) => param.isNamed, (param, name, jsonName,
            classMeta, JsonProperty? meta, value, TypeInfo typeInfo) {
      if (!_isFieldIgnored(value, classMeta, meta, context.options)) {
        result[Symbol(name)] = value;
      }
    });

    return result;
  }

  List _getPositionalArguments(ClassMirror cm, JsonMap jsonMap,
      DeserializationContext context, List<String> positionalArgumentNames) {
    final result = [];

    _enumerateConstructorParameters(
        cm, jsonMap, context, (param) => !param.isOptional && !param.isNamed,
        (param, name, jsonName, classMeta, JsonProperty? meta, value,
            TypeInfo typeInfo) {
      positionalArgumentNames.add(name);
      result.add(_isFieldIgnored(value, classMeta, meta, context.options)
          ? null
          : value);
    });

    return result;
  }

  void _configureConverter(
      ICustomConverter converter, DeserializationContext context,
      {dynamic value}) {
    if (converter is ICompositeConverter) {
      (converter as ICompositeConverter).setGetConverterFunction(_getConverter);
      (converter as ICompositeConverter)
          .setGetConvertedValueFunction(_getConvertedValue);
    }
    if (converter is ICustomIterableConverter) {
      (converter as ICustomIterableConverter).setIterableInstance(value);
    }
    if (converter is ICustomMapConverter) {
      final instance = value ?? (context.options.template);
      (converter as ICustomMapConverter).setMapInstance(instance);
    }
    if (converter is IRecursiveConverter) {
      (converter as IRecursiveConverter).setSerializeObjectFunction(
          (o) => _serializeObject(o, context as SerializationContext));
      (converter as IRecursiveConverter).setDeserializeObjectFunction(
          (o, type) => _deserializeObject(
              o,
              DeserializationContext(context.options,
                  typeInfo: _getTypeInfo(type),
                  parentJsonMaps: context.parentJsonMaps,
                  jsonPropertyMeta: context.jsonPropertyMeta,
                  classMeta: context.classMeta)));
    }
  }

  dynamic _serializeIterable(Iterable object, SerializationContext? context) =>
      object.map((item) => _serializeObject(item, context)).toList();

  dynamic _serializeObject(Object? object, SerializationContext? context) {
    if (object == null) {
      return object;
    }

    final im = _safeGetInstanceMirror(object);
    final converter = _getConverter(
        context!.jsonPropertyMeta, _getTypeInfo(object.runtimeType));
    if (converter != null) {
      _configureConverter(converter, context, value: object);
      return object is Iterable
          ? _serializeIterable(object, context)
          : _getConvertedValue(converter, object, context);
    }

    if (object is Iterable) {
      return _serializeIterable(object, context);
    }

    if (im == null) {
      if (context.serializationOptions.ignoreUnknownTypes == true) {
        return null;
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
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
          (jsonMeta != null && jsonMeta.allowCircularReferences! > 0);
      final allowanceExceeded = (allowanceIsSet &&
              processedObjectDescriptor.levelsCount >
                  jsonMeta!.allowCircularReferences!)
          ? true
          : null;
      if (allowanceExceeded == true) {
        return null;
      }
      if (allowanceIsSet == false) {
        throw CircularReferenceError(object);
      }
    }
    _dumpDiscriminatorToObjectProperty(result, im.type, context.options);
    _enumeratePublicProperties(im, null, context.options, (name,
        jsonName,
        value,
        isGetterOnly,
        JsonProperty? meta,
        converter,
        scalarType,
        TypeInfo typeInfo) {
      if (value == null && meta?.defaultValue != null) {
        result.setPropertyValue(jsonName, meta?.defaultValue);
      } else {
        dynamic convertedValue;
        final newContext = SerializationContext(
            context.options as SerializationOptions,
            level: context.level + 1,
            jsonPropertyMeta: meta,
            classMeta: jsonMeta,
            typeInfo: typeInfo);
        if (meta?.flatten == true) {
          final Map flattenedPropertiesMap =
              _serializeObject(value, newContext);
          for (var element in flattenedPropertiesMap.entries) {
            result.setPropertyValue(element.key, element.value);
          }
          return;
        }
        if (converter != null) {
          _configureConverter(converter, newContext, value: value);
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
      final anyMap = im.invoke(jsonAnyGetter.simpleName, [])!;
      result.map.addAll(anyMap as Map<String, dynamic>);
    }

    return result.map;
  }

  Object? _deserializeIterable(
      dynamic jsonValue, DeserializationContext context) {
    Iterable jsonList =
        (jsonValue is String) ? _jsonDecoder.convert(jsonValue) : jsonValue;
    final value = jsonList
        .map((item) => _deserializeObject(
            item,
            DeserializationContext(context.options,
                typeInfo: _getTypeInfo(context.typeInfo!.scalarType!),
                parentJsonMaps: context.parentJsonMaps,
                jsonPropertyMeta: context.jsonPropertyMeta,
                classMeta: context.classMeta)))
        .toList();
    return _applyValueDecorator(value, context.typeInfo!);
  }

  Object? _deserializeObject(
      dynamic jsonValue, DeserializationContext context) {
    if (jsonValue == null) {
      return null;
    }
    var typeInfo = context.typeInfo!;
    final converter = _getConverter(context.jsonPropertyMeta, typeInfo);
    if (converter != null) {
      _configureConverter(converter, context);
      if (typeInfo.isIterable &&
          (converter is ICustomIterableConverter &&
              converter is! DefaultIterableConverter)) {
        return _applyValueDecorator(
            _getConvertedValue(converter, jsonValue, context), typeInfo);
      }
      return _applyValueDecorator(
          (typeInfo.isIterable)
              ? _deserializeIterable(jsonValue, context)
              : _getConvertedValue(converter, jsonValue, context),
          typeInfo);
    } else if (typeInfo.isIterable) {
      return _deserializeIterable(jsonValue, context);
    }

    dynamic convertedJsonValue;
    try {
      convertedJsonValue =
          (jsonValue is String) ? _jsonDecoder.convert(jsonValue) : jsonValue;
    } on FormatException catch (exception) {
      throw JsonFormatError(context, formatException: exception);
    }

    final jsonMap = JsonMap(
        convertedJsonValue, null, context.parentJsonMaps as List<JsonMap>?);
    typeInfo =
        _detectObjectType(null, context.typeInfo!.type, jsonMap, context)!;
    final cm =
        _classes[typeInfo.typeName] ?? _classes[typeInfo.genericTypeName];
    if (cm == null) {
      throw MissingAnnotationOnTypeError(typeInfo.type);
    }
    final classInfo = ClassInfo(cm);
    jsonMap.jsonMeta = classInfo.getMeta(context.options.scheme);

    final namedArguments = _getNamedArguments(cm, jsonMap, context);
    final positionalArgumentNames = <String>[];
    final positionalArguments =
        _getPositionalArguments(cm, jsonMap, context, positionalArgumentNames);
    final objectInstance = context.options.template ??
        (cm.isEnum
            ? null
            : cm.newInstance(
                classInfo
                    .getJsonConstructor(context.options.scheme)!
                    .constructorName,
                positionalArguments,
                namedArguments));
    final im = _safeGetInstanceMirror(objectInstance)!;
    final inheritedPublicFieldNames = classInfo.inheritedPublicFieldNames;
    final mappedFields = namedArguments.keys
        .map((Symbol symbol) =>
            RegExp('"(.+)"').allMatches(symbol.toString()).first.group(1))
        .toList()
          ..addAll(positionalArgumentNames);

    _enumeratePublicProperties(im, jsonMap, context.options, (name,
        jsonName,
        value,
        isGetterOnly,
        JsonProperty? meta,
        converter,
        scalarType,
        TypeInfo typeInfo) {
      final parentMaps = <JsonMap>[...(context.parentJsonMaps ?? []), jsonMap];
      final newContext = DeserializationContext(context.options,
          typeInfo: typeInfo,
          jsonPropertyMeta: meta,
          parentJsonMaps: parentMaps,
          classMeta: context.classMeta);
      final defaultValue = meta?.defaultValue;
      final hasJsonProperty = jsonMap.hasProperty(jsonName);
      var fieldValue = jsonMap.getPropertyValue(jsonName);
      if (!hasJsonProperty || mappedFields.contains(name)) {
        if (meta?.flatten == true) {
          im.invokeSetter(name, _deserializeObject(fieldValue, newContext));
        }
        if (defaultValue != null && !isGetterOnly) {
          im.invokeSetter(name, defaultValue);
        }
        return;
      }
      if (fieldValue is Iterable && converter is! ICustomIterableConverter) {
        fieldValue = fieldValue
            .map((item) => _deserializeObject(
                item,
                DeserializationContext(context.options,
                    typeInfo: _getTypeInfo(scalarType),
                    jsonPropertyMeta: meta,
                    parentJsonMaps: parentMaps,
                    classMeta: context.classMeta)))
            .toList();
      } else {
        fieldValue = _deserializeObject(fieldValue, newContext);
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

    final discriminatorPropertyName =
        _getDiscriminatorProperty(classInfo, context.options);
    final unmappedFields = jsonMap.map.keys
        .where((field) =>
            !mappedFields.contains(field) && field != discriminatorPropertyName)
        .toList();
    if (unmappedFields.isNotEmpty) {
      final jsonAnySetter = classInfo.getJsonAnySetter(context.options.scheme);
      for (var field in unmappedFields) {
        final jsonSetter =
            classInfo.getJsonSetter(field, context.options.scheme) ??
                jsonAnySetter;
        final params = jsonSetter == jsonAnySetter
            ? [field, jsonMap.map[field]]
            : [jsonMap.map[field]];
        if (jsonSetter != null) {
          im.invoke(jsonSetter.simpleName, params);
        }
      }
    }

    return _applyValueDecorator(objectInstance, typeInfo);
  }
}
