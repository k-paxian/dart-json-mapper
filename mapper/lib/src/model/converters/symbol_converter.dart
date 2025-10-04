import '../index.dart';

const symbolConverter = SymbolConverter();

/// Default converter for [Symbol] type
class SymbolConverter implements ICustomConverter {
  const SymbolConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is String ? Symbol(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    return object != null
        ? RegExp('"(.+)"').allMatches(object.toString()).first.group(1)
        : null;
  }
}
