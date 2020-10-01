library json_mapper.test;

import 'dart:collection'
    show HashSet, HashMap, UnmodifiableListView, UnmodifiableMapView;
import 'dart:typed_data';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import '_test.mapper.g.dart' show initializeJsonMapper;

part 'json.dart';
part 'model.dart';
part 'test.collections.dart';
part 'test.constructors.dart';
part 'test.converters.dart';
part 'test.enums.dart';
part 'test.errors.dart';
part 'test.generics.dart';
part 'test.inheritance.dart';
part 'test.integration.dart';
part 'test.name.casing.dart';
part 'test.name.path.dart';
part 'test.partial.deserialization.dart';
part 'test.scheme.dart';
part 'test.special.cases.dart';
part 'test.value.decorators.dart';

void main() {
  initializeJsonMapper().info();

  testScheme();
  testNameCasing();
  testErrorHandling();
  testConverters();
  testValueDecorators();
  testConstructors();
  testPartialDeserialization();
  testIntegration();
  testSpecialCases();
  testGenerics();
  testNamePath();
  testInheritance();
  testCollections();
  testEnums();
}
