import 'package:reflectable/reflectable.dart';

import 'model/index.dart';

Type typeOf<T>() => T;

String toWords(String input) => input
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}')
    .replaceAllMapped(RegExp('([A-Z])([A-Z])(?=[a-z])'),
        (match) => '${match.group(1)} ${match.group(2)}')
    .toLowerCase();

String capitalize(String input) => input.replaceFirstMapped(
    RegExp('(^|\s)[a-z]'), (match) => match.group(0).toUpperCase());

String transformFieldName(String input, CaseStyle caseStyle) {
  switch (caseStyle) {
    case CaseStyle.Kebab:
      return toWords(input).replaceAll(' ', '-');
    case CaseStyle.Snake:
      return toWords(input).replaceAll(' ', '_');
    case CaseStyle.SnakeAllCaps:
      return toWords(input).replaceAll(' ', '_').toUpperCase();
    case CaseStyle.Pascal:
      return toWords(input).split(' ').map((word) => capitalize(word)).join();
    default:
      return input;
  }
}

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
    final path = _getPath(name);
    _isPathExists(path, (m, k) {
      result = (m is Map && m.containsKey(k) && k != path) ? m[k] : m;
    });
    return result;
  }

  void setPropertyValue(String name, dynamic value) {
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
    var existingSegmentsCount = 0;
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

  Json getMeta([dynamic scheme]) => metaData.firstWhere(
      (m) => (m is Json &&
          ((scheme != null && m.scheme == scheme) ||
              (scheme == null && m.scheme == null))),
      orElse: () => null);

  JsonProperty getDeclarationMeta(DeclarationMirror dm, [dynamic scheme]) =>
      lookupDeclarationMetaData(dm).firstWhere(
          (m) => (m is JsonProperty &&
              ((scheme != null && m.scheme == scheme) ||
                  (scheme == null && m.scheme == null))),
          orElse: () => null);

  JsonConstructor hasConstructorMeta(DeclarationMirror dm, [dynamic scheme]) =>
      lookupDeclarationMetaData(dm).firstWhere(
          (m) => (m is JsonConstructor &&
              ((scheme != null && m.scheme == scheme) ||
                  (scheme == null && m.scheme == null))),
          orElse: () => null);

  List<Object> get metaData {
    return lookupClassMetaData(classMirror);
  }

  MethodMirror getJsonConstructor([dynamic scheme]) {
    MethodMirror result;
    try {
      result =
          classMirror.declarations.values.firstWhere((DeclarationMirror dm) {
        return !dm.isPrivate &&
            dm is MethodMirror &&
            dm.isConstructor &&
            hasConstructorMeta(dm, scheme) != null;
      });
    } catch (error) {
      result = null;
    }

    return result ??
        classMirror.declarations.values.firstWhere((DeclarationMirror dm) {
          return !dm.isPrivate && dm is MethodMirror && dm.isConstructor;
        });
  }

  List<String> get publicFieldNames {
    final instanceMembers = classMirror.instanceMembers;
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
    final result = [...classMirror.metadata];
    result.addAll(lookupClassMetaData(_safeGetSuperClassMirror(classMirror)));
    return result;
  }

  List<Object> lookupDeclarationMetaData(DeclarationMirror declarationMirror) {
    if (declarationMirror == null) {
      return [];
    }
    final result = [...declarationMirror.metadata];
    final parentClassMirror = _safeGetParentClassMirror(declarationMirror);
    if (parentClassMirror == null) {
      return result;
    }
    final parentDeclarationMirror = ClassInfo(parentClassMirror)
        .getDeclarationMirror(declarationMirror.simpleName);
    result.addAll(parentClassMirror.isTopLevel
        ? parentDeclarationMirror != null
            ? parentDeclarationMirror.metadata
            : []
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
