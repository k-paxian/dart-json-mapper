import 'dart:convert' show JsonEncoder, JsonDecoder;

import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'property_handler.dart';
import 'reflection_handler.dart';

class DeserializationHandler {
  final JsonMapper _mapper;

  DeserializationHandler(this._mapper);

  Object? deserializeObject(
      dynamic jsonValue, DeserializationContext context) {
    if (jsonValue == null) {
      return null;
    }
    var typeInfo = context.typeInfo!;
    final converter = _mapper.converterHandler.getConverter(context.jsonPropertyMeta, typeInfo);
    if (converter != null) {
      _mapper.converterHandler.configureConverter(converter, context);
      if (typeInfo.isIterable &&
          (converter is ICustomIterableConverter &&
              converter is! DefaultIterableConverter)) {
        return _mapper.applyValueDecorator(
            _mapper.converterHandler.getConvertedValue(converter, jsonValue, context), typeInfo);
      }
      return _mapper.applyValueDecorator(
          _mapper.converterHandler.getConvertedValue(converter, jsonValue, context), typeInfo);
    }

    dynamic convertedJsonValue =
        JsonMap.isValidJSON(jsonValue) ? JsonDecoder().convert(jsonValue) : jsonValue;

    if (convertedJsonValue is String && typeInfo.type is Type) {
      return _mapper.typeInfoHandler.getTypeByStringName(convertedJsonValue.replaceAll("\"", ""));
    }

    final jsonMap = JsonMap(
        convertedJsonValue, null, context.parentJsonMaps as List<JsonMap>?);
    typeInfo =
        _detectObjectType(null, context.typeInfo!.type, jsonMap, context) ??
            typeInfo;
    final classInfo = _mapper.classes[typeInfo.type] ??
        _mapper.classes[typeInfo.genericType] ??
        _mapper.classes[typeInfo.mixinType];
    if (classInfo == null) {
      throw MissingAnnotationOnTypeError(typeInfo.type);
    }
    jsonMap.jsonMeta = classInfo.getMeta(context.options.scheme);

    final namedArguments =
        _getNamedArguments(classInfo, jsonMap, context);
    final positionalArgumentNames = <String>[];
    final positionalArguments = _getPositionalArguments(
        classInfo, jsonMap, context, positionalArgumentNames);
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

    final im = ReflectionHandler.safeGetInstanceMirror(objectInstance)!;
    final inheritedPublicFieldNames = classInfo.inheritedPublicFieldNames;
    final mappedFields = namedArguments.keys
        .map((Symbol symbol) =>
            RegExp('"(.+)"').allMatches(symbol.toString()).first.group(1))
        .toList()
      ..addAll(positionalArgumentNames);

    _mapper.propertyHandler.enumeratePublicProperties(im, jsonMap, context, (name, property,
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
        if (meta?.flatten == true) {
          if (mappedFields.contains(name) || isGetterOnly) {
              return;
          }
          final fieldValue = jsonMap.getPropertyValue(property.name);
          final metaName = meta?.name;
          final objectToDeserialize = metaName != null && fieldValue is Map
              ? fieldValue.map((key, value) => MapEntry(skipPrefix(metaName, key, propertyContext.caseStyle), value))
              : fieldValue;

          im.invokeSetter(name, deserializeObject(objectToDeserialize, propertyContext));
          return;
        }
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
          ? deserializeObject(fieldValue, propertyContext)
          : property.value;
      if (isGetterOnly) {
        if (inheritedPublicFieldNames.contains(name) &&
            !mappedFields.contains(property.name)) {
          mappedFields.add(property.name);
        }
      } else {
        if (meta?.rawJson == true && typeInfo.type == String) {
          if (fieldValue is Map || fieldValue is List) {
            fieldValue = JsonEncoder().convert(fieldValue);
          } else if (fieldValue == null) {
            fieldValue = null;
          } else {
            fieldValue = fieldValue.toString();
          }
        }

        fieldValue = _mapper.applyValueDecorator(fieldValue, typeInfo) ?? defaultValue;
        im.invokeSetter(name, fieldValue);
        mappedFields.add(property.name);
      }
    });

    final discriminatorPropertyName =
        _mapper.typeInfoHandler.getDiscriminatorProperty(classInfo, context.options);
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

    return _mapper.applyValueDecorator(objectInstance, typeInfo);
  }

  TypeInfo? _detectObjectType(dynamic objectInstance, Type? objectType,
      JsonMap objectJsonMap, DeserializationContext context) {
    final objectClassInfo = _mapper.classes[objectType];
    if (objectClassInfo == null) {
      return null;
    }
    final meta = objectClassInfo.getMeta(context.options.scheme);

    if (objectInstance is Map<String, dynamic>) {
      objectJsonMap = JsonMap(objectInstance, meta);
    }
    final typeInfo = _mapper.typeInfoHandler.getTypeInfo(objectType ?? objectInstance.runtimeType);

    final discriminatorProperty =
        _mapper.typeInfoHandler.getDiscriminatorProperty(objectClassInfo, context.options);
    final discriminatorValue = discriminatorProperty != null &&
            objectJsonMap.hasProperty(discriminatorProperty)
        ? objectJsonMap.getPropertyValue(discriminatorProperty)
        : null;
    if (discriminatorProperty != null && discriminatorValue != null) {
      final declarationMirror =
          objectClassInfo.getDeclarationMirror(discriminatorProperty);
      if (declarationMirror != null) {
        final discriminatorType = ReflectionHandler.getDeclarationType(declarationMirror);
        final value = deserializeObject(discriminatorValue,
            context.reBuild(typeInfo: _mapper.typeInfoHandler.getTypeInfo(discriminatorType)));
        if (value is Type) {
          return _mapper.typeInfoHandler.getTypeInfo(value);
        }

        if (_mapper.discriminatorToType[value] == null) {
          final validDiscriminators = ClassInfo.getAllSubTypes(
                  _mapper.classes, objectClassInfo)
              .map((e) => e.getMeta(context.options.scheme)!.discriminatorValue)
              .toList();
          throw JsonMapperSubtypeError(
            discriminatorValue,
            validDiscriminators,
            objectClassInfo,
          );
        }

        return _mapper.typeInfoHandler.getTypeInfo(_mapper.discriminatorToType[value]!);
      }
    }
    if (discriminatorValue != null) {
      final targetType = _mapper.typeInfoHandler.getTypeByStringName(discriminatorValue);
      return _mapper.classes[targetType] != null
          ? _mapper.typeInfoHandler.getTypeInfo(_mapper.classes[targetType]!.reflectedType!)
          : typeInfo;
    }
    return typeInfo;
  }

  void _enumerateConstructorParameters(ClassInfo classInfo, JsonMap jsonMap,
      DeserializationContext context, Function filter, Function visitor) {
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
              : _mapper.typeInfoHandler.getGenericParameterTypeByIndex(
                      methodMirror.parameters.indexOf(param),
                      context.typeInfo!) ??
                  dynamic;
      var paramTypeInfo = _mapper.typeInfoHandler.getTypeInfo(paramType);
      paramTypeInfo = paramTypeInfo.isDynamic
          ? _mapper.typeInfoHandler.getTypeInfo(ReflectionHandler.getDeclarationType(declarationMirror))
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

      dynamic finalValueForVisitor;
      String? jsonNameForVisitor;

      if (meta?.flatten == true) {
        finalValueForVisitor = deserializeObject(jsonMap.map, propertyContext.reBuild(jsonPropertyMeta: null));
        jsonNameForVisitor = context.transformIdentifier(meta?.name ?? name);
      } else {
        final property = _mapper.propertyHandler.resolveProperty(
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
        if (property.raw) {
            finalValueForVisitor = deserializeObject(property.value, propertyContext);
        } else {
            finalValueForVisitor = property.value;
        }
      }

      visitor(param, name, jsonNameForVisitor, classMeta, meta, finalValueForVisitor, paramTypeInfo);
    }
  }

  Map<Symbol, dynamic> _getNamedArguments(
      ClassInfo cm, JsonMap jsonMap, DeserializationContext context) {
    final result = <Symbol, dynamic>{};

    _enumerateConstructorParameters(
        cm, jsonMap, context, (param) => param.isNamed, (param, name, jsonName,
            classMeta, JsonProperty? meta, value, TypeInfo typeInfo) {
      if (!PropertyHandler.isFieldIgnoredByValue(value, classMeta, meta, context.options)) {
        result[Symbol(name)] = value;
      }
    });

    return result;
  }

  List _getPositionalArguments(ClassInfo cm, JsonMap jsonMap,
      DeserializationContext context, List<String> positionalArgumentNames) {
    final result = [];

    _enumerateConstructorParameters(
        cm, jsonMap, context, (param) => !param.isOptional && !param.isNamed,
        (param, name, jsonName, classMeta, JsonProperty? meta, value,
            TypeInfo typeInfo) {
      positionalArgumentNames.add(name);
      result.add(PropertyHandler.isFieldIgnoredByValue(value, classMeta, meta, context.options)
          ? null
          : value);
    });

    return result;
  }
}