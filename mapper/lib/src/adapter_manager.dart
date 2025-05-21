import 'dart:math';

import 'model/index.dart'; // For IJsonMapperAdapter, ICustomConverter, ValueDecoratorFunction, ITypeInfoDecorator, JsonMapperAdapter

/// Manages the registration and centralized access to adapter-derived collections
/// like converters, enum values, and decorators.
class AdapterManager {
  /// Storage for registered adapters with their priorities.
  final Map<int, IJsonMapperAdapter> _adapters = {};

  // --- Computed collections from adapters ---
  Map<Type, dynamic> _computedEnumValues = {};
  Map<Type, ICustomConverter> _computedConverters = {};
  Map<Type, ValueDecoratorFunction> _computedValueDecorators = {};
  Map<int, ITypeInfoDecorator> _computedTypeInfoDecorators = {};

  /// Provides a consolidated map of enum values from all registered adapters.
  Map<Type, dynamic> get enumValues => _computedEnumValues;
  /// Provides a consolidated map of custom converters from all registered adapters.
  Map<Type, ICustomConverter> get converters => _computedConverters;
  /// Provides a consolidated map of value decorators from all registered adapters.
  Map<Type, ValueDecoratorFunction> get valueDecorators => _computedValueDecorators;
  /// Provides a consolidated map of type info decorators from all registered adapters.
  Map<int, ITypeInfoDecorator> get typeInfoDecorators => _computedTypeInfoDecorators;

  AdapterManager() {
    _rebuildAdapterDerivedCollections();
  }

  /// Rebuilds all derived collections (enumValues, converters, etc.)
  /// based on the current set of registered adapters.
  /// This method should be called whenever adapters are added or removed.
  void _rebuildAdapterDerivedCollections() {
    final newEnumValues = <Type, dynamic>{};
    final newConverters = <Type, ICustomConverter>{};
    final newValueDecorators = <Type, ValueDecoratorFunction>{};
    final newTypeInfoDecorators = <int, ITypeInfoDecorator>{};

    // Iterate through adapters by priority (implicitly by map iteration order if priorities are keys)
    // or sort them if necessary, though current JsonMapper logic just iterates.
    for (var adapter in _adapters.values) {
      newEnumValues.addAll(adapter.enumValues);
      newConverters.addAll(adapter.converters);
      newValueDecorators.addAll(adapter.valueDecorators);
      newTypeInfoDecorators.addAll(adapter.typeInfoDecorators);
    }

    _computedEnumValues = newEnumValues;
    _computedConverters = newConverters;
    _computedValueDecorators = newValueDecorators;
    _computedTypeInfoDecorators = newTypeInfoDecorators;
  }

  /// Registers an instance of [IJsonMapperAdapter] with the mapper engine.
  /// Adapters are meant to be used as pluggable extensions, widening
  /// the number of supported types to be seamlessly converted to/from JSON.
  void useAdapter(IJsonMapperAdapter adapter, [int? priority]) {
    if (_adapters.containsValue(adapter)) {
      return; // Avoid re-adding the same adapter instance
    }
    final nextPriority = priority ??
        (_adapters.keys.isNotEmpty
            // Determine the next available priority
            ? _adapters.keys.reduce((value, item) => max(value, item)) + 1
            : 0);
    _adapters[nextPriority] = adapter;
    _rebuildAdapterDerivedCollections();
  }

  /// De-registers a previously registered adapter.
  void removeAdapter(IJsonMapperAdapter adapter) {
    _adapters.removeWhere((priority, x) => x == adapter);
    _rebuildAdapterDerivedCollections();
  }

  /// Prints out the current adapter configuration to the console,
  /// listing registered adapters and their priorities.
  void info() =>
      _adapters.forEach((priority, adapter) => print('$priority : $adapter'));

  /// Enumerates adapter [IJsonMapperAdapter] instances using visitor pattern.
  /// Abstracts adapters ordering logic from consumers.
  /// This method was originally static in JsonMapper.
  static void enumerateAdapters(
      Iterable<JsonMapperAdapter> adapters, Function visitor) {
    final generatedAdapters = adapters.where((adapter) => adapter.isGenerated);
    final otherAdapters = adapters.where((adapter) => !adapter.isGenerated);
    // Process generated adapters first, then others
    for (var adapter in [...generatedAdapters, ...otherAdapters]) {
      visitor(adapter);
    }
  }
}
