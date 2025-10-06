import 'dart:convert' show JsonDecoder;

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'reflection_handler.dart';

class SerializationHandler {
  final JsonMapper _mapper;

  SerializationHandler(this._mapper);

  dynamic serializeObject(Object? object, SerializationContext? context) {
    if (object == null) {
      return object;
    }

    final im = ReflectionHandler.safeGetInstanceMirror(object);
    final converter = _mapper.converterHandler.getConverter(
        context!.jsonPropertyMeta, _mapper.typeInfoHandler.getTypeInfo(object.runtimeType));
    if (converter != null) {
      _mapper.converterHandler.configureConverter(converter, context, value: object);
      return _mapper.converterHandler.getConvertedValue(converter, object, context);
    }

    if (im == null) {
      if (context.serializationOptions.ignoreUnknownTypes == true) {
        return null;
      } else {
        throw MissingAnnotationOnTypeError(object.runtimeType);
      }
    }

    final classInfo = ClassInfo.fromCache(im.type, _mapper.classes);
    final jsonMeta = classInfo.getMeta(context.options.scheme);
    final initialMap = context.level == 0
        ? context.options.template ?? <String, dynamic>{}
        : <String, dynamic>{};
    final result = JsonMap(initialMap, jsonMeta);
    final processedObjectDescriptor =
        _mapper.getObjectProcessed(object, context.level);
    if (processedObjectDescriptor != null &&
        processedObjectDescriptor.levelsCount > 1) {
      final allowanceIsSet =
          (jsonMeta != null && jsonMeta.allowCircularReferences! > 0);
      final allowanceExceeded = allowanceIsSet &&
              processedObjectDescriptor.levelsCount >
                  jsonMeta.allowCircularReferences!
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
    _mapper.propertyHandler.enumeratePublicProperties(im, null, context, (name, property, isGetterOnly,
        JsonProperty? meta, converter, TypeInfo typeInfo) {
      dynamic convertedValue;
      final propertyContext = context.reBuild(
          level: context.level + 1,
          jsonPropertyMeta: meta,
          classMeta: jsonMeta,
          typeInfo: typeInfo) as SerializationContext;

      if (meta?.rawJson == true && typeInfo.type == String && property.value is String) {
        final jsonString = property.value as String;
        if (jsonString.isEmpty || jsonString == "null") {
          convertedValue = null;
        } else {
          try {
            convertedValue = JsonDecoder().convert(jsonString);
          } on FormatException {
            convertedValue = jsonString;
          }
        }
      } else {
        if (meta?.flatten == true) {
          final Map flattenedPropertiesMap =
              serializeObject(property.value, propertyContext);
          final metaName = meta?.name;
          final fieldPrefixWords = metaName != null
              ? toWords(metaName, propertyContext.caseStyle).join(' ')
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
          return;
        }

        final actualConverter = _mapper.converterHandler.getConverter(meta, typeInfo);
        if (actualConverter != null) {
          final valueToConvert = property.value ?? meta?.defaultValue;
          _mapper.converterHandler.configureConverter(actualConverter, propertyContext, value: valueToConvert);
          convertedValue = _mapper.converterHandler.getConvertedValue(actualConverter, valueToConvert, propertyContext);
        } else {
          convertedValue = serializeObject(property.value, propertyContext);
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

  void _dumpDiscriminatorToObjectProperty(JsonMap object,
      type, DeserializationOptions? options) {
    final classInfo = ClassInfo.fromCache(type, _mapper.classes);
    final discriminatorProperty = _mapper.typeInfoHandler.getDiscriminatorProperty(classInfo, options);
    if (discriminatorProperty != null) {
      final typeInfo = _mapper.typeInfoHandler.getTypeInfo(type.reflectedType);
      final lastMeta = classInfo.getMeta(options?.scheme);
      final discriminatorValue =
          (lastMeta != null && lastMeta.discriminatorValue != null
                  ? lastMeta.discriminatorValue
                  : typeInfo.typeName) ??
              typeInfo.typeName;
      object.setPropertyValue(discriminatorProperty, discriminatorValue);
    }
  }
}