import '../index.dart';
import 'base_converter.dart';

const durationConverter = DurationConverter();

/// DurationConverter converter for [Duration] type
class DurationConverter implements ICustomConverter<Duration?> {
  const DurationConverter() : super();

  @override
  Duration? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is num
        ? Duration(microseconds: jsonValue as int)
        : jsonValue;
  }

  @override
  dynamic toJSON(Duration? object, SerializationContext context) {
    return object?.inMicroseconds;
  }
}
