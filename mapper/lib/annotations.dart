library json_mapper.annotations;

import 'package:dart_json_mapper/converters.dart';
import 'package:reflectable/reflectable.dart';

typedef ValueDecoratorFunction = dynamic Function(dynamic value);

/// [Json] is used as metadata, to annotate Dart class as top level Json object
class Json {
  /// Denotes the json Object root name/path to be used for mapping
  /// Example:  name: 'foo'
  ///           name: 'bar'
  ///           name: 'foo/bar/baz'
  final String name;

  /// Declares necessity for annotated class and all it's subclasses to dump type name to
  /// custom named json property.
  final String typeNameProperty;

  /// Null class members
  /// will be excluded from serialization process
  final bool ignoreNullMembers;

  /// Allow circular object references during serialization
  /// for annotated class. Presume You know what you are doing
  final int allowCircularReferences;

  /// Scheme marker to associate this meta information with particular mapping scheme
  final dynamic scheme;

  const Json(
      {this.allowCircularReferences,
      this.scheme,
      this.typeNameProperty,
      this.ignoreNullMembers,
      this.name});
}

/// [JsonProperty] is used as metadata, for annotation of individual class fields
/// to fine tune Json property level.
class JsonProperty {
  /// Scheme marker to associate this meta information with particular mapping scheme
  final dynamic scheme;

  /// Denotes the json property name/path to be used for mapping to the annotated field
  /// Example:  name: 'foo'
  ///           name: 'bar'
  ///           name: 'foo/bar/baz'
  final String name;

  /// Declares custom converter instance, to be used for annotated field
  /// serialization / deserialization
  final ICustomConverter converter;

  /// Map of named parameters to be passed to the custom converter instance
  final Map<String, dynamic> converterParams;

  /// Declares annotated field as ignored so it will be excluded from
  /// serialization / deserialization process
  final bool ignore;

  /// Declares annotated field as ignored if it's value is null so it
  /// will be excluded from serialization / deserialization process
  final bool ignoreIfNull;

  /// Provides a way to specify enum values, via Dart built in
  /// capability for all Enum instances. `Enum.values`
  final List<dynamic> enumValues;

  const JsonProperty(
      {this.scheme,
      this.name,
      this.ignore,
      this.ignoreIfNull,
      this.converter,
      this.enumValues,
      this.converterParams});

  /// Validate provided enum values [enumValues] against provided value
  bool isEnumValuesValid(dynamic enumValue) {
    final getEnumTypeNameFromString =
        (value) => value.toString().split('.').first;
    final enumValueTypeName = getEnumTypeNameFromString(enumValue);
    return enumValues
        .every((item) => getEnumTypeNameFromString(item) == enumValueTypeName);
  }
}

/// [jsonSerializable] is used as shorthand metadata, marking classes targeted
/// for serialization / deserialization, w/o "()"
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
            typeRelationsCapability,
            declarationsCapability);
}
