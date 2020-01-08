import 'dart:typed_data' show Uint8List;

import '../utils.dart';

typedef ValueDecoratorFunction = dynamic Function(dynamic value);

Map<Type, ValueDecoratorFunction> getDefaultValueDecorators() {
  final result = {};
  // Dart built-in types
  // List
  result[typeOf<List<String>>()] = (value) => value.cast<String>();
  result[typeOf<List<DateTime>>()] = (value) => value.cast<DateTime>();
  result[typeOf<List<num>>()] = (value) => value.cast<num>();
  result[typeOf<List<int>>()] = (value) => value.cast<int>();
  result[typeOf<List<double>>()] = (value) => value.cast<double>();
  result[typeOf<List<bool>>()] = (value) => value.cast<bool>();
  result[typeOf<List<Symbol>>()] = (value) => value.cast<Symbol>();
  result[typeOf<List<BigInt>>()] = (value) => value.cast<BigInt>();

  // Set
  result[typeOf<Set<String>>()] = (value) => value.cast<String>();
  result[typeOf<Set<DateTime>>()] = (value) => value.cast<DateTime>();
  result[typeOf<Set<num>>()] = (value) => value.cast<num>();
  result[typeOf<Set<int>>()] = (value) => value.cast<int>();
  result[typeOf<Set<double>>()] = (value) => value.cast<double>();
  result[typeOf<Set<bool>>()] = (value) => value.cast<bool>();
  result[typeOf<Set<Symbol>>()] = (value) => value.cast<Symbol>();
  result[typeOf<Set<BigInt>>()] = (value) => value.cast<BigInt>();

  // Typed data
  result[typeOf<Uint8List>()] =
      (value) => Uint8List.fromList(value.cast<int>());
  return result.cast<Type, ValueDecoratorFunction>();
}
