import '../index.dart';
import 'base_converter.dart';

const enumConverterNumeric = ConstEnumConverterNumeric();

/// Const wrapper for [EnumConverterNumeric]
class ConstEnumConverterNumeric
    implements ICustomConverter, ICustomEnumConverter {
  const ConstEnumConverterNumeric();

  @override
  Object? fromJSON(jsonValue, DeserializationContext context) =>
      _enumConverterNumeric.fromJSON(jsonValue, context);

  @override
  dynamic toJSON(object, SerializationContext context) =>
      _enumConverterNumeric.toJSON(object, context);

  @override
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor) {
    _enumConverterNumeric.setEnumDescriptor(enumDescriptor);
  }
}

final _enumConverterNumeric = EnumConverterNumeric();

/// Numeric index based converter for [enum] type
class EnumConverterNumeric implements ICustomConverter, ICustomEnumConverter {
  EnumConverterNumeric() : super();

  IEnumDescriptor? _enumDescriptor;

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue is int
        ? jsonValue < _enumDescriptor!.values.length && jsonValue >= 0
            ? (_enumDescriptor!.values as List)[jsonValue]
            : _enumDescriptor!.defaultValue
        : jsonValue;
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    final valueIndex = (_enumDescriptor!.values as List).indexOf(object);
    return valueIndex >= 0 ? valueIndex : _enumDescriptor!.defaultValue;
  }

  @override
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor) {
    _enumDescriptor = enumDescriptor;
  }
}