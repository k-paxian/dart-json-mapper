import 'dart:math';

import 'model/index.dart'; // For IJsonMapperAdapter, ICustomConverter, ValueDecoratorFunction, ITypeInfoDecorator, JsonMapperAdapter

// For now, assuming these core adapters are added externally via useAdapter by JsonMapper itself.

class AdapterManager {
  final Map<int, IJsonMapperAdapter> _adapters = {};

  // Public getters for derived collections
  Map<Type, dynamic> _computedEnumValues = {};
  Map<Type, ICustomConverter> _computedConverters = {};
  Map<Type, ValueDecoratorFunction> _computedValueDecorators = {};
  Map<int, ITypeInfoDecorator> _computedTypeInfoDecorators = {};

  Map<Type, dynamic> get enumValues => _computedEnumValues;
  Map<Type, ICustomConverter> get converters => _computedConverters;
  Map<Type, ValueDecoratorFunction> get valueDecorators => _computedValueDecorators;
  Map<int, ITypeInfoDecorator> get typeInfoDecorators => _computedTypeInfoDecorators;

  AdapterManager() {
    _rebuildAdapterDerivedCollections(); // Initialize with empty collections
  }

  void _rebuildAdapterDerivedCollections() {
    final newEnumValues = <Type, dynamic>{};
    final newConverters = <Type, ICustomConverter>{};
    final newValueDecorators = <Type, ValueDecoratorFunction>{};
    final newTypeInfoDecorators = <int, ITypeInfoDecorator>{};

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

  /// Registers an instance of [IJsonMapperAdapter] with the mapper engine
  void useAdapter(IJsonMapperAdapter adapter, [int? priority]) {
    if (_adapters.containsValue(adapter)) {
      return;
    }
    final nextPriority = priority ??
        (_adapters.keys.isNotEmpty
            ? _adapters.keys.reduce((value, item) => max(value, item)) + 1
            : 0);
    _adapters[nextPriority] = adapter;
    _rebuildAdapterDerivedCollections();
  }

  /// De-registers previously registered adapter using [useAdapter] method
  void removeAdapter(IJsonMapperAdapter adapter) {
    _adapters.removeWhere((priority, x) => x == adapter);
    _rebuildAdapterDerivedCollections();
  }

  /// Prints out current mapper configuration to the console
  /// List of currently registered adapters and their priorities
  void info() =>
      _adapters.forEach((priority, adapter) => print('$priority : $adapter'));

  static void enumerateAdapters(
      Iterable<JsonMapperAdapter> adapters, Function visitor) {
    final generatedAdapters = adapters.where((adapter) => adapter.isGenerated);
    final otherAdapters = adapters.where((adapter) => !adapter.isGenerated);
    for (var adapter in [...generatedAdapters, ...otherAdapters]) {
      visitor(adapter);
    }
  }
}
