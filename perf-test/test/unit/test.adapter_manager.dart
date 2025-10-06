import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:dart_json_mapper/src/logic/adapter_manager.dart';
import 'package:test/test.dart';

void testAdapterManager() {
  group('AdapterManager', () {
    late AdapterManager adapterManager;

    setUp(() {
      adapterManager = AdapterManager();
    });

    test('should register and remove adapters', () {
      final adapter = JsonMapperAdapter();
      adapterManager.use(adapter);
      expect(adapterManager.allEnumValues, isEmpty);
      adapterManager.remove(adapter);
      expect(adapterManager.allEnumValues, isEmpty);
    });

    test('should enumerate adapters in the correct order', () {
      final adapter1 = JsonMapperAdapter(title: 'Adapter 1');
      final adapter2 = JsonMapperAdapter(title: 'Adapter 2');
      adapterManager.use(adapter1, 1);
      adapterManager.use(adapter2, 0);

      final enumeratedAdapters = <IJsonMapperAdapter>[];
      adapterManager.enumerate((adapter) {
        enumeratedAdapters.add(adapter);
      });

      expect(enumeratedAdapters.map((a) => a.title).toList(),
          ['Adapter 2', 'Adapter 1']);
    });
  });
}