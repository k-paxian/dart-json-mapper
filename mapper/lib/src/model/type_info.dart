import 'dart:collection';

import 'package:collection/collection.dart' show IterableExtension;

import './value_decorators.dart';
import '../utils.dart';

/// Provides enhanced type information based on `Type.toString()` value
class TypeInfo {
  Type? type;
  String? typeName;

  Type? genericType;
  String? genericTypeName;

  Type? mixinType;
  String? mixinTypeName;

  Iterable<Type> parameters = []; // Type<T, K, V, etc.>

  late bool isDynamic;
  late bool isGeneric;
  late bool isMap;
  late bool isList;
  late bool isSet;
  late bool isIterable;
  bool? isEnum;
  late bool isWithMixin;

  TypeInfo(this.type);

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;

  @override
  String toString() =>
      'typeName: $typeName, parameters: $parameters, genericType: ' +
      genericType.runtimeType.toString();

  @override
  int get hashCode => typeName.hashCode;
}

/// Abstract class for custom typeInfo decorator implementations
abstract class ITypeInfoDecorator {
  void init(
      Map<Type, ClassInfo> knownClasses,
      Map<Type, ValueDecoratorFunction> valueDecorators,
      Map<Type, dynamic> enumValues);
  TypeInfo decorate(TypeInfo typeInfo);
}

final defaultTypeInfoDecorator = DefaultTypeInfoDecorator();

// TODO: Split types detection over several decorators
class DefaultTypeInfoDecorator implements ITypeInfoDecorator {
  late Map<Type, ClassInfo> _knownClasses;
  late Iterable<Type> _valueDecoratorTypes;
  late Map<Type, dynamic> _enumValues;

  Map<String, Type>? _cacheSimpleTypesByName;
  Map<String, Type>? _cacheKnownClassesByName;
  Map<String, Type>? _cacheValueDecoratorTypesByName;
  Map<String, Type>? _cacheEnumValuesByName;

  bool isBigInt(TypeInfo typeInfo) =>
      typeInfo.typeName == 'BigInt' || typeInfo.typeName == '_BigIntImpl';

  bool isRegExp(TypeInfo typeInfo) =>
      typeInfo.typeName == 'RegExp' || typeInfo.typeName == '_RegExp';

  bool isUri(TypeInfo typeInfo) =>
      typeInfo.typeName == 'Uri' || typeInfo.typeName == '_SimpleUri';

  bool isHashSet(TypeInfo typeInfo) =>
      typeInfo.typeName!.startsWith('HashSet<') ||
      typeInfo.typeName!.startsWith('_HashSet<') ||
      typeInfo.typeName!.startsWith('_CompactLinkedHashSet<');

  bool isUnmodifiableListView(TypeInfo typeInfo) =>
      typeInfo.typeName!.startsWith('UnmodifiableListView<');

  bool isCastList(TypeInfo typeInfo) =>
      typeInfo.typeName!.startsWith('CastList<');

  bool isUnmodifiableMapView(TypeInfo typeInfo) =>
      typeInfo.typeName!.startsWith('UnmodifiableMapView<');

  bool isHashMap(TypeInfo typeInfo) =>
      typeInfo.typeName!.startsWith('HashMap<') ||
      typeInfo.typeName!.startsWith('_HashMap<');

  bool isLinkedHashMap(TypeInfo typeInfo) =>
      typeInfo.typeName!.startsWith('_LinkedHashMap<') ||
      typeInfo.typeName!.startsWith('_InternalLinkedHashMap<');

  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    final type = typeInfo.type;
    final typeName = type != null ? type.toString() : '';

    typeInfo.typeName = typeName;

    final mixinTypeNames = detectMixinTypeName(typeInfo);
    typeInfo.isWithMixin = mixinTypeNames.isNotEmpty;
    if (typeInfo.isWithMixin) {
      typeInfo.typeName = mixinTypeNames.first;
      typeInfo.mixinTypeName = mixinTypeNames.last;
    }

    typeInfo.isDynamic = typeName == 'dynamic';
    typeInfo.isList = typeName.startsWith('_GrowableList<') ||
        typeName.startsWith('List<') ||
        isUnmodifiableListView(typeInfo) ||
        isCastList(typeInfo);
    typeInfo.isSet = typeName.startsWith('Set<') || isHashSet(typeInfo);
    typeInfo.isMap = typeName.startsWith('Map<') ||
        isHashMap(typeInfo) ||
        isLinkedHashMap(typeInfo) ||
        isUnmodifiableMapView(typeInfo);
    typeInfo.isIterable = typeInfo.isList || typeInfo.isSet;

    if (_knownClasses[type] != null) {
      typeInfo.isEnum = _knownClasses[type]!.classMirror.isEnum;
    } else {
      if (_enumValues[type!] != null) {
        typeInfo.isEnum = _enumValues[type] != null;
      }
    }

    typeInfo.parameters =
        getTypeParams(typeInfo).map((typeName) => detectTypeByName(typeName));

    typeInfo.genericTypeName = detectGenericTypeName(typeInfo);
    typeInfo.genericType = detectGenericType(typeInfo);

    if (typeInfo.parameters.isNotEmpty) {
      typeInfo.isGeneric = true;
    }

    if (isBigInt(typeInfo)) {
      typeInfo.type = BigInt;
      typeInfo.genericType = BigInt;
    }

    if (isRegExp(typeInfo)) {
      typeInfo.type = RegExp;
      typeInfo.genericType = RegExp;
    }

    if (isUri(typeInfo)) {
      typeInfo.type = Uri;
      typeInfo.genericType = Uri;
    }

    return typeInfo;
  }

  Iterable<String> getTypeParams(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('<') > 0
          ? RegExp('<(.+)>')
              .allMatches(typeInfo.typeName!)
              .first
              .group(1)!
              .split(',')
              .map((x) => x.trim())
              .toList()
          : [];

  Iterable<String> detectMixinTypeName(TypeInfo typeInfo) {
    final mixinPattern = RegExp(r'Type(..(.+) with .(.+))');
    return mixinPattern.hasMatch(typeInfo.typeName!)
        ? mixinPattern.allMatches(typeInfo.typeName!).first.groups([2, 3]).map(
            (e) => e!.replaceAll('.', '').replaceAll(')', ''))
        : [];
  }

  String? detectGenericTypeName(TypeInfo typeInfo) =>
      typeInfo.typeName!.contains('<')
          ? typeInfo.typeName!.substring(0, typeInfo.typeName!.indexOf('<')) +
              '<' +
              typeInfo.parameters.map((x) => 'dynamic').join(', ') +
              '>'
          : null;

  Type? detectGenericType(TypeInfo typeInfo) {
    if (isUnmodifiableListView(typeInfo)) {
      return UnmodifiableListView;
    }
    if (typeInfo.isList) {
      return List;
    }
    if (isHashSet(typeInfo)) {
      return HashSet;
    }
    if (typeInfo.isSet) {
      return Set;
    }
    if (isHashMap(typeInfo)) {
      return HashMap;
    }
    if (isLinkedHashMap(typeInfo)) {
      return LinkedHashMap;
    }
    if (isUnmodifiableMapView(typeInfo)) {
      return UnmodifiableMapView;
    }
    if (typeInfo.isMap) {
      return Map;
    }
    return _knownClasses.keys.firstWhereOrNull(
        (Type key) => key.toString() == typeInfo.genericTypeName);
  }

  Type detectTypeByName(String? name) {
    if (name == null) {
      return dynamic;
    }

    if (_cacheKnownClassesByName == null) {
      _cacheSimpleTypesByName = {
        'DateTime': DateTime,
        'num': num,
        'int': int,
        'double': double,
        'Duration': Duration,
        'BigInt': BigInt,
        'bool': bool,
        'String': String,
        'Symbol': Symbol,
      };

      _cacheKnownClassesByName = {for (var kvp in _knownClasses.entries) kvp.key.toString(): kvp.key};
      _cacheValueDecoratorTypesByName = {for (var type in _valueDecoratorTypes) type.toString(): type};
      _cacheEnumValuesByName = {for (var kvp in _enumValues.entries) kvp.key.toString(): kvp.key};
    }
    return _cacheSimpleTypesByName![name] ??
        _cacheKnownClassesByName![name] ??
        _cacheValueDecoratorTypesByName![name] ??
        _cacheEnumValuesByName![name] ??
        dynamic;
  }

  @override
  void init(
      Map<Type, ClassInfo> knownClasses,
      Map<Type, ValueDecoratorFunction> valueDecorators,
      Map<Type, dynamic> enumValues) {
    _knownClasses = knownClasses;
    _valueDecoratorTypes = valueDecorators.keys;
    _enumValues = enumValues;

    _invalidateCache();
  }

  void _invalidateCache() {
    _cacheSimpleTypesByName = null;
    _cacheKnownClassesByName = null;
    _cacheValueDecoratorTypesByName = null;
    _cacheEnumValuesByName = null;
  }
}
