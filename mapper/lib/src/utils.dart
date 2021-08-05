import 'package:collection/collection.dart' show IterableExtension;
import 'package:reflectable/reflectable.dart';

import 'model/index.dart';

Type typeOf<T>() => T;

const kIsWeb = identical(0, 0.0);

/// Provides logic for traversing Json object tree
class JsonMap {
  final pathDelimiter = '/';

  Map<String, dynamic> map;
  InjectableValues? injectableValues;
  List<JsonMap>? parentMaps = [];
  Json? jsonMeta;

  JsonMap(this.map, [this.jsonMeta, this.parentMaps, this.injectableValues]);

  bool hasProperty(String name, {bool? inject}) {
    return _isPathExists(_getPath(name)) || (inject == true && hasInjectableProperty(name));
  }

  bool hasInjectableProperty(String name) {
    return _isInjectablePathExists(_getPath(name));
  }

  bool isPropertyInjected(String name) {
    return !_isPathExists(_getPath(name)) && _isInjectablePathExists(_getPath(name));
  }

  dynamic getPropertyValue(String name, {bool? inject}) {
    dynamic result;
    final path = _getPath(name);
    _isPathExists(path, (m, k) {
      result = (m is Map && m.containsKey(k) && k != path) ? m[k] : ((inject != true || !_isInjectablePathExists(path)) ? m : null);
    });
    if (result == null && inject == true) {
      _isInjectablePathExists(path, (m, k) {
        result = (m is Map && m.containsKey(k) && k != path) ? m[k] : m;
      });
    }
    return result;
  }

  void setPropertyValue(String name, dynamic value) {
    _isPathExists(_getPath(name), (m, k) {}, true, value);
  }

  String _decodePath(String path) {
    if (path.startsWith('#')) {
      path = Uri.decodeComponent(path).substring(1);
    }
    return path;
  }

  String _getPath(String propertyName) {
    final rootObjectSegments = jsonMeta != null && jsonMeta!.name != null
        ? _decodePath(jsonMeta!.name!).split(pathDelimiter)
        : [];
    final propertySegments = _decodePath(propertyName).split(pathDelimiter);
    rootObjectSegments.addAll(propertySegments);
    rootObjectSegments.removeWhere((value) => value == '');
    return rootObjectSegments.join(pathDelimiter);
  }

  bool _isPathExists(String path,
      [Function? propertyVisitor, bool? autoCreate, dynamic autoValue]) {
    final segments = path
        .split(pathDelimiter)
        .map((p) => p.replaceAll('~1', pathDelimiter).replaceAll('~0', '~'))
        .toList();
    dynamic current = map;
    var existingSegmentsCount = 0;
    for (var segment in segments) {
      final idx = int.tryParse(segment);
      if (segment == '..') {
        final nearestParent =
            parentMaps!.lastWhereOrNull((element) => element.map != current);
        if (nearestParent != null) {
          current = nearestParent.map;
          existingSegmentsCount++;
        }
        continue;
      }
      if (current is List &&
          idx != null &&
          (current.length > idx) &&
          (idx >= 0) &&
          current.elementAt(idx) != null) {
        current = current.elementAt(idx);
        existingSegmentsCount++;
      }
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
        existingSegmentsCount++;
      } else {
        if (autoCreate == true) {
          existingSegmentsCount++;
          final isLastSegment = segments.length == existingSegmentsCount;
          current[segment] = isLastSegment ? autoValue : {};
          current = current[segment];
        }
      }
    }
    if (propertyVisitor != null && current != null) {
      propertyVisitor(current, segments.last);
    }
    return segments.length == existingSegmentsCount &&
        existingSegmentsCount > 0;
  }

  bool _isInjectablePathExists(String path,
      [Function? propertyVisitor]) {
    final segments = path
        .split(pathDelimiter)
        .map((p) => p.replaceAll('~1', pathDelimiter).replaceAll('~0', '~'))
        .toList();
    dynamic current = injectableValues;
    var existingSegmentsCount = 0;
    for (var segment in segments) {
      final idx = int.tryParse(segment);
      if (segment == '..') {
        final nearestParent =
        parentMaps!.lastWhereOrNull((element) => element.injectableValues != current);
        if (nearestParent != null) {
          current = nearestParent.injectableValues;
          existingSegmentsCount++;
        }
        continue;
      }
      if (current is List &&
          idx != null &&
          (current.length > idx) &&
          (idx >= 0) &&
          current.elementAt(idx) != null) {
        current = current.elementAt(idx);
        existingSegmentsCount++;
      }
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
        existingSegmentsCount++;
      }
    }

    if (propertyVisitor != null && current != null) {
      propertyVisitor(current, segments.last);
    }
    return segments.length == existingSegmentsCount &&
        existingSegmentsCount > 0;
  }
}

/// Provides unified access to class information based on [ClassMirror]
class ClassInfo {
  ClassMirror? classMirror;

  ClassInfo(this.classMirror);

  Json? getMeta([dynamic scheme]) => _metaData.firstWhereOrNull((m) =>
      (m is Json &&
          ((scheme != null && m.scheme == scheme) ||
              (scheme == null && m.scheme == null)))) as Json?;

  Json? getMetaWhere(Function whereFunction, [dynamic scheme]) =>
      _metaData.firstWhereOrNull((m) => (m is Json &&
          whereFunction(m) == true &&
          ((scheme != null && m.scheme == scheme) ||
              (scheme == null && m.scheme == null)))) as Json?;

  JsonProperty? getDeclarationMeta(DeclarationMirror dm, [dynamic scheme]) {
    final all = getAllDeclarationMeta(dm, scheme);
    return all.isNotEmpty ? all.last : null;
  }

  List<JsonProperty> getAllDeclarationMeta(DeclarationMirror dm,
          [dynamic scheme]) =>
      lookupDeclarationMetaData(dm)
          .where((m) => (m is JsonProperty &&
              ((scheme != null && m.scheme == scheme) ||
                  (scheme == null && m.scheme == null))))
          .toList()
          .cast<JsonProperty>();

  JsonConstructor? hasConstructorMeta(DeclarationMirror dm, [dynamic scheme]) =>
      lookupDeclarationMetaData(dm).firstWhereOrNull((m) =>
          (m is JsonConstructor &&
              ((scheme != null && m.scheme == scheme) ||
                  (scheme == null && m.scheme == null)))) as JsonConstructor?;

  List<Object> get _metaData {
    return lookupClassMetaData(classMirror);
  }

  MethodMirror? getJsonSetter(String? name, [dynamic scheme]) {
    MethodMirror? result;
    try {
      result =
          classMirror!.declarations.values.firstWhere((DeclarationMirror dm) {
        String? returnType;
        try {
          returnType = dm is MethodMirror ? dm.returnType.simpleName : null;
        } catch (error) {
          returnType = null;
        }
        return dm is MethodMirror &&
            !dm.isPrivate &&
            !dm.isConstructor &&
            returnType == 'void' &&
            getDeclarationMeta(dm, scheme) != null &&
            getDeclarationMeta(dm, scheme)!.name == name;
      }) as MethodMirror?;
    } catch (error) {
      result = null;
    }
    return result;
  }

  ClassMirror? get superClass {
    try {
      return classMirror!.superclass;
    } catch (error) {
      return null;
    }
  }

  Type? get reflectedType {
    if (classMirror!.hasReflectedType) {
      return classMirror!.reflectedType;
    } else if (classMirror!.hasDynamicReflectedType) {
      return classMirror!.dynamicReflectedType;
    }
    return null;
  }

  MethodMirror? getJsonAnySetter([dynamic scheme]) =>
      getJsonSetter(null, scheme);

  void enumerateJsonGetters(Function visitor, [dynamic scheme]) {
    classMirror!.declarations.values.where((DeclarationMirror dm) {
      return !dm.isPrivate &&
          dm is MethodMirror &&
          !dm.isConstructor &&
          dm.isRegularMethod &&
          dm.parameters.isEmpty &&
          getDeclarationMeta(dm, scheme) != null &&
          getDeclarationMeta(dm, scheme)!.name != null;
    }).forEach((DeclarationMirror dm) {
      visitor(dm, getDeclarationMeta(dm, scheme));
    });
  }

  MethodMirror? getJsonAnyGetter([dynamic scheme]) {
    MethodMirror? result;
    try {
      result =
          classMirror!.declarations.values.firstWhere((DeclarationMirror dm) {
        return !dm.isPrivate &&
            dm is MethodMirror &&
            !dm.isConstructor &&
            dm.parameters.isEmpty &&
            dm.hasReflectedReturnType &&
            dm.reflectedReturnType.toString() == 'Map<String, dynamic>' &&
            getDeclarationMeta(dm, scheme) != null;
      }) as MethodMirror?;
    } catch (error) {
      result = null;
    }
    return result;
  }

  MethodMirror? getJsonConstructor([dynamic scheme]) {
    MethodMirror? result;
    try {
      result = classMirror!.declarations.values
          .firstWhereOrNull((DeclarationMirror dm) {
        return !dm.isPrivate &&
            dm is MethodMirror &&
            dm.isConstructor &&
            hasConstructorMeta(dm, scheme) != null;
      }) as MethodMirror?;
    } catch (error) {
      result = null;
    }

    return result ??
        classMirror!.declarations.values
            .firstWhereOrNull((DeclarationMirror dm) {
          return !dm.isPrivate && dm is MethodMirror && dm.isConstructor;
        }) as MethodMirror?;
  }

  List<String> get publicFieldNames {
    final instanceMembers = classMirror!.instanceMembers;
    return instanceMembers.values
        .where((MethodMirror method) {
          final isGetterAndSetter = method.isGetter &&
              classMirror!.instanceMembers[method.simpleName + '='] != null;
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

  List<String> get inheritedPublicFieldNames {
    final result = <String>[];
    for (var fieldName in publicFieldNames) {
      final dm = getDeclarationMirror(fieldName)!;
      if (_safeGetParentClassMirror(dm) != classMirror) {
        result.add(fieldName);
      }
    }
    return result;
  }

  ClassMirror? _safeGetParentClassMirror(DeclarationMirror declarationMirror) {
    ClassMirror? result;
    try {
      result = declarationMirror.owner as ClassMirror?;
    } catch (error) {
      return result;
    }
    return result;
  }

  ClassMirror? _safeGetSuperClassMirror(ClassMirror classMirror) {
    ClassMirror? result;
    try {
      result = classMirror.superclass;
    } catch (error) {
      return result;
    }
    return result;
  }

  List<Object> lookupClassMetaData(ClassMirror? classMirror) {
    if (classMirror == null) {
      return [];
    }
    final result = [...classMirror.metadata];
    result.addAll(lookupClassMetaData(_safeGetSuperClassMirror(classMirror)));
    for (var superinterface in classMirror.superinterfaces) {
      result.addAll(lookupClassMetaData(superinterface));
    }
    return result;
  }

  List<Object> lookupDeclarationMetaData(DeclarationMirror? declarationMirror) {
    if (declarationMirror == null) {
      return [];
    }
    final result = [...declarationMirror.metadata];
    final parentClassMirror = _safeGetParentClassMirror(declarationMirror);
    if (parentClassMirror == null) {
      return result;
    }

    for (var element in [
      parentClassMirror,
      _safeGetSuperClassMirror(parentClassMirror),
      ...parentClassMirror.superinterfaces
    ]) {
      final parentDeclarationMirror =
          ClassInfo(element).getDeclarationMirror(declarationMirror.simpleName);
      result.addAll(parentClassMirror.isTopLevel
          ? parentDeclarationMirror != null
              ? parentDeclarationMirror.metadata
              : []
          : lookupDeclarationMetaData(parentDeclarationMirror));
    }

    return result;
  }

  bool isGetterOnly(String name) {
    return classMirror!.instanceMembers[name + '='] == null;
  }

  DeclarationMirror? getDeclarationMirror(String name) {
    DeclarationMirror? result;
    try {
      result = classMirror!.declarations[name] as VariableMirror?;
    } catch (error) {
      result = null;
    }
    if (result == null) {
      try {
        result = classMirror!.declarations[name] as MethodMirror?;
      } catch (error) {
        result = null;
      }
    }
    if (result == null) {
      try {
        classMirror!.instanceMembers
            .forEach((memberName, MethodMirror methodMirror) {
          if (memberName == name) {
            result = methodMirror;
          }
        });
      } catch (error) {
        result = null;
      }
    }
    return result;
  }
}
