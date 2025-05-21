import 'package:collection/collection.dart' show IterableExtension; // For firstWhereOrNull
import 'package:reflectable/reflectable.dart'
    show DeclarationMirror, MethodMirror, VariableMirror;

import 'model/index.dart'; // For TypeInfo, ClassInfo, ITypeInfoDecorator, ValueDecoratorFunction etc.

class TypeInfoProvider {
  // Dependencies provided by JsonMapper
  final Map<Type, ClassInfo> _classes;
  final Map<int, ITypeInfoDecorator> _typeInfoDecorators;
  final Map<Type, ValueDecoratorFunction> _valueDecorators;
  final Map<Type, dynamic> _enumValues;

  // Internal state
  final Map<Type, TypeInfo> _typeInfoCache = {};
  final Map<String, ClassInfo> _mixins = {};

  TypeInfoProvider({
    required Map<Type, ClassInfo> classes,
    required Map<int, ITypeInfoDecorator> typeInfoDecorators,
    required Map<Type, ValueDecoratorFunction> valueDecorators,
    required Map<Type, dynamic> enumValues,
  })  : _classes = classes,
        _typeInfoDecorators = typeInfoDecorators,
        _valueDecorators = valueDecorators,
        _enumValues = enumValues {
    // Initial build of mixins based on the provided classes
    _rebuildMixins();
  }

  void _rebuildMixins() {
    _mixins.clear();
    // Iterate over the values of the _classes map
    for (var classInfo in _classes.values) {
      if (classInfo.superClass != null) {
        final superClassInfo = ClassInfo.fromCache(classInfo.superClass!, _classes);
        if (superClassInfo.reflectedType != null) {
          // Use public getTypeInfo to ensure decorated TypeInfo is used for mixin check
          final superClassTypeInfo = getTypeInfo(superClassInfo.reflectedType!);
          if (superClassTypeInfo.isWithMixin && superClassTypeInfo.mixinTypeName != null) {
            _mixins[superClassTypeInfo.mixinTypeName!] = classInfo;
          }
        }
      }
    }
  }

  /// Clears only the TypeInfo cache. Mixins are rebuilt via onClassesUpdated.
  void clearCache() {
    _typeInfoCache.clear();
  }

  /// Call this method when the underlying _classes map in JsonMapper has been updated.
  /// This will rebuild mixins and clear the TypeInfo cache.
  void onClassesUpdated() {
    _rebuildMixins();
    _typeInfoCache.clear(); // TypeInfos might depend on mixins and class structure
  }

  TypeInfo getTypeInfo(Type type) {
    if (_typeInfoCache[type] != null) {
      return _typeInfoCache[type]!;
    }
    var result = TypeInfo(type);
    for (var decorator in _typeInfoDecorators.values) {
      decorator.init(_classes, _valueDecorators, _enumValues);
      result = decorator.decorate(result);
    }
    // Check if this type is a mixin target and set mixinType if so
    if (_mixins[result.typeName] != null) {
      result.mixinType = _mixins[result.typeName]!.reflectedType;
    }
    _typeInfoCache[type] = result;
    return result;
  }

  TypeInfo getDeclarationTypeInfo(Type declarationType, Type? valueType) =>
      getTypeInfo((declarationType == dynamic && valueType != null)
          ? valueType
          : declarationType);

  Type getDeclarationType(DeclarationMirror mirror) {
    Type? result = dynamic;
    if (mirror is VariableMirror) {
      result = mirror.hasReflectedType ? mirror.reflectedType : null;
    } else if (mirror is MethodMirror) {
      result = mirror.hasReflectedReturnType ? mirror.reflectedReturnType : null;
    }
    return result ?? dynamic; // Ensure dynamic is returned if null
  }

  Type? getGenericParameterTypeByIndex(
          num parameterIndex, TypeInfo genericType) =>
      genericType.isGeneric &&
              genericType.parameters.length - 1 >= parameterIndex
          ? genericType.parameters.elementAt(parameterIndex as int)
          : null;

  Type? getTypeByStringName(String? typeName) {
    if (typeName == null) return null;
    // Using _classes.keys.firstWhereOrNull from package:collection
    return _classes.keys.firstWhereOrNull((t) => t.toString() == typeName);
   }
}
