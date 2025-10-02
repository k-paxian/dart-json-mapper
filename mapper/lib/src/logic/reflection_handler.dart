import 'package:reflectable/reflectable.dart'
    show
        ClassMirror,
        InstanceMirror,
        DeclarationMirror,
        VariableMirror,
        MethodMirror;

import '../model/annotations.dart';

class ReflectionHandler {
  static const _serializable = JsonSerializable();

  static InstanceMirror? safeGetInstanceMirror(Object object) {
    InstanceMirror? result;
    try {
      result = _serializable.reflect(object);
    } catch (error) {
      return result;
    }
    return result;
  }

  static Type getDeclarationType(DeclarationMirror mirror) {
    Type? result = dynamic;
    VariableMirror variable;
    MethodMirror method;

    try {
      variable = mirror as VariableMirror;
      result = variable.hasReflectedType ? variable.reflectedType : null;
    } catch (error) {
      result = result;
    }

    try {
      method = mirror as MethodMirror;
      result =
          method.hasReflectedReturnType ? method.reflectedReturnType : null;
    } catch (error) {
      result = result;
    }

    return result ??= dynamic;
  }

  static void enumerateAnnotatedClasses(Function(ClassMirror) visitor) {
    for (var classMirror in _serializable.annotatedClasses) {
      visitor(classMirror);
    }
  }
}