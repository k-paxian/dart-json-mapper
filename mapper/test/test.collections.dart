import 'dart:collection';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart' show compactOptions;

void testCollections() {
  group('[Verify Dart Collection cases]', () {
    test('UnmodifiableMapView<String, int>', () {
      // given
      final instance = UnmodifiableMapView({'a': 1, 'b': 2, 'c': 3});
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<UnmodifiableMapView<String, int>>(): (value) =>
            UnmodifiableMapView<String, int>(value.cast<String, int>())
      });
      JsonMapper().useAdapter(adapter);

      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      final target =
          JsonMapper.deserialize<UnmodifiableMapView<String, int>>(json)!;

      // then
      expect(json, '{"a":1,"b":2,"c":3}');

      expect(target, TypeMatcher<UnmodifiableMapView<String, int>>());
      expect(target.containsKey('a'), true);
      expect(target['a'], 1);
      expect(target.containsKey('b'), true);
      expect(target['b'], 2);
      expect(target.containsKey('c'), true);
      expect(target['c'], 3);

      JsonMapper().removeAdapter(adapter);
    });

    test('UnmodifiableListView<int>', () {
      // given
      final instance = UnmodifiableListView([1, 2, 3]);
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<UnmodifiableListView<int>>(): (value) =>
            UnmodifiableListView<int>(value.cast<int>())
      });
      JsonMapper().useAdapter(adapter);

      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<UnmodifiableListView<int>>(json)!;

      // then
      expect(json, '[1,2,3]');

      expect(target, TypeMatcher<UnmodifiableListView<int>>());
      expect(target.first, 1);
      expect(target.last, 3);

      JsonMapper().removeAdapter(adapter);
    });

    test('HashSet<int>', () {
      // given
      final instance = HashSet.of([1, 2, 3]);
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<HashSet<int>>(): (value) =>
            HashSet<int>.of(value.cast<int>().toList())
      });
      JsonMapper().useAdapter(adapter);

      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<HashSet<int>>(json)!;

      // then
      expect(json, '[1,2,3]');

      expect(target, TypeMatcher<HashSet<int>>());
      expect(target.first, 1);
      expect(target.last, 3);

      JsonMapper().removeAdapter(adapter);
    });

    test('HashMap<String, int>', () {
      // given
      final instance = HashMap.of({'a': 1, 'b': 2, 'c': 3});
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<HashMap<String, int>>(): (value) =>
            HashMap<String, int>.of(value.cast<String, int>())
      });
      JsonMapper().useAdapter(adapter);

      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<HashMap<String, int>>(json)!;

      // then
      expect(json, '{"c":3,"a":1,"b":2}');

      expect(target, TypeMatcher<HashMap<String, int>>());
      expect(target.containsKey('a'), true);
      expect(target['a'], 1);
      expect(target.containsKey('b'), true);
      expect(target['b'], 2);
      expect(target.containsKey('c'), true);
      expect(target['c'], 3);

      JsonMapper().removeAdapter(adapter);
    });

    test('HashMap<int, String>', () {
      // given
      final instance = HashMap.of({1: 'a', 2: 'b', 3: 'c'});
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<HashMap<int, String>>(): (value) => HashMap<int, String>.of(
            value.map((key, value) => MapEntry(key, value)).cast<int, String>())
      });
      JsonMapper().useAdapter(adapter);

      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<HashMap<int, String>>(json)!;

      // then
      // https://stackoverflow.com/questions/9304528/why-json-allows-only-string-to-be-a-key
      expect(json, '{"1":"a","2":"b","3":"c"}');

      expect(target, TypeMatcher<HashMap<int, String>>());
      expect(target.containsKey(1), true);
      expect(target[1], 'a');
      expect(target.containsKey(2), true);
      expect(target[2], 'b');
      expect(target.containsKey(3), true);
      expect(target[3], 'c');

      JsonMapper().removeAdapter(adapter);
    });
  });
}
