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
  final Map<Type, bool Function(TypeInfo)> _collectionTypePredicates = {
    BuiltList: (TypeInfo typeInfo) =>
        typeInfo.typeName!.startsWith('_BuiltList<') ||
        typeInfo.typeName!.startsWith('BuiltList<'),
    BuiltMap: (TypeInfo typeInfo) =>
        typeInfo.typeName!.startsWith('_BuiltMap<') ||
        typeInfo.typeName!.startsWith('BuiltMap<'),
    BuiltSet: (TypeInfo typeInfo) =>
        typeInfo.typeName!.startsWith('_BuiltSet<') ||
        typeInfo.typeName!.startsWith('BuiltSet<'),
  };

  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    typeInfo = super.decorate(typeInfo);
    typeInfo.isList =
        typeInfo.isList || _collectionTypePredicates[BuiltList]!(typeInfo);
    typeInfo.isSet =
        typeInfo.isSet || _collectionTypePredicates[BuiltSet]!(typeInfo);
    typeInfo.isMap =
        typeInfo.isMap || _collectionTypePredicates[BuiltMap]!(typeInfo);
    typeInfo.isIterable =
        typeInfo.isIterable || typeInfo.isList || typeInfo.isSet;
    typeInfo.genericType = detectGenericType(typeInfo);
    return typeInfo;
  }

  @override
  Type? detectGenericType(TypeInfo typeInfo) {
    for (var entry in _collectionTypePredicates.entries) {
      if (entry.value(typeInfo)) {
        return entry.key;
      }
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
  dynamic fromJSON(dynamic jsonValue, DeserializationContext context) {
    if (context.typeInfo != null && jsonValue is Map) {
      return jsonValue.map((key, value) => MapEntry(
          _deserializeObject(key, context, context.typeInfo!.parameters.first),
          _deserializeObject(
              value, context, context.typeInfo!.parameters.last)));
    }
    return jsonValue;
  }

  @override
  dynamic toJSON(dynamic object, SerializationContext context) =>
      (object as BuiltMap).toMap().map((key, value) => MapEntry(
          _serializeObject(key, context).toString(),
          _serializeObject(value, context)));

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