import '../index.dart';
import 'base_converter.dart';

const bigIntConverter = BigIntConverter();

/// [BigInt] converter
class BigIntConverter implements ICustomConverter {
  const BigIntConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is String ? BigInt.tryParse(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    return object is BigInt ? object.toString() : object;
  }
}