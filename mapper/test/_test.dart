library json_mapper.test;

import '_test.mapper.g.dart' show initializeJsonMapper;
import 'test.collections.dart';
import 'test.constructors.dart';
import 'test.converters.dart';
import 'test.enums.dart';
import 'test.errors.dart';
import 'test.generics.dart';
import 'test.inheritance.dart';
import 'test.integration.dart';
import 'test.name.casing.dart';
import 'test.name.path.dart';
import 'test.partial.deserialization.dart';
import 'test.scheme.dart';
import 'test.special.cases.dart';
import 'test.value.decorators.dart';

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
