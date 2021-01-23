library json_mapper_fixnum.example;

import 'package:built_collection/built_collection.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable;
import 'package:dart_json_mapper_built/dart_json_mapper_built.dart'
    show builtAdapter;

import 'example.mapper.g.dart' show initializeJsonMapper;

@jsonSerializable
class ImmutableClass {
  final BuiltList<int> list;

  const ImmutableClass(this.list);
}

void main() {
  initializeJsonMapper(adapters: [builtAdapter]);

  print(JsonMapper.serialize(ImmutableClass(BuiltList.of([1, 2, 3]))));
}
