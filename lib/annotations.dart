library json_mapper.annotations;

import 'package:dart_json_mapper/converters.dart';
import "package:reflectable/reflectable.dart";

typedef ValueDecoratorFunction = dynamic Function(dynamic value);

/// [JsonProperty] is used as metadata, marking individual class fields for
/// fine tuned configuration parameters.
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

  @override
  String toString() {
    return "JsonProperty name: ${name}, "
        "ignore: ${ignore}, "
        "enumValues: ${enumValues}, "
        "converterParams: ${converterParams}, "
        "converter: ${converter}";
  }
}

/// [jsonSerializable] is used as shorthand metadata, marking classes for
/// serialization / deserialization, w/o "()"
const jsonSerializable = JsonSerializable();

final String DEFAULT_TYPE_NAME_PROPERTY = '@@type';

/// [JsonSerializable] is used as metadata, marking classes as
/// serialization / deserialization capable targets
class JsonSerializable extends Reflectable {
  /// Declares necessity for annotated class to dump type name to json property
  final bool includeTypeName;

  const JsonSerializable({this.includeTypeName})
      : super(
            instanceInvokeCapability,
            metadataCapability,
            reflectedTypeCapability,
            newInstanceCapability,
            declarationsCapability);
}
