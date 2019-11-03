library json_mapper.test;

import 'dart:typed_data';

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import 'package:dart_json_mapper/errors.dart';
import 'package:dart_json_mapper/json_mapper.dart';
import "package:fixnum/fixnum.dart";
import "package:test/test.dart";

import '_test.reflectable.dart';

part 'json.dart';
part 'model.dart';
part 'test.constructors.dart';
part 'test.converters.dart';
part 'test.errors.dart';
part 'test.integration.dart';
part 'test.partial.deserialization.dart';
part 'test.value.decorators.dart';

void main() {
  initializeReflectable();

  testErrorHandling();
  testConverters();
  testValueDecorators();
  testConstructors();
  testPartialDeserialization();
  testIntegration();
}
