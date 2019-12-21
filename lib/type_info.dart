/// Provides enhanced type information based on `Type.toString()` value
class TypeInfo {
  Type type;
  String typeName;

  Type scalarType;
  String scalarTypeName;

  bool isDynamic;
  bool isMap;
  bool isList;
  bool isSet;
  bool isIterable;

  TypeInfo(this.type);
}

/// Abstract class for custom typeInfo decorator implementations
abstract class ITypeInfoDecorator {
  TypeInfo decorate(TypeInfo typeInfo);
}

final defaultTypeInfoDecorator = DefaultTypeInfoDecorator();

class DefaultTypeInfoDecorator implements ITypeInfoDecorator {
  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    final type = typeInfo.type;
    final typeName = type != null ? type.toString() : '';

    typeInfo.typeName = typeName;
    typeInfo.isDynamic = typeName == 'dynamic';
    typeInfo.isList = typeName.indexOf('List<') == 0;
    typeInfo.isSet = typeName.indexOf('Set<') == 0;
    typeInfo.isMap = typeName.indexOf('Map<') == 0;
    typeInfo.isIterable = typeInfo.isList || typeInfo.isSet;
    typeInfo.scalarType = detectScalarType(typeInfo);

    return typeInfo;
  }

  String detectScalarTypeName(TypeInfo typeInfo) => typeInfo.isIterable
      ? RegExp('<(.+)>')
          .allMatches(typeInfo.typeName)
          .first
          .group(0)
          .replaceAll('<', '')
          .replaceAll('>', '')
      : null;

  Type detectScalarType(TypeInfo typeInfo) {
    typeInfo.scalarTypeName = detectScalarTypeName(typeInfo);
    if (typeInfo.isDynamic) return dynamic;
    switch (typeInfo.scalarTypeName) {
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
        return null;
    }
  }
}
