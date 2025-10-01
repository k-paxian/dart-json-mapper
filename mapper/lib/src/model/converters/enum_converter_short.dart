import 'package:collection/collection.dart' show IterableExtension;

import '../../identifier_casing.dart';
import '../index.dart';
import 'base_converter.dart';

final defaultEnumConverter = enumConverterShort;
final enumConverterShort = EnumConverterShort();

/// Default converter for [enum] type
class EnumConverterShort implements ICustomConverter, ICustomEnumConverter {
  EnumConverterShort() : super();

  IEnumDescriptor? _enumDescriptor;

  @override
  Object? fromJSON(dynamic jsonValue, DeserializationContext context) {
    dynamic transformDescriptorValue(value) =>
        _transformValue(value, context, doubleMapping: true);
    dynamic transformJsonValue(value) =>
        _transformValue(value, context, preTransform: true);
    dynamic convert(value) =>
        _enumDescriptor!.values.firstWhereOrNull((eValue) =>
            _enumDescriptor!.caseInsensitive == true
                ? transformJsonValue(value).toLowerCase() ==
                    transformDescriptorValue(eValue).toLowerCase()
                : transformJsonValue(value) ==
                    transformDescriptorValue(eValue)) ??
        _enumDescriptor!.defaultValue;
    return jsonValue is Iterable
        ? jsonValue.map(convert).toList()
        : convert(jsonValue);
  }

  @override
  dynamic toJSON(Object? object, SerializationContext context) {
    dynamic convert(value) =>
        value != null ? _transformValue(value, context) : null;
    return (object is Iterable)
        ? object.map(convert).toList()
        : convert(object);
  }

  @override
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor) {
    _enumDescriptor = enumDescriptor;
  }

  dynamic _transformValue(dynamic value, DeserializationContext context,
      {bool doubleMapping = false, bool preTransform = false}) {
    final mapping = {};
    mapping.addAll(_enumDescriptor!.mapping);
    if (context.jsonPropertyMeta != null &&
        context.jsonPropertyMeta!.converterParams != null) {
      mapping.addAll(context.jsonPropertyMeta!.converterParams!);
    }
    value = _mapValue(value, mapping);
    if (doubleMapping) {
      value = _mapValue(value, mapping);
    }
    if (value is String) {
      if (preTransform) {
        value = transformIdentifierCaseStyle(
            value, context.targetCaseStyle, context.sourceCaseStyle);
      }
      value = context.transformIdentifier(value);
    }
    return value;
  }

  dynamic _mapValue(dynamic value, Map mapping) => mapping.containsKey(value)
      ? mapping[value]
      : value.toString().split('.').last;
}