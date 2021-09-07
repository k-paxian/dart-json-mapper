library json_mapper_built;

import 'package:built_collection/built_collection.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart'
    show
        DefaultTypeInfoDecorator,
        defaultIterableConverter,
        ICustomConverter,
        IRecursiveConverter,
        SerializeObjectFunction,
        DeserializeObjectFunction,
        TypeInfo,
        DeserializationContext,
        SerializationContext,
        JsonMapperAdapter;

/// Shorthand for ready made decorator instance
final builtTypeInfoDecorator = BuiltTypeInfoDecorator();

/// Type info decorator provides support for Built types like
/// BuiltList, BuiltMap, BuiltSet
class BuiltTypeInfoDecorator extends DefaultTypeInfoDecorator {
  bool isBuiltList(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('_BuiltList<') == 0 ||
      typeInfo.typeName!.indexOf('BuiltList<') == 0;

  bool isBuiltMap(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('_BuiltMap<') == 0 ||
      typeInfo.typeName!.indexOf('BuiltMap<') == 0;

  bool isBuiltSet(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('_BuiltSet<') == 0 ||
      typeInfo.typeName!.indexOf('BuiltSet<') == 0;

  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    typeInfo = super.decorate(typeInfo);
    typeInfo.isList = typeInfo.isList || isBuiltList(typeInfo);
    typeInfo.isSet = typeInfo.isSet || isBuiltSet(typeInfo);
    typeInfo.isMap = typeInfo.isMap || isBuiltMap(typeInfo);
    typeInfo.isIterable =
        typeInfo.isIterable || typeInfo.isList || typeInfo.isSet;
    typeInfo.genericType = detectGenericType(typeInfo);
    return typeInfo;
  }

  @override
  Type? detectGenericType(TypeInfo typeInfo) {
    if (isBuiltList(typeInfo)) {
      return BuiltList;
    }
    if (isBuiltSet(typeInfo)) {
      return BuiltSet;
    }
    if (isBuiltMap(typeInfo)) {
      return BuiltMap;
    }
    return super.detectGenericType(typeInfo);
  }
}

/// Shorthand for ready made converter instance
final builtMapConverter = BuiltMapConverter();

/// [BuiltMap<K, V>] converter
class BuiltMapConverter implements ICustomConverter, IRecursiveConverter {
  BuiltMapConverter() : super();

  late SerializeObjectFunction _serializeObject;
  late DeserializeObjectFunction _deserializeObject;

  @override
  dynamic fromJSON(dynamic jsonValue, [DeserializationContext? context]) {
    if (context!.typeInfo != null && jsonValue is Map) {
      return jsonValue.map((key, value) => MapEntry(
          _deserializeObject(key, context.typeInfo!.parameters.first),
          _deserializeObject(value, context.typeInfo!.parameters.last)));
    }
    return jsonValue;
  }

  @override
  dynamic toJSON(dynamic object, [SerializationContext? context]) =>
      (object as BuiltMap).toMap().map((key, value) =>
          MapEntry(_serializeObject(key).toString(), _serializeObject(value)));

  @override
  void setSerializeObjectFunction(SerializeObjectFunction serializeObject) {
    _serializeObject = serializeObject;
  }

  @override
  void setDeserializeObjectFunction(
      DeserializeObjectFunction deserializeObject) {
    _deserializeObject = deserializeObject;
  }
}

/// Adapter definition, should be passed to the Json Mapper initialization method:
///  initializeJsonMapper(adapters: [builtAdapter]);
final builtAdapter = JsonMapperAdapter(
    title: 'Built Collection Adapter',
    refUrl: 'https://pub.dev/packages/built_collection',
    url:
        'https://github.com/k-paxian/dart-json-mapper/tree/master/adapters/built',
    typeInfoDecorators: {
      0: builtTypeInfoDecorator
    },
    converters: {
      BuiltList: defaultIterableConverter,
      BuiltSet: defaultIterableConverter,
      BuiltMap: builtMapConverter,
    });
