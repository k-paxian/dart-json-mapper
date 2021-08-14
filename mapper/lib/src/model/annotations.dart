import 'package:meta/meta_meta.dart';
import 'package:reflectable/reflectable.dart';

import 'converters.dart';
import 'name_casing.dart';
import 'value_decorators.dart';

/// [jsonConstructor] is used as a shorthand metadata w/o "()"
const jsonConstructor = JsonConstructor();

/// [JsonConstructor] is used as metadata, to annotate specific Dart class constructor
/// being used for deserialization
@Target({}) // should be [TargetKind.constructor] but it doesn't exists :(
class JsonConstructor {
  /// Scheme marker to associate this meta information with particular mapping scheme
  final dynamic scheme;

  const JsonConstructor({this.scheme});
}

/// [Json] is used as metadata, to annotate Dart class as top level Json object
@Target({TargetKind.classType})
class Json {
  /// Defines RFC 6901 JSON [pointer]
  /// Denotes the json Object root name/path to be used for mapping
  /// Example:  name: 'foo'
  ///           name: 'bar'
  ///           name: 'foo/bar/baz'
  ///           name: '#/foo/0/baz'
  final String? name;

  /// Defines a class property to be used as a source of truth for discrimination logic
  /// in a hierarchy of inherited classes. Usually used on annotation of [abstract] class
  final String? discriminatorProperty;

  /// Defines a custom override value for a discriminator
  /// Usually used on annotations of subclasses, to distinguish it from each other
  /// Default value: <Annotated class name>
  final dynamic discriminatorValue;

  /// The most popular ways to combine words into a single string
  /// Based on assumption: That all Dart class fields initially
  /// given as CaseStyle.camel
  final CaseStyle? caseStyle;

  /// Null class members
  /// will be excluded from serialization process
  /// unless [JsonProperty.required] or [JsonProperty.notNull] is given to `true`
  final bool? ignoreNullMembers;

  /// Class members having [JsonProperty.defaultValue]
  /// will be excluded from serialization process
  final bool? ignoreDefaultMembers;

  /// Process only annotated class members
  final bool? processAnnotatedMembersOnly;

  /// Allow circular object references during serialization
  /// for annotated class. Presume You know what you are doing
  final int? allowCircularReferences;

  /// Static function to return a Map of Inline value decorators
  ///
  /// @jsonSerializable
  /// class NoticeItem {}
  ///
  /// @Json(valueDecorators: NoticeList.valueDecorators)
  /// @jsonSerializable
  /// class NoticeList {
  ///   static Map<Type, ValueDecoratorFunction> valueDecorators() =>
  ///       <Type, ValueDecoratorFunction>{
  ///         typeOf<List<NoticeItem>>(): (value) => value.cast<NoticeItem>()
  ///       };
  ///
  ///   final List<NoticeItem> list;
  ///
  ///   const NoticeList(this.list);
  /// }
  ///
  final Map<Type, ValueDecoratorFunction> Function()? valueDecorators;

  /// Scheme marker to associate this meta information with particular mapping scheme
  final dynamic scheme;

  const Json(
      {this.allowCircularReferences,
      this.valueDecorators,
      this.scheme,
      this.discriminatorProperty,
      this.discriminatorValue,
      this.caseStyle,
      this.ignoreNullMembers,
      this.ignoreDefaultMembers,
      this.processAnnotatedMembersOnly,
      this.name});
}

/// [jsonProperty] is used as a shorthand metadata w/o "()"
const jsonProperty = JsonProperty();

/// [JsonProperty] is used as metadata, for annotation of individual class fields
/// to fine tune & configure Json property level.
@Target({
  TargetKind.field,
  TargetKind.method,
  TargetKind.parameter,
  TargetKind.getter,
  TargetKind.setter
})
class JsonProperty {
  /// Scheme marker to associate this meta information with particular mapping scheme
  final dynamic scheme;

  /// Defines RFC 6901 JSON [pointer]
  /// Denotes the json property name/path/aliases to be used for mapping to the annotated field
  /// Example:  name: 'foo'
  ///           name: 'bar'
  ///           name: 'foo/bar/baz'
  ///           name: '../foo'
  ///           name: ['foo', 'bar', 'baz']  'foo' - primary, 'bar', 'baz' - aliases
  final dynamic name;

  /// Defines an optional message to be thrown as an explanation to why is
  /// this field needs to be provided in incoming JSON payload object
  /// If this message is provided it's treated as if [required] is set to `true`
  final String? requiredMessage;

  /// Defines an optional message to be thrown as an explanation to why is
  /// this field needs to be not NULL in incoming JSON payload object
  /// If this message is provided it's treated as if [notNull] is set to `true`
  final String? notNullMessage;

  /// Declares custom converter instance, to be used for annotated field
  /// serialization / deserialization
  final ICustomConverter? converter;

  /// Map of parameters to be passed to the converter instance
  final Map? converterParams;

  /// Declares annotated field as required for serialization / deserialization process
  /// i.e needs to be present explicitly in incoming JSON payload object
  /// Optional custom message [requiredMessage] could be provided as well
  /// Mild obligation
  /// If set to `true` states of [ignore], [ignoreForDeserialization],
  /// [ignoreForSerialization], [ignoreIfNull], [Json.ignoreNullMembers] has no meaning.
  final bool? required;

  /// Declares annotated field as NOT NULL for serialization / deserialization process
  /// i.e needs to be present in incoming JSON payload object as not NULL value
  /// Optional custom message [notNullMessage] could be provided as well
  /// Strict obligation
  /// If set to `true` states of [required], [ignore], [ignoreForDeserialization],
  /// [ignoreForSerialization], [ignoreIfNull], [Json.ignoreNullMembers] has no meaning.
  final bool? notNull;

  /// Declares annotated field to be directly injected from [DeserializationOptions.injectableValues]
  /// during deserialization process
  final bool? inject;

  /// Declares annotated field as ignored so it will be excluded from
  /// serialization / deserialization process
  final bool? ignore;

  /// Declares annotated field as excluded from serialization process
  final bool? ignoreForSerialization;

  /// Declares annotated field as excluded from deserialization process
  final bool? ignoreForDeserialization;

  /// Declares annotated field as ignored if it's value is null so it
  /// will be excluded from serialization process
  final bool? ignoreIfNull;

  /// Declares annotated field as ignored if it's value is [JsonProperty.defaultValue] so it
  /// will be excluded from serialization process
  final bool? ignoreIfDefault;

  /// Declares annotated field to be flattened and merged with the host object
  final bool? flatten;

  /// Final field default value
  final dynamic defaultValue;

  const JsonProperty(
      {this.scheme,
      this.name,
      this.required,
      this.notNull,
      this.ignore,
      this.inject,
      this.flatten,
      this.requiredMessage,
      this.notNullMessage,
      this.ignoreForSerialization,
      this.ignoreForDeserialization,
      this.ignoreIfNull,
      this.ignoreIfDefault,
      this.converter,
      this.defaultValue,
      this.converterParams});

  static const parentReference = '..';

  /// [name] is referencing Parent object itself OR it's fields,
  /// by default this means that [ignoreForSerialization] is treated as true
  static bool hasParentReference(JsonProperty? jsonProperty) =>
      jsonProperty != null &&
      (jsonProperty.name != null &&
          jsonProperty.name.toString().contains(parentReference));

  static bool isDefaultValue(JsonProperty? jsonProperty, dynamic value) =>
      jsonProperty != null && (jsonProperty.defaultValue == value);

  static bool isRequired(JsonProperty? jsonProperty) =>
      jsonProperty != null &&
      (jsonProperty.required == true || jsonProperty.requiredMessage != null);

  static bool isNotNull(JsonProperty? jsonProperty) =>
      jsonProperty != null &&
      (jsonProperty.notNull == true || jsonProperty.notNullMessage != null);

  static String? getPrimaryName(JsonProperty? jsonProperty) =>
      jsonProperty != null
          ? jsonProperty.name is Iterable && jsonProperty.name.isNotEmpty
              ? jsonProperty.name.first
              : jsonProperty.name
          : null;

  static List<String>? getAliases(JsonProperty? jsonProperty) =>
      jsonProperty != null &&
              jsonProperty.name is Iterable &&
              jsonProperty.name.length > 1
          ? jsonProperty.name
              .where((x) => x != getPrimaryName(jsonProperty))
              .toList()
              .cast<String>()
          : [];
}

/// [jsonSerializable] is used for marking classes, mixins, enums as
/// serialization / deserialization capable targets
const jsonSerializable = JsonSerializable();

/// [JsonSerializable] is used for marking classes, mixins, enums as
/// serialization / deserialization capable targets
@Target({TargetKind.classType, TargetKind.mixinType, TargetKind.enumType})
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
