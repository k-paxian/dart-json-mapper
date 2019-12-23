library json_mapper_mobx.example;

import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/json_mapper.dart';
import 'package:dart_json_mapper_mobx/dart_json_mapper_mobx.dart';
import 'package:mobx/mobx.dart';

import 'example.reflectable.dart'; // Import generated code.

@jsonSerializable
class MobX {
  ObservableList<String> mailingList = ObservableList<String>();

  MobX(this.mailingList);
}

void main() {
  initializeReflectable();
  initializeJsonMapperForMobX();

  final m = MobX(
      ObservableList<String>.of(['aa@test.com', 'bb@test.com', 'cc@test.com']));
  final targetJson = JsonMapper.serialize(m, '');
  final instance = JsonMapper.deserialize<MobX>(targetJson);

  // Serialized object
  print(targetJson);

  // Deserialize object
  print(instance);
}
