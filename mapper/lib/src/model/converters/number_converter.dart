import 'package:intl/intl.dart';

import '../index.dart';

const numberConverter = NumberConverter();

/// Default converter for [num] type
class NumberConverter extends BaseCustomConverter implements ICustomConverter {
  const NumberConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    final format = getNumberFormat(context.jsonPropertyMeta);
    return format != null && (jsonValue is String)
        ? getNumberFormat(context.jsonPropertyMeta)!.parse(jsonValue)
        : (jsonValue is String)
            ? num.tryParse(jsonValue) ?? jsonValue
            : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    final format = getNumberFormat(context.jsonPropertyMeta);
    return object != null && format != null
        ? getNumberFormat(context.jsonPropertyMeta)!.format(object)
        : (object is String)
            ? num.tryParse(object)
            : object;
  }

  NumberFormat? getNumberFormat([JsonProperty? jsonProperty]) {
    String? format = getConverterParameter('format', jsonProperty);
    return format != null ? NumberFormat(format) : null;
  }
}
