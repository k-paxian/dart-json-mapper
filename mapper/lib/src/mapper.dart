import 'dart:convert' show JsonDecoder, JsonEncoder; // dart: imports first

import 'package:collection/collection.dart' show IterableExtension; // package: imports next
import 'package:reflectable/reflectable.dart'
    show ClassMirror, DeclarationMirror, InstanceMirror;

import 'adapter_manager.dart'; // relative file imports last
import 'deserialization_pipeline.dart';
import 'errors.dart';
import 'model/index.dart';
import 'serialization_pipeline.dart';
import 'type_info_provider.dart';
import 'utils.dart';

// Note: Original file had duplicate class JsonMapper {} definitions due to merge issue.
// Assuming one definition that incorporates all members.

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
    final effectiveOptions = options ?? JsonMapper.globalSerializationOptions;
    final context = SerializationContext(
        effectiveOptions,
        typeInfo: instance._typeInfoProvider.getTypeInfo(object.runtimeType));
    instance.clearCache(); 

    final pipeline = SerializationPipeline(instance);
    return SerializationPipeline.getJsonEncoder(context, pipeline)
        .convert(pipeline.execute(object, context));
  }

  static T? deserialize<T>(dynamic jsonValue,
      [DeserializationOptions? options]) {
    final targetOptions = options ?? JsonMapper.globalDeserializationOptions;
    final targetType = T != dynamic
        ? T
        : targetOptions.template != null
            ? targetOptions.template.runtimeType
            : targetOptions.type ?? dynamic;
    assert(targetType != dynamic,
        throw MissingTypeForDeserializationError());

    final deserializationContext = DeserializationContext(targetOptions,
            classMeta:
                instance._classes[targetType]?.getMeta(targetOptions.scheme),
            typeInfo: instance._typeInfoProvider.getTypeInfo(targetType));
    
    final parsedJson = jsonValue != null
            ? jsonValue is String
                ? instance._jsonDecoder.convert(jsonValue) 
                : jsonValue
            : null;

    final pipeline = DeserializationPipeline(instance);
    return pipeline.execute(parsedJson, deserializationContext) as T?;
  }

  static String toJson(Object? object, [SerializationOptions? options]) =>
      serialize(object, options);

  static Uri toUri({Object? getParams, String? baseUrl = ''}) {
    final serializedParams = serialize(getParams);
    final Map<String, dynamic>? paramsMap = instance._jsonDecoder.convert(serializedParams) as Map<String, dynamic>?;
    final paramsString = paramsMap?.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    return Uri.parse('$baseUrl${paramsString != null && paramsString.isNotEmpty ? '?$paramsString' : ''}');
  }

  static T? fromJson<T>(String jsonValue, [DeserializationOptions? options]) =>
      deserialize<T>(jsonValue, options);

  static Map<String, dynamic>? toMap(Object? object,
      [SerializationOptions? options]) {
    final effectiveOptions = options ?? JsonMapper.globalSerializationOptions;
    final context = SerializationContext(
        effectiveOptions,
        typeInfo: instance._typeInfoProvider.getTypeInfo(object.runtimeType));
    instance.clearCache(); 

    final pipeline = SerializationPipeline(instance);
    final result = pipeline.execute(object, context);
    return result is Map<String, dynamic> ? result : null;
  }

  static T? fromMap<T>(Map<String, dynamic>? map,
          [DeserializationOptions? options]) =>
      deserialize<T>(map, options);

  static T? clone<T>(T object) => fromJson<T>(toJson(object));

  static T? copy<T>(T object) => clone<T>(object);

  static T? copyWith<T>(T object, Map<String, dynamic> map) =>
      fromMap<T>(mergeMaps(toMap(object), map));

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

  static void enumerateAdapters(
      Iterable<JsonMapperAdapter> adapters, Function visitor) {
    final generatedAdapters = adapters.where((adapter) => adapter.isGenerated);
    final otherAdapters = adapters.where((adapter) => !adapter.isGenerated);
    for (var adapter in [...generatedAdapters, ...otherAdapters]) {
      visitor(adapter);
    }
  }

  final AdapterManager _adapterManager = AdapterManager();
  late final TypeInfoProvider _typeInfoProvider; 

  JsonMapper useAdapter(IJsonMapperAdapter adapter, [int? priority]) {
    _adapterManager.useAdapter(adapter, priority);
    _updateInternalMaps(); 
    return this;
  }

  JsonMapper removeAdapter(IJsonMapperAdapter adapter) {
    _adapterManager.removeAdapter(adapter);
    _updateInternalMaps(); 
    return this;
  }

  void info() => _adapterManager.info();
  
  void clearCache() {
    _typeInfoProvider.clearCache(); 
    _convertedValuesCache.clear();
  }

  static final JsonMapper instance = JsonMapper._internal();
  final JsonDecoder _jsonDecoder = JsonDecoder();

  final _serializable = const JsonSerializable(); 
  final Map<Type, ClassInfo> _classes = {};
  final Map<Type, ValueDecoratorFunction> _inlineValueDecorators = {};
  final Map<dynamic, Type> _discriminatorToType = {};
  final Map<
          ICustomConverter?,
          Map<ConversionDirection,
              Map<DeserializationContext?, Map<dynamic, dynamic>>>>
      _convertedValuesCache = {};

  Map<Type, ICustomConverter> get converters => _adapterManager.converters;
  Map<int, ITypeInfoDecorator> get typeInfoDecorators => _adapterManager.typeInfoDecorators;
  Map<Type, ValueDecoratorFunction> get valueDecorators {
    final allDecorators = <Type, ValueDecoratorFunction>{};
    allDecorators.addAll(_inlineValueDecorators);
    allDecorators.addAll(_adapterManager.valueDecorators); 
    return allDecorators;
  }
  Map<Type, dynamic> get enumValues => _adapterManager.enumValues;

  factory JsonMapper() => instance;

  JsonMapper._internal() {
    _typeInfoProvider = TypeInfoProvider(
        classes: _classes, 
        typeInfoDecorators: _adapterManager.typeInfoDecorators, 
        valueDecorators: this.valueDecorators, 
        enumValues: _adapterManager.enumValues 
    );
    useAdapter(dartCoreAdapter);
    useAdapter(dartCollectionAdapter);
  }

  void _updateInternalMaps() {
    _inlineValueDecorators.clear();
    _classes.clear();
    _discriminatorToType.clear(); 

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
    
    _typeInfoProvider.onClassesUpdated();
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

  ICustomConverter? _getConverter(
      JsonProperty? jsonProperty, TypeInfo typeInfo) {
    final result = jsonProperty?.converter ??
        this.converters[typeInfo.type!] ??
        this.converters[typeInfo.genericType] ??
        (this.enumValues[typeInfo.type!] != null ? this.converters[Enum] : null) ??
        this.converters[this.converters.keys.firstWhereOrNull(
            (Type type) => type.toString() == typeInfo.typeName)];

    if (result is ICustomEnumConverter) {
      (result as ICustomEnumConverter)
          .setEnumDescriptor(_getEnumDescriptor(this.enumValues[typeInfo.type!]));
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
    
    _convertedValuesCache
        .putIfAbsent(converter, () => {})
        .putIfAbsent(direction, () => {})
        .putIfAbsent(context, () => {})[value] = computedValue;

    return computedValue;
  }

  dynamic _applyValueDecorator(dynamic value, TypeInfo typeInfo) {
    if (value == null) {
      return null;
    }
    if (this.valueDecorators[typeInfo.genericType] != null) {
      value = this.valueDecorators[typeInfo.genericType]!(value);
    }
    if (this.valueDecorators[typeInfo.type!] != null) {
      value = this.valueDecorators[typeInfo.type!]!(value);
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

  void _processSingleProperty({
    required String propertyName,
    required DeclarationMirror declarationMirror,
    required bool isMethod, 
    required InstanceMirror instanceMirror,
    required JsonMap? jsonMap,
    required DeserializationContext context,
    required ClassInfo classInfo,
    required Json? classMeta,
    required Function visitor,
  }) {
    final declarationType = _typeInfoProvider.getDeclarationType(declarationMirror);
    final isGetterOnly = isMethod ? true : classInfo.isGetterOnly(propertyName);
    final meta = classInfo.getDeclarationMeta(declarationMirror, context.options.scheme);

    if (meta == null && _getProcessAnnotatedMembersOnly(classMeta, context.options) == true) {
      return;
    }
    if (_isFieldIgnored(classMeta, meta, context.options)) {
      return;
    }

    final propertyContext = context.reBuild(classMeta: classMeta, jsonPropertyMeta: meta);
    final property = _resolveProperty(
      propertyName,
      jsonMap,
      propertyContext,
      classMeta,
      meta,
      (name, jsonName, _) {
        var result = isMethod ? instanceMirror.invoke(name, []) : instanceMirror.invokeGetter(name);
        if (result == null && jsonMap != null) {
          result = jsonMap.getPropertyValue(jsonName);
        }
        return result;
      },
    );

    _checkFieldConstraints(property.value, propertyName, jsonMap?.hasProperty(property.name), meta);

    if (_isFieldIgnoredByValue(property.value, classMeta, meta, propertyContext.options)) {
      return;
    }

    final typeInfo = _typeInfoProvider.getDeclarationTypeInfo(declarationType, property.value?.runtimeType);
    visitor(propertyName, property, isGetterOnly, meta, _getConverter(meta, typeInfo), typeInfo);
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
      _processSingleProperty(
        propertyName: name,
        declarationMirror: declarationMirror,
        isMethod: false,
        instanceMirror: instanceMirror,
        jsonMap: jsonMap,
        context: context,
        classInfo: classInfo,
        classMeta: classMeta,
        visitor: visitor,
      );
    }

    classInfo.enumerateJsonGetters((MethodMirror mm, JsonProperty metaPropertyAnnotation) {
      _processSingleProperty(
        propertyName: mm.simpleName,
        declarationMirror: mm, 
        isMethod: true,
        instanceMirror: instanceMirror,
        jsonMap: jsonMap,
        context: context, 
        classInfo: classInfo,
        classMeta: classMeta,
        visitor: visitor,
      );
    }, context.options.scheme);
  }

  PropertyDescriptor _resolveProperty(
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
    // If the primary name didn't yield a value from the instance, or isn't in the jsonMap, try aliases.
    if (jsonMap != null && meta != null && (value == null || !jsonMap.hasProperty(jsonName))) {
      final initialValue = value;
      for (final alias in JsonProperty.getAliases(meta)!) {
        final targetJsonName = transformIdentifierCaseStyle(
            alias, context.targetCaseStyle, context.sourceCaseStyle);
        // If an alias has already found a value, or this alias isn't in the map, skip.
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
          (o, context) => SerializationPipeline(this).execute(o,context)); // Use pipeline
      (converter as IRecursiveConverter).setDeserializeObjectFunction((o,
              context, type) =>
          DeserializationPipeline(this).execute(o, context.reBuild(typeInfo: _typeInfoProvider.getTypeInfo(type)))); // Use pipeline
    }
  }
}
