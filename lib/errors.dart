abstract class CircularReferenceError extends Error {
  factory CircularReferenceError(Object object) = _CircularReferenceErrorImpl;
}

class _CircularReferenceErrorImpl extends Error
    implements CircularReferenceError {
  final Object _object;

  _CircularReferenceErrorImpl(Object object) : _object = object;

  toString() => "Circular reference detected. ${_object.toString()}";
}

abstract class MissingAnnotationOnTypeError extends Error {
  factory MissingAnnotationOnTypeError(Type type) =
      _MissingAnnotationOnTypeErrorImpl;
}

class _MissingAnnotationOnTypeErrorImpl extends Error
    implements MissingAnnotationOnTypeError {
  final Type _type;

  _MissingAnnotationOnTypeErrorImpl(Type type) : _type = type;

  toString() =>
      "It seems your class '${_type.toString()}' has not been annotated "
      "with @jsonSerializable";
}

abstract class MissingEnumValuesError extends Error {
  factory MissingEnumValuesError(Type type) = _MissingEnumValuesErrorImpl;
}

class _MissingEnumValuesErrorImpl extends Error
    implements MissingEnumValuesError {
  final Type _type;

  _MissingEnumValuesErrorImpl(Type type) : _type = type;

  toString() => "It seems your Enum class field is missing annotation:\n"
      "@JsonProperty(enumValues: ${_type.toString()}.values)";
}

abstract class MissingTypeForDeserializationError extends Error {
  factory MissingTypeForDeserializationError() =
      _MissingTypeForDeserializationErrorImpl;
}

class _MissingTypeForDeserializationErrorImpl extends Error
    implements MissingTypeForDeserializationError {
  _MissingTypeForDeserializationErrorImpl() : super();

  toString() => "It seems you've omitted target Type for deserialization.\n"
      "You should call it like this: JsonMapper.deserialize<TargetType>(jsonString)\n"
      "OR Infere type via result variable like: TargetType target = JsonMapper.deserialize(jsonString)";
}
