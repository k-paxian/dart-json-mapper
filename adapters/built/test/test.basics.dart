import 'package:built_collection/built_collection.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

@jsonSerializable
class Item {}

@jsonSerializable
class ItemsList {
  BuiltList<Item> items = BuiltList.of([Item(), Item()]);
  BuiltSet<Item> itemsSet = BuiltSet.of([Item(), Item()]);
  BuiltMap<String, Item> itemsMap = BuiltMap.of({'1': Item(), '2': Item()});
}

final compactOptions = SerializationOptions(indent: '');

void testBasics() {
  group('[Verify BuiltList]', () {
    test('BuiltList<Item>, BuiltSet<Item>, BuiltMap<String, Item>', () {
      // given
      final json =
          '''{"items":[{},{}],"itemsSet":[{},{}],"itemsMap":{"1":{},"2":{}}}''';

      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<BuiltMap<String, Item>>(): (value) => (value is BuiltMap)
            ? value
            : BuiltMap<String, Item>.of(value.cast<String, Item>()),
      });

      // when
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(ItemsList(), compactOptions);
      final instance = JsonMapper.deserialize<ItemsList>(targetJson);

      JsonMapper().removeAdapter(adapter);

      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<ItemsList>());
      expect(instance.items.length, 2);
      expect(instance.items.first, TypeMatcher<Item>());
      expect(instance.itemsSet.length, 2);
      expect(instance.itemsSet.first, TypeMatcher<Item>());
      expect(instance.itemsMap.length, 2);
      expect(instance.itemsMap.values.first, TypeMatcher<Item>());
    });
  });
}
