import 'package:reflectable/reflectable.dart';

import 'converters.dart';
import 'name_casing.dart';
import 'value_decorators.dart';

/// [jsonConstructor] is used as a shorthand metadata w/o "()"
const jsonConstructor = JsonConstructor();

/// [JsonConstructor] is used as metadata, to annotate specific Dart class constructor
/// being used for deserialization
class JsonConstructor {
  /// Scheme marker to associate this meta information with particular mapping scheme
  final dynamic scheme;

  const JsonConstructor({this.scheme});
}

/// [Json] is used as metadata, to annotate Dart class as top level Json object
class Json {
  /// Defines RFC 6901 JSON [pointer]
  /// Denotes the json Object root name/path to be used for mapping
  /// Example:  name: 'foo'
  ///           name: 'bar'
  ///           name: 'foo/bar/baz'
  ///           name: '#/foo/0/baz'
  final String name;

  /// Declares necessity for annotated class and all its subclasses to dump their own type name to the
  /// custom named json property.
  final String typeNameProperty;

  /// The most popular ways to combine words into a single string
  /// Based on assumption: That all Dart class fields initially
  /// given as CaseStyle.Camel
  final CaseStyle caseStyle;

  /// Provides a way to specify enum values, via Dart built in
  /// capability for all Enum instances. `Enum.values`
  final List<dynamic> enumValues;

  /// Null class members
  /// will be excluded from serialization process
  final bool ignoreNullMembers;

  /// Process only annotated class members
  final bool processAnnotatedMembersOnly;

  /// Allow circular object references during serialization
  /// for annotated class. Presume You know what you are doing
  final int allowCircularReferences;

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
  final Map<Type, ValueDecoratorFunction> Function() valueDecorators;

  /// Scheme marker to associate this meta information with particular mapping scheme
  final dynamic scheme;

  const Json(
      {this.allowCircularReferences,
      this.valueDecorators,
      this.scheme,
      this.enumValues,
      this.typeNameProperty,
      this.caseStyle,
      this.ignoreNullMembers,
      this.processAnnotatedMembersOnly,
      this.name});
}

/// [jsonProperty] is used as a shorthand metadata w/o "()"
const jsonProperty = JsonProperty();

/// [JsonProperty] is used as metadata, for annotation of individual class fields
/// to fine tune Json property level.
class JsonProperty {
  /// Scheme marker to associate this meta information with particular mapping scheme
  final dynamic scheme;

  /// Defines RFC 6901 JSON [pointer]
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

  /// Final field default value
  final dynamic defaultValue;

  const JsonProperty(
      {this.scheme,
      this.name,
      this.ignore,
      this.ignoreIfNull,
      this.converter,
      this.enumValues,
      this.defaultValue,
      this.converterParams});

  bool isEnumType(Type enumType) =>
      enumValues != null && isEnumTypeForValues(enumType);

  /// Validate provided enumType against provided [enumValues]
  bool isEnumTypeForValues(Type enumType, [Iterable enumValuesList]) {
    final getEnumTypeNameFromString =
        (value) => value.toString().split('.').first;
    final enumValueTypeName = getEnumTypeNameFromString(enumType.toString());
    return enumType == dynamic ||
        (enumValues ?? enumValuesList).every(
            (item) => getEnumTypeNameFromString(item) == enumValueTypeName);
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
