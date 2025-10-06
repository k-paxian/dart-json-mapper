import 'dart:convert' show JsonEncoder, JsonDecoder;

import 'package:dart_json_mapper/src/model/index.dart';

import 'class_info.dart';
import 'errors.dart';
import 'logic/adapter_manager.dart';
import 'logic/cache_manager.dart';
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

  static DeserializationContext _getDeserializationContext<T>(
      [DeserializationOptions? options]) {
    final targetOptions = options ?? JsonMapper.globalDeserializationOptions;
    final targetType = T != dynamic
        ? T
        : targetOptions.template != null
            ? targetOptions.template.runtimeType
            : targetOptions.type ?? dynamic;
    if (targetType == dynamic) {
      throw MissingTypeForDeserializationError();
    }
    return DeserializationContext(targetOptions,
        classMeta:
            instance.classes[targetType]?.getMeta(targetOptions.scheme),
        typeInfo: instance.typeInfoHandler.getTypeInfo(targetType));
  }

  static SerializationContext _getSerializationContext(
      Object? object, SerializationOptions? options) {
    instance.clearCache();
    return SerializationContext(
        options ?? JsonMapper.globalSerializationOptions,
        typeInfo: instance.typeInfoHandler.getTypeInfo(object.runtimeType));
  }

  /// Converts an instance of Dart object to JSON String
  static String serialize(Object? object, [SerializationOptions? options]) {
    final context = _getSerializationContext(object, options);
    return getJsonEncoder(context)
        .convert(instance.serializationHandler.serializeObject(object, context));
  }

  /// Converts JSON [String] Or [Object] Or [Map<String, dynamic>] to Dart object instance of type T
  /// [jsonValue] could be as of [String] type, then it will be parsed internally
  /// [jsonValue] could be as of [Object] type, then it will be processed as is
  /// [jsonValue] could be as of [Map<String, dynamic>] type, then it will be processed as is
  static T? deserialize<T>(dynamic jsonValue,
      [DeserializationOptions? options]) {
    final context = _getDeserializationContext<T>(options);
    final json = jsonValue != null
        ? jsonValue is String
            ? jsonDecoder.convert(jsonValue)
            : jsonValue
        : null;
    return instance.deserializationHandler.deserializeObject(json, context)
        as T?;
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
    final context = _getSerializationContext(object, options);
    final result =
        instance.serializationHandler.serializeObject(object, context);
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
    adapterManager.use(adapter, priority);
    _updateInternalMaps();
    return this;
  }

  /// De-registers previously registered adapter using [useAdapter] method
  JsonMapper removeAdapter(IJsonMapperAdapter adapter) {
    adapterManager.remove(adapter);
    _updateInternalMaps();
    return this;
  }

  /// Prints out current mapper configuration to the console
  /// List of currently registered adapters and their priorities
  void info() => adapterManager.info();

  /// Wipes the internal caches
  void clearCache() {
    cacheManager.clear();
    converterHandler.clearCache();
  }

  static final JsonMapper instance = JsonMapper._internal();
  static final JsonDecoder jsonDecoder = JsonDecoder();
  final Map<Type, ClassInfo> classes = {};
  final Map<String, ClassInfo> mixins = {};
  final CacheManager cacheManager = CacheManager();
  final AdapterManager adapterManager = AdapterManager();
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
      (Object? object) =>
          instance.serializationHandler.serializeObject(object, context);

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
    _clearCachesAndMaps();
    _populateMapsFromReflection();
    _updateMapsFromAdapters();
  }

  void _clearCachesAndMaps() {
    converterHandler.clearCache();
    discriminatorToType.clear();
    typeInfoCache.clear();
    classes.clear();
    mixins.clear();
    inlineValueDecorators.clear();
  }

  void _populateMapsFromReflection() {
    _populateClassesAndDiscriminators();
    _populateMixins();
  }

  void _populateClassesAndDiscriminators() {
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
  }

  void _populateMixins() {
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

  void _updateMapsFromAdapters() {
    enumValues = adapterManager.allEnumValues;
    converterHandler.converters = adapterManager.allConverters;
    typeInfoDecorators = adapterManager.allTypeInfoDecorators;
    valueDecorators = adapterManager.allValueDecorators(inlineValueDecorators);
  }

  ProcessedObjectDescriptor? getObjectProcessed(Object object, int level) {
    return cacheManager.getObjectProcessed(object, level);
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