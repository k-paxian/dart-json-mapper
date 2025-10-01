import 'dart:convert' show JsonEncoder;

import '../index.dart';
import 'base_converter.dart';

const defaultConverter = DefaultConverter();

/// Default converter for all types
class DefaultConverter implements ICustomConverter {
  const DefaultConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    final jsonProperty = context.jsonPropertyMeta;
    final typeInfo = context.typeInfo;

    if (jsonProperty?.rawJson == true && typeInfo?.type == String) {
      if (jsonValue == null) {
        return null;
      }
      if (jsonValue is Map || jsonValue is List) {
        return JsonEncoder().convert(jsonValue);
      }
      return jsonValue.toString();
    } else {
      // If this DefaultConverter is specifically handling a String type (even if not rawJson)
      if (typeInfo?.type == String) {
        if (jsonValue == null) {
          return null;
        }
        // For non-rawJson strings, ensure it's robustly converted to string.
        // Original strict: return jsonValue as String?;
        return jsonValue.toString();
      }
      // Original pass-through logic for other types this DefaultConverter might handle
      return jsonValue;
    }
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) => object;
}
