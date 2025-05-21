import 'dart:collection';

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

  /// Checks if the type is a core Dart type (e.g., String, int, bool).
  /// This logic might need refinement based on how "dart.core" types are identified.
  /// A simple check for common types might be more robust than `startsWith('dart.core.')`
  /// if `Type.toString()` doesn't consistently include the library prefix.
  bool get isDartCoreType {
    // A more robust check might be needed if typeName doesn't always include 'dart.core.'
    // For example, checking against a list of known Dart core types.
    // However, if typeName is reliably like 'dart.core.String', this is fine.
    // Given the context, a simple check for common types is often used.
    if (typeName == null) return false;
    return typeName == 'String' ||
        typeName == 'int' ||
        typeName == 'double' ||
        typeName == 'bool' ||
        typeName == 'num' ||
        typeName == 'Null' || // Consider if Null should be a "core type" for this check
        typeName == 'Object' || // Object is a core type
        typeName == 'DateTime' || // DateTime is often treated as a core serializable type
        typeName == 'Duration' ||
        typeName == 'Symbol' ||
        typeName!.startsWith('List<') || // Also consider collections of core types if not handled by isList etc.
        typeName!.startsWith('Map<') ||
        typeName!.startsWith('Set<') ||
        typeName == 'dynamic'; // dynamic is a core concept
  }


  @override
  bool operator ==(Object other) => hashCode == other.hashCode;

  @override
  String toString() =>
      'typeName: $typeName, parameters: $parameters, genericType: ${genericType.runtimeType}';

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
  late Map<Type, dynamic> _enumValues;
  late Map<String, Type> _simpleTypesByName;
  late Map<String, Type> _knownClassesByName;
  late Map<String, Type> _valueDecoratorTypesByName;
  late Map<String, Type> _enumValuesByName;

  bool isBigInt(TypeInfo typeInfo) =>
      typeInfo.typeName == 'BigInt' || typeInfo.typeName == '_BigIntImpl';

  bool isRegExp(TypeInfo typeInfo) =>
      typeInfo.typeName == 'JSSyntaxRegExp' ||
      typeInfo.typeName == 'RegExp' ||
      typeInfo.typeName == '_RegExp';

  bool isUri(TypeInfo typeInfo) =>
      typeInfo.typeName == 'Uri' ||
      typeInfo.typeName == '_SimpleUri' ||
      typeInfo.typeName == '_Uri';

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
        typeName.startsWith('JSArray<') ||
        isUnmodifiableListView(typeInfo) ||
        isCastList(typeInfo);
    typeInfo.isSet = typeName.startsWith('_Set<') ||
        typeName.startsWith('Set<') ||
        isHashSet(typeInfo);
    typeInfo.isMap = typeName == '_JsonMap' ||
        typeName.startsWith('_Map<') ||
        typeName.startsWith('Map<') ||
        typeName.startsWith('IdentityMap<') ||
        typeName.startsWith('LinkedMap<') ||
        isHashMap(typeInfo) ||
        isLinkedHashMap(typeInfo) ||
        isUnmodifiableMapView(typeInfo);
    typeInfo.isIterable = typeInfo.isList || typeInfo.isSet;

    if (_knownClasses[type] != null) {
      typeInfo.isEnum = _knownClasses[type]!.classMirror.isEnum;
    } else {
      if (_enumValues[type] != null) {
        typeInfo.isEnum = true;
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

  String? detectGenericTypeName(TypeInfo typeInfo) => typeInfo.typeName!
          .contains('<')
      ? '${typeInfo.typeName!.substring(0, typeInfo.typeName!.indexOf('<'))}<${typeInfo.parameters.map((x) => 'dynamic').join(', ')}>'
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
    return _knownClassesByName[typeInfo.genericTypeName];
  }

  Type detectTypeByName(String? name) {
    if (name == null) {
      return dynamic;
    }

    return _simpleTypesByName[name] ??
        _knownClassesByName[name] ??
        _valueDecoratorTypesByName[name] ??
        _enumValuesByName[name] ??
        dynamic;
  }

  @override
  void init(
      Map<Type, ClassInfo> knownClasses,
      Map<Type, ValueDecoratorFunction> valueDecorators,
      Map<Type, dynamic> enumValues) {
    _knownClasses = knownClasses;
    _enumValues = enumValues;
    _simpleTypesByName = {
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

    _knownClassesByName = {
      for (var kvp in knownClasses.entries) kvp.key.toString(): kvp.key
    };
    _valueDecoratorTypesByName = {
      for (var type in valueDecorators.keys) type.toString(): type
    };
    _enumValuesByName = {
      for (var kvp in enumValues.entries) kvp.key.toString(): kvp.key
    };
  }
}
