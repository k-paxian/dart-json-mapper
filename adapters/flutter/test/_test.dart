library json_mapper_flutter.test;

import 'dart:ui';

import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable, SerializationOptions;
import 'package:dart_json_mapper_flutter/dart_json_mapper_flutter.dart'
    show flutterAdapter;
import 'package:flutter_test/flutter_test.dart';

import '_test.mapper.g.dart' show initializeJsonMapper;

part 'test.basics.dart';

void main() {
  initializeJsonMapper(adapters: [flutterAdapter]).info();

  testBasics();
}
