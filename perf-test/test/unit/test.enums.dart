import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart' show compactOptions, Color;

enum ThirdParty { A, B, C }

@jsonSerializable
class ShortEnumConverter {
  @JsonProperty(converterParams: {ThirdParty.B: 'Be'})
  ThirdParty? party;

  ShortEnumConverter({this.party});
}

@jsonSerializable
class EnumMappingsOverrideTest {
  @JsonProperty(converterParams: {ThirdParty.B: 'Be'})
  List<ThirdParty>? parties = [];

  EnumMappingsOverrideTest({this.parties});
}

@jsonSerializable
class EnumIterables {
  ThirdParty? party;
  Color? color;
  List<ThirdParty> parties = [];
  List<Color>? colors;
  Set<Color>? colorsSet;
  Map<Color, int> colorPriorities = <Color, int>{};
  Map<ThirdParty, int> partyPriorities = <ThirdParty, int>{};
}

@jsonSerializable
class EnumIterablesWithConstructor {
  List<Color>? colors;
  Set<Color>? colorsSet;

  EnumIterablesWithConstructor({this.colors, this.colorsSet});
}

@jsonSerializable
class StylingModel {
  const StylingModel({this.primary});
  final String? primary;
}

@jsonSerializable
enum Category { first, second, third }

@jsonSerializable
class DefaultCategory {
  @JsonProperty(defaultValue: Category.first)
  Category? category;
}

@jsonSerializable
@Json(valueDecorators: Split.valueDecorators)
class Split {
  static Map<Type, ValueDecoratorFunction> valueDecorators() =>
      {typeOf<Map<Category, int>>(): (value) => value.cast<Category, int>()};

  Map<Category, int> values;

  Split(this.values);
}

@jsonSerializable
@Json(valueDecorators: SplitModel.valueDecorators)
class SplitModel {
  static Map<Type, ValueDecoratorFunction> valueDecorators() => {
        typeOf<Map<Category, StylingModel>>(): (value) =>
            value.cast<Category, StylingModel>()
      };

  final Map<Category, StylingModel> values;

  const SplitModel(this.values);
}

void testEnums() {
  group('[Verify Enums cases]', () {
    test('Short Enum Converter', () {
      // given
      final instance = ShortEnumConverter(party: ThirdParty.A);

      // when
      final adapter =
          JsonMapperAdapter(enumValues: {ThirdParty: ThirdParty.values});
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<ShortEnumConverter>(targetJson)!;

      // then
      expect(targetJson, '{"party":"A"}');
      expect(target.party, ThirdParty.A);

      JsonMapper().removeAdapter(adapter);
    });

    test('Single Enum Value', () {
      // given
      final instance = Color.green;

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<Color>(targetJson);

      // then
      expect(targetJson, r'"green"');
      expect(target, Color.green);
    });

    test('Null Enum Value', () {
      // given
      final dynamic instance = null;

      // when
      final target = JsonMapper.deserialize<Color>(instance);

      // then
      expect(target, null);
    });

    test('Unknown Enum Value', () {
      // given
      final json = r'"Purple"';

      // when
      final target = JsonMapper.deserialize<Color>(json);

      // then
      expect(target, null);
    });

    test('When Unknown Enum Value use defaultValue from annotation', () {
      // given
      final json = r'{"category":"Fourth"}';

      // when
      final target = JsonMapper.deserialize<DefaultCategory>(json)!;

      // then
      expect(target.category, Category.first);
    });

    test('Map<Enum, int> instance', () {
      // given
      final instance = <Color, int>{Color.black: 1, Color.blue: 2};

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize(
          targetJson, DeserializationOptions(template: <Color, int>{}));

      // then
      expect(targetJson, '{"black":1,"blue":2}');

      expect(target, TypeMatcher<Map<Color, int>>());
      expect(target.containsKey(Color.black), true);
      expect(target.containsKey(Color.blue), true);
      expect(target[Color.black], 1);
      expect(target[Color.blue], 2);
    });

    test('Map<Category, int> as constructor parameter', () {
      // given
      final json = '{"values":{"first":1,"second":2,"third":3}}';
      final map = {
        Category.first: 1,
        Category.second: 2,
        Category.third: 3,
      };
      final split = Split(map);

      // when
      final targetJson = JsonMapper.serialize(split, compactOptions);
      final instance = JsonMapper.deserialize<Split>(targetJson)!;

      // then
      expect(json, targetJson);
      expect(instance, TypeMatcher<Split>());
      expect(instance.values[Category.first], 1);
      expect(instance.values[Category.second], 2);
      expect(instance.values[Category.third], 3);
    });

    test('Map<Category, StylingModel> as constructor parameter', () {
      // given
      final json =
          '{"values":{"first":{"primary":"1"},"second":{"primary":"2"},"third":{"primary":"3"}}}';
      final map = {
        Category.first: StylingModel(primary: '1'),
        Category.second: StylingModel(primary: '2'),
        Category.third: StylingModel(primary: '3'),
      };
      final split = SplitModel(map);

      // when
      final targetJson = JsonMapper.serialize(split, compactOptions);
      final instance = JsonMapper.deserialize<SplitModel>(targetJson)!;

      // then
      expect(json, targetJson);
      expect(instance, TypeMatcher<SplitModel>());
      expect(instance.values[Category.first], TypeMatcher<StylingModel>());
      expect(instance.values[Category.second]!.primary, '2');
    });

    test('Enum Iterable instance', () {
      // given
      final instance = <Color>[Color.black, Color.blue];

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final targetList = JsonMapper.deserialize<List<Color>>(targetJson)!;
      final targetSet = JsonMapper.deserialize<Set<Color>>(targetJson)!;

      // then
      expect(targetJson, '["black","blue"]');

      expect(targetList, TypeMatcher<List<Color>>());
      expect(targetList.length, 2);
      expect(targetList.first, Color.black);
      expect(targetList.last, Color.blue);

      expect(targetSet, TypeMatcher<Set<Color>>());
      expect(targetSet.length, 2);
      expect(targetSet.first, Color.black);
      expect(targetSet.last, Color.blue);
    });

    test('EnumIterables', () {
      // given
      final instance = EnumIterables();
      instance.party = ThirdParty.A;
      instance.parties = [ThirdParty.A, ThirdParty.B];
      instance.color = Color.grayMetallic;
      instance.colors = <Color>[Color.black, Color.blue];
      instance.colorsSet = <Color>{Color.black, Color.blue};
      instance.colorPriorities = <Color, int>{Color.black: 1, Color.blue: 2};
      instance.partyPriorities = <ThirdParty, int>{
        ThirdParty.A: 1,
        ThirdParty.B: 2
      };

      // when
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<ThirdParty>>(): (value) => value.cast<ThirdParty>(),
        typeOf<Map<Color, int>>(): (value) => value.cast<Color, int>(),
        typeOf<Map<ThirdParty, int>>(): (value) =>
            value.cast<ThirdParty, int>(),
      }, enumValues: {
        ThirdParty: ThirdParty.values
      });
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<EnumIterables>(targetJson)!;

      JsonMapper().removeAdapter(adapter);

      // then
      expect(targetJson,
          '''{"party":"A","color":"grayMetallic","parties":["A","B"],"colors":["black","blue"],"colorsSet":["black","blue"],"colorPriorities":{"black":1,"blue":2},"partyPriorities":{"A":1,"B":2}}''');

      expect(target, TypeMatcher<EnumIterables>());
      expect(target.party, ThirdParty.A);
      expect(target.parties, [ThirdParty.A, ThirdParty.B]);
      expect(
          target.colorPriorities, <Color, int>{Color.black: 1, Color.blue: 2});
      expect(target.partyPriorities,
          <ThirdParty, int>{ThirdParty.A: 1, ThirdParty.B: 2});
      expect(target.color, Color.grayMetallic);
      expect(target.colors?.length, 2);
      expect(target.colors?.first, Color.black);
      expect(target.colors?.last, Color.blue);
      expect(target.colorsSet?.length, 2);
      expect(target.colorsSet?.first, Color.black);
      expect(target.colorsSet?.last, Color.blue);
    });

    test('EnumIterablesWithConstructor', () {
      // given
      final instance = EnumIterablesWithConstructor(
          colors: <Color>[Color.black, Color.blue],
          colorsSet: <Color>{Color.black, Color.blue});

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target =
          JsonMapper.deserialize<EnumIterablesWithConstructor>(targetJson)!;

      // then
      expect(targetJson,
          '{"colors":["black","blue"],"colorsSet":["black","blue"]}');

      expect(target, TypeMatcher<EnumIterablesWithConstructor>());
      expect(target.colors!.length, 2);
      expect(target.colors!.first, Color.black);
      expect(target.colors!.last, Color.blue);

      expect(target.colorsSet!.length, 2);
      expect(target.colorsSet!.first, Color.black);
      expect(target.colorsSet!.last, Color.blue);
    });

    test('Enum with caseInsensitive String values mapping', () {
      // given
      final instance = [ThirdParty.A, ThirdParty.B, ThirdParty.C];
      final json = '''["a","B","c"]''';
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<ThirdParty>>(): (value) => value?.cast<ThirdParty>(),
      }, enumValues: {
        ThirdParty:
            EnumDescriptor(caseInsensitive: true, values: ThirdParty.values)
      });

      // when
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<List<ThirdParty>>(json);

      JsonMapper().removeAdapter(adapter);

      // then
      expect(targetJson, '''["A","B","C"]''');
      expect(target, instance);
    });

    test('Enum with custom String values mapping', () {
      // given
      final instance = [ThirdParty.A, ThirdParty.B, ThirdParty.C];
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<ThirdParty>>(): (value) => value.cast<ThirdParty>(),
      }, enumValues: {
        ThirdParty: EnumDescriptor(
            values: ThirdParty.values,
            mapping: <ThirdParty, String>{
              ThirdParty.A: 'AAA',
              ThirdParty.B: 'BBB',
              ThirdParty.C: 'CCC'
            })
      });

      // when
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<List<ThirdParty>>(targetJson);

      JsonMapper().removeAdapter(adapter);

      // then
      expect(targetJson, '''["AAA","BBB","CCC"]''');
      expect(target, instance);
    });

    test('Enum with custom Num values mapping', () {
      // given
      final instance = [ThirdParty.A, ThirdParty.B, ThirdParty.C];
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<ThirdParty>>(): (value) => value.cast<ThirdParty>(),
      }, enumValues: {
        ThirdParty: EnumDescriptor(
            values: ThirdParty.values,
            mapping: <ThirdParty, num>{
              ThirdParty.A: -2.22,
              ThirdParty.B: 1120,
              ThirdParty.C: 1.2344
            })
      });

      // when
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<List<ThirdParty>>(targetJson);

      JsonMapper().removeAdapter(adapter);

      // then
      expect(targetJson, '''[-2.22,1120,1.2344]''');
      expect(target, instance);
    });

    test('Enum with defaultValue on unknown entries', () {
      // given
      final json = '''["A","D","C"]''';
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<ThirdParty>>(): (value) => value.cast<ThirdParty>(),
      }, enumValues: {
        ThirdParty: EnumDescriptor(
            values: ThirdParty.values, defaultValue: ThirdParty.B)
      });

      // when
      JsonMapper().useAdapter(adapter);

      final target = JsonMapper.deserialize<List<ThirdParty>>(json);

      JsonMapper().removeAdapter(adapter);

      // then
      expect(target, [ThirdParty.A, ThirdParty.B, ThirdParty.C]);
    });

    test('Enum mappings could be given on a field level as `converterParams`',
        () {
      // given
      final instance = ShortEnumConverter(party: ThirdParty.B);
      final adapter =
          JsonMapperAdapter(enumValues: {ThirdParty: ThirdParty.values});

      // when
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<ShortEnumConverter>(targetJson)!;

      JsonMapper().removeAdapter(adapter);

      // then
      expect(targetJson, '''{"party":"Be"}''');
      expect(target, TypeMatcher<ShortEnumConverter>());
      expect(target.party, ThirdParty.B);
    });

    test(
        'Enum mappings could be given on a field level as `converterParams` '
        'to override global Enum mappings', () {
      // given
      final instance = EnumMappingsOverrideTest(
          parties: [ThirdParty.A, ThirdParty.B, ThirdParty.C]);
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<ThirdParty>>(): (value) => value.cast<ThirdParty>(),
      }, enumValues: {
        ThirdParty: EnumDescriptor(
            values: ThirdParty.values,
            mapping: <ThirdParty, String>{
              ThirdParty.A: 'A_A',
              ThirdParty.B: 'BBB',
              ThirdParty.C: 'C_C'
            })
      });

      // when
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target =
          JsonMapper.deserialize<EnumMappingsOverrideTest>(targetJson)!;

      JsonMapper().removeAdapter(adapter);

      // then
      expect(targetJson, '''{"parties":["A_A","Be","C_C"]}''');
      expect(target, TypeMatcher<EnumMappingsOverrideTest>());
      expect(target.parties!.elementAt(1), ThirdParty.B);
    });
  });
}
