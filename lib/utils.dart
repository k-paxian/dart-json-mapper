import 'package:dart_json_mapper/annotations.dart';
import 'package:reflectable/reflectable.dart';

bool isEnumInstance(InstanceMirror instanceMirror) =>
    (instanceMirror != null && instanceMirror.hasReflectee)
        ? instanceMirror.reflectee.toString().split('.').length == 2
        : false;

/// Provides logic for traversing Json object tree
class JsonMap {
  final PATH_DELIMITER = '/';

  Map<String, dynamic> map;
  Json jsonMeta;

  JsonMap(this.map, [this.jsonMeta]);

  bool hasProperty(String name) {
    return _isPathExists(_getPath(name));
  }

  dynamic getPropertyValue(String name) {
    dynamic result;
    _isPathExists(_getPath(name), (m, k) {
      result = (m is Map && m.containsKey(k)) ? m[k] : m;
    });
    return result;
  }

  setPropertyValue(String name, dynamic value) {
    _isPathExists(_getPath(name), (m, k) {}, true, value);
  }

  String _getPath(String propertyName) {
    final rootObjectSegments = jsonMeta != null && jsonMeta.name != null
        ? jsonMeta.name.split(PATH_DELIMITER)
        : [];
    final propertySegments = propertyName.split(PATH_DELIMITER);
    rootObjectSegments.addAll(propertySegments);
    rootObjectSegments.removeWhere((value) => value == '');
    return rootObjectSegments.join(PATH_DELIMITER);
  }

  bool _isPathExists(String path,
      [Function propertyVisitor, bool autoCreate, dynamic autoValue]) {
    final segments = path.split(PATH_DELIMITER);
    dynamic current = map;
    int existingSegmentsCount = 0;
    segments.forEach((key) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
        existingSegmentsCount++;
      } else {
        if (autoCreate == true) {
          existingSegmentsCount++;
          final isLastSegment = segments.length == existingSegmentsCount;
          current[key] = isLastSegment ? autoValue : {};
          current = current[key];
        }
      }
    });
    if (propertyVisitor != null && current != null) {
      propertyVisitor(current, segments.last);
    }
    return segments.length == existingSegmentsCount &&
        existingSegmentsCount > 0;
  }
}

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
              !['hashCode', 'runtimeType'].contains(method.simpleName);
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
