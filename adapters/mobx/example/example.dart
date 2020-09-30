library json_mapper_mobx.example;

import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable, SerializationOptions;
import 'package:dart_json_mapper_mobx/dart_json_mapper_mobx.dart'
    show mobXAdapter;
import 'package:mobx/mobx.dart' show ObservableList;

import 'example.mapper.g.dart' show initializeReflectable;

@jsonSerializable
class MobX {
  ObservableList<String> mailingList = ObservableList<String>();

  MobX(this.mailingList);
}

void main() {
  initializeReflectable();
  JsonMapper().useAdapter(mobXAdapter);

  final m = MobX(
      ObservableList<String>.of(['aa@test.com', 'bb@test.com', 'cc@test.com']));
  final targetJson = JsonMapper.serialize(m, SerializationOptions(indent: ''));
  final instance = JsonMapper.deserialize<MobX>(targetJson);

  // Serialized object
  print(targetJson);

  // Deserialize object
  print(instance);
}
