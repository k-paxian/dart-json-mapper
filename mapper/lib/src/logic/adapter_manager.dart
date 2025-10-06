import 'dart:math';
import 'package:dart_json_mapper/src/model/index.dart';

class AdapterManager {
  final Map<int, IJsonMapperAdapter> _adapters = {};

  void use(IJsonMapperAdapter adapter, [int? priority]) {
    if (_adapters.containsValue(adapter)) {
      return;
    }
    final nextPriority = priority ??
        (_adapters.keys.isNotEmpty
            ? _adapters.keys.reduce((value, item) => max(value, item)) + 1
            : 0);
    _adapters[nextPriority] = adapter;
  }

  void remove(IJsonMapperAdapter adapter) {
    _adapters.removeWhere((priority, x) => x == adapter);
  }

  void info() =>
      _adapters.forEach((priority, adapter) => print('$priority : $adapter'));

  void enumerate(Function visitor) {
    final sortedKeys = _adapters.keys.toList()..sort();
    final sortedAdapters = sortedKeys.map((key) => _adapters[key]!);
    final generatedAdapters =
        sortedAdapters.where((adapter) => adapter.isGenerated);
    final otherAdapters =
        sortedAdapters.where((adapter) => !adapter.isGenerated);
    for (var adapter in [...generatedAdapters, ...otherAdapters]) {
      visitor(adapter);
    }
  }

  Map<Type, dynamic> get allEnumValues {
    final result = <Type, dynamic>{};
    for (var adapter in _adapters.values) {
      result.addAll(adapter.enumValues);
    }
    return result;
  }

  Map<Type, ICustomConverter> get allConverters {
    final result = <Type, ICustomConverter>{};
    for (var adapter in _adapters.values) {
      result.addAll(adapter.converters);
    }
    return result;
  }

  Map<Type, ValueDecoratorFunction> allValueDecorators(
      Map<Type, ValueDecoratorFunction> inlineDecorators) {
    final result = <Type, ValueDecoratorFunction>{};
    result.addAll(inlineDecorators);
    for (var adapter in _adapters.values) {
      result.addAll(adapter.valueDecorators);
    }
    return result;
  }

  Map<int, ITypeInfoDecorator> get allTypeInfoDecorators {
    final result = <int, ITypeInfoDecorator>{};
    for (var adapter in _adapters.values) {
      result.addAll(adapter.typeInfoDecorators);
    }
    return result;
  }
}