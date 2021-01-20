/// Virtual class
/// Used as a generic reference to all Enum based types
/// enum ABC {A, B, C}, etc.
abstract class Enum {}

/// Enum descriptor, values, mappings, etc
abstract class IEnumDescriptor {
  Iterable values;
  Map mapping;
}

/// EnumDescriptor
class EnumDescriptor implements IEnumDescriptor {
  @override
  Map mapping;

  @override
  Iterable values;

  EnumDescriptor({this.values, this.mapping});
}
