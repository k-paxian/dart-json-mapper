import 'dart:convert' show base64Decode, base64Encode;
import 'dart:typed_data' show Uint8List;

import '../index.dart';
import 'base_converter.dart';

const uint8ListConverter = Uint8ListConverter();

/// [Uint8List] converter to base64 and back
class Uint8ListConverter implements ICustomConverter {
  const Uint8ListConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is String ? base64Decode(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    return object is Uint8List ? base64Encode(object) : object;
  }
}
