library json_mapper_flutter.test;

import 'dart:ui';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:dart_json_mapper_flutter/dart_json_mapper_flutter.dart'
    show flutterAdapter;
import 'package:test/test.dart';

import '_test.reflectable.dart' show initializeReflectable;

part 'test.basics.dart';

void main() {
  initializeReflectable();
  JsonMapper().useAdapter(flutterAdapter).info();

  testBasics();
}
