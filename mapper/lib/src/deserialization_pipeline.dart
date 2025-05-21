import 'dart:convert' show JsonDecoder; // dart: imports first

import 'package:reflectable/reflectable.dart' // package: imports next
    show ClassMirror, InstanceMirror, ParameterMirror;

import 'errors.dart'; // relative file imports last
import 'mapper.dart';
import 'model/index.dart';
import 'utils.dart';

class DeserializationPipeline {
  final JsonMapper _mapperInstance;
  final JsonDecoder _jsonDecoder = JsonDecoder();

  DeserializationPipeline(this._mapperInstance);

  /// Public entry point for the deserialization pipeline.
  Object? execute(dynamic jsonValue, DeserializationContext context) {
    return _deserializeObject(jsonValue, context);
  }

  bool _isValidJSON(dynamic jsonValue) {
    try {
      if (jsonValue is String) {
        this._jsonDecoder.convert(jsonValue);
        return true;
      }
      return jsonValue is Map || jsonValue is List;
    } on FormatException {
      return false;
    }
  }

  TypeInfo? _detectObjectType(dynamic objectInstance, Type? objectType,
      JsonMap objectJsonMap, DeserializationContext context) {
    final objectClassInfo = _mapperInstance._classes[objectType];
    if (objectClassInfo == null) {
      return null;
    }
    final meta = objectClassInfo.getMeta(context.options.scheme);

    if (objectInstance is Map<String, dynamic>) {
      objectJsonMap = JsonMap(objectInstance, meta);
    }
    final typeInfo = _mapperInstance._typeInfoProvider.getTypeInfo(objectType ?? objectInstance.runtimeType);

    final discriminatorProperty =
        _mapperInstance._getDiscriminatorProperty(objectClassInfo, context.options);
    final discriminatorValue = discriminatorProperty != null &&
            objectJsonMap.hasProperty(discriminatorProperty)
        ? objectJsonMap.getPropertyValue(discriminatorProperty)
        : null;
    if (discriminatorProperty != null && discriminatorValue != null) {
      final declarationMirror =
          objectClassInfo.getDeclarationMirror(discriminatorProperty);
      if (declarationMirror != null) {
        final discriminatorType = _mapperInstance._typeInfoProvider.getDeclarationType(declarationMirror);
        final value = _deserializeObject(discriminatorValue,
            context.reBuild(typeInfo: _mapperInstance._typeInfoProvider.getTypeInfo(discriminatorType)));
        if (value is Type) {
          return _mapperInstance._typeInfoProvider.getTypeInfo(value);
        }

        if (_mapperInstance._discriminatorToType[value] == null) {
          final validDiscriminators = ClassInfo.getAllSubTypes(
                  _mapperInstance._classes, objectClassInfo)
              .map((e) => e.getMeta(context.options.scheme)!.discriminatorValue)
              .toList();
          throw JsonMapperSubtypeError(
            discriminatorValue,
            validDiscriminators,
            objectClassInfo,
          );
        }
        return _mapperInstance._typeInfoProvider.getTypeInfo(_mapperInstance._discriminatorToType[value]!);
      }
    }
    if (discriminatorValue != null) {
      final targetType = _mapperInstance._typeInfoProvider.getTypeByStringName(discriminatorValue);
      return _mapperInstance._classes[targetType] != null
          ? _mapperInstance._typeInfoProvider.getTypeInfo(_mapperInstance._classes[targetType]!.reflectedType!)
          : typeInfo;
    }
    return typeInfo;
  }

  void _enumerateConstructorParameters(ClassMirror classMirror, JsonMap jsonMap,
      DeserializationContext context, Function filter, Function visitor) {
    final classInfo = ClassInfo.fromCache(classMirror, _mapperInstance._classes);
    final classMeta = classInfo.getMeta(context.options.scheme);
    final scheme =
        classMeta != null ? classMeta.scheme : context.options.scheme;
    final methodMirror = classInfo.getJsonConstructor(scheme);
    if (methodMirror == null) {
      return;
    }
    for (var param in methodMirror.parameters) {
      if (!filter(param as ParameterMirror)) { 
        continue; 
      }
      final name = param.simpleName;
      final declarationMirror = classInfo.getDeclarationMirror(name) ?? param;
      final paramType = param.hasReflectedType
          ? param.reflectedType
          : param.hasDynamicReflectedType
              ? param.dynamicReflectedType
              : _mapperInstance._typeInfoProvider.getGenericParameterTypeByIndex( 
                      methodMirror.parameters.indexOf(param),
                      context.typeInfo!) ??
                  dynamic;
      var paramTypeInfo = _mapperInstance._typeInfoProvider.getTypeInfo(paramType); 
      paramTypeInfo = paramTypeInfo.isDynamic
          ? _mapperInstance._typeInfoProvider.getTypeInfo(_mapperInstance._typeInfoProvider.getDeclarationType(declarationMirror))
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
      final value = property.raw
          ? _deserializeObject(property.value, propertyContext) 
          : property.value;

      visitor(param, name, jsonName, classMeta, meta, value, paramTypeInfo);
    }
  }

  Map<Symbol, dynamic> _getNamedArguments(
      ClassMirror cm, JsonMap jsonMap, DeserializationContext context) {
    final result = <Symbol, dynamic>{};

    _enumerateConstructorParameters( 
        cm, jsonMap, context, (ParameterMirror param) => param.isNamed, (param, name, jsonName,
            classMeta, JsonProperty? meta, value, TypeInfo typeInfo) {
      if (!_mapperInstance._isFieldIgnoredByValue(value, classMeta, meta, context.options)) {
        result[Symbol(name)] = value;
      }
    });
    return result;
  }

  List _getPositionalArguments(ClassMirror cm, JsonMap jsonMap,
      DeserializationContext context, List<String> positionalArgumentNames) {
    final result = [];

    _enumerateConstructorParameters( 
        cm, jsonMap, context, (ParameterMirror param) => !param.isOptional && !param.isNamed,
        (param, name, jsonName, classMeta, JsonProperty? meta, value,
            TypeInfo typeInfo) {
      positionalArgumentNames.add(name);
      result.add(_mapperInstance._isFieldIgnoredByValue(value, classMeta, meta, context.options)
          ? null
          : value);
    });
    return result;
  }

  Object? _deserializeObject(
      dynamic jsonValue, DeserializationContext context) {
    if (jsonValue == null) {
      return null;
    }
    var typeInfo = context.typeInfo!;
    final converter = _mapperInstance._getConverter(context.jsonPropertyMeta, typeInfo);
    if (converter != null) {
      _mapperInstance._configureConverter(converter, context);
      if (typeInfo.isIterable &&
          (converter is ICustomIterableConverter &&
              converter is! DefaultIterableConverter)) { 
        return _mapperInstance._applyValueDecorator(
            _mapperInstance._getConvertedValue(converter, jsonValue, context), typeInfo);
      }
      return _mapperInstance._applyValueDecorator(
          _mapperInstance._getConvertedValue(converter, jsonValue, context), typeInfo);
    }

    dynamic convertedJsonValue =
        (jsonValue is String && _isValidJSON(jsonValue)) ? this._jsonDecoder.convert(jsonValue) : jsonValue;

    if (convertedJsonValue is String && typeInfo.type is Type) { 
      return _mapperInstance._typeInfoProvider.getTypeByStringName(convertedJsonValue.replaceAll("\"", ""));
    }

    final jsonMap = JsonMap(
        convertedJsonValue, null, context.parentJsonMaps as List<JsonMap>?);
    
    typeInfo =
        _detectObjectType(null, context.typeInfo!.type, jsonMap, context) ??
            typeInfo;
            
    final classInfo = _mapperInstance._classes[typeInfo.type] ??
        _mapperInstance._classes[typeInfo.genericType] ??
        _mapperInstance._classes[typeInfo.mixinType];

    if (classInfo == null) {
      if (typeInfo.isDartCoreType && typeInfo.type != Object) {
         if (jsonValue.runtimeType == typeInfo.type) return jsonValue;
      }
      throw MissingAnnotationOnTypeError(typeInfo.type);
    }
    jsonMap.jsonMeta = classInfo.getMeta(context.options.scheme);

    final namedArguments = _getNamedArguments(classInfo.classMirror, jsonMap, context);
    final positionalArgumentNames = <String>[];
    final positionalArguments = _getPositionalArguments(classInfo.classMirror, jsonMap, context, positionalArgumentNames);

    final objectInstance = _createInstanceWithConstructor(
        classInfo, context, positionalArguments, namedArguments, positionalArgumentNames);

    final im = _mapperInstance._safeGetInstanceMirror(objectInstance)!;
    
    final List<String> mappedFields = namedArguments.keys
        .map((Symbol symbol) => RegExp('"(.+)"').allMatches(symbol.toString()).first.group(1)!)
        .toList()
      ..addAll(positionalArgumentNames);

    _populateProperties(im, jsonMap, context, classInfo, mappedFields, objectInstance);
    _handleUnmappedFields(im, jsonMap, context, classInfo, mappedFields);

    return _mapperInstance._applyValueDecorator(objectInstance, typeInfo);
  }

  dynamic _createInstanceWithConstructor(
      ClassInfo classInfo,
      DeserializationContext context,
      List<dynamic> positionalArguments,
      Map<Symbol, dynamic> namedArguments,
      List<String> positionalArgumentNames) {
    try {
      return context.options.template ??
          (classInfo.classMirror.isEnum
              ? null
              : classInfo.classMirror.newInstance(
                  classInfo.getJsonConstructor(context.options.scheme)!.constructorName,
                  positionalArguments,
                  namedArguments));
    } on TypeError catch (typeError) {
      final positionalNullArguments = positionalArgumentNames.where(
          (element) => positionalArguments[positionalArgumentNames.indexOf(element)] == null);
      final namedNullArguments = Map<Symbol, dynamic>.from(namedArguments)
        ..removeWhere((key, value) => value != null);
      throw CannotCreateInstanceError(
          typeError, classInfo, positionalNullArguments, namedNullArguments);
    }
  }

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

      if (!hasJsonProperty || mappedFields.contains(name)) {
        if (meta?.flatten == true) {
          final Map<String, dynamic>? objectMap = fieldValue is Map<String, dynamic> ? fieldValue : null;
          final object = meta.name != null && objectMap != null
              ? objectMap.map((key, value) => MapEntry(
                  skipPrefix(meta.name!, key, propertyContext.caseStyle), value))
              : fieldValue;
          im.invokeSetter(name, _deserializeObject(object, propertyContext));
        }
        if (im.invokeGetter(name) == null && defaultValue != null && !isGetterOnly) {
          im.invokeSetter(name, defaultValue);
        }
        if (meta?.inject != true) {
           return;
        }
      }

      fieldValue = property.raw
          ? _deserializeObject(fieldValue, propertyContext) 
          : property.value;

      if (isGetterOnly) {
        if (inheritedPublicFieldNames.contains(name) && !mappedFields.contains(property.name)) {
          mappedFields.add(property.name);
        }
      } else {
        fieldValue = _mapperInstance._applyValueDecorator(fieldValue, typeInfo) ?? defaultValue;
        im.invokeSetter(name, fieldValue);
        mappedFields.add(property.name); 
      }
    });
  }

  void _handleUnmappedFields(
      InstanceMirror im,
      JsonMap jsonMap,
      DeserializationContext context,
      ClassInfo classInfo,
      List<String> mappedFields) {

    final discriminatorPropertyName =
        _mapperInstance._getDiscriminatorProperty(classInfo, context.options);
    
    final unmappedFields = jsonMap.map.keys
        .where((field) => !mappedFields.contains(field) && field != discriminatorPropertyName)
        .toList();

    if (unmappedFields.isNotEmpty) {
      final jsonAnySetter = classInfo.getJsonAnySetter(context.options.scheme);
      for (var field in unmappedFields) {
        final jsonSetter = classInfo.getJsonSetter(field, context.options.scheme) ?? jsonAnySetter;
        if (jsonSetter != null) {
           final params = jsonSetter == jsonAnySetter
              ? [field, jsonMap.map[field]]
              : [jsonMap.map[field]];
          im.invoke(jsonSetter.simpleName, params);
        }
      }
    }
  }
}
