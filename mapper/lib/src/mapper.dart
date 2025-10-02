import 'dart:convert' show JsonEncoder, JsonDecoder;
import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:dart_json_mapper/src/model/index.dart';
import 'package:reflectable/reflectable.dart' show InstanceMirror, MethodMirror;

import 'class_info.dart';
import 'errors.dart';
import 'globals.dart';
import 'json_map.dart';
import 'logic/deserialization_handler.dart';
import 'logic/field_handler.dart';
import 'logic/reflection_handler.dart';
import 'logic/serialization_handler.dart';
import 'logic/type_info_handler.dart';

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
        typeInfo: instance.typeInfoHandler.getTypeInfo(object.runtimeType));
    instance.clearCache();
    return getJsonEncoder(context)
        .convert(instance.serializationHandler.serializeObject(object, context));
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
    return instance.deserializationHandler.deserializeObject(
        jsonValue != null
            ? jsonValue is String
                ? jsonDecoder.convert(jsonValue)
                : jsonValue
            : null,
        DeserializationContext(targetOptions,
            classMeta:
                instance.classes[targetType]?.getMeta(targetOptions.scheme),
            typeInfo: instance.typeInfoHandler.getTypeInfo(targetType))) as T?;
  }

  /// Converts Dart object to JSON String
  static String toJson(Object? object, [SerializationOptions? options]) =>
      serialize(object, options);

  /// Converts [getParams] object to Uri GET request with [baseUrl]
  static Uri toUri({Object? getParams, String? baseUrl = ''}) {
    final params = jsonDecoder
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
        typeInfo: instance.typeInfoHandler.getTypeInfo(object.runtimeType));
    instance.clearCache();
    final result = instance.serializationHandler.serializeObject(object, context);
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
    if (adapters.containsValue(adapter)) {
      return this;
    }
    final nextPriority = priority ??
        (adapters.keys.isNotEmpty
            ? adapters.keys.reduce((value, item) => max(value, item)) + 1
            : 0);
    adapters[nextPriority] = adapter;
    _updateInternalMaps();
    return this;
  }

  /// De-registers previously registered adapter using [useAdapter] method
  JsonMapper removeAdapter(IJsonMapperAdapter adapter) {
    adapters.removeWhere((priority, x) => x == adapter);
    _updateInternalMaps();
    return this;
  }

  /// Prints out current mapper configuration to the console
  /// List of currently registered adapters and their priorities
  void info() =>
      adapters.forEach((priority, adapter) => print('$priority : $adapter'));

  /// Wipes the internal caches
  void clearCache() {
    processedObjects.clear();
    convertedValuesCache.clear();
  }

  static final JsonMapper instance = JsonMapper._internal();
  static final JsonDecoder jsonDecoder = JsonDecoder();
  final Map<Type, ClassInfo> classes = {};
  final Map<String, ClassInfo> mixins = {};
  final Map<int, IJsonMapperAdapter> adapters = {};
  final Map<String, ProcessedObjectDescriptor> processedObjects = {};
  final Map<Type, ValueDecoratorFunction> inlineValueDecorators = {};
  final Map<Type, TypeInfo> typeInfoCache = {};
  final Map<dynamic, Type> discriminatorToType = {};
  final Map<
          ICustomConverter?,
          Map<ConversionDirection,
              Map<DeserializationContext?, Map<dynamic, dynamic>>>>
      convertedValuesCache = {};

  late final TypeInfoHandler typeInfoHandler;
  late final SerializationHandler serializationHandler;
  late final DeserializationHandler deserializationHandler;

  Map<Type, ICustomConverter> converters = {};
  Map<int, ITypeInfoDecorator> typeInfoDecorators = {};
  Map<Type, ValueDecoratorFunction> valueDecorators = {};
  Map<Type, dynamic> enumValues = {};

  static JsonEncoder getJsonEncoder(SerializationContext context) =>
      context.serializationOptions.indent != null &&
              context.serializationOptions.indent!.isNotEmpty
          ? JsonEncoder.withIndent(
              context.serializationOptions.indent, toEncodable(context))
          : JsonEncoder(toEncodable(context));

  static dynamic toEncodable(SerializationContext context) =>
      (Object? object) => instance.serializationHandler.serializeObject(object, context);

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    typeInfoHandler = TypeInfoHandler(this);
    serializationHandler = SerializationHandler(this);
    deserializationHandler = DeserializationHandler(this);
    useAdapter(dartCoreAdapter);
    useAdapter(dartCollectionAdapter);
  }

  void _updateInternalMaps() {
    convertedValuesCache.clear();
    discriminatorToType.clear();
    typeInfoCache.clear();

    enumValues = _enumValues;
    converters = _converters;
    typeInfoDecorators = _typeInfoDecorators;
    valueDecorators = _valueDecorators;

    ReflectionHandler.enumerateAnnotatedClasses((classMirror) {
      final classInfo = ClassInfo.fromCache(classMirror, classes);
      final jsonMeta = classInfo.getMeta();
      if (jsonMeta != null && jsonMeta.valueDecorators != null) {
        inlineValueDecorators.addAll(jsonMeta.valueDecorators!());
      }
      if (classInfo.reflectedType != null) {
        classes[classInfo.reflectedType!] = classInfo;
      }
      if (jsonMeta != null &&
          jsonMeta.discriminatorValue != null &&
          classInfo.reflectedType != null) {
        discriminatorToType.putIfAbsent(
            jsonMeta.discriminatorValue, () => classInfo.reflectedType!);
      }
    });

    ReflectionHandler.enumerateAnnotatedClasses((classMirror) {
      final classInfo = ClassInfo.fromCache(classMirror, classes);
      if (classInfo.superClass != null) {
        final superClassInfo =
            ClassInfo.fromCache(classInfo.superClass!, classes);
        final superClassTypeInfo = superClassInfo.reflectedType != null
            ? typeInfoHandler.getTypeInfo(superClassInfo.reflectedType!)
            : null;
        if (superClassTypeInfo != null && superClassTypeInfo.isWithMixin) {
          mixins[superClassTypeInfo.mixinTypeName!] = classInfo;
        }
      }
    });
  }

  Map<Type, dynamic> get _enumValues {
    final result = <Type, dynamic>{};
    for (var adapter in adapters.values) {
      result.addAll(adapter.enumValues);
    }
    return result;
  }

  Map<Type, ICustomConverter> get _converters {
    final result = <Type, ICustomConverter>{};
    for (var adapter in adapters.values) {
      result.addAll(adapter.converters);
    }
    return result;
  }

  Map<Type, ValueDecoratorFunction> get _valueDecorators {
    final result = <Type, ValueDecoratorFunction>{};
    result.addAll(inlineValueDecorators);
    for (var adapter in adapters.values) {
      result.addAll(adapter.valueDecorators);
    }
    return result;
  }

  Map<int, ITypeInfoDecorator> get _typeInfoDecorators {
    final result = <int, ITypeInfoDecorator>{};
    for (var adapter in adapters.values) {
      result.addAll(adapter.typeInfoDecorators);
    }
    return result;
  }

  String getObjectKey(Object object) =>
      '${object.runtimeType}-${identityHashCode(object)}';

  ProcessedObjectDescriptor? getObjectProcessed(Object object, int level) {
    ProcessedObjectDescriptor? result;

    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
      return result;
    }

    final key = getObjectKey(object);
    if (processedObjects.containsKey(key)) {
      result = processedObjects[key];
      result!.logUsage(level);
    } else {
      result = processedObjects[key] = ProcessedObjectDescriptor(object);
    }
    return result;
  }

  ICustomConverter? getConverter(
      JsonProperty? jsonProperty, TypeInfo typeInfo) {
    final result = jsonProperty?.converter ??
        converters[typeInfo.type!] ??
        converters[typeInfo.genericType] ??
        (enumValues[typeInfo.type!] != null ? converters[Enum] : null) ??
        converters[converters.keys.firstWhereOrNull(
            (Type type) => type.toString() == typeInfo.typeName)];

    if (result is ICustomEnumConverter) {
      (result as ICustomEnumConverter)
          .setEnumDescriptor(getEnumDescriptor(enumValues[typeInfo.type!]));
    }
    return result;
  }

  IEnumDescriptor? getEnumDescriptor(dynamic descriptor) {
    if (descriptor is Iterable) {
      return EnumDescriptor(values: descriptor);
    }
    if (descriptor is IEnumDescriptor) {
      return descriptor;
    }
    return null;
  }

  dynamic getConvertedValue(ICustomConverter converter, dynamic value,
      DeserializationContext context) {
    final direction = context.direction;
    if (convertedValuesCache.containsKey(converter) &&
        convertedValuesCache[converter]!.containsKey(direction) &&
        convertedValuesCache[converter]![direction]!.containsKey(context) &&
        convertedValuesCache[converter]![direction]![context]!
            .containsKey(value)) {
      return convertedValuesCache[converter]![direction]![context]![value];
    }

    final computedValue = direction == ConversionDirection.fromJson
        ? converter.fromJSON(value, context)
        : converter.toJSON(value, context as SerializationContext);
    convertedValuesCache.putIfAbsent(
        converter,
        () => {
              direction: {
                context: {value: computedValue}
              }
            });
    convertedValuesCache[converter]!.putIfAbsent(
        direction,
        () => {
              context: {value: computedValue}
            });
    convertedValuesCache[converter]![direction]!
        .putIfAbsent(context, () => {value: computedValue});
    convertedValuesCache[converter]![direction]![context]!
        .putIfAbsent(value, () => computedValue);
    return computedValue;
  }

  dynamic applyValueDecorator(dynamic value, TypeInfo typeInfo) {
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

  void enumeratePublicProperties(InstanceMirror instanceMirror,
      JsonMap? jsonMap, DeserializationContext context, Function visitor) {
    final classInfo = ClassInfo.fromCache(instanceMirror.type, classes);
    final classMeta = classInfo.getMeta(context.options.scheme);

    for (var name in classInfo.publicFieldNames) {
      final declarationMirror = classInfo.getDeclarationMirror(name);
      if (declarationMirror == null) {
        continue;
      }
      final declarationType = ReflectionHandler.getDeclarationType(declarationMirror);
      final isGetterOnly = classInfo.isGetterOnly(name);
      final meta = classInfo.getDeclarationMeta(
          declarationMirror, context.options.scheme);
      if (meta == null &&
          Json.getProcessAnnotatedMembersOnly(classMeta, context.options) == true) {
        continue;
      }

      if (FieldHandler.isFieldIgnored(classMeta, meta, context.options)) {
        continue;
      }
      final propertyContext =
          context.reBuild(classMeta: classMeta, jsonPropertyMeta: meta);
      final property = resolveProperty(
          name, jsonMap, propertyContext, classMeta, meta, (name, jsonName, _) {
        var result = instanceMirror.invokeGetter(name);
        if (result == null && jsonMap != null) {
          result = jsonMap.getPropertyValue(jsonName);
        }
        return result;
      });

      FieldHandler.checkFieldConstraints(
          property.value, name, jsonMap?.hasProperty(property.name), meta);

      if (FieldHandler.isFieldIgnoredByValue(
          property.value, classMeta, meta, propertyContext.options)) {
        continue;
      }
      final typeInfo =
          typeInfoHandler.getDeclarationTypeInfo(declarationType, property.value?.runtimeType);
      visitor(name, property, isGetterOnly, meta, getConverter(meta, typeInfo),
          typeInfo);
    }

    classInfo.enumerateJsonGetters((MethodMirror mm, JsonProperty meta) {
      final declarationType = ReflectionHandler.getDeclarationType(mm);
      final propertyContext =
          context.reBuild(classMeta: classMeta, jsonPropertyMeta: meta);
      final property = resolveProperty(
          mm.simpleName, jsonMap, propertyContext, classMeta, meta,
          (name, jsonName, _) {
        var result = instanceMirror.invoke(name, []);
        if (result == null && jsonMap != null) {
          result = jsonMap.getPropertyValue(jsonName);
        }
        return result;
      });

      FieldHandler.checkFieldConstraints(property.value, mm.simpleName,
          jsonMap?.hasProperty(property.name), meta);
      if (FieldHandler.isFieldIgnoredByValue(
          property.value, classMeta, meta, context.options)) {
        return;
      }
      final typeInfo =
          typeInfoHandler.getDeclarationTypeInfo(declarationType, property.value?.runtimeType);
      visitor(mm.simpleName, property, true, meta,
          getConverter(meta, typeInfo), typeInfoHandler.getTypeInfo(declarationType));
    }, context.options.scheme);
  }

  PropertyDescriptor resolveProperty(
      String name,
      JsonMap? jsonMap,
      DeserializationContext context,
      Json? classMeta,
      JsonProperty? meta,
      Function getValueByName) {
    String? jsonName = name;

    if (meta != null && meta.name != null) {
      jsonName = JsonProperty.getPrimaryName(meta);
    }
    jsonName = context.transformIdentifier(jsonName!);
    var value = getValueByName(name, jsonName, meta?.defaultValue);
    if (jsonMap != null &&
        meta != null &&
        (value == null || !jsonMap.hasProperty(jsonName))) {
      final initialValue = value;
      for (final alias in JsonProperty.getAliases(meta)!) {
        final targetJsonName = transformIdentifierCaseStyle(
            alias, context.targetCaseStyle, context.sourceCaseStyle);
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
        FieldHandler.isFieldIgnoredByDefault(
            meta, classMeta, context.options as SerializationOptions)) {
      return PropertyDescriptor(jsonName!, meta?.defaultValue, true);
    }
    return PropertyDescriptor(jsonName!, value, true);
  }

  void configureConverter(
      ICustomConverter converter, DeserializationContext context,
      {dynamic value}) {
    if (converter is ICompositeConverter) {
      (converter as ICompositeConverter).setGetConverterFunction(getConverter);
      (converter as ICompositeConverter)
          .setGetConvertedValueFunction(getConvertedValue);
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
          (o, context) => serializationHandler.serializeObject(o, context));
      (converter as IRecursiveConverter).setDeserializeObjectFunction((o,
              context, type) =>
          deserializationHandler.deserializeObject(o, context.reBuild(typeInfo: typeInfoHandler.getTypeInfo(type))));
    }
  }
}