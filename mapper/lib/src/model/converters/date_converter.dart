import 'package:intl/intl.dart';

import '../index.dart';

const dateConverter = DateConverter();

/// Default converter for [DateTime] type
class DateConverter extends BaseCustomConverter implements ICustomConverter {
  const DateConverter() : super();

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    final format = getDateFormat(context.jsonPropertyMeta);

    if (jsonValue is String) {
      return format != null
          ? format.parse(jsonValue)
          : DateTime.parse(jsonValue);
    }

    return jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    final format = getDateFormat(context.jsonPropertyMeta);
    return format != null && object != null && object is! String
        ? format.format(object as DateTime)
        : (object is List)
            ? object.map((item) => item.toString()).toList()
            : object?.toString();
  }

  DateFormat? getDateFormat([JsonProperty? jsonProperty]) {
    String? format = getConverterParameter('format', jsonProperty);
    return format != null ? DateFormat(format) : null;
  }
}
