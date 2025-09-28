import 'dart:convert' show JsonEncoder, JsonDecoder;
import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
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
  /// global [SerializationOptions]
  static SerializationOptions globalSerializationOptions =
      defaultSerializationOptions;

  /// global [DeserializationOptions]
  static DeserializationOptions globalDeserializationOptions =
      defaultDeserializationOptions;

  /// Converts an instance of Dart object to JSON String
  static String serialize(Object? object, [SerializationOptions? options]) {
    final context = SerializationContext(
        options ?? JsonMapper.globalSerializationOptions,
        typeInfo: instance._getTypeInfo(object.runtimeType));
    instance.clearCache();
    return _getJsonEncoder(context)
        .convert(instance._serializeObject(object, context));
  }

  /// Converts JSON [String] Or [Object] Or [Map<String, dynamic>] to Dart object instance of type T
  /// [jsonValue] could be as of [String] type, then it will be parsed internally
  /// [jsonValue] could be as of [Object] type, then it will be processed as is
  /// [jsonValue] could be as of [Map<String, dynamic>] type, then it will be processed as is
  static T? deserialize<T>(dynamic jsonValue,
      [DeserializationOptions? options]) {
    final targetOptions = options ?? JsonMapper.globalDeserializationOptions;
    final targetType = T != dynamic
        ? T
        : targetOptions.template != null
            ? targetOptions.template.runtimeType
            : targetOptions.type ?? dynamic;
    assert(targetType != dynamic
        ? true
        : throw MissingTypeForDeserializationError());
    return instance._deserializeObject(
        jsonValue != null
            ? jsonValue is String
                ? _jsonDecoder.convert(jsonValue)
                : jsonValue
            : null,
        DeserializationContext(targetOptions,
            classMeta:
                instance._classes[targetType]?.getMeta(targetOptions.scheme),
            typeInfo: instance._getTypeInfo(targetType))) as T?;
  }

  /// Converts Dart object to JSON String
  static String toJson(Object? object, [SerializationOptions? options]) =>
      serialize(object, options);

  /// Converts [getParams] object to Uri GET request with [baseUrl]
  static Uri toUri({Object? getParams, String? baseUrl = ''}) {
    final params = _jsonDecoder
        .convert(serialize(getParams))
        ?.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    return Uri.parse('$baseUrl${params != null ? '?$params' : ''}');
  }

  /// Converts JSON String to Dart object of type T
  static T? fromJson<T>(String jsonValue, [DeserializationOptions? options]) =>
      deserialize<T>(jsonValue, options);

  /// Converts Dart object to `Map<String, dynamic>`
  static Map<String, dynamic>? toMap(Object? object,
      [SerializationOptions? options]) {
    final context = SerializationContext(
        options ?? JsonMapper.globalSerializationOptions,
        typeInfo: instance._getTypeInfo(object.runtimeType));
    instance.clearCache();
    final result = instance._serializeObject(object, context);
    return result is Map<String, dynamic> ? result : null;
  }

  /// Converts `Map<String, dynamic>` to Dart object instance of type T
  static T? fromMap<T>(Map<String, dynamic>? map,
          [DeserializationOptions? options]) =>
      deserialize<T>(map, options);

  /// Clone Dart object of type T
  static T? clone<T>(T object) => fromJson<T>(toJson(object));

  /// Alias for clone method to copy Dart object of type T
  static T? copy<T>(T object) => clone<T>(object);

  /// Copy Dart object of type T & merge it with ```Map<String, dynamic>```
  static T? copyWith<T>(T object, Map<String, dynamic> map) =>
      fromMap<T>(mergeMaps(toMap(object), map));

  /// Recursive deep merge two maps
  static Map<String, dynamic> mergeMaps(
      Map<String, dynamic>? mapA, Map<String, dynamic> mapB) {
    if (mapA == null) {
      return mapB;
    }
    mapB.forEach((key, value) {
      if (!mapA.containsKey(key)) {
        mapA[key] = value;
      } else {
        if (mapA[key] is Map) {
          mergeMaps(mapA[key], mapB[key]);
        } else {
          mapA[key] = mapB[key];
        }
      }
    });
    return mapA;
  }

  /// Enumerates adapter [IJsonMapperAdapter] instances using visitor pattern
  /// Abstracts adapters ordering logic from consumers
  static void enumerateAdapters(
      Iterable<JsonMapperAdapter> adapters, Function visitor) {
    final generatedAdapters = adapters.where((adapter) => adapter.isGenerated);
    final otherAdapters = adapters.where((adapter) => !adapter.isGenerated);
    for (var adapter in [...generatedAdapters, ...otherAdapters]) {
      visitor(adapter);
    }
  }

  /// Registers an instance of [IJsonMapperAdapter] with the mapper engine
  /// Adapters are meant to be used as a pluggable extensions, widening
  /// the number of supported types to be seamlessly converted to/from JSON
  JsonMapper useAdapter(IJsonMapperAdapter adapter, [int? priority]) {
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
  JsonMapper removeAdapter(IJsonMapperAdapter adapter) {
    _adapters.removeWhere((priority, x) => x == adapter);
    _updateInternalMaps();
    return this;
  }

  /// Prints out current mapper configuration to the console
  /// List of currently registered adapters and their priorities
  void info() =>
      _adapters.forEach((priority, adapter) => print('$priority : $adapter'));

  /// Wipes the internal caches
  void clearCache() {
    _processedObjects.clear();
    _convertedValuesCache.clear();
  }

  static final JsonMapper instance = JsonMapper._internal();
  static final JsonDecoder _jsonDecoder = JsonDecoder();
  final _serializable = const JsonSerializable();
  final Map<Type, ClassInfo> _classes = {};
  final Map<String, ClassInfo> _mixins = {};
  final Map<int, IJsonMapperAdapter> _adapters = {};
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
    _typeInfoCache.clear();
    _enumerateAnnotatedClasses((ClassInfo classInfo) {
      final jsonMeta = classInfo.getMeta();
      if (jsonMeta != null && jsonMeta.valueDecorators != null) {
        _inlineValueDecorators.addAll(jsonMeta.valueDecorators!());
      }
      if (classInfo.reflectedType != null) {
        _classes[classInfo.reflectedType!] = classInfo;
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
        final superClassInfo =
            ClassInfo.fromCache(classInfo.superClass!, _classes);
        final superClassTypeInfo = superClassInfo.reflectedType != null
            ? _getTypeInfo(superClassInfo.reflectedType!)
            : null;
        if (superClassTypeInfo != null && superClassTypeInfo.isWithMixin) {
          _mixins[superClassTypeInfo.mixinTypeName!] = classInfo;
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
      '${object.runtimeType}-${identityHashCode(object)}';

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
    if (_mixins[result.typeName] != null) {
      result.mixinType = _mixins[result.typeName]!.reflectedType;
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
    final objectClassInfo = _classes[objectType];
    if (objectClassInfo == null) {
      return null;
    }
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
        final value = _deserializeObject(discriminatorValue,
            context.reBuild(typeInfo: _getTypeInfo(discriminatorType)));
        if (value is Type) {
          return _getTypeInfo(value);
        }

        if (_discriminatorToType[value] == null) {
          final validDiscriminators = ClassInfo.getAllSubTypes(
                  _classes, objectClassInfo)
              .map((e) => e.getMeta(context.options.scheme)!.discriminatorValue)
              .toList();
          throw JsonMapperSubtypeError(
            discriminatorValue,
            validDiscriminators,
            objectClassInfo,
          );
        }

        return _getTypeInfo(_discriminatorToType[value]!);
      }
    }
    if (discriminatorValue != null) {
      final targetType = _getTypeByStringName(discriminatorValue);
      return _classes[targetType] != null
          ? _getTypeInfo(_classes[targetType]!.reflectedType!)
          : typeInfo;
    }
    return typeInfo;
  }

  Type? _getTypeByStringName(String? typeName) =>
      _classes.keys.firstWhereOrNull((t) => t.toString() == typeName);

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
        (enumValues[typeInfo.type!] != null ? converters[Enum] : null) ??
        converters[converters.keys.firstWhereOrNull(
            (Type type) => type.toString() == typeInfo.typeName)];

    if (result is ICustomEnumConverter) {
      (result as ICustomEnumConverter)
          .setEnumDescriptor(_getEnumDescriptor(enumValues[typeInfo.type!]));
    }
    return result;
  }

  IEnumDescriptor? _getEnumDescriptor(dynamic descriptor) {
    if (descriptor is Iterable) {
      return EnumDescriptor(values: descriptor);
    }
    if (descriptor is IEnumDescriptor) {
      return descriptor;
    }
    return null;
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

  bool _isNullableField(JsonProperty? meta) =>
      !(JsonProperty.isRequired(meta) || JsonProperty.isNotNull(meta));

  bool _isFieldIgnored(
          [Json? classMeta,
          JsonProperty? meta,
          DeserializationOptions? options]) =>
      (meta != null &&
          (meta.ignore == true ||
              ((meta.ignoreForSerialization == true ||
                      JsonProperty.hasParentReference(meta) ||
                      meta.inject == true) &&
                  options is SerializationOptions) ||
              (meta.ignoreForDeserialization == true &&
                  options is! SerializationOptions)) &&
          _isNullableField(meta));

  bool _isFieldIgnoredByValue(
          [dynamic value,
          Json? classMeta,
          JsonProperty? meta,
          DeserializationOptions? options]) =>
      ((meta != null &&
              (_isFieldIgnored(classMeta, meta, options) ||
                  meta.ignoreIfNull == true && value == null)) ||
          (options is SerializationOptions &&
              (((options.ignoreNullMembers == true ||
                          classMeta?.ignoreNullMembers == true) &&
                      value == null) ||
                  ((_isFieldIgnoredByDefault(meta, classMeta, options)) &&
                      JsonProperty.isDefaultValue(meta, value) == true)))) &&
      _isNullableField(meta);

  bool _isFieldIgnoredByDefault(
          JsonProperty? meta, Json? classMeta, SerializationOptions options) =>
      meta?.ignoreIfDefault == true ||
      classMeta?.ignoreDefaultMembers == true ||
      options.ignoreDefaultMembers == true;

  void _enumerateAnnotatedClasses(Function visitor) {
    for (var classMirror in _serializable.annotatedClasses) {
      visitor(ClassInfo.fromCache(classMirror, _classes));
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
      JsonMap? jsonMap, DeserializationContext context, Function visitor) {
    final classInfo = ClassInfo.fromCache(instanceMirror.type, _classes);
    final classMeta = classInfo.getMeta(context.options.scheme);

    for (var name in classInfo.publicFieldNames) {
      final declarationMirror = classInfo.getDeclarationMirror(name);
      if (declarationMirror == null) {
        continue;
      }
      final declarationType = _getDeclarationType(declarationMirror);
      final isGetterOnly = classInfo.isGetterOnly(name);
      final meta = classInfo.getDeclarationMeta(
          declarationMirror, context.options.scheme);
      if (meta == null &&
          _getProcessAnnotatedMembersOnly(classMeta, context.options) == true) {
        continue;
      }

      if (_isFieldIgnored(classMeta, meta, context.options)) {
        continue;
      }
      final propertyContext =
          context.reBuild(classMeta: classMeta, jsonPropertyMeta: meta);
      final property = _resolveProperty(
          name, jsonMap, propertyContext, classMeta, meta, (name, jsonName, _) {
        var result = instanceMirror.invokeGetter(name);
        if (result == null && jsonMap != null) {
          result = jsonMap.getPropertyValue(jsonName);
        }
        return result;
      });

      _checkFieldConstraints(
          property.value, name, jsonMap?.hasProperty(property.name), meta);

      if (_isFieldIgnoredByValue(
          property.value, classMeta, meta, propertyContext.options)) {
        continue;
      }
      final typeInfo =
          _getDeclarationTypeInfo(declarationType, property.value?.runtimeType);
      visitor(name, property, isGetterOnly, meta, _getConverter(meta, typeInfo),
          typeInfo);
    }

    classInfo.enumerateJsonGetters((MethodMirror mm, JsonProperty meta) {
      final declarationType = _getDeclarationType(mm);
      final propertyContext =
          context.reBuild(classMeta: classMeta, jsonPropertyMeta: meta);
      final property = _resolveProperty(
          mm.simpleName, jsonMap, propertyContext, classMeta, meta,
          (name, jsonName, _) {
        var result = instanceMirror.invoke(name, []);
        if (result == null && jsonMap != null) {
          result = jsonMap.getPropertyValue(jsonName);
        }
        return result;
      });

      _checkFieldConstraints(property.value, mm.simpleName,
          jsonMap?.hasProperty(property.name), meta);
      if (_isFieldIgnoredByValue(
          property.value, classMeta, meta, context.options)) {
        return;
      }
      final typeInfo =
          _getDeclarationTypeInfo(declarationType, property.value?.runtimeType);
      visitor(mm.simpleName, property, true, meta,
          _getConverter(meta, typeInfo), _getTypeInfo(declarationType));
    }, context.options.scheme);
  }

  PropertyDescriptor _resolveProperty(
      String name,
      JsonMap? jsonMap,
      DeserializationContext context,
      Json? classMeta,
      JsonProperty? meta,
      Function getValueByName) {
    String? jsonName;
    final isDeserialization = jsonMap != null;
    final isExplicitName = meta != null && meta.name != null;

    if (isExplicitName) {
      jsonName = JsonProperty.getPrimaryName(meta);
    } else {
      jsonName = name;
    }

    if (!isExplicitName || !isDeserialization) {
      jsonName = context.transformIdentifier(jsonName!);
    }

    var value = getValueByName(name, jsonName, meta?.defaultValue);

    if (isDeserialization &&
        meta != null &&
        (value == null || !jsonMap!.hasProperty(jsonName!))) {
      final initialValue = value;
      for (final alias in JsonProperty.getAliases(meta)!) {
        final targetJsonName =
            isExplicitName ? alias : context.transformIdentifier(alias);
        if (value != initialValue || !jsonMap.hasProperty(targetJsonName)) {
          continue;
        }
        jsonName = targetJsonName;
        value = jsonMap.getPropertyValue(jsonName);
      }
    }

    if (meta != null &&
        meta.inject == true &&
        context.options.injectableValues != null) {
      final injectionJsonMap = JsonMap(context.options.injectableValues!);
      if (injectionJsonMap.hasProperty(jsonName!)) {
        value = injectionJsonMap.getPropertyValue(jsonName);
        return PropertyDescriptor(jsonName, value, false);
      } else {
        return PropertyDescriptor(jsonName, null, false);
      }
    }
    if (jsonName == JsonProperty.parentReference) {
      return PropertyDescriptor(
          jsonName!, context.parentObjectInstances!.last, false);
    }
    if (value == null &&
        meta?.defaultValue != null &&
        _isFieldIgnoredByDefault(
            meta, classMeta, context.options as SerializationOptions)) {
      return PropertyDescriptor(jsonName!, meta?.defaultValue, true);
    }
    return PropertyDescriptor(jsonName!, value, true);
  }

  void _enumerateConstructorParameters(ClassMirror classMirror, JsonMap jsonMap,
      DeserializationContext context, Function filter, Function visitor) {
    final classInfo = ClassInfo.fromCache(classMirror, _classes);
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
      final propertyContext = context.reBuild(
          classMeta: classMeta,
          jsonPropertyMeta: meta,
          typeInfo: paramTypeInfo,
          parentJsonMaps: <JsonMap>[
            ...(context.parentJsonMaps ?? []),
            jsonMap
          ]);

      // New logic to determine jsonNameForVisitor and finalValueForVisitor starts here:
      dynamic finalValueForVisitor;
      String? jsonNameForVisitor;

      if (meta?.flatten == true) {
        finalValueForVisitor = _deserializeObject(jsonMap.map, propertyContext.reBuild(jsonPropertyMeta: null));
        jsonNameForVisitor = context.transformIdentifier(meta?.name ?? name);
      } else { // This is the beginning of the 'else' block to be replaced
        final property = _resolveProperty(
            name,
            jsonMap,
            propertyContext,
            classMeta,
            meta,
            (_, resolvedJsonNameFromCallback, defaultValueFromCallback) =>
                jsonMap.hasProperty(resolvedJsonNameFromCallback)
                    ? jsonMap.getPropertyValue(resolvedJsonNameFromCallback) ?? defaultValueFromCallback
                    : defaultValueFromCallback);
        jsonNameForVisitor = property.name;
        if (property.raw) { // This check is crucial
            finalValueForVisitor = _deserializeObject(property.value, propertyContext);
        } else {
            finalValueForVisitor = property.value;
        }
      } // This is the end of the 'else' block to be replaced

      // Call the visitor with the determined jsonNameForVisitor and finalValueForVisitor
      visitor(param, name, jsonNameForVisitor, classMeta, meta, finalValueForVisitor, paramTypeInfo);
      // End of the new logic block for this section
    }
  }

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
    final classInfo = ClassInfo.fromCache(classMirror, _classes);
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
    final result = <Symbol, dynamic>{};

    _enumerateConstructorParameters(
        cm, jsonMap, context, (param) => param.isNamed, (param, name, jsonName,
            classMeta, JsonProperty? meta, value, TypeInfo typeInfo) {
      if (!_isFieldIgnoredByValue(value, classMeta, meta, context.options)) {
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
      result.add(_isFieldIgnoredByValue(value, classMeta, meta, context.options)
          ? null
          : value);
    });

    return result;
  }

  bool _isValidJSON(dynamic jsonValue) {
    try {
      if (jsonValue is String) {
        _jsonDecoder.convert(jsonValue);
        return true;
      }
      return false;
    } on FormatException {
      return false;
    }
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
          (o, context) => _serializeObject(o, context));
      (converter as IRecursiveConverter).setDeserializeObjectFunction((o,
              context, type) =>
          _deserializeObject(o, context.reBuild(typeInfo: _getTypeInfo(type))));
    }
  }

  dynamic _serializeObject(Object? object, SerializationContext? context) {
    if (object == null) {
      return object;
    }

    final im = _safeGetInstanceMirror(object);
    final converter = _getConverter(
        context!.jsonPropertyMeta, _getTypeInfo(object.runtimeType));
    if (converter != null) {
      _configureConverter(converter, context, value: object);
      return _getConvertedValue(converter, object, context);
    }

    if (im == null) {
      if (context.serializationOptions.ignoreUnknownTypes == true) {
        return null;
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
      }
    }

    final classInfo = ClassInfo.fromCache(im.type, _classes);
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
                  jsonMeta.allowCircularReferences!)
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
    _enumeratePublicProperties(im, null, context, (name, property, isGetterOnly,
        JsonProperty? meta, converter, TypeInfo typeInfo) {
      dynamic convertedValue;
      final propertyContext = context.reBuild(
          level: context.level + 1,
          jsonPropertyMeta: meta,
          classMeta: jsonMeta, // jsonMeta is from _serializeObject scope
          typeInfo: typeInfo) as SerializationContext;

  if (meta?.rawJson == true && typeInfo.type == String && property.value is String) {
    final jsonString = property.value as String;
    if (jsonString.isEmpty || jsonString == "null") {
      convertedValue = null;
    } else {
      try {
        convertedValue = JsonDecoder().convert(jsonString);
      } on FormatException {
        convertedValue = jsonString; // Treat as plain string
      }
    }
  } else { // Not a rawJson string field
    if (meta?.flatten == true) {
      final Map flattenedPropertiesMap =
          _serializeObject(property.value, propertyContext);
      final fieldPrefixWords = meta?.name != null
          ? toWords(meta?.name, propertyContext.caseStyle).join(' ')
          : null;
      for (var element in flattenedPropertiesMap.entries) {
        result.setPropertyValue(
            fieldPrefixWords != null
                ? transformIdentifierCaseStyle(
                    transformIdentifierCaseStyle(
                        '$fieldPrefixWords ${element.key}',
                        defaultCaseStyle,
                        null),
                    propertyContext.targetCaseStyle,
                    defaultCaseStyle)
                : element.key,
            element.value);
      }
      return; // from callback
    }

    final actualConverter = _getConverter(meta, typeInfo); // Use _getConverter here
    if (actualConverter != null) {
      final valueToConvert = property.value ?? meta?.defaultValue;
      _configureConverter(actualConverter, propertyContext, value: valueToConvert);
      convertedValue = _getConvertedValue(actualConverter, valueToConvert, propertyContext);
    } else {
      // No specific converter found for the type (e.g. custom object, non-string primitive not covered)
      convertedValue = _serializeObject(property.value, propertyContext);
    }
  }
  result.setPropertyValue(property.name, convertedValue ?? meta?.defaultValue);
    });

    final jsonAnyGetter = classInfo.getJsonAnyGetter();
    if (jsonAnyGetter != null) {
      final anyMap = im.invoke(jsonAnyGetter.simpleName, [])!;
      result.map.addAll(anyMap as Map<String, dynamic>);
    }

    return result.map;
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
          _getConvertedValue(converter, jsonValue, context), typeInfo);
    }

    dynamic convertedJsonValue =
        _isValidJSON(jsonValue) ? _jsonDecoder.convert(jsonValue) : jsonValue;

    if (convertedJsonValue is String && typeInfo.type is Type) {
      return _getTypeByStringName(convertedJsonValue.replaceAll("\"", ""));
    }

    final jsonMap = JsonMap(
        convertedJsonValue, null, context.parentJsonMaps as List<JsonMap>?);
    typeInfo =
        _detectObjectType(null, context.typeInfo!.type, jsonMap, context) ??
            typeInfo;
    final classInfo = _classes[typeInfo.type] ??
        _classes[typeInfo.genericType] ??
        _classes[typeInfo.mixinType];
    if (classInfo == null) {
      throw MissingAnnotationOnTypeError(typeInfo.type);
    }
    jsonMap.jsonMeta = classInfo.getMeta(context.options.scheme);

    final namedArguments =
        _getNamedArguments(classInfo.classMirror, jsonMap, context);
    final positionalArgumentNames = <String>[];
    final positionalArguments = _getPositionalArguments(
        classInfo.classMirror, jsonMap, context, positionalArgumentNames);
    dynamic objectInstance;
    try {
      objectInstance = context.options.template ??
          (classInfo.classMirror.isEnum
              ? null
              : classInfo.classMirror.newInstance(
                  classInfo
                      .getJsonConstructor(context.options.scheme)!
                      .constructorName,
                  positionalArguments,
                  namedArguments));
    } on TypeError catch (typeError) {
      final positionalNullArguments = positionalArgumentNames.where((element) =>
          positionalArguments[positionalArgumentNames.indexOf(element)] ==
          null);
      final namedNullArguments = Map<Symbol, dynamic>.from(namedArguments);
      namedNullArguments.removeWhere((key, value) => value != null);
      throw CannotCreateInstanceError(
          typeError, classInfo, positionalNullArguments, namedNullArguments);
    }

    final im = _safeGetInstanceMirror(objectInstance)!;
    final inheritedPublicFieldNames = classInfo.inheritedPublicFieldNames;
    final mappedFields = namedArguments.keys
        .map((Symbol symbol) =>
            RegExp('"(.+)"').allMatches(symbol.toString()).first.group(1))
        .toList()
      ..addAll(positionalArgumentNames);

    _enumeratePublicProperties(im, jsonMap, context, (name, property,
        isGetterOnly, JsonProperty? meta, converter, TypeInfo typeInfo) {
      final propertyContext = context.reBuild(
          parentObjectInstances: [
            ...(context.parentObjectInstances ?? []),
            objectInstance
          ],
          typeInfo: typeInfo,
          jsonPropertyMeta: meta,
          parentJsonMaps: <JsonMap>[
            ...(context.parentJsonMaps ?? []),
            jsonMap
          ]);
      final defaultValue = meta?.defaultValue;
      final hasJsonProperty = jsonMap.hasProperty(property.name);
      var fieldValue = jsonMap.getPropertyValue(property.name);
      if (!hasJsonProperty || mappedFields.contains(name)) {
      // BEGINNING OF BLOCK TO REPLACE/OVERWRITE
      if (meta?.flatten == true) {
          // name: the simple name of the property (e.g., "page")
          // mappedFields: list of names of fields handled by constructor
          // isGetterOnly: boolean, true if the property is final or getter-only

          if (mappedFields.contains(name) || isGetterOnly) {
              // If the field was handled by the constructor OR it's a final/getter-only field,
              // do not attempt to process it further here (especially invokeSetter).
              return; 
          }

          // If we reach here, it's a mutable (non-final) flattened field 
          // that was NOT handled by the constructor. This scenario might be rare
          // for 'flatten:true' but this logic would apply.
          final fieldValue = jsonMap.getPropertyValue(property.name); 
          final objectToDeserialize = meta?.name != null && fieldValue is Map 
              ? fieldValue.map((key, value) => MapEntry(skipPrefix(meta?.name, key, propertyContext.caseStyle), value)) 
              : fieldValue;
          
          im.invokeSetter(name, _deserializeObject(objectToDeserialize, propertyContext));
          return; // Ensure we don't fall through to other logic for this property
      }
      // END OF BLOCK TO REPLACE/OVERWRITE
        if (im.invokeGetter(name) == null &&
            defaultValue != null &&
            !isGetterOnly) {
          im.invokeSetter(name, defaultValue);
        }
        if (meta?.inject != true) {
          return;
        }
      }
      fieldValue = property.raw
          ? _deserializeObject(fieldValue, propertyContext)
          : property.value;
      if (isGetterOnly) {
        if (inheritedPublicFieldNames.contains(name) &&
            !mappedFields.contains(property.name)) {
          mappedFields.add(property.name);
        }
      } else {
        // Logic for !isGetterOnly fields:
        if (meta?.rawJson == true && typeInfo.type == String) {
          if (fieldValue is Map || fieldValue is List) {
            // If it's a Map or List, convert to JSON string.
            fieldValue = JsonEncoder().convert(fieldValue);
          } else if (fieldValue == null) {
            // If JSON value is null, field should be null.
            fieldValue = null;
          } else {
            // If it's any other type (e.g., String, num, bool),
            // convert it to string to ensure type safety for the String field.
            fieldValue = fieldValue.toString();
          }
        }

        // Now, apply decorator and set the property.
        // fieldValue at this point MUST be a String if rawJson conditions were met and typeInfo.type is String, or null.
        fieldValue = _applyValueDecorator(fieldValue, typeInfo) ?? defaultValue;
        im.invokeSetter(name, fieldValue);
        mappedFields.add(property.name);
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