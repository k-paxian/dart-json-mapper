library json_mapper_fixnum.test;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/json_mapper.dart';
import 'package:dart_json_mapper_fixnum/dart_json_mapper_fixnum.dart';
import 'package:fixnum/fixnum.dart' show Int32, Int64;
import 'package:test/test.dart';

import '_test.reflectable.dart';

part 'test.basics.dart';

void main() {
  initializeReflectable();
  initializeJsonMapperForFixnum();

  testBasics();
}
