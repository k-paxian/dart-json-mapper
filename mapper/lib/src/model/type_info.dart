import 'dart:collection';

import 'package:reflectable/reflectable.dart';

import './value_decorators.dart';

/// Provides enhanced type information based on `Type.toString()` value
class TypeInfo {
  Type type;
  String typeName;

  Type scalarType;
  String scalarTypeName;

  Type genericType;
  String genericTypeName;

  Iterable<Type> parameters = []; // Type<T, K, V, etc.>

  bool isDynamic;
  bool isGeneric;
  bool isMap;
  bool isList;
  bool isSet;
  bool isIterable;
  bool isEnum;

  TypeInfo(this.type);

  @override
  String toString() =>
      'typeName: $typeName, parameters: $parameters, genericType: ' +
      genericType.runtimeType.toString();
}

/// Abstract class for custom typeInfo decorator implementations
abstract class ITypeInfoDecorator {
  void init(Map<String, ClassMirror> knownClasses,
      Map<Type, ValueDecoratorFunction> valueDecorators);
  TypeInfo decorate(TypeInfo typeInfo);
}

final defaultTypeInfoDecorator = DefaultTypeInfoDecorator();

// TODO: Split types detection over several decorators
class DefaultTypeInfoDecorator implements ITypeInfoDecorator {
  Map<String, ClassMirror> _knownClasses;
  Iterable<Type> _valueDecoratorTypes;

  bool isBigInt(TypeInfo typeInfo) =>
      typeInfo.typeName == 'BigInt' || typeInfo.typeName == '_BigIntImpl';

  bool isHashSet(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('HashSet<') == 0;

  bool isUnmodifiableListView(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('UnmodifiableListView<') == 0;

  bool isUnmodifiableMapView(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('UnmodifiableMapView<') == 0;

  bool isHashMap(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('HashMap<') == 0 ||
      typeInfo.typeName.indexOf('_HashMap<') == 0;

  bool isLinkedHashMap(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('_LinkedHashMap<') == 0 ||
      typeInfo.typeName.indexOf('_InternalLinkedHashMap<') == 0;

  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    final type = typeInfo.type;
    final typeName = type != null ? type.toString() : '';

    typeInfo.typeName = typeName;
    typeInfo.isDynamic = typeName == 'dynamic';
    typeInfo.isList =
        typeName.indexOf('List<') == 0 || isUnmodifiableListView(typeInfo);
    typeInfo.isSet = typeName.indexOf('Set<') == 0 || isHashSet(typeInfo);
    typeInfo.isMap = typeName.indexOf('Map<') == 0 ||
        isHashMap(typeInfo) ||
        isLinkedHashMap(typeInfo) ||
        isUnmodifiableMapView(typeInfo);
    typeInfo.isIterable = typeInfo.isList || typeInfo.isSet;
    typeInfo.scalarType = detectScalarType(typeInfo);
    typeInfo.genericType = detectGenericType(typeInfo);

    if (typeName != null && _knownClasses[typeName] != null) {
      typeInfo.isEnum = _knownClasses[typeName].isEnum;
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

    return typeInfo;
  }

  Iterable<String> getTypeParams(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('<') > 0
          ? RegExp('<(.+)>')
              .allMatches(typeInfo.typeName)
              .first
              .group(1)
              .split(',')
              .map((x) => x.trim())
              .toList()
          : [];

  String detectScalarTypeName(TypeInfo typeInfo) => typeInfo.isIterable
      ? RegExp('<(.+)>').allMatches(typeInfo.typeName).first.group(1)
      : null;

  String detectGenericTypeName(
          TypeInfo typeInfo) =>
      typeInfo.typeName.contains('<')
          ? typeInfo.typeName.substring(0, typeInfo.typeName.indexOf('<')) +
              '<' +
              typeInfo.parameters.map((x) => 'dynamic').join(', ') +
              '>'
          : null;

  Type detectGenericType(TypeInfo typeInfo) {
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

  Type detectTypeByName(String name) {
    switch (name) {
      case 'DateTime':
        return DateTime;
      case 'num':
        return num;
      case 'int':
        return int;
      case 'double':
        return double;
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
          return _knownClasses[name].reflectedType;
        }
        return _valueDecoratorTypes.firstWhere((t) => t.toString() == name,
            orElse: () => dynamic);
    }
  }

  Type detectScalarType(TypeInfo typeInfo) {
    typeInfo.scalarTypeName = detectScalarTypeName(typeInfo);
    if (typeInfo.isDynamic) return dynamic;
    return detectTypeByName(typeInfo.scalarTypeName);
  }

  @override
  void init(Map<String, ClassMirror> knownClasses,
      Map<Type, ValueDecoratorFunction> valueDecorators) {
    _knownClasses = knownClasses;
    _valueDecoratorTypes = valueDecorators.keys;
  }
}
