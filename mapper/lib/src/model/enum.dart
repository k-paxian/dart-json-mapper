/// Virtual class
/// Used as a generic reference to all Enum based types
/// enum ABC {A, B, C}, etc.
abstract class Enum {}

/// Enum descriptor, defines Enum possible values, mappings, defaultValue, case sensitivity, etc
abstract class IEnumDescriptor {
  Iterable values = [];
  dynamic defaultValue;
  bool? caseInsensitive;
  Map mapping = {};
}

/// Enum descriptor, defines Enum possible values, mappings, defaultValue, case sensitivity, etc
class EnumDescriptor implements IEnumDescriptor {
  /// Defines a mapping for enum values, key is the enum value, value is the target mapping value
  /// Example:
  /// EnumDescriptor(
  ///           values: RecordType.values,
  ///           mapping: <RecordType, String>{
  ///             RecordType.asset: 'Asset',
  ///             RecordType.series: 'Series'
  ///           })
  @override
  Map mapping;

  /// Defines possible enum values
  /// Example:
  /// EnumDescriptor(values: RecordType.values)
  @override
  Iterable values;

  /// Defines possible enum values
  /// Example:
  /// EnumDescriptor(defaultValue: RecordType.asset)
  @override
  dynamic defaultValue;

  /// Defines case sensitivity for string based enum values
  /// Example:
  /// EnumDescriptor(values: RecordType.values, caseInsensitive: true)
  @override
  bool? caseInsensitive;

  EnumDescriptor(
      {this.values = const [],
      this.mapping = const {},
      this.defaultValue,
      this.caseInsensitive});
}
