abstract class CircularReferenceError extends Error {
  factory CircularReferenceError(String message) = _CircularReferenceErrorImpl;
}

class _CircularReferenceErrorImpl extends Error
    implements CircularReferenceError {
  final String _message;

  _CircularReferenceErrorImpl(String message) : _message = message;

  toString() => _message;
}
