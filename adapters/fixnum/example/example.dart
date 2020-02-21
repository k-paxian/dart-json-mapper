library json_mapper_fixnum.example;

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:dart_json_mapper_fixnum/dart_json_mapper_fixnum.dart';
import 'package:fixnum/fixnum.dart' show Int32;

import 'example.reflectable.dart'; // Import generated code.

@jsonSerializable
class Int32IntData {
  Int32 int32;

  Int32IntData(this.int32);
}

void main() {
  initializeReflectable();
  JsonMapper().useAdapter(fixnumAdapter);

  // given
  final rawString = '1234567890';
  final json = '{"int32":"${rawString}"}';

  // when
  final targetJson = JsonMapper.serialize(
      Int32IntData(Int32.parseInt(rawString)),
      SerializationOptions(indent: ''));

  // Serialized object
  print(targetJson);

  // when
  final target = JsonMapper.deserialize<Int32IntData>(json);

  // Deserialize object
  print(target.int32.toString());
}
