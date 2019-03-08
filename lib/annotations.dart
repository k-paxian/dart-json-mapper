library json_mapper.annotations;

import 'package:dart_json_mapper/converters.dart';
import "package:reflectable/reflectable.dart";

typedef ValueDecoratorFunction = dynamic Function(dynamic value);

final String DEFAULT_TYPE_NAME_PROPERTY = '@@type';

/// [Json] is used as metadata, to annotate Dart class as top level Json object
class Json {
  /// Declares necessity for annotated class to dump type name to
  /// special json property. Please use [JsonMapper.typeNameProperty] to
  /// setup suitable json property name. [DEFAULT_TYPE_NAME_PROPERTY] by default.
  final bool includeTypeName;

  const Json({this.includeTypeName});
}

/// [JsonProperty] is used as metadata, for annotation of individual class fields
/// to fine tune Json property level.
class JsonProperty {
  /// Denotes the json property name to be used for mapping to the annotated field
  final String name;

  /// Declares custom converter instance, to be used for annotated field
  /// serialization / deserialization
  final ICustomConverter converter;

  /// Map of named parameters to be passed to the custom converter instance
  final Map<String, dynamic> converterParams;

  /// Decorate value before setting it to the new instance field during
  /// deserialization process.
  ///
  /// Most commonly used for casting List<dynamic> to List<T>
  final ValueDecoratorFunction valueDecoratorFunction;

  /// Declares annotated field as ignored so it will be excluded from
  /// serialization / deserialization process
  final bool ignore;

  /// Provides a way to specify enum values, via Dart built in
  /// capability for all Enum instances. `Enum.values`
  final List<dynamic> enumValues;

  const JsonProperty(
      {this.name,
      this.valueDecoratorFunction,
      this.ignore,
      this.converter,
      this.enumValues,
      this.converterParams});

  /// Validate provided enum values [enumValues] against provided value
  bool isEnumValuesValid(dynamic enumValue) {
    final getEnumTypeNameFromString =
        (value) => value.toString().split('.').first;
    final String enumValueTypeName = getEnumTypeNameFromString(enumValue);
    return this
        .enumValues
        .every((item) => getEnumTypeNameFromString(item) == enumValueTypeName);
  }
}

/// [jsonSerializable] is used as shorthand metadata, marking classes targeted for
/// serialization / deserialization, w/o "()"
const jsonSerializable = JsonSerializable();

/// [JsonSerializable] is used as metadata, marking classes as
/// serialization / deserialization capable targets
class JsonSerializable extends Reflectable {
  const JsonSerializable()
      : super(
            instanceInvokeCapability,
            metadataCapability,
            reflectedTypeCapability,
            newInstanceCapability,
            declarationsCapability);
}
