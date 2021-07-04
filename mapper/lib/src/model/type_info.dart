import 'dart:collection';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:reflectable/reflectable.dart';

import './value_decorators.dart';

/// Provides enhanced type information based on `Type.toString()` value
class TypeInfo {
  Type? type;
  String? typeName;

  Type? scalarType;
  String? scalarTypeName;

  Type? genericType;
  String? genericTypeName;

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
      Map<String?, ClassMirror?> knownClasses,
      Map<Type, ValueDecoratorFunction> valueDecorators,
      Map<Type, dynamic> enumValues);
  TypeInfo decorate(TypeInfo typeInfo);
}

final defaultTypeInfoDecorator = DefaultTypeInfoDecorator();

// TODO: Split types detection over several decorators
class DefaultTypeInfoDecorator implements ITypeInfoDecorator {
  late Map<String?, ClassMirror?> _knownClasses;
  late Iterable<Type> _valueDecoratorTypes;
  late Map<Type, dynamic> _enumValues;

  bool isBigInt(TypeInfo typeInfo) =>
      typeInfo.typeName == 'BigInt' || typeInfo.typeName == '_BigIntImpl';

  bool isRegExp(TypeInfo typeInfo) =>
      typeInfo.typeName == 'RegExp' || typeInfo.typeName == '_RegExp';

  bool isUri(TypeInfo typeInfo) =>
      typeInfo.typeName == 'Uri' || typeInfo.typeName == '_SimpleUri';

  bool isHashSet(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('HashSet<') == 0 ||
      typeInfo.typeName!.indexOf('_HashSet<') == 0 ||
      typeInfo.typeName!.indexOf('_CompactLinkedHashSet<') == 0;

  bool isUnmodifiableListView(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('UnmodifiableListView<') == 0;

  bool isCastList(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('CastList<') == 0;

  bool isUnmodifiableMapView(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('UnmodifiableMapView<') == 0;

  bool isHashMap(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('HashMap<') == 0 ||
      typeInfo.typeName!.indexOf('_HashMap<') == 0;

  bool isLinkedHashMap(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('_LinkedHashMap<') == 0 ||
      typeInfo.typeName!.indexOf('_InternalLinkedHashMap<') == 0;

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
    typeInfo.isList = typeName.indexOf('List<') == 0 ||
        isUnmodifiableListView(typeInfo) ||
        isCastList(typeInfo);
    typeInfo.isSet = typeName.indexOf('Set<') == 0 || isHashSet(typeInfo);
    typeInfo.isMap = typeName.indexOf('Map<') == 0 ||
        isHashMap(typeInfo) ||
        isLinkedHashMap(typeInfo) ||
        isUnmodifiableMapView(typeInfo);
    typeInfo.isIterable = typeInfo.isList || typeInfo.isSet;
    typeInfo.scalarType = detectScalarType(typeInfo);
    typeInfo.genericType = detectGenericType(typeInfo);

    if (_knownClasses[typeName] != null) {
      typeInfo.isEnum = _knownClasses[typeName]!.isEnum;
    } else {
      if (_enumValues[type!] != null) {
        typeInfo.isEnum = _enumValues[type] != null;
      }
    }

    typeInfo.parameters =
        getTypeParams(typeInfo).map((typeName) => detectTypeByName(typeName));

    typeInfo.genericTypeName = detectGenericTypeName(typeInfo);

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

  String? detectScalarTypeName(TypeInfo typeInfo) => typeInfo.isIterable
      ? RegExp('<(.+)>').allMatches(typeInfo.typeName!).first.group(1)
      : null;

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
    return null;
  }

  Type detectTypeByName(String? name) {
    switch (name) {
      case 'DateTime':
        return DateTime;
      case 'num':
        return num;
      case 'int':
        return int;
      case 'double':
        return double;
      case 'Duration':
        return Duration;
      case 'BigInt':
        return BigInt;
      case 'bool':
        return bool;
      case 'String':
        return String;
      case 'Symbol':
        return Symbol;
      default:
        if (_knownClasses[name] != null) {
          return _knownClasses[name]!.reflectedType;
        }
        final resultFromDecorators =
            _valueDecoratorTypes.firstWhereOrNull((t) => t.toString() == name);
        final resultFromEnums =
            _enumValues.keys.firstWhereOrNull((t) => t.toString() == name);
        return resultFromDecorators ?? resultFromEnums ?? dynamic;
    }
  }

  Type detectScalarType(TypeInfo typeInfo) {
    typeInfo.scalarTypeName = detectScalarTypeName(typeInfo);
    return detectTypeByName(typeInfo.scalarTypeName);
  }

  @override
  void init(
      Map<String?, ClassMirror?> knownClasses,
      Map<Type, ValueDecoratorFunction> valueDecorators,
      Map<Type, dynamic> enumValues) {
    _knownClasses = knownClasses;
    _valueDecoratorTypes = valueDecorators.keys;
    _enumValues = enumValues;
  }
}
