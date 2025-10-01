import '../../globals.dart';
import '../../identifier_casing.dart';
import 'injectable_values.dart';

const defaultDeserializationOptions = DeserializationOptions();

/// Declares configuration parameters for Deserialization process
class DeserializationOptions {
  /// The most popular ways to combine words into a single string
  /// Based on assumption: That all Dart class fields initially
  /// given as [CaseStyle.camel]
  final CaseStyle? caseStyle;

  /// Scheme to be used
  final dynamic scheme;

  /// Process annotated class members only
  final bool? processAnnotatedMembersOnly;

  /// Template Instance
  /// - for Deserialization output it could be a typed `Iterable<T>`, or `Map<K, V>`, or else
  /// - for Serialization output it could be an instance of `Map<String, dynamic>`
  final dynamic template;

  /// A `Map<String, dynamic>` of injectable values to be used for direct injection
  final InjectableValues? injectableValues;

  /// Declares a fallback target type to deserialize to, when it's not possible to detect
  /// it from target type inference OR [template]
  final Type? type;

  const DeserializationOptions(
      {this.scheme,
      this.caseStyle,
      this.template,
      this.injectableValues,
      this.type,
      this.processAnnotatedMembersOnly});
}

const defaultSerializationOptions = SerializationOptions(indent: ' ');

/// Declares configuration parameters for Serialization process
/// fully includes [DeserializationOptions]
class SerializationOptions extends DeserializationOptions {
  /// JSON Indentation, usually it's just a string of [space] characters
  final String? indent;

  /// Null class members
  /// will be excluded from serialization process
  final bool? ignoreNullMembers;

  /// Class members having [JsonProperty.defaultValue]
  /// will be excluded from serialization process
  final bool? ignoreDefaultMembers;

  /// Class members having Unknown types
  /// will be excluded from serialization process
  /// Java Jackson's "@JsonIgnoreProperties(ignoreUnknown = true)"
  final bool? ignoreUnknownTypes;

  const SerializationOptions(
      {super.scheme,
      super.caseStyle,
      super.template,
      super.processAnnotatedMembersOnly,
      this.indent,
      this.ignoreNullMembers,
      this.ignoreDefaultMembers,
      this.ignoreUnknownTypes})
      : super();
}
