library json_mapper_mobx.test;

import 'package:dart_json_mapper/dart_json_mapper.dart'
    show SerializationOptions, jsonSerializable, JsonMapper, Json;
import 'package:dart_json_mapper_mobx/dart_json_mapper_mobx.dart'
    show mobXAdapter;
import 'package:mobx/mobx.dart'
    show ObservableList, ObservableSet, ObservableMap, Observable;
import 'package:test/test.dart';

import '_test.reflectable.dart' show initializeReflectable;

part 'test.observables.dart';

void main() {
  initializeReflectable();
  JsonMapper().useAdapter(mobXAdapter).info();

  testObservables();
}
