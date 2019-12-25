library json_mapper_mobx.test;

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:dart_json_mapper_mobx/dart_json_mapper_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:test/test.dart';

import '_test.reflectable.dart';

part 'test.observables.dart';

void main() {
  initializeReflectable();
  initializeJsonMapperForMobX();

  testObservables();
}
