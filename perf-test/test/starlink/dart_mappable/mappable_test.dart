library perf_test.test;

import 'dart:convert' show json, JsonEncoder;
import 'dart:io' show File;

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as path;

import 'mappable_test.mapper.g.dart' show Mapper;

part './index.dart';
part './model.dart';

void main() async {
  print('\n>> dart_mappable');
  testStarlink(json.decode(
      await File(path.absolute('test/starlink/starlink.json')).readAsString()));
}
