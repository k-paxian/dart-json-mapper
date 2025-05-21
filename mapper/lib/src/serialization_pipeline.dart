import 'dart:convert' show JsonEncoder; // dart: imports first

import 'package:reflectable/reflectable.dart' show ClassMirror, InstanceMirror; // package: imports next

import 'errors.dart'; // relative file imports last
import 'mapper.dart';
import 'model/index.dart';
import 'utils.dart';

class SerializationPipeline {
  final JsonMapper _mapperInstance; 
  
  final Map<String, ProcessedObjectDescriptor> _processedObjects = {};

  SerializationPipeline(this._mapperInstance);

  /// Public entry point for the serialization pipeline.
  dynamic execute(Object? object, SerializationContext context) {
    return _serializeObject(object, context);
  }

  static JsonEncoder getJsonEncoder(SerializationContext context, SerializationPipeline pipeline) =>
      context.serializationOptions.indent != null &&
              context.serializationOptions.indent!.isNotEmpty
          ? JsonEncoder.withIndent(
              context.serializationOptions.indent, _toEncodable(context, pipeline))
          : JsonEncoder(_toEncodable(context, pipeline));

  static dynamic _toEncodable(SerializationContext context, SerializationPipeline pipeline) =>
      (Object? object) => pipeline._serializeObject(object, context);

  String _getObjectKey(Object object) =>
      '${object.runtimeType}-${identityHashCode(object)}'; // identityHashCode is from dart:core

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

  dynamic _serializeObject(Object? object, SerializationContext? context) {
    if (object == null) {
      return object;
    }

    final im = _mapperInstance._safeGetInstanceMirror(object);
    final converter = _mapperInstance._getConverter(
        context!.jsonPropertyMeta, _mapperInstance._typeInfoProvider.getTypeInfo(object.runtimeType));
    if (converter != null) {
      _mapperInstance._configureConverter(converter, context, value: object);
      return _mapperInstance._getConvertedValue(converter, object, context);
    }

    if (im == null) {
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
    
    _mapperInstance._enumeratePublicProperties(im, null, context, (name, property, isGetterOnly,
        JsonProperty? meta, converter, TypeInfo typeInfo) {
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
        convertedValue = _serializeObject(property.value, propertyContext); 
      }
      result.setPropertyValue(
          property.name, convertedValue ?? meta?.defaultValue);
    });

    final jsonAnyGetter = classInfo.getJsonAnyGetter();
    if (jsonAnyGetter != null) {
      final anyMap = im.invoke(jsonAnyGetter.simpleName, [])!;
      result.map.addAll(anyMap as Map<String, dynamic>);
    }

    return result.map;
  }

  void _serializeFlattenedProperty(JsonMap mainResultMap, dynamic propertyValue, JsonProperty propertyMeta, SerializationContext propertyContext) {
    if (propertyValue == null) return; // Nothing to flatten

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
        key = transformIdentifierCaseStyle(
                transformIdentifierCaseStyle('$fieldPrefix ${element.key}', defaultCaseStyle, null), 
                propertyContext.targetCaseStyle, 
                defaultCaseStyle);
      } else {
         key = transformIdentifierCaseStyle(element.key, propertyContext.targetCaseStyle, propertyContext.sourceCaseStyle ?? defaultCaseStyle);
      }
      mainResultMap.setPropertyValue(key, element.value);
    }
  }
}
