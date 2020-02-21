import 'dart:typed_data' show Uint8List;

import '../utils.dart';
import 'converters.dart';
import 'type_info.dart';
import 'value_decorators.dart';

/// Abstract contract class for adapters implementations
abstract class IAdapter {
  String get title;
  String get url;
  String get refUrl;
  Map<Type, ICustomConverter> get converters;
  Map<Type, ValueDecoratorFunction> get valueDecorators;
  Map<int, ITypeInfoDecorator> get typeInfoDecorators;
}

/// Base class for JsonMapper adapters
class JsonMapperAdapter implements IAdapter {
  @override
  final String title;
  @override
  final String url;
  @override
  final String refUrl;
  @override
  final Map<Type, ICustomConverter> converters;
  @override
  final Map<Type, ValueDecoratorFunction> valueDecorators;
  @override
  final Map<int, ITypeInfoDecorator> typeInfoDecorators;

  const JsonMapperAdapter(
      {this.converters = const {},
      this.valueDecorators = const {},
      this.typeInfoDecorators = const {},
      this.title = 'JsonMapperAdapter',
      this.refUrl,
      this.url = 'https://github.com/k-paxian/dart-json-mapper'});

  @override
  String toString() => '$title : $url';
}

final defaultJsonMapperAdapter = JsonMapperAdapter(
    title: 'Default Embeded JsonMapper Adapter',
    typeInfoDecorators: {
      0: defaultTypeInfoDecorator
    },
    converters: {
      dynamic: defaultConverter,
      String: defaultConverter,
      bool: defaultConverter,
      Symbol: symbolConverter,
      DateTime: dateConverter,
      num: numberConverter,
      int: numberConverter,
      double: numberConverter,
      BigInt: bigIntConverter,
      List: defaultIterableConverter,
      Set: defaultIterableConverter,
      Uint8List: uint8ListConverter,
      typeOf<Map<String, dynamic>>(): mapStringDynamicConverter,
      typeOf<Map<String, String>>(): mapStringStringConverter,
    },
    valueDecorators: {
      typeOf<List<String>>(): (value) => value.cast<String>(),
      typeOf<List<DateTime>>(): (value) => value.cast<DateTime>(),
      typeOf<List<num>>(): (value) => value.cast<num>(),
      typeOf<List<int>>(): (value) => value.cast<int>(),
      typeOf<List<double>>(): (value) => value.cast<double>(),
      typeOf<List<bool>>(): (value) => value.cast<bool>(),
      typeOf<List<Symbol>>(): (value) => value.cast<Symbol>(),
      typeOf<List<BigInt>>(): (value) => value.cast<BigInt>(),
      typeOf<Set<String>>(): (value) => value.cast<String>(),
      typeOf<Set<DateTime>>(): (value) => value.cast<DateTime>(),
      typeOf<Set<num>>(): (value) => value.cast<num>(),
      typeOf<Set<int>>(): (value) => value.cast<int>(),
      typeOf<Set<double>>(): (value) => value.cast<double>(),
      typeOf<Set<bool>>(): (value) => value.cast<bool>(),
      typeOf<Set<Symbol>>(): (value) => value.cast<Symbol>(),
      typeOf<Set<BigInt>>(): (value) => value.cast<BigInt>(),
      typeOf<Uint8List>(): (value) => Uint8List.fromList(value.cast<int>()),
    });
