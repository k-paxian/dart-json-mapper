abstract class JsonMapperError extends Error {}

abstract class CircularReferenceError extends JsonMapperError {
  factory CircularReferenceError(Object object) = _CircularReferenceErrorImpl;
}

class _CircularReferenceErrorImpl extends JsonMapperError
    implements CircularReferenceError {
  final Object _object;

  _CircularReferenceErrorImpl(Object object) : _object = object;

  @override
  String toString() => 'Circular reference detected. ${_object.toString()}';
}

abstract class MissingAnnotationOnTypeError extends JsonMapperError {
  factory MissingAnnotationOnTypeError(Type type) =
      _MissingAnnotationOnTypeErrorImpl;
}

class _MissingAnnotationOnTypeErrorImpl extends JsonMapperError
    implements MissingAnnotationOnTypeError {
  final Type _type;

  _MissingAnnotationOnTypeErrorImpl(Type type) : _type = type;

  @override
  String toString() =>
      "It seems your class '${_type.toString()}' has not been annotated "
      'with @jsonSerializable';
}

abstract class MissingEnumValuesError extends JsonMapperError {
  factory MissingEnumValuesError(Type type) = _MissingEnumValuesErrorImpl;
}

class _MissingEnumValuesErrorImpl extends JsonMapperError
    implements MissingEnumValuesError {
  final Type _type;

  _MissingEnumValuesErrorImpl(Type type) : _type = type;

  @override
  String toString() => 'It seems your Enum class field is missing annotation:\n'
      '@JsonProperty(enumValues: ${_type.toString()}.values)';
}

abstract class InvalidEnumValueError extends JsonMapperError {
  factory InvalidEnumValueError(dynamic value, Iterable validValues) =
      _InvalidEnumValueErrorImpl;
}

class _InvalidEnumValueErrorImpl extends JsonMapperError
    implements InvalidEnumValueError {
  final dynamic _value;
  final Iterable _validValues;

  _InvalidEnumValueErrorImpl(dynamic value, Iterable validValues)
      : _value = value,
        _validValues = validValues;

  @override
  String toString() => 'Invalid Enum value: "${_value.toString()}" detected,\n'
      'it should be one of: ${_validValues.toString()}';
}

abstract class MissingTypeForDeserializationError extends JsonMapperError {
  factory MissingTypeForDeserializationError() =
      _MissingTypeForDeserializationErrorImpl;
}

class _MissingTypeForDeserializationErrorImpl extends JsonMapperError
    implements MissingTypeForDeserializationError {
  _MissingTypeForDeserializationErrorImpl() : super();

  @override
  String toString() =>
      "It seems you've omitted target Type for deserialization.\n"
      'You should call it like this: JsonMapper.deserialize<TargetType>'
      '(jsonString)\n'
      'OR Infere type via result variable like: TargetType target = '
      'JsonMapper.deserialize(jsonString)';
}
