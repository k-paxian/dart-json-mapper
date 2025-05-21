import 'package:collection/collection.dart' show IterableExtension; // For firstWhereOrNull
import 'package:reflectable/reflectable.dart'
    show DeclarationMirror, MethodMirror, VariableMirror;

import 'model/index.dart'; // For TypeInfo, ClassInfo, ITypeInfoDecorator, ValueDecoratorFunction etc.

/// Provides centralized management and caching of [TypeInfo] objects
/// and related type resolution logic.
class TypeInfoProvider {
  // Dependencies provided by JsonMapper, holding the source of truth for class and adapter configurations.
  final Map<Type, ClassInfo> _classes;
  final Map<int, ITypeInfoDecorator> _typeInfoDecorators;
  final Map<Type, ValueDecoratorFunction> _valueDecorators;
  final Map<Type, dynamic> _enumValues;

  // Internal state
  /// Cache for resolved TypeInfo objects to avoid redundant computations.
  final Map<Type, TypeInfo> _typeInfoCache = {};
  /// Cache for mixin relationships, mapping mixin type name to the target ClassInfo.
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
    _rebuildMixins();
  }

  /// Rebuilds the internal `_mixins` map based on the current `_classes` data.
  /// This is necessary when class information changes (e.g., after adapters are updated).
  void _rebuildMixins() {
    _mixins.clear();
    for (var classInfo in _classes.values) {
      if (classInfo.superClass != null) {
        final superClassInfo = ClassInfo.fromCache(classInfo.superClass!, _classes);
        if (superClassInfo.reflectedType != null) {
          final superClassTypeInfo = getTypeInfo(superClassInfo.reflectedType!);
          if (superClassTypeInfo.isWithMixin && superClassTypeInfo.mixinTypeName != null) {
            _mixins[superClassTypeInfo.mixinTypeName!] = classInfo;
          }
        }
      }
    }
  }

  /// Clears the internal [TypeInfo] cache.
  void clearCache() {
    _typeInfoCache.clear();
  }

  /// Called when the main `_classes` map in JsonMapper is updated.
  /// This triggers a rebuild of mixin information and clears the TypeInfo cache.
  void onClassesUpdated() {
    _rebuildMixins();
    _typeInfoCache.clear(); 
  }

  /// Retrieves or computes the [TypeInfo] for a given [Type].
  /// Applies decorators and resolves mixin information.
  /// Results are cached for performance.
  TypeInfo getTypeInfo(Type type) {
    if (_typeInfoCache[type] != null) {
      return _typeInfoCache[type]!;
    }
    var result = TypeInfo(type);
    // Apply type info decorators
    for (var decorator in _typeInfoDecorators.values) {
      decorator.init(_classes, _valueDecorators, _enumValues);
      result = decorator.decorate(result);
    }
    // Resolve and apply mixin information
    if (_mixins[result.typeName] != null) {
      result.mixinType = _mixins[result.typeName]!.reflectedType;
    }
    _typeInfoCache[type] = result;
    return result;
  }

  /// Gets [TypeInfo] preferring the [valueType] if [declarationType] is dynamic.
  /// This is useful for resolving the most specific type information available.
  TypeInfo getDeclarationTypeInfo(Type declarationType, Type? valueType) =>
      getTypeInfo((declarationType == dynamic && valueType != null)
          ? valueType
          : declarationType);

  /// Extracts the reflected [Type] from a [DeclarationMirror].
  /// Handles both [VariableMirror] (for fields) and [MethodMirror] (for method return types).
  Type getDeclarationType(DeclarationMirror mirror) {
    Type? result = dynamic;
    if (mirror is VariableMirror) {
      result = mirror.hasReflectedType ? mirror.reflectedType : null;
    } else if (mirror is MethodMirror) {
      result = mirror.hasReflectedReturnType ? mirror.reflectedReturnType : null;
    }
    return result ?? dynamic; 
  }

  /// Retrieves a generic type parameter by its index from a generic [TypeInfo].
  /// Returns `null` if the type is not generic or the index is out of bounds.
  Type? getGenericParameterTypeByIndex(
          num parameterIndex, TypeInfo genericType) =>
      genericType.isGeneric &&
              genericType.parameters.length - 1 >= parameterIndex
          ? genericType.parameters.elementAt(parameterIndex as int)
          : null;

  /// Finds a [Type] by its string name from the known annotated classes.
  /// Returns `null` if no matching type is found.
  Type? getTypeByStringName(String? typeName) {
    if (typeName == null) return null;
    return _classes.keys.firstWhereOrNull((t) => t.toString() == typeName);
   }
}
