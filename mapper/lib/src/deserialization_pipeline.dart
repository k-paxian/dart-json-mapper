import 'dart:convert' show JsonDecoder; // dart: imports first

import 'package:reflectable/reflectable.dart' // package: imports next
    show ClassMirror, InstanceMirror, ParameterMirror;

import 'errors.dart'; // relative file imports last
import 'mapper.dart';
import 'model/index.dart';
import 'utils.dart';

/// Handles the process of deserializing a JSON structure (Map or String) into a Dart object.
/// It manages type detection, constructor invocation, property population, and error handling.
class DeserializationPipeline {
  final JsonMapper _mapperInstance;
  final JsonDecoder _jsonDecoder = JsonDecoder();

  DeserializationPipeline(this._mapperInstance);

  /// Public entry point for the deserialization pipeline.
  /// Takes a [jsonValue] (String, Map, or List) and a [context] to guide deserialization.
  /// Returns the deserialized Dart object.
  Object? execute(dynamic jsonValue, DeserializationContext context) {
    return _deserializeObject(jsonValue, context);
  }

  /// Checks if the given [jsonValue] is a valid JSON string.
  /// Also returns true for already parsed Maps or Lists.
  bool _isValidJSON(dynamic jsonValue) {
    try {
      if (jsonValue is String) {
        this._jsonDecoder.convert(jsonValue); // Attempt to parse
        return true;
      }
      // If not a string, assume it's already a parsed JSON structure (Map/List) or a primitive.
      return jsonValue is Map || jsonValue is List;
    } on FormatException {
      return false; // String is not valid JSON
    }
  }

  /// Detects the actual target [TypeInfo] for deserialization, potentially using discriminator logic.
  /// [objectInstance] is typically null during initial detection.
  /// [objectType] is the declared type. [objectJsonMap] is the input JSON data.
  TypeInfo? _detectObjectType(dynamic objectInstance, Type? objectType,
      JsonMap objectJsonMap, DeserializationContext context) {
    final objectClassInfo = _mapperInstance.internalClasses[objectType]; // Use public getter
    if (objectClassInfo == null) {
      return null; // Cannot proceed without class metadata
    }
    final meta = objectClassInfo.getMeta(context.options.scheme);

    if (objectInstance is Map<String, dynamic>) { // Should not happen if objectInstance is null
      objectJsonMap = JsonMap(objectInstance, meta);
    }
    // Initial TypeInfo based on the declared type or runtime type of a template
    final typeInfo = _mapperInstance.typeInfoProvider.getTypeInfo(objectType ?? objectInstance.runtimeType); // Use public getter

    final discriminatorProperty =
        _mapperInstance._getDiscriminatorProperty(objectClassInfo, context.options);
    final discriminatorValue = discriminatorProperty != null &&
            objectJsonMap.hasProperty(discriminatorProperty)
        ? objectJsonMap.getPropertyValue(discriminatorProperty)
        : null;
    
    // Logic for handling discriminator property for polymorphic deserialization
    if (discriminatorProperty != null && discriminatorValue != null) {
      final declarationMirror =
          objectClassInfo.getDeclarationMirror(discriminatorProperty);
      if (declarationMirror != null) {
        final discriminatorType = _mapperInstance.typeInfoProvider.getDeclarationType(declarationMirror); // Use public getter
        // Deserialize the discriminator value itself to determine the target type
        final value = _deserializeObject(discriminatorValue,
            context.reBuild(typeInfo: _mapperInstance.typeInfoProvider.getTypeInfo(discriminatorType))); // Use public getter
        
        if (value is Type) { // Discriminator value directly resolved to a Type
          return _mapperInstance.typeInfoProvider.getTypeInfo(value); // Use public getter
        }

        // Look up type in discriminator-to-type mapping
        if (_mapperInstance.internalDiscriminatorToType[value] == null) { // Use public getter
          final validDiscriminators = ClassInfo.getAllSubTypes(
                  _mapperInstance.internalClasses, objectClassInfo) // Use public getter
              .map((e) => e.getMeta(context.options.scheme)!.discriminatorValue)
              .toList();
          throw JsonMapperSubtypeError(
            discriminatorValue, // The value from JSON that was not found
            validDiscriminators, // Expected values
            objectClassInfo, // The base class being deserialized
          );
        }
        return _mapperInstance.typeInfoProvider.getTypeInfo(_mapperInstance.internalDiscriminatorToType[value]!); // Use public getter
      }
    }
    // Fallback if discriminator value itself is a type name string
    if (discriminatorValue != null) {
      final targetType = _mapperInstance.typeInfoProvider.getTypeByStringName(discriminatorValue); // Use public getter
      return _mapperInstance.internalClasses[targetType] != null // Use public getter
          ? _mapperInstance.typeInfoProvider.getTypeInfo(_mapperInstance.internalClasses[targetType]!.reflectedType!) // Use public getter
          : typeInfo; // Default to original typeInfo if string name doesn't match
    }
    return typeInfo; // Default if no discriminator logic applied
  }

  /// Enumerates constructor parameters of a [classMirror] to resolve their values from [jsonMap].
  /// Uses [filter] to select parameters (e.g., named or positional) and [visitor] to process each.
  void _enumerateConstructorParameters(ClassMirror classMirror, JsonMap jsonMap,
      DeserializationContext context, Function filter, Function visitor) {
    final classInfo = ClassInfo.fromCache(classMirror, _mapperInstance.internalClasses); // Use public getter
    final classMeta = classInfo.getMeta(context.options.scheme);
    final scheme =
        classMeta != null ? classMeta.scheme : context.options.scheme;
    final methodMirror = classInfo.getJsonConstructor(scheme); // Constructor mirror
    if (methodMirror == null) {
      return; // No suitable constructor found
    }
    for (var param in methodMirror.parameters) {
      if (!filter(param as ParameterMirror)) { 
        continue; 
      }
      final name = param.simpleName;
      final declarationMirror = classInfo.getDeclarationMirror(name) ?? param; // Field or param mirror
      // Determine parameter type, considering generics
      final paramType = param.hasReflectedType
          ? param.reflectedType
          : param.hasDynamicReflectedType
              ? param.dynamicReflectedType
              : _mapperInstance.typeInfoProvider.getGenericParameterTypeByIndex( // Use public getter
                      methodMirror.parameters.indexOf(param),
                      context.typeInfo!) ??
                  dynamic;
      var paramTypeInfo = _mapperInstance.typeInfoProvider.getTypeInfo(paramType); // Use public getter
      // Refine type if initial type was dynamic but declaration offers more info
      paramTypeInfo = paramTypeInfo.isDynamic
          ? _mapperInstance.typeInfoProvider.getTypeInfo(_mapperInstance.typeInfoProvider.getDeclarationType(declarationMirror)) // Use public getter
          : paramTypeInfo;
      
      final meta = classInfo.getDeclarationMeta(
              declarationMirror, context.options.scheme) ??
          classInfo.getDeclarationMeta(param, context.options.scheme); // Property metadata
      
      final propertyContext = context.reBuild( // Context for this specific parameter
          classMeta: classMeta,
          jsonPropertyMeta: meta,
          typeInfo: paramTypeInfo,
          parentJsonMaps: <JsonMap>[
            ...(context.parentJsonMaps ?? []),
            jsonMap
          ]);

      // Resolve property value from JSON, considering name transformations and defaults
      final property = _mapperInstance._resolveProperty( 
          name,
          jsonMap,
          propertyContext,
          classMeta,
          meta,
          (_, jsonName, defaultValue) => jsonMap.hasProperty(jsonName)
              ? jsonMap.getPropertyValue(jsonName) ?? defaultValue
              : defaultValue);
      final jsonName = property.name;
      // Deserialize the resolved value if it's marked as 'raw' (i.e., needs further deserialization)
      final value = property.raw
          ? _deserializeObject(property.value, propertyContext) 
          : property.value;

      visitor(param, name, jsonName, classMeta, meta, value, paramTypeInfo);
    }
  }

  /// Resolves named arguments for constructor invocation.
  Map<Symbol, dynamic> _getNamedArguments(
      ClassMirror cm, JsonMap jsonMap, DeserializationContext context) {
    final result = <Symbol, dynamic>{};
    _enumerateConstructorParameters( 
        cm, jsonMap, context, 
        (ParameterMirror param) => param.isNamed, // Filter for named parameters
        (param, name, jsonName, classMeta, JsonProperty? meta, value, TypeInfo typeInfo) {
      if (!_mapperInstance._isFieldIgnoredByValue(value, classMeta, meta, context.options)) {
        result[Symbol(name)] = value;
      }
    });
    return result;
  }

  /// Resolves positional arguments for constructor invocation.
  List _getPositionalArguments(ClassMirror cm, JsonMap jsonMap,
      DeserializationContext context, List<String> positionalArgumentNames) {
    final result = [];
    _enumerateConstructorParameters( 
        cm, jsonMap, context, 
        (ParameterMirror param) => !param.isOptional && !param.isNamed, // Filter for non-optional, non-named
        (param, name, jsonName, classMeta, JsonProperty? meta, value, TypeInfo typeInfo) {
      positionalArgumentNames.add(name); // Track names for error reporting
      result.add(_mapperInstance._isFieldIgnoredByValue(value, classMeta, meta, context.options)
          ? null // Use null if field is ignored by value (e.g. ignoreIfNull)
          : value);
    });
    return result;
  }

  /// Core recursive method to deserialize a [jsonValue] into a Dart object,
  /// guided by the [DeserializationContext].
  Object? _deserializeObject(
      dynamic jsonValue, DeserializationContext context) {
    if (jsonValue == null) {
      return null;
    }
    var typeInfo = context.typeInfo!; // Assumes typeInfo is always present in context
    
    // Attempt to use a custom converter if one is applicable.
    final converter = _mapperInstance._getConverter(context.jsonPropertyMeta, typeInfo);
    if (converter != null) {
      _mapperInstance._configureConverter(converter, context); // Setup converter (e.g., for recursion)
      // Special handling for iterables with custom converters (excluding default)
      if (typeInfo.isIterable &&
          (converter is ICustomIterableConverter &&
              converter is! DefaultIterableConverter)) { 
        return _mapperInstance._applyValueDecorator( // Apply decorators after conversion
            _mapperInstance._getConvertedValue(converter, jsonValue, context), typeInfo);
      }
      return _mapperInstance._applyValueDecorator(
          _mapperInstance._getConvertedValue(converter, jsonValue, context), typeInfo);
    }

    // Prepare JSON value: parse if string, otherwise use as is.
    dynamic convertedJsonValue =
        (jsonValue is String && _isValidJSON(jsonValue)) ? this._jsonDecoder.convert(jsonValue) : jsonValue;

    // Handle case where JSON value is a string representing a type name (e.g., for Type properties).
    if (convertedJsonValue is String && typeInfo.type is Type) { 
      return _mapperInstance.typeInfoProvider.getTypeByStringName(convertedJsonValue.replaceAll("\"", "")); // Use public getter
    }

    final jsonMap = JsonMap(
        convertedJsonValue, null, context.parentJsonMaps as List<JsonMap>?);
    
    // Detect actual target type, considering discriminators.
    typeInfo =
        _detectObjectType(null, context.typeInfo!.type, jsonMap, context) ??
            typeInfo; // Fallback to original typeInfo if detection fails
            
    final classInfo = _mapperInstance.internalClasses[typeInfo.type] ?? // Use public getter
        _mapperInstance.internalClasses[typeInfo.genericType] ?? // Use public getter
        _mapperInstance.internalClasses[typeInfo.mixinType]; // Use public getter

    // If no ClassInfo (metadata) is found for the type, and it's not a core type handled implicitly.
    if (classInfo == null) {
      if (typeInfo.isDartCoreType && typeInfo.type != Object) { // Allow basic dart types to pass through if value matches
         if (jsonValue.runtimeType == typeInfo.type) return jsonValue;
      }
      throw MissingAnnotationOnTypeError(typeInfo.type); // No metadata for a custom class
    }
    jsonMap.jsonMeta = classInfo.getMeta(context.options.scheme); // Assign metadata to JsonMap

    // Prepare arguments for constructor.
    final namedArguments = _getNamedArguments(classInfo.classMirror, jsonMap, context);
    final positionalArgumentNames = <String>[];
    final positionalArguments = _getPositionalArguments(classInfo.classMirror, jsonMap, context, positionalArgumentNames);

    // Create instance of the object.
    final objectInstance = _createInstanceWithConstructor(
        classInfo, context, positionalArguments, namedArguments, positionalArgumentNames);

    final im = _mapperInstance._safeGetInstanceMirror(objectInstance)!; // Get instance mirror
    
    // Track fields already mapped by the constructor.
    final List<String> mappedFields = namedArguments.keys
        .map((Symbol symbol) => RegExp('"(.+)"').allMatches(symbol.toString()).first.group(1)!)
        .toList()
      ..addAll(positionalArgumentNames);

    // Populate remaining properties of the instance.
    _populateProperties(im, jsonMap, context, classInfo, mappedFields, objectInstance);
    // Handle any fields in JSON not mapped to properties or constructor params.
    _handleUnmappedFields(im, jsonMap, context, classInfo, mappedFields);

    // Apply final value decorators to the fully constructed object.
    return _mapperInstance._applyValueDecorator(objectInstance, typeInfo);
  }

  /// Creates an instance of an object using its constructor.
  /// Handles `TypeError` if constructor arguments don't match, providing a detailed error.
  dynamic _createInstanceWithConstructor(
      ClassInfo classInfo,
      DeserializationContext context,
      List<dynamic> positionalArguments,
      Map<Symbol, dynamic> namedArguments,
      List<String> positionalArgumentNames) {
    try {
      return context.options.template ?? // Use template if provided
          (classInfo.classMirror.isEnum // Handle enums (though typically by converter)
              ? null 
              : classInfo.classMirror.newInstance( // Standard instantiation
                  classInfo.getJsonConstructor(context.options.scheme)!.constructorName,
                  positionalArguments,
                  namedArguments));
    } on TypeError catch (typeError) { // Catch type errors during instantiation
      final positionalNullArguments = positionalArgumentNames.where(
          (element) => positionalArguments[positionalArgumentNames.indexOf(element)] == null);
      final namedNullArguments = Map<Symbol, dynamic>.from(namedArguments)
        ..removeWhere((key, value) => value != null);
      // Throw a more specific error for instantiation failures.
      throw CannotCreateInstanceError(
          typeError, classInfo, positionalNullArguments, namedNullArguments);
    }
  }

  /// Populates the properties of a newly created [objectInstance].
  /// Iterates through public properties, deserializes their values from [jsonMap],
  /// and sets them on the instance [im].
  void _populateProperties(
      InstanceMirror im,
      JsonMap jsonMap,
      DeserializationContext context,
      ClassInfo classInfo,
      List<String> mappedFields, 
      dynamic objectInstance) { 

    final inheritedPublicFieldNames = classInfo.inheritedPublicFieldNames;

    _mapperInstance._enumeratePublicProperties(im, jsonMap, context,
        (String name, PropertyDescriptor property, bool isGetterOnly, JsonProperty? meta,
            ICustomConverter? converter, TypeInfo typeInfo) { 

      final propertyContext = context.reBuild(
          parentObjectInstances: [
            ...(context.parentObjectInstances ?? []),
            objectInstance! 
          ],
          typeInfo: typeInfo,
          jsonPropertyMeta: meta,
          parentJsonMaps: <JsonMap>[
            ...(context.parentJsonMaps ?? []),
            jsonMap
          ]);
      
      final defaultValue = meta?.defaultValue;
      final hasJsonProperty = jsonMap.hasProperty(property.name);
      dynamic fieldValue = jsonMap.getPropertyValue(property.name); 

      // Skip if property was set by constructor, unless it's flatten or injectable.
      if (!hasJsonProperty || mappedFields.contains(name)) {
        if (meta?.flatten == true) { // Handle flattened properties
          final Map<String, dynamic>? objectMap = fieldValue is Map<String, dynamic> ? fieldValue : null;
          final object = meta?.name != null && objectMap != null // Use meta?.name
              ? objectMap.map((key, value) => MapEntry(
                  skipPrefix(meta!.name!, key, propertyContext.caseStyle), value)) // meta!.name is safe due to previous check
              : fieldValue;
          im.invokeSetter(name, _deserializeObject(object, propertyContext)); // Recursive
        }
        // Apply default value if property is null and not getter-only
        if (im.invokeGetter(name) == null && defaultValue != null && !isGetterOnly) {
          im.invokeSetter(name, defaultValue);
        }
        // If not injectable, and already handled (by constructor or flatten), return.
        if (meta?.inject != true) {
           return;
        }
      }

      // Deserialize the property value.
      fieldValue = property.raw
          ? _deserializeObject(fieldValue, propertyContext) // Recursive deserialization
          : property.value;

      if (isGetterOnly) {
        // Track getter-only fields from superclasses if they appear in JSON,
        // to prevent JsonAnySetter from trying to process them.
        if (inheritedPublicFieldNames.contains(name) && !mappedFields.contains(property.name)) {
          mappedFields.add(property.name);
        }
      } else {
        // Apply value decorator and set the property.
        fieldValue = _mapperInstance._applyValueDecorator(fieldValue, typeInfo) ?? defaultValue;
        im.invokeSetter(name, fieldValue);
        mappedFields.add(property.name); 
      }
    });
  }

  /// Handles fields present in the JSON that were not mapped to constructor parameters
  /// or properties, using `JsonAnySetter` or specific `JsonSetter`s.
  void _handleUnmappedFields(
      InstanceMirror im,
      JsonMap jsonMap,
      DeserializationContext context,
      ClassInfo classInfo,
      List<String> mappedFields) {

    final discriminatorPropertyName =
        _mapperInstance._getDiscriminatorProperty(classInfo, context.options);
    
    // Identify fields in JSON not yet mapped.
    final unmappedFields = jsonMap.map.keys
        .where((field) => !mappedFields.contains(field) && field != discriminatorPropertyName)
        .toList();

    if (unmappedFields.isNotEmpty) {
      final jsonAnySetter = classInfo.getJsonAnySetter(context.options.scheme);
      for (var field in unmappedFields) {
        final jsonSetter = classInfo.getJsonSetter(field, context.options.scheme) ?? jsonAnySetter;
        if (jsonSetter != null) { // If a setter exists for this unmapped field
           final params = jsonSetter == jsonAnySetter // Prepare parameters for invocation
              ? [field, jsonMap.map[field]]
              : [jsonMap.map[field]];
          im.invoke(jsonSetter.simpleName, params);
        }
      }
    }
  }
}
