library json_mapper.test;

import 'dart:typed_data';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import '_test.reflectable.dart' show initializeReflectable;

part 'json.dart';
part 'model.dart';
part 'test.constructors.dart';
part 'test.converters.dart';
part 'test.errors.dart';
part 'test.integration.dart';
part 'test.name.casing.dart';
part 'test.name.path.dart';
part 'test.partial.deserialization.dart';
part 'test.scheme.dart';
part 'test.special.cases.dart';
part 'test.value.decorators.dart';

void main() {
  initializeReflectable();

  testScheme();
  testNameCasing();
  testErrorHandling();
  testConverters();
  testValueDecorators();
  testConstructors();
  testPartialDeserialization();
  testIntegration();
  testSpecialCases();
  testNamePath();
}
