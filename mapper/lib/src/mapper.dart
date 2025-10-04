import 'dart:convert' show JsonEncoder, JsonDecoder;
import 'dart:math';

import 'package:dart_json_mapper/src/model/index.dart';

import 'class_info.dart';
import 'errors.dart';
import 'logic/converter_handler.dart';
import 'logic/deserialization_handler.dart';
import 'logic/property_handler.dart';
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
    converterHandler.clearCache();
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
  late final TypeInfoHandler typeInfoHandler;
  late final SerializationHandler serializationHandler;
  late final DeserializationHandler deserializationHandler;
  late final ConverterHandler converterHandler;
  late final PropertyHandler propertyHandler;
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
    converterHandler = ConverterHandler(this);
    propertyHandler = PropertyHandler(this);
    useAdapter(dartCoreAdapter);
    useAdapter(dartCollectionAdapter);
  }

  void _updateInternalMaps() {
    converterHandler.clearCache();
    discriminatorToType.clear();
    typeInfoCache.clear();

    enumValues = _enumValues;
    converterHandler.converters = _converters;
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


}