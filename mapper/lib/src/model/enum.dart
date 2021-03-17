/// Virtual class
/// Used as a generic reference to all Enum based types
/// enum ABC {A, B, C}, etc.
abstract class Enum {}

/// Enum descriptor, values, mappings, etc
abstract class IEnumDescriptor {
  Iterable? values;
  dynamic defaultValue;
  Map? mapping;
}

/// EnumDescriptor
class EnumDescriptor implements IEnumDescriptor {
  @override
  Map? mapping;

  @override
  Iterable? values;

  @override
  var defaultValue;

  EnumDescriptor({this.values, this.mapping, this.defaultValue});
}
