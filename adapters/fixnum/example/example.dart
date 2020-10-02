library json_mapper_fixnum.example;

import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable, SerializationOptions;
import 'package:dart_json_mapper_fixnum/dart_json_mapper_fixnum.dart'
    show fixnumAdapter;
import 'package:fixnum/fixnum.dart' show Int32;

import 'example.mapper.g.dart' show initializeJsonMapper;

@jsonSerializable
class Int32IntData {
  Int32 int32;

  Int32IntData(this.int32);
}

void main() {
  initializeJsonMapper([fixnumAdapter]);

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
