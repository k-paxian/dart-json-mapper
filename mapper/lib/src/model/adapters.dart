import 'dart:collection'
    show
        HashSet,
        HashMap,
        LinkedHashMap,
        UnmodifiableListView,
        UnmodifiableMapView;
import 'dart:typed_data' show Uint8List;

// ignore_for_file: implementation_imports
import 'package:reflectable/reflectable.dart' show Reflectable;
import 'package:reflectable/src/reflectable_builder_based.dart'
    show ReflectorData;

import '../model/index.dart' show Enum;
import '../globals.dart';
import 'converters.dart';
import 'type_info.dart';
import 'value_decorators.dart';

/// Abstract contract class for JsonMapper adapters implementations
abstract class IJsonMapperAdapter {
  /// Brief adapter description / purpose
  String get title;

  /// URL to the adapter source code
  String get url;

  /// URL to the code/package which contains types this adapter is built for
  String? get refUrl;

  /// A Map of converter instances to be used for handling certain [Type]
  Map<Type, ICustomConverter> get converters;

  /// A Map of value decorator functions to be used for decorating [Type] instances
  /// during Deserialization process
  Map<Type, ValueDecoratorFunction> get valueDecorators;

  /// A Map of [Enum] descriptors. [Enum] as a key and value could be [Enum.values] or [EnumDescriptor]
  Map<Type, dynamic> get enumValues;

  /// A Map of [ITypeInfoDecorator] instances used to decorate an instance of [TypeInfo]
  /// using an array of decorators, in the order of priority given by the [int] key
  Map<int, ITypeInfoDecorator> get typeInfoDecorators;

  /// This mapping contains the mirror-data for each reflector.
  /// It will be initialized in the generated code.
  Map<Reflectable, ReflectorData>? get reflectableData;

  /// This mapping translates symbols to strings for the covered members.
  /// It will be initialized in the generated code.
  Map<Symbol, String>? get memberSymbolMap;

  /// [true] value declares the fact that this adapter has been built from
  /// code generation w/o manual interventions and it will be initialized with the first priority.
  bool get isGenerated;
}

/// Base class for JsonMapper adapters
class JsonMapperAdapter implements IJsonMapperAdapter {
  @override
  final String title;
  @override
  final String url;
  @override
  final String? refUrl;
  @override
  final Map<Type, ICustomConverter> converters;
  @override
  final Map<Type, ValueDecoratorFunction> valueDecorators;
  @override
  final Map<int, ITypeInfoDecorator> typeInfoDecorators;
  @override
  final Map<Type, dynamic> enumValues;
  @override
  final Map<Symbol, String>? memberSymbolMap;
  @override
  final Map<Reflectable, ReflectorData>? reflectableData;

  const JsonMapperAdapter(
      {this.converters = const {},
      this.valueDecorators = const {},
      this.typeInfoDecorators = const {},
      this.enumValues = const {},
      this.memberSymbolMap,
      this.reflectableData,
      this.title = 'JsonMapperAdapter',
      this.refUrl,
      this.url =
          'https://github.com/k-paxian/dart-json-mapper/tree/master/adapters'});

  @override
  String toString() => '$title : $url';

  @override
  bool get isGenerated => reflectableData != null;
}

/// Covers support for Dart core types
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
  typeOf<List<Uint8List>>(): (value) => value.cast<Uint8List>(),
});

/// Covers support for Dart collection types
final dartCollectionAdapter =
    JsonMapperAdapter(title: 'Dart Collection Adapter', converters: {
  UnmodifiableListView: defaultIterableConverter,
  HashSet: defaultIterableConverter,
  HashMap: mapConverter,
  LinkedHashMap: mapConverter,
  UnmodifiableMapView: mapConverter
});
