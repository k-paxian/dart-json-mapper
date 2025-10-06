import 'package:dart_json_mapper/src/model/index.dart';

class CacheManager {
  final Map<String, ProcessedObjectDescriptor> _processedObjects = {};

  String getObjectKey(Object object) =>
      '${object.runtimeType}-${identityHashCode(object)}';

  ProcessedObjectDescriptor? getObjectProcessed(Object object, int level) {
    ProcessedObjectDescriptor? result;

    if (object.runtimeType.toString() == 'Null' ||
        object.runtimeType.toString() == 'bool') {
      return result;
    }

    final key = getObjectKey(object);
    if (_processedObjects.containsKey(key)) {
      result = _processedObjects[key];
      result!.logUsage(level);
    } else {
      result = _processedObjects[key] = ProcessedObjectDescriptor(object);
    }
    return result;
  }

  void clear() {
    _processedObjects.clear();
  }
}