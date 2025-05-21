import 'dart:convert' show JsonDecoder, JsonEncoder; // dart: imports first

import 'package:collection/collection.dart' show IterableExtension; // package: imports next
import 'package:reflectable/reflectable.dart'
    show ClassMirror, DeclarationMirror, InstanceMirror, MethodMirror; // Added MethodMirror

import 'adapter_manager.dart'; // relative file imports last
import 'deserialization_pipeline.dart';
import 'errors.dart';
import 'model/index.dart';
import 'serialization_pipeline.dart';
import 'type_info_provider.dart';
import 'utils.dart';

/// Singleton class providing mostly static methods for conversion of previously
/// annotated by [JsonSerializable] Dart objects from / to JSON string.
///
/// It serves as the main entry point for the serialization and deserialization
/// processes and manages configurations such as adapters and options.
class JsonMapper {
  /// Global options for serialization, used when no specific options are provided
  /// to serialization methods. Defaults to [defaultSerializationOptions].
  static SerializationOptions globalSerializationOptions =
      defaultSerializationOptions;

  /// Global options for deserialization, used when no specific options are provided
  /// to deserialization methods. Defaults to [defaultDeserializationOptions].
  static DeserializationOptions globalDeserializationOptions =
      defaultDeserializationOptions;

  /// Converts an instance of a Dart [object] to a JSON String.
  ///
  /// An optional [options] object can be provided to customize the serialization process.
  /// If no options are given, [JsonMapper.globalSerializationOptions] will be used.
  static String serialize(Object? object, [SerializationOptions? options]) {
    final effectiveOptions = options ?? JsonMapper.globalSerializationOptions;
    final context = SerializationContext(
        effectiveOptions,
        typeInfo: instance.typeInfoProvider.getTypeInfo(object.runtimeType)); // Use public getter
    instance.clearCache(); 

    final pipeline = SerializationPipeline(instance);
    return SerializationPipeline.getJsonEncoder(context, pipeline)
        .convert(pipeline.execute(object, context));
  }

  /// Converts a JSON value ([jsonValue]) to a Dart object instance of type [T].
  ///
  /// [jsonValue] can be a JSON String, a `Map<String, dynamic>`, or a `List`.
  /// An optional [options] object can be provided to customize deserialization.
  /// If no options are given, [JsonMapper.globalDeserializationOptions] will be used.
  /// The target type [T] must be specified, or an error will be thrown if it cannot be inferred.
  static T? deserialize<T>(dynamic jsonValue,
      [DeserializationOptions? options]) {
    final targetOptions = options ?? JsonMapper.globalDeserializationOptions;
    final targetType = T != dynamic
        ? T
        : targetOptions.template != null
            ? targetOptions.template.runtimeType
            : targetOptions.type ?? dynamic;
    assert(targetType != dynamic, // Ensure target type is available
        throw MissingTypeForDeserializationError());

    final deserializationContext = DeserializationContext(targetOptions,
            classMeta:
                instance.internalClasses[targetType]?.getMeta(targetOptions.scheme), // Use public getter
            typeInfo: instance.typeInfoProvider.getTypeInfo(targetType)); // Use public getter
    
    final parsedJson = jsonValue != null
            ? jsonValue is String
                ? instance._jsonDecoder.convert(jsonValue) 
                : jsonValue // Assumed to be already a Map/List
            : null;

    final pipeline = DeserializationPipeline(instance);
    return pipeline.execute(parsedJson, deserializationContext) as T?;
  }

  /// Alias for [serialize]. Converts a Dart [object] to a JSON String.
  static String toJson(Object? object, [SerializationOptions? options]) =>
      serialize(object, options);

  /// Converts a Dart object [getParams] into a URI query string.
  /// Optionally prepends a [baseUrl].
  static Uri toUri({Object? getParams, String? baseUrl = ''}) {
    final serializedParams = serialize(getParams); // Uses pipeline-based serialization
    final Map<String, dynamic>? paramsMap = instance._jsonDecoder.convert(serializedParams) as Map<String, dynamic>?;
    final paramsString = paramsMap?.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    return Uri.parse('$baseUrl${paramsString != null && paramsString.isNotEmpty ? '?$paramsString' : ''}');
  }

  /// Alias for [deserialize]. Converts a JSON String [jsonValue] to an object of type [T].
  static T? fromJson<T>(String jsonValue, [DeserializationOptions? options]) =>
      deserialize<T>(jsonValue, options);

  /// Converts a Dart [object] to a `Map<String, dynamic>`.
  static Map<String, dynamic>? toMap(Object? object,
      [SerializationOptions? options]) {
    final effectiveOptions = options ?? JsonMapper.globalSerializationOptions;
    final context = SerializationContext(
        effectiveOptions,
        typeInfo: instance.typeInfoProvider.getTypeInfo(object.runtimeType)); // Use public getter
    instance.clearCache(); 

    final pipeline = SerializationPipeline(instance);
    final result = pipeline.execute(object, context);
    return result is Map<String, dynamic> ? result : null;
  }

  /// Converts a `Map<String, dynamic>` [map] to an object of type [T].
  static T? fromMap<T>(Map<String, dynamic>? map,
          [DeserializationOptions? options]) =>
      deserialize<T>(map, options);

  /// Creates a deep clone of a Dart [object] of type [T].
  /// This is achieved by serializing the object to JSON and then deserializing it back.
  static T? clone<T>(T object) => fromJson<T>(toJson(object));

  /// Alias for [clone]. Creates a deep copy of a Dart [object] of type [T].
  static T? copy<T>(T object) => clone<T>(object);

  /// Creates a copy of a Dart [object] of type [T] and merges it with values from a [map].
  static T? copyWith<T>(T object, Map<String, dynamic> map) =>
      fromMap<T>(mergeMaps(toMap(object), map));

  /// Recursively merges two maps [mapA] and [mapB].
  /// Values in [mapB] will overwrite values in [mapA] for the same keys.
  /// If a key exists in both maps and both values are maps, they will be merged recursively.
  static Map<String, dynamic> mergeMaps(
      Map<String, dynamic>? mapA, Map<String, dynamic> mapB) {
    if (mapA == null) {
      return mapB;
    }
    mapB.forEach((key, value) {
      if (!mapA.containsKey(key)) {
        mapA[key] = value;
      } else {
        if (mapA[key] is Map && value is Map) { // Ensure both are maps before recursive merge
          // Ensure the map types are compatible for recursive merge.
          try {
            mapA[key] = mergeMaps(mapA[key] as Map<String,dynamic>, value as Map<String,dynamic>);
          } catch(e) { // Fallback if types are not Map<String, dynamic>
            mapA[key] = value;
          }
        } else {
          mapA[key] = value;
        }
      }
    });
    return mapA;
  }

  /// Enumerates adapter [IJsonMapperAdapter] instances using a visitor pattern.
  /// This method abstracts the ordering logic (e.g., generated adapters first) from consumers.
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

  /// Registers an instance of [IJsonMapperAdapter] with the mapper engine.
  /// Adapters extend the mapper's capabilities for handling custom types.
  /// An optional [priority] can be specified for the adapter.
  JsonMapper useAdapter(IJsonMapperAdapter adapter, [int? priority]) {
    _adapterManager.useAdapter(adapter, priority);
    _updateInternalMaps(); 
    return this;
  }

  /// De-registers a previously registered [adapter].
  JsonMapper removeAdapter(IJsonMapperAdapter adapter) {
    _adapterManager.removeAdapter(adapter);
    _updateInternalMaps(); 
    return this;
  }

  /// Prints the current mapper configuration to the console,
  /// including registered adapters and their priorities.
  void info() => _adapterManager.info();
  
  /// Wipes internal caches, such as the TypeInfo cache and converted values cache.
  /// This is typically called before a new serialization/deserialization operation.
  void clearCache() {
    _typeInfoProvider.clearCache(); 
    _convertedValuesCache.clear();
  }

  /// Singleton instance of [JsonMapper].
  static final JsonMapper instance = JsonMapper._internal();
  /// JSON decoder instance used for parsing JSON strings during deserialization.
  final JsonDecoder _jsonDecoder = JsonDecoder();

  /// Reflectable instance used to access metadata for annotated classes.
  final _serializable = const JsonSerializable(); 
  /// Cache for [ClassInfo] objects, storing metadata about reflectable classes.
  final Map<Type, ClassInfo> _classes = {};
  /// Stores inline value decorators defined directly within class annotations.
  final Map<Type, ValueDecoratorFunction> _inlineValueDecorators = {};
  /// Maps discriminator values to their corresponding [Type]s for polymorphic deserialization.
  final Map<dynamic, Type> _discriminatorToType = {};
  
  // Public getters for internal state needed by helper classes (pipelines, providers)
  /// Provides access to the internal map of [ClassInfo] objects.
  /// Intended for use by internal helper classes within the same library.
  Map<Type, ClassInfo> get internalClasses => _classes;
  /// Provides access to the internal map of discriminator values to Types.
  /// Intended for use by internal helper classes within the same library.
  Map<dynamic, Type> get internalDiscriminatorToType => _discriminatorToType;
  /// Provides access to the [TypeInfoProvider] instance.
  /// Intended for use by internal helper classes within the same library.
  TypeInfoProvider get typeInfoProvider => _typeInfoProvider;


  /// Cache for results of custom converter operations to avoid re-computation.
  /// Keyed by converter instance, conversion direction, context, and original value.
  final Map<
          ICustomConverter?,
          Map<ConversionDirection,
              Map<DeserializationContext?, Map<dynamic, dynamic>>>>
      _convertedValuesCache = {};

  /// Consolidated map of custom converters from all registered adapters.
  Map<Type, ICustomConverter> get converters => _adapterManager.converters;
  /// Consolidated map of type info decorators from all registered adapters.
  Map<int, ITypeInfoDecorator> get typeInfoDecorators => _adapterManager.typeInfoDecorators;
  /// Consolidated map of value decorators, combining inline and adapter-provided decorators.
  Map<Type, ValueDecoratorFunction> get valueDecorators {
    final allDecorators = <Type, ValueDecoratorFunction>{};
    allDecorators.addAll(_inlineValueDecorators); // Inline decorators take precedence or are combined
    allDecorators.addAll(_adapterManager.valueDecorators); 
    return allDecorators;
  }
  /// Consolidated map of enum values from all registered adapters.
  Map<Type, dynamic> get enumValues => _adapterManager.enumValues;

  /// Provides access to the singleton instance of [JsonMapper].
  factory JsonMapper() => instance;

  /// Internal constructor for the singleton instance.
  /// Initializes the [TypeInfoProvider] and registers core adapters.
  JsonMapper._internal() {
    _typeInfoProvider = TypeInfoProvider(
        classes: _classes, // Pass by reference; _classes is populated by _updateInternalMaps
        typeInfoDecorators: _adapterManager.typeInfoDecorators, 
        valueDecorators: this.valueDecorators, 
        enumValues: _adapterManager.enumValues 
    );
    // Register default adapters for core Dart types and collections.
    useAdapter(dartCoreAdapter);
    useAdapter(dartCollectionAdapter);
  }

  /// Updates internal maps and caches after changes like adapter registration.
  /// This ensures that class metadata, discriminator mappings, and type info are current.
  void _updateInternalMaps() {
    // Clear collections that are rebuilt from scratch based on _classes and annotations.
    _inlineValueDecorators.clear();
    _classes.clear();
    _discriminatorToType.clear(); 

    // Re-populate _classes, _inlineValueDecorators, and _discriminatorToType from annotated classes.
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
    
    // Notify TypeInfoProvider that class information has changed.
    _typeInfoProvider.onClassesUpdated();
  }

  /// Safely gets an [InstanceMirror] for an [object].
  /// Returns `null` if reflection fails (e.g., object not reflectable).
  InstanceMirror? _safeGetInstanceMirror(Object object) {
    InstanceMirror? result;
    try {
      result = _serializable.reflect(object);
    } catch (error) {
      // Ignore errors, typically meaning the object isn't covered by @JsonSerializable
      return result;
    }
    return result;
  }

  /// Gets a custom converter for a given [jsonProperty] and [typeInfo], if available.
  /// Considers converters defined directly on the property or globally via adapters.
  ICustomConverter? _getConverter(
      JsonProperty? jsonProperty, TypeInfo typeInfo) {
    final result = jsonProperty?.converter ??
        this.converters[typeInfo.type!] ??
        this.converters[typeInfo.genericType] ??
        (this.enumValues[typeInfo.type!] != null ? this.converters[Enum] : null) ??
        this.converters[this.converters.keys.firstWhereOrNull(
            (Type type) => type.toString() == typeInfo.typeName)];

    // If it's an enum converter, provide it with the enum descriptor.
    if (result is ICustomEnumConverter) {
      (result as ICustomEnumConverter)
          .setEnumDescriptor(_getEnumDescriptor(this.enumValues[typeInfo.type!]));
    }
    return result;
  }

  /// Creates an [IEnumDescriptor] from a dynamic [descriptor] (Iterable or existing IEnumDescriptor).
  IEnumDescriptor? _getEnumDescriptor(dynamic descriptor) {
    if (descriptor is Iterable) {
      return EnumDescriptor(values: descriptor);
    }
    if (descriptor is IEnumDescriptor) {
      return descriptor;
    }
    return null;
  }

  /// Retrieves a cached converted value or computes it using the [converter].
  /// Caches results based on converter, direction, context, and original value.
  dynamic _getConvertedValue(ICustomConverter converter, dynamic value,
      DeserializationContext context) {
    final direction = context.direction;
    // Check cache first
    if (_convertedValuesCache.containsKey(converter) &&
        _convertedValuesCache[converter]!.containsKey(direction) &&
        _convertedValuesCache[converter]![direction]!.containsKey(context) &&
        _convertedValuesCache[converter]![direction]![context]!
            .containsKey(value)) {
      return _convertedValuesCache[converter]![direction]![context]![value];
    }

    // Compute value if not in cache
    final computedValue = direction == ConversionDirection.fromJson
        ? converter.fromJSON(value, context)
        : converter.toJSON(value, context as SerializationContext); 
    
    // Populate cache
    _convertedValuesCache
        .putIfAbsent(converter, () => {})
        .putIfAbsent(direction, () => {})
        .putIfAbsent(context, () => {})[value] = computedValue;

    return computedValue;
  }

  /// Applies value decorators to a [value] based on its [typeInfo].
  /// Decorators for both the generic type and specific type are applied if present.
  dynamic _applyValueDecorator(dynamic value, TypeInfo typeInfo) {
    if (value == null) {
      return null;
    }
    // Apply decorator for generic type, if any
    if (this.valueDecorators[typeInfo.genericType] != null) {
      value = this.valueDecorators[typeInfo.genericType]!(value);
    }
    // Apply decorator for specific type, if any (can be chained)
    if (this.valueDecorators[typeInfo.type!] != null) {
      value = this.valueDecorators[typeInfo.type!]!(value);
    }
    return value;
  }

  /// Checks if a field is nullable based on its metadata.
  bool _isNullableField(JsonProperty? meta) =>
      !(JsonProperty.isRequired(meta) || JsonProperty.isNotNull(meta));

  /// Determines if a field should be ignored during serialization/deserialization
  /// based on its metadata and the current options.
  bool _isFieldIgnored(
          [Json? classMeta,
          JsonProperty? meta,
          DeserializationOptions? options]) =>
      (meta != null &&
          (meta.ignore == true ||
              // Ignore for serialization specific conditions
              ((meta.ignoreForSerialization == true ||
                      JsonProperty.hasParentReference(meta) ||
                      meta.inject == true) &&
                  options is SerializationOptions) ||
              // Ignore for deserialization specific conditions
              (meta.ignoreForDeserialization == true &&
                  options is! SerializationOptions)) &&
          _isNullableField(meta)); // Ignored fields must also be nullable

  /// Determines if a field should be ignored based on its [value], metadata, and options.
  /// Considers ignoreIfNull, ignoreNullMembers, and default value ignoring.
  bool _isFieldIgnoredByValue(
          [dynamic value,
          Json? classMeta,
          JsonProperty? meta,
          DeserializationOptions? options]) =>
      ((meta != null &&
              (_isFieldIgnored(classMeta, meta, options) || // General ignore conditions
                  (meta.ignoreIfNull == true && value == null))) || // ignoreIfNull condition
          // Serialization-specific value-based ignore conditions
          (options is SerializationOptions &&
              (((options.ignoreNullMembers == true || // Global ignoreNullMembers
                          classMeta?.ignoreNullMembers == true) && // Class-level ignoreNullMembers
                      value == null) ||
                  // Default value ignoring
                  ((_isFieldIgnoredByDefault(meta, classMeta, options)) &&
                      JsonProperty.isDefaultValue(meta, value) == true)))) &&
      _isNullableField(meta); // Ignored fields based on value must also be nullable

  /// Checks if default members should be ignored based on metadata and options.
  bool _isFieldIgnoredByDefault(
          JsonProperty? meta, Json? classMeta, SerializationOptions options) =>
      meta?.ignoreIfDefault == true || // Property-level
      classMeta?.ignoreDefaultMembers == true || // Class-level
      options.ignoreDefaultMembers == true; // Global-level

  /// Enumerates all classes annotated with `@JsonSerializable`.
  /// Applies the [visitor] function to the [ClassInfo] of each.
  void _enumerateAnnotatedClasses(Function visitor) {
    for (var classMirror in _serializable.annotatedClasses) {
      visitor(ClassInfo.fromCache(classMirror, _classes));
    }
  }

  /// Checks field constraints like `isNotNull` and `isRequired`.
  /// Throws appropriate errors if constraints are violated.
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

  /// Helper method to process a single property (field or getter) during enumeration.
  /// Encapsulates common logic for resolving value, checking ignores/constraints, and visiting.
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
      (name, jsonName, _) { // Callback to get initial value
        var result = isMethod ? instanceMirror.invoke(name, []) : instanceMirror.invokeGetter(name);
        if (result == null && jsonMap != null) { // If instance value is null, try from JSON map
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

  /// Enumerates public properties (fields and JsonGetters) of an [instanceMirror].
  /// For each property, it resolves its value, checks constraints/ignores, and calls [visitor].
  /// Used by both serialization and deserialization property population logic.
  void _enumeratePublicProperties(InstanceMirror instanceMirror,
      JsonMap? jsonMap, DeserializationContext context, Function visitor) {
    final classInfo = ClassInfo.fromCache(instanceMirror.type, _classes);
    final classMeta = classInfo.getMeta(context.options.scheme);

    // Process public fields
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

    // Process JsonGetters
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

  /// Resolves a property's name and value, considering metadata like aliases,
  /// injectable values, parent references, and default values.
  PropertyDescriptor _resolveProperty(
      String name,
      JsonMap? jsonMap,
      DeserializationContext context,
      Json? classMeta,
      JsonProperty? meta,
      Function getValueByName) { // Callback to get initial value from instance or map
    String? jsonName = name;

    if (meta != null && meta.name != null) {
      jsonName = JsonProperty.getPrimaryName(meta);
    }
    jsonName = context.transformIdentifier(jsonName!);
    var value = getValueByName(name, jsonName, meta?.defaultValue);
    
    // If the primary name didn't yield a value from the instance, or isn't in the jsonMap, try aliases.
    // This is mainly for deserialization where jsonMap is present.
    if (jsonMap != null && meta != null && (value == null || !jsonMap.hasProperty(jsonName))) {
      final initialValue = value; // Value before trying aliases
      for (final alias in JsonProperty.getAliases(meta)!) {
        final targetJsonName = transformIdentifierCaseStyle(
            alias, context.targetCaseStyle, context.sourceCaseStyle);
        // If an alias has already found a value (value != initialValue),
        // or this alias isn't in the map, skip to the next alias.
        if (value != initialValue || !jsonMap.hasProperty(targetJsonName)) {
          continue;
        }
        jsonName = targetJsonName;
        value = jsonMap.getPropertyValue(jsonName);
      }
    }
    // Handle injectable values
    if (meta != null &&
        meta.inject == true &&
        context.options.injectableValues != null) {
      final injectionJsonMap = JsonMap(context.options.injectableValues!);
      if (injectionJsonMap.hasProperty(jsonName!)) {
        value = injectionJsonMap.getPropertyValue(jsonName);
        return PropertyDescriptor(jsonName, value, false); // Injected value is not 'raw'
      } else {
        // If injectable but no value provided, treat as null.
        return PropertyDescriptor(jsonName, null, false);
      }
    }
    // Handle parent reference
    if (jsonName == JsonProperty.parentReference) {
      return PropertyDescriptor(
          jsonName!, context.parentObjectInstances!.last, false); // Parent is not 'raw'
    }
    // Handle default value if applicable (typically for deserialization)
    if (value == null &&
        meta?.defaultValue != null &&
        options is SerializationOptions && // Default value logic might differ for serialization
        _isFieldIgnoredByDefault(
            meta, classMeta, options as SerializationOptions)) {
      // This condition seems specific to when default values are ignored during serialization.
      // For deserialization, a simpler `value == null && meta?.defaultValue != null` might be sufficient.
      // However, keeping original logic structure.
      return PropertyDescriptor(jsonName!, meta?.defaultValue, true); // Default value is 'raw'
    }
    return PropertyDescriptor(jsonName!, value, true); // Default: value is 'raw' (needs processing)
  }

  /// Gets the discriminator property name from class metadata.
  String? _getDiscriminatorProperty(
          ClassInfo classInfo, DeserializationOptions? options) =>
      classInfo
          .getMetaWhere((Json meta) => meta.discriminatorProperty != null,
              options?.scheme)
          ?.discriminatorProperty;

  /// Determines if only annotated members should be processed based on class/global options.
  bool? _getProcessAnnotatedMembersOnly(
          Json? meta, DeserializationOptions options) =>
      meta != null && meta.processAnnotatedMembersOnly != null
          ? meta.processAnnotatedMembersOnly
          : options.processAnnotatedMembersOnly;

  /// Configures a [converter] before use, setting up recursive serialization/deserialization
  /// functions and other necessary context like iterable/map instances.
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
    // Provide recursive capabilities to converters that need them.
    if (converter is IRecursiveConverter) {
      (converter as IRecursiveConverter).setSerializeObjectFunction(
          (o, ctxt) => SerializationPipeline(this).execute(o,ctxt as SerializationContext)); 
      (converter as IRecursiveConverter).setDeserializeObjectFunction((o,
              ctxt, type) =>
          DeserializationPipeline(this).execute(o, (ctxt as DeserializationContext).reBuild(typeInfo: _typeInfoProvider.getTypeInfo(type)))); 
    }
  }
}

[end of mapper/lib/src/mapper.dart]
