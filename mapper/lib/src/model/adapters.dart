import 'dart:collection'
    show
        HashSet,
        HashMap,
        LinkedHashMap,
        UnmodifiableListView,
        UnmodifiableMapView;
import 'dart:typed_data' show Uint8List;

import '../model/index.dart' show Enum;
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
  Map<Type, List> get enumValues;
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
  @override
  final Map<Type, List> enumValues;

  const JsonMapperAdapter(
      {this.converters = const {},
      this.valueDecorators = const {},
      this.typeInfoDecorators = const {},
      this.enumValues = const {},
      this.title = 'JsonMapperAdapter',
      this.refUrl,
      this.url = 'https://github.com/k-paxian/dart-json-mapper'});

  @override
  String toString() => '$title : $url';
}

final dartCoreAdapter =
    JsonMapperAdapter(title: 'Dart Core Adapter', typeInfoDecorators: {
  0: defaultTypeInfoDecorator
}, converters: {
  RegExp: regExpConverter,
  Uri: uriConverter,
  dynamic: defaultConverter,
  String: defaultConverter,
  bool: defaultConverter,
  Enum: defaultEnumConverter,
  Symbol: symbolConverter,
  DateTime: dateConverter,
  Duration: durationConverter,
  num: numberConverter,
  int: numberConverter,
  double: numberConverter,
  BigInt: bigIntConverter,
  List: defaultIterableConverter,
  Set: defaultIterableConverter,
  Map: mapConverter,
  Uint8List: uint8ListConverter
}, valueDecorators: {
  typeOf<Map<String, dynamic>>(): (value) => value.cast<String, dynamic>(),
  typeOf<List<Uri>>(): (value) => value.cast<Uri>(),
  typeOf<List<RegExp>>(): (value) => value.cast<RegExp>(),
  typeOf<List<String>>(): (value) => value.cast<String>(),
  typeOf<List<DateTime>>(): (value) => value.cast<DateTime>(),
  typeOf<List<Duration>>(): (value) => value.cast<Duration>(),
  typeOf<List<num>>(): (value) => value.cast<num>(),
  typeOf<List<int>>(): (value) => value.cast<int>(),
  typeOf<List<double>>(): (value) => value.cast<double>(),
  typeOf<List<bool>>(): (value) => value.cast<bool>(),
  typeOf<List<Symbol>>(): (value) => value.cast<Symbol>(),
  typeOf<List<BigInt>>(): (value) => value.cast<BigInt>(),
  typeOf<Set>(): (value) =>
      value is! Set && value is Iterable ? Set.from(value) : value,
  typeOf<Set<Uri>>(): (value) => value.cast<Uri>(),
  typeOf<Set<RegExp>>(): (value) => value.cast<RegExp>(),
  typeOf<Set<String>>(): (value) => value.cast<String>(),
  typeOf<Set<DateTime>>(): (value) => value.cast<DateTime>(),
  typeOf<Set<Duration>>(): (value) => value.cast<Duration>(),
  typeOf<Set<num>>(): (value) => value.cast<num>(),
  typeOf<Set<int>>(): (value) => value.cast<int>(),
  typeOf<Set<double>>(): (value) => value.cast<double>(),
  typeOf<Set<bool>>(): (value) => value.cast<bool>(),
  typeOf<Set<Symbol>>(): (value) => value.cast<Symbol>(),
  typeOf<Set<BigInt>>(): (value) => value.cast<BigInt>(),
  typeOf<Uint8List>(): (value) => Uint8List.fromList(value.cast<int>()),
});

final dartCollectionAdapter =
    JsonMapperAdapter(title: 'Dart Collection Adapter', converters: {
  UnmodifiableListView: defaultIterableConverter,
  HashSet: defaultIterableConverter,
  HashMap: mapConverter,
  LinkedHashMap: mapConverter,
  UnmodifiableMapView: mapConverter
});
