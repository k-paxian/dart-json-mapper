import 'package:reflectable/reflectable.dart';

import './value_decorators.dart';

/// Provides enhanced type information based on `Type.toString()` value
class TypeInfo {
  Type type;
  String typeName;

  Type scalarType;
  String scalarTypeName;

  Type genericType;

  Iterable<Type> parameters = []; // Type<T, K, V, etc.>

  bool isDynamic;
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

class DefaultTypeInfoDecorator implements ITypeInfoDecorator {
  Map<String, ClassMirror> _knownClasses;
  Iterable<Type> _valueDecoratorTypes;

  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    final type = typeInfo.type;
    final typeName = type != null ? type.toString() : '';

    typeInfo.typeName = typeName;
    typeInfo.isDynamic = typeName == 'dynamic';
    typeInfo.isList = typeName.indexOf('List<') == 0;
    typeInfo.isSet = typeName.indexOf('Set<') == 0;
    typeInfo.isMap = typeName.indexOf('Map<') == 0 ||
        typeName.indexOf('_InternalLinkedHashMap<') == 0;
    typeInfo.isIterable = typeInfo.isList || typeInfo.isSet;
    typeInfo.scalarType = detectScalarType(typeInfo);
    typeInfo.genericType = detectGenericType(typeInfo);

    if (typeName != null && _knownClasses[typeName] != null) {
      typeInfo.isEnum = _knownClasses[typeName].isEnum;
    }

    typeInfo.parameters =
        getTypeParams(typeInfo).map((typeName) => detectTypeByName(typeName));

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

  Type detectGenericType(TypeInfo typeInfo) {
    if (typeInfo.isList) {
      return List;
    }
    if (typeInfo.isSet) {
      return Set;
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
