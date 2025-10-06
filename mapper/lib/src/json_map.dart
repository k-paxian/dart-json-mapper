import 'dart:convert' show JsonDecoder;

import 'package:collection/collection.dart' show IterableExtension;

import 'model/index.dart';

/// Provides logic for traversing Json object tree
class JsonMap {
  final pathDelimiter = '/';

  final Map map;
  final List<JsonMap>? parentMaps;
  final Json? jsonMeta;

  const JsonMap(this.map, [this.jsonMeta, this.parentMaps = const []]);

  static final JsonDecoder _jsonDecoder = const JsonDecoder();

  static bool isValidJSON(dynamic jsonValue) {
    try {
      if (jsonValue is String) {
        _jsonDecoder.convert(jsonValue);
        return true;
      }
      return false;
    } on FormatException {
      return false;
    }
  }

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