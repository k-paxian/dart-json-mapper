import 'dart:convert' show JsonEncoder; // dart: imports first

import 'package:reflectable/reflectable.dart' show ClassMirror, InstanceMirror; // package: imports next

import 'errors.dart'; // relative file imports last
import 'mapper.dart';
import 'model/index.dart';
import 'utils.dart';

/// Handles the process of serializing a Dart object into a JSON-compatible map structure.
/// It manages circular references and applies serialization options.
class SerializationPipeline {
  final JsonMapper _mapperInstance; 
  
  /// Tracks objects already processed during a single serialization run to handle circular references.
  final Map<String, ProcessedObjectDescriptor> _processedObjects = {};

  SerializationPipeline(this._mapperInstance);

  /// Public entry point for the serialization pipeline.
  /// Takes a Dart [object] and a [context] to guide serialization.
  /// Returns a JSON-compatible representation (usually a Map or primitive).
  dynamic execute(Object? object, SerializationContext context) {
    // The _processedObjects cache is instance-specific for this pipeline run.
    return _serializeObject(object, context);
  }

  /// Creates a [JsonEncoder] configured according to the [SerializationContext].
  /// Uses the provided [pipeline] instance for the `toEncodable` callback.
  static JsonEncoder getJsonEncoder(SerializationContext context, SerializationPipeline pipeline) =>
      context.serializationOptions.indent != null &&
              context.serializationOptions.indent!.isNotEmpty
          ? JsonEncoder.withIndent(
              context.serializationOptions.indent, _toEncodable(context, pipeline))
          : JsonEncoder(_toEncodable(context, pipeline));

  /// Provides the `toEncodable` function required by [JsonEncoder].
  /// This function is called by the encoder for each object it needs to convert.
  static dynamic _toEncodable(SerializationContext context, SerializationPipeline pipeline) =>
      (Object? object) => pipeline._serializeObject(object, context);

  /// Generates a unique key for an object instance based on its runtime type and identity hash code.
  String _getObjectKey(Object object) =>
      '${object.runtimeType}-${identityHashCode(object)}'; // identityHashCode is from dart:core

  /// Retrieves or creates a [ProcessedObjectDescriptor] for the given [object]
  /// at the current serialization [level]. This is used to detect circular references.
  ProcessedObjectDescriptor? _getObjectProcessed(Object object, int level) {
    ProcessedObjectDescriptor? result;

    // Skip tracking for primitive types that don't cause circular refs.
    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
      return result;
    }

    final key = _getObjectKey(object);
    if (_processedObjects.containsKey(key)) {
      result = _processedObjects[key];
      result!.logUsage(level); // Log that this object is seen again at this level
    } else {
      result = _processedObjects[key] = ProcessedObjectDescriptor(object);
    }
    return result;
  }
  
  /// Adds the discriminator property to the JSON [object] map if configured.
  /// The [classMirror] and [options] are used to determine the property name and value.
  void _dumpDiscriminatorToObjectProperty(JsonMap object,
      ClassMirror classMirror, SerializationOptions? options) {
    final classInfo = ClassInfo.fromCache(classMirror, _mapperInstance._classes);
    final discriminatorProperty = _mapperInstance._getDiscriminatorProperty(classInfo, options);
    if (discriminatorProperty != null) {
      final typeInfo = _mapperInstance._typeInfoProvider.getTypeInfo(classMirror.reflectedType);
      final lastMeta = classInfo.getMeta(options?.scheme);
      final discriminatorValue =
          (lastMeta != null && lastMeta.discriminatorValue != null
                  ? lastMeta.discriminatorValue
                  : typeInfo.typeName) ??
              typeInfo.typeName;
      object.setPropertyValue(discriminatorProperty, discriminatorValue);
    }
  }

  /// Core recursive method to serialize an [object] based on the given [context].
  dynamic _serializeObject(Object? object, SerializationContext? context) {
    if (object == null) {
      return null;
    }

    final im = _mapperInstance._safeGetInstanceMirror(object);
    // Attempt to use a custom converter if one is applicable for the object's type.
    final converter = _mapperInstance._getConverter(
        context!.jsonPropertyMeta, _mapperInstance._typeInfoProvider.getTypeInfo(object.runtimeType));
    if (converter != null) {
      _mapperInstance._configureConverter(converter, context, value: object);
      return _mapperInstance._getConvertedValue(converter, object, context);
    }

    // If no converter, proceed with standard reflection-based serialization.
    if (im == null) { // Not reflectable and no converter
      if (context.serializationOptions.ignoreUnknownTypes == true) {
        return null;
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
      }
    }

    final classInfo = ClassInfo.fromCache(im.type, _mapperInstance._classes);
    final jsonMeta = classInfo.getMeta(context.options.scheme);
    final initialMap = context.level == 0
        ? context.options.template ?? <String, dynamic>{}
        : <String, dynamic>{};
    final result = JsonMap(initialMap, jsonMeta);

    // Handle circular references.
    final processedObjectDescriptor = _getObjectProcessed(object, context.level); 
    if (processedObjectDescriptor != null &&
        processedObjectDescriptor.levelsCount > 1) { // Object seen multiple times
      final allowanceIsSet = (jsonMeta != null && jsonMeta.allowCircularReferences! > 0);
      final allowanceExceeded = (allowanceIsSet &&
              processedObjectDescriptor.levelsCount > jsonMeta.allowCircularReferences!)
          ? true
          : null; // Using null for "not exceeded or not applicable"
      if (allowanceExceeded == true) {
        return null; // Exceeded allowance, serialize as null
      }
      if (allowanceIsSet == false) { // No allowance set, but object is repeating
        throw CircularReferenceError(object);
      }
    }

    // Add discriminator property if applicable.
    _dumpDiscriminatorToObjectProperty(result, im.type, context.options); 
    
    // Enumerate and serialize object properties.
    _mapperInstance._enumeratePublicProperties(im, null, context, (name, property, isGetterOnly,
        JsonProperty? meta, converter, TypeInfo typeInfo) { // Types for callback params for clarity
      dynamic convertedValue;
      final propertyContext = context.reBuild(
          level: context.level + 1,
          jsonPropertyMeta: meta,
          classMeta: jsonMeta,
          typeInfo: typeInfo) as SerializationContext;
      
      if (meta?.flatten == true) {
        _serializeFlattenedProperty(result, property.value, meta!, propertyContext);
        return;
      }
      
      if (converter != null) {
        final value = property.value ?? meta?.defaultValue;
        _mapperInstance._configureConverter(converter, propertyContext, value: value);
        convertedValue = _mapperInstance._getConvertedValue(converter, value, propertyContext);
      } else {
        // Recursively serialize nested objects.
        convertedValue = _serializeObject(property.value, propertyContext); 
      }
      result.setPropertyValue(
          property.name, convertedValue ?? meta?.defaultValue);
    });

    // Handle JsonAnyGetter if present.
    final jsonAnyGetter = classInfo.getJsonAnyGetter();
    if (jsonAnyGetter != null) {
      final anyMap = im.invoke(jsonAnyGetter.simpleName, [])!;
      result.map.addAll(anyMap as Map<String, dynamic>);
    }

    return result.map;
  }

  /// Serializes a property marked with `@JsonProperty(flatten: true)`.
  /// The [propertyValue] is serialized, and its resulting map's entries are
  /// merged into the [mainResultMap]. Keys may be prefixed.
  void _serializeFlattenedProperty(JsonMap mainResultMap, dynamic propertyValue, JsonProperty propertyMeta, SerializationContext propertyContext) {
    if (propertyValue == null) return; 

    final Map flattenedPropertiesMap = _serializeObject(propertyValue, propertyContext);
    
    final String? fieldPrefix;
    if (propertyMeta.name != null && propertyMeta.name!.isNotEmpty) {
      final prefixWords = toWords(propertyMeta.name!, propertyContext.caseStyle).join(' ');
      fieldPrefix = prefixWords.isNotEmpty ? prefixWords : null;
    } else {
      fieldPrefix = null;
    }

    for (var element in flattenedPropertiesMap.entries) {
      String key = element.key as String;
      if (fieldPrefix != null) {
        // Combine prefix and key, then transform to target case style.
        key = transformIdentifierCaseStyle(
                transformIdentifierCaseStyle('$fieldPrefix ${element.key}', defaultCaseStyle, null), 
                propertyContext.targetCaseStyle, 
                defaultCaseStyle);
      } else {
         // Ensure the key itself is in the correct style if no prefix.
         key = transformIdentifierCaseStyle(element.key, propertyContext.targetCaseStyle, propertyContext.sourceCaseStyle ?? defaultCaseStyle);
      }
      mainResultMap.setPropertyValue(key, element.value);
    }
  }
}
