import 'package:collection/collection.dart' show IterableExtension;
import 'package:reflectable/reflectable.dart';

import 'model/index.dart';

/// Helper function to get a type variable from a generic type argument
@Deprecated(
    'Outdated since Dart 2.15, use type literals or update your Dart SDK')
Type typeOf<T>() => T;

const kIsWeb = identical(0, 0.0);

/// Provides logic for traversing Json object tree
class JsonMap {
  final pathDelimiter = '/';

  Map map;
  List<JsonMap>? parentMaps = [];
  Json? jsonMeta;

  JsonMap(this.map, [this.jsonMeta, this.parentMaps]);

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
      if (segment == JsonProperty.parentReference) {
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
}

/// Provides unified access to class information based on [ClassMirror]
class ClassInfo {
  ClassMirror classMirror;

  ClassInfo(this.classMirror);

  Map<Type, ClassInfo>? cachedClasses;

  factory ClassInfo.fromCache(
      ClassMirror classMirror, Map<Type, ClassInfo>? cache) {
    final type = _getReflectedType(classMirror);

    if (cache != null && type != null) {
      if (cache.containsKey(type)) {
        final cachedValue = cache[type]!;
        if (cachedValue.classMirror == classMirror) {
          return cachedValue;
        }
      }

      final result = ClassInfo(classMirror)..cachedClasses = cache;

      cache[type] = result;
      return result;
    }
    return ClassInfo(classMirror);
  }

  final Map<DeclarationMirror, List<Object>> _cacheLookupDeclarationMetaData =
      {};

  Json? getMeta([dynamic scheme]) => _metaData.firstWhereOrNull((m) =>
      (m is Json &&
          ((scheme != null && m.scheme == scheme) ||
              (scheme == null && m.scheme == null)))) as Json?;

  Json? getMetaWhere(Function whereFunction, [dynamic scheme]) =>
      _metaData.firstWhereOrNull((m) => (m is Json &&
          whereFunction(m) == true &&
          ((scheme != null && m.scheme == scheme) ||
              (scheme == null && m.scheme == null)))) as Json?;

  JsonProperty? getDeclarationMeta(DeclarationMirror dm, [dynamic scheme]) =>
      getLastDeclarationMeta(dm, scheme);

  List<JsonProperty> getAllDeclarationMeta(DeclarationMirror dm,
          [dynamic scheme]) =>
      lookupDeclarationMetaData(dm)
          .where((m) => (m is JsonProperty &&
              ((scheme != null && m.scheme == scheme) ||
                  (scheme == null && m.scheme == null))))
          .toList()
          .cast<JsonProperty>();

  JsonProperty? getLastDeclarationMeta(DeclarationMirror dm,
          [dynamic scheme]) =>
      lookupDeclarationMetaData(dm)
          .reversed
          .where((m) => (m is JsonProperty &&
              ((scheme != null && m.scheme == scheme) ||
                  (scheme == null && m.scheme == null))))
          .cast<JsonProperty>()
          .firstOrNull;

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
          classMirror.declarations.values.firstWhere((DeclarationMirror dm) {
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
      return classMirror.superclass;
    } catch (error) {
      return null;
    }
  }

  Type? get reflectedType {
    return _getReflectedType(classMirror);
  }

  static Type? _getReflectedType(ClassMirror classMirror) {
    if (classMirror.hasReflectedType) {
      return classMirror.reflectedType;
    } else if (classMirror.hasDynamicReflectedType) {
      return classMirror.dynamicReflectedType;
    }
    return null;
  }

  MethodMirror? getJsonAnySetter([dynamic scheme]) =>
      getJsonSetter(null, scheme);

  void enumerateJsonGetters(Function visitor, [dynamic scheme]) {
    classMirror.declarations.values.where((DeclarationMirror dm) {
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
          classMirror.declarations.values.firstWhere((DeclarationMirror dm) {
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
      result = classMirror.declarations.values
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
        classMirror.declarations.values
            .firstWhereOrNull((DeclarationMirror dm) {
          return !dm.isPrivate && dm is MethodMirror && dm.isConstructor;
        }) as MethodMirror?;
  }

  List<String> get publicFieldNames {
    final instanceMembers = classMirror.instanceMembers;
    return instanceMembers.values
        .where((MethodMirror method) {
          return !method.isPrivate &&
              (method.isGetter &&
                  (method.isSynthetic ||
                      _isPublicGetter(method) ||
                      _isGetterAndSetter(method, classMirror)));
        })
        .map((MethodMirror method) => method.simpleName)
        .toList();
  }

  static const Set<String> _builtinPublicGetters = {'hashCode', 'runtimeType'};
  static bool _isGetterAndSetter(MethodMirror method, ClassMirror classMirror) {
    return method.isGetter &&
        classMirror.instanceMembers['${method.simpleName}='] != null;
  }

  static bool _isPublicGetter(MethodMirror method) {
    return method.isGetter &&
        !method.isRegularMethod &&
        !_builtinPublicGetters.contains(method.simpleName);
  }

  List<String> get inheritedPublicFieldNames {
    final result = <String>[];
    for (final fieldName in publicFieldNames) {
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
    for (final superinterface in classMirror.superinterfaces) {
      result.addAll(lookupClassMetaData(superinterface));
    }
    return result;
  }

  static const List<Object> _emptyDeclarationMetaData = [];

  List<Object> lookupDeclarationMetaData(DeclarationMirror? declarationMirror) {
    if (declarationMirror == null) {
      return _emptyDeclarationMetaData;
    }

    if (_cacheLookupDeclarationMetaData.containsKey(declarationMirror)) {
      return _cacheLookupDeclarationMetaData[declarationMirror]!;
    }

    var result = declarationMirror.metadata;
    final parentClassMirror = _safeGetParentClassMirror(declarationMirror);
    if (parentClassMirror == null) {
      return declarationMirror.metadata;
    }

    for (final element in [
      parentClassMirror,
      _safeGetSuperClassMirror(parentClassMirror),
      ...parentClassMirror.superinterfaces
    ]) {
      if (element == null) {
        continue;
      }
      final parentDeclarationMirror =
          ClassInfo.fromCache(element, cachedClasses)
              .getDeclarationMirror(declarationMirror.simpleName);
      result = result +
          (parentClassMirror.isTopLevel
              ? parentDeclarationMirror != null
                  ? parentDeclarationMirror.metadata
                  : []
              : lookupDeclarationMetaData(parentDeclarationMirror));
    }

    _cacheLookupDeclarationMetaData[declarationMirror] = result;
    return result;
  }

  bool isGetterOnly(String name) {
    return classMirror.instanceMembers['$name='] == null;
  }

  DeclarationMirror? getDeclarationMirror(String name) {
    DeclarationMirror? result;
    try {
      result = classMirror.declarations[name] as VariableMirror?;
    } catch (error) {
      result = null;
    }
    if (result == null) {
      try {
        result = classMirror.declarations[name] as MethodMirror?;
      } catch (error) {
        result = null;
      }
    }
    if (result == null) {
      try {
        classMirror.instanceMembers
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
