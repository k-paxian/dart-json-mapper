import '../index.dart';

const regExpConverter = RegExpConverter();

/// RegExp converter
class RegExpConverter implements ICustomConverter<RegExp?> {
  const RegExpConverter() : super();

  @override
  RegExp? fromJSON(dynamic jsonValue, DeserializationContext context) =>
      jsonValue is String ? RegExp(jsonValue) : jsonValue;

  @override
  dynamic toJSON(RegExp? object, SerializationContext context) =>
      object?.pattern;
}
