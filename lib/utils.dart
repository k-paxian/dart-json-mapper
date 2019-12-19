import 'package:reflectable/reflectable.dart';

bool isEnumInstance(InstanceMirror instanceMirror) =>
    (instanceMirror != null && instanceMirror.hasReflectee)
        ? instanceMirror.reflectee.toString().split('.').length == 2
        : false;

/// Provides unified access to class information based on [ClassMirror]
class ClassInfo {
  ClassMirror classMirror;

  ClassInfo(this.classMirror);

  List<Object> get metaData {
    return lookupClassMetaData(classMirror);
  }

  MethodMirror get publicConstructor {
    return classMirror.declarations.values.where((DeclarationMirror dm) {
      return !dm.isPrivate && dm is MethodMirror && dm.isConstructor;
    }).first;
  }

  List<String> get publicFieldNames {
    Map<String, MethodMirror> instanceMembers = classMirror.instanceMembers;
    return instanceMembers.values
        .where((MethodMirror method) {
          final isGetterAndSetter = method.isGetter &&
              classMirror.instanceMembers[method.simpleName + '='] != null;
          final isPublicGetter = method.isGetter &&
              !method.isRegularMethod &&
              ['hashCode', 'runtimeType'].indexOf(method.simpleName) < 0;
          return (method.isGetter &&
                  (method.isSynthetic ||
                      (isGetterAndSetter || isPublicGetter))) &&
              !method.isPrivate;
        })
        .map((MethodMirror method) => method.simpleName)
        .toList();
  }

  ClassMirror _safeGetParentClassMirror(DeclarationMirror declarationMirror) {
    ClassMirror result;
    try {
      result = declarationMirror.owner;
    } catch (error) {
      return result;
    }
    return result;
  }

  ClassMirror _safeGetSuperClassMirror(ClassMirror classMirror) {
    ClassMirror result;
    try {
      result = classMirror.superclass;
    } catch (error) {
      return result;
    }
    return result;
  }

  List<Object> lookupClassMetaData(ClassMirror classMirror) {
    if (classMirror == null) {
      return [];
    }
    final result = []..addAll(classMirror.metadata);
    result.addAll(lookupClassMetaData(_safeGetSuperClassMirror(classMirror)));
    return result;
  }

  List<Object> lookupDeclarationMetaData(DeclarationMirror declarationMirror) {
    if (declarationMirror == null) {
      return [];
    }
    final result = []..addAll(declarationMirror.metadata);
    final ClassMirror parentClassMirror =
        _safeGetParentClassMirror(declarationMirror);
    if (parentClassMirror == null) {
      return result;
    }
    final DeclarationMirror parentDeclarationMirror =
        ClassInfo(parentClassMirror)
            .getDeclarationMirror(declarationMirror.simpleName);
    result.addAll(parentClassMirror.isTopLevel
        ? parentDeclarationMirror.metadata
        : lookupDeclarationMetaData(parentDeclarationMirror));
    return result;
  }

  bool isGetterOnly(String name) {
    return classMirror.instanceMembers[name + '='] == null;
  }

  DeclarationMirror getDeclarationMirror(String name) {
    DeclarationMirror result;
    try {
      result = classMirror.declarations[name] as VariableMirror;
    } catch (error) {
      result = null;
    }
    if (result == null) {
      classMirror.instanceMembers
          .forEach((memberName, MethodMirror methodMirror) {
        if (memberName == name) {
          result = methodMirror;
        }
      });
    }
    return result;
  }
}
