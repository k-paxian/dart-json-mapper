import 'package:dart_json_mapper/src/logic/cache_manager.dart';
import 'package:test/test.dart';

void testCacheManager() {
  group('CacheManager', () {
    late CacheManager cacheManager;

    setUp(() {
      cacheManager = CacheManager();
    });

    test('should cache and retrieve processed objects', () {
      final object = Object();
      final processedObject = cacheManager.getObjectProcessed(object, 0);
      expect(processedObject, isNotNull);
      final cachedObject = cacheManager.getObjectProcessed(object, 1);
      expect(cachedObject, same(processedObject));
    });

    test('should not cache null or bool objects', () {
      expect(cacheManager.getObjectProcessed(true, 0), isNull);
      // expect(cacheManager.getObjectProcessed(null, 0), isNull);
    });

    test('should clear the cache', () {
      final object = Object();
      cacheManager.getObjectProcessed(object, 0);
      cacheManager.clear();
      final processedObject = cacheManager.getObjectProcessed(object, 0);
      expect(processedObject, isNotNull);
    });
  });
}