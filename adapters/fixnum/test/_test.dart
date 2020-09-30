library json_mapper_fixnum.test;

import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, SerializationOptions, jsonSerializable;
import 'package:dart_json_mapper_fixnum/dart_json_mapper_fixnum.dart'
    show fixnumAdapter;
import 'package:fixnum/fixnum.dart' show Int32, Int64;
import 'package:test/test.dart';

import '_test.mapper.g.dart' show initializeReflectable;

part 'test.basics.dart';

void main() {
  initializeReflectable();
  JsonMapper().useAdapter(fixnumAdapter).info();

  testBasics();
}
