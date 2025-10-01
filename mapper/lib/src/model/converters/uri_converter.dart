import '../index.dart';
import 'base_converter.dart';

const uriConverter = UriConverter();

/// Uri converter
class UriConverter implements ICustomConverter<Uri?> {
  const UriConverter() : super();

  @override
  Uri? fromJSON(dynamic jsonValue, DeserializationContext context) =>
      jsonValue is String ? Uri.tryParse(jsonValue) : jsonValue;

  @override
  String? toJSON(Uri? object, SerializationContext context) =>
      object?.toString();
}