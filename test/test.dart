library json_mapper.test;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/converters.dart';
import 'package:dart_json_mapper/errors.dart';
import 'package:dart_json_mapper/json_mapper.dart';
import "package:test/test.dart";

import 'test.reflectable.dart';

part 'json.dart';
part 'model.dart';
part 'test.converters.dart';
part 'test.errors.dart';
part 'test.integration.dart';

void main() {
  initializeReflectable();

  testErrorHandling();
  testConverters();
  testIntegration();
}
