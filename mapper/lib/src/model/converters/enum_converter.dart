import '../index.dart';

final enumConverter = EnumConverter();

/// Long converter for [enum] type
class EnumConverter implements ICustomConverter, ICustomEnumConverter {
  EnumConverter() : super();

  IEnumDescriptor? _enumDescriptor;

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    dynamic convert(value) => _enumDescriptor!.values.firstWhere(
        (eValue) => eValue.toString() == value.toString(),
        orElse: () => null);
    return jsonValue is Iterable
        ? jsonValue.map(convert).toList()
        : convert(jsonValue);
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    dynamic convert(value) => value.toString();
    return (object is Iterable)
        ? object.map(convert).toList()
        : convert(object);
  }

  @override
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor) {
    _enumDescriptor = enumDescriptor;
  }
}
