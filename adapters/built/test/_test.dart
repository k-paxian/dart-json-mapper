library json_mapper_built.test;

import 'package:dart_json_mapper_built/dart_json_mapper_built.dart'
    show builtAdapter;

import '_test.mapper.g.dart' show initializeJsonMapper;
import 'test.basics.dart';

void main() {
  initializeJsonMapper(adapters: [builtAdapter]).info();

  testBasics();
}
