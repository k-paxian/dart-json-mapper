import 'package:dart_json_mapper/dart_json_mapper.dart';

abstract class JsonMapperError extends Error {}

abstract class JsonFormatError extends JsonMapperError {
  factory JsonFormatError(DeserializationContext context,
      {FormatException? formatException}) = _JsonFormatErrorImpl;
}

class JsonMapperSubtypeError extends JsonMapperError {
  JsonMapperSubtypeError(
      this.discriminatorValue, this.validDiscriminators, this.superclass);

  final dynamic discriminatorValue;
  final List<dynamic> validDiscriminators;
  final ClassInfo superclass;

  @override
  String toString() =>
      '"$discriminatorValue" is not a valid discriminator value for type "${superclass.reflectedType}".\n\n'
      'Valid values are:\n${validDiscriminators.map((x) => '  - $x').join(',\n')}';
}

class _JsonFormatErrorImpl extends JsonMapperError implements JsonFormatError {
  final DeserializationContext _context;
  final FormatException? _formatException;

  _JsonFormatErrorImpl(DeserializationContext context,
      {FormatException? formatException})
      : _context = context,
        _formatException = formatException;

  @override
  String toString() =>
      '${_context.toString()} \n ${_formatException.toString()}';
}

abstract class FieldCannotBeNullError extends JsonMapperError {
  factory FieldCannotBeNullError(String fieldName, {String? message}) =
      _FieldCannotBeNullErrorImpl;
}

class _FieldCannotBeNullErrorImpl extends JsonMapperError
    implements FieldCannotBeNullError {
  final String _fieldName;
  final String? _message;

  _FieldCannotBeNullErrorImpl(String fieldName, {String? message})
      : _fieldName = fieldName,
        _message = message;

  @override
  String toString() =>
      'Field "$_fieldName" cannot be NULL. ${_message ?? 'Please specify valid value in JSON payload'}.';
}

abstract class FieldIsRequiredError extends JsonMapperError {
  factory FieldIsRequiredError(String fieldName, {String? message}) =
      _FieldIsRequiredErrorImpl;
}

class _FieldIsRequiredErrorImpl extends JsonMapperError
    implements FieldIsRequiredError {
  final String _fieldName;
  final String? _message;

  _FieldIsRequiredErrorImpl(String fieldName, {String? message})
      : _fieldName = fieldName,
        _message = message;

  @override
  String toString() =>
      'Field "$_fieldName" is required. ${_message ?? 'And has to be provided in JSON payload'}.';
}

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
  factory MissingAnnotationOnTypeError(Type? type) =
      _MissingAnnotationOnTypeErrorImpl;
}

class _MissingAnnotationOnTypeErrorImpl extends JsonMapperError
    implements MissingAnnotationOnTypeError {
  final Type? _type;

  _MissingAnnotationOnTypeErrorImpl(Type? type) : _type = type;

  @override
  String toString() =>
      "It seems your class '${_type.toString()}' has not been annotated "
      'with @jsonSerializable';
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

abstract class CannotCreateInstanceError extends JsonMapperError {
  factory CannotCreateInstanceError(
      TypeError typeError,
      ClassInfo classInfo,
      Iterable<String> positionalNullArguments,
      Map<Symbol, dynamic> namedNullArguments) = _CannotCreateInstanceErrorImpl;
}

class _CannotCreateInstanceErrorImpl extends JsonMapperError
    implements CannotCreateInstanceError {
  final ClassInfo _classInfo;
  final TypeError _typeError;
  final Iterable<String> _positionalNullArguments;
  final Map<Symbol, dynamic> _namedNullArguments;

  _CannotCreateInstanceErrorImpl(
      TypeError typeError,
      ClassInfo classInfo,
      Iterable<String> positionalNullArguments,
      Map<Symbol, dynamic> namedNullArguments)
      : _classInfo = classInfo,
        _typeError = typeError,
        _positionalNullArguments = positionalNullArguments,
        _namedNullArguments = namedNullArguments;

  @override
  String toString() =>
      _typeError.toString().startsWith("type 'Null' is not a subtype of type")
          ? [
              "Unable to instantiate class '${_classInfo.classMirror.simpleName}'",
              _positionalNullArguments.isEmpty
                  ? null
                  : '  with null positional arguments [${_positionalNullArguments.join(', ')}]',
              _namedNullArguments.keys.isEmpty
                  ? null
                  : '  with null named arguments [${_namedNullArguments.keys.join(', ')}]'
            ].where((element) => element != null).join('\n')
          : _typeError.toString();
}
