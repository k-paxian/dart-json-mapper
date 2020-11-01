import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import './model/model.dart';

enum ThirdParty { A, B, C }

@jsonSerializable
class ShortEnumConverter {
  ThirdParty party;

  ShortEnumConverter({this.party});
}

@jsonSerializable
class EnumIterables {
  ThirdParty party;
  Color color;
  List<ThirdParty> parties = [];
  List<Color> colors;
  Set<Color> colorsSet;
  Map<Color, int> colorPriorities = <Color, int>{};
  Map<ThirdParty, int> partyPriorities = <ThirdParty, int>{};
}

@jsonSerializable
class EnumIterablesWithConstructor {
  List<Color> colors;
  Set<Color> colorsSet;

  EnumIterablesWithConstructor({this.colors, this.colorsSet});
}

@jsonSerializable
class StylingModel {
  const StylingModel({this.primary});
  final String primary;
}

@jsonSerializable
enum Category { First, Second, Third }

@jsonSerializable
class DefaultCategory {
  @JsonProperty(defaultValue: Category.First)
  Category category;
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
      final target = JsonMapper.deserialize<ShortEnumConverter>(targetJson);

      // then
      expect(targetJson, '{"party":"A"}');
      expect(target.party, ThirdParty.A);

      JsonMapper().removeAdapter(adapter);
    });

    test('Single Enum Value', () {
      // given
      final instance = Color.Green;

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<Color>(targetJson);

      // then
      expect(targetJson, r'Green');
      expect(target, Color.Green);
    });

    test('Unknown Enum Value', () {
      // given
      final json = r'Purple';

      // when
      final target = JsonMapper.deserialize<Color>(json);

      // then
      expect(target, null);
    });

    test('When Unknown Enum Value use defaultValue from annotation', () {
      // given
      final json = r'{"category":"Fourth"}';

      // when
      final target = JsonMapper.deserialize<DefaultCategory>(json);

      // then
      expect(target.category, Category.First);
    });

    test('Map<Enum, int> instance', () {
      // given
      final instance = <Color, int>{Color.Black: 1, Color.Blue: 2};

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize(
          targetJson, DeserializationOptions(template: <Color, int>{}));

      // then
      expect(targetJson, '{"Black":1,"Blue":2}');

      expect(target, TypeMatcher<Map<Color, int>>());
      expect(target.containsKey(Color.Black), true);
      expect(target.containsKey(Color.Blue), true);
      expect(target[Color.Black], 1);
      expect(target[Color.Blue], 2);
    });

    test('Map<Category, int> as constructor parameter', () {
      // given
      final json = '{"values":{"First":1,"Second":2,"Third":3}}';
      final map = {
        Category.First: 1,
        Category.Second: 2,
        Category.Third: 3,
      };
      final split = Split(map);

      // when
      final targetJson = JsonMapper.serialize(split, compactOptions);
      final instance = JsonMapper.deserialize<Split>(targetJson);

      // then
      expect(json, targetJson);
      expect(instance, TypeMatcher<Split>());
      expect(instance.values[Category.First], 1);
      expect(instance.values[Category.Second], 2);
      expect(instance.values[Category.Third], 3);
    });

    test('Map<Category, StylingModel> as constructor parameter', () {
      // given
      final json =
          '{"values":{"First":{"primary":"1"},"Second":{"primary":"2"},"Third":{"primary":"3"}}}';
      final map = {
        Category.First: StylingModel(primary: '1'),
        Category.Second: StylingModel(primary: '2'),
        Category.Third: StylingModel(primary: '3'),
      };
      final split = SplitModel(map);

      // when
      final targetJson = JsonMapper.serialize(split, compactOptions);
      final instance = JsonMapper.deserialize<SplitModel>(targetJson);

      // then
      expect(json, targetJson);
      expect(instance, TypeMatcher<SplitModel>());
      expect(instance.values[Category.First], TypeMatcher<StylingModel>());
      expect(instance.values[Category.Second].primary, '2');
    });

    test('Enum Iterable instance', () {
      // given
      final instance = <Color>[Color.Black, Color.Blue];

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final targetList = JsonMapper.deserialize<List<Color>>(targetJson);
      final targetSet = JsonMapper.deserialize<Set<Color>>(targetJson);

      // then
      expect(targetJson, '["Black","Blue"]');

      expect(targetList, TypeMatcher<List<Color>>());
      expect(targetList.length, 2);
      expect(targetList.first, Color.Black);
      expect(targetList.last, Color.Blue);

      expect(targetSet, TypeMatcher<Set<Color>>());
      expect(targetSet.length, 2);
      expect(targetSet.first, Color.Black);
      expect(targetSet.last, Color.Blue);
    });

    test('EnumIterables', () {
      // given
      final instance = EnumIterables();
      instance.party = ThirdParty.A;
      instance.parties = [ThirdParty.A, ThirdParty.B];
      instance.color = Color.GrayMetallic;
      instance.colors = <Color>[Color.Black, Color.Blue];
      instance.colorsSet = <Color>{Color.Black, Color.Blue};
      instance.colorPriorities = <Color, int>{Color.Black: 1, Color.Blue: 2};
      instance.partyPriorities = <ThirdParty, int>{
        ThirdParty.A: 1,
        ThirdParty.B: 2
      };

      // when
      final adapter =
          JsonMapperAdapter(enumValues: {ThirdParty: ThirdParty.values});
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<EnumIterables>(targetJson);

      JsonMapper().removeAdapter(adapter);

      // then
      expect(targetJson,
          '''{"party":"A","color":"GrayMetallic","parties":["A","B"],"colors":["Black","Blue"],"colorsSet":["Black","Blue"],"colorPriorities":{"Black":1,"Blue":2},"partyPriorities":{"A":1,"B":2}}''');

      expect(target, TypeMatcher<EnumIterables>());
      expect(target.party, ThirdParty.A);
      expect(target.parties, [ThirdParty.A, ThirdParty.B]);
      expect(
          target.colorPriorities, <Color, int>{Color.Black: 1, Color.Blue: 2});
      expect(target.partyPriorities,
          <ThirdParty, int>{ThirdParty.A: 1, ThirdParty.B: 2});
      expect(target.color, Color.GrayMetallic);
      expect(target.colors.length, 2);
      expect(target.colors.first, Color.Black);
      expect(target.colors.last, Color.Blue);
      expect(target.colorsSet.length, 2);
      expect(target.colorsSet.first, Color.Black);
      expect(target.colorsSet.last, Color.Blue);
    });

    test('EnumIterablesWithConstructor', () {
      // given
      final instance = EnumIterablesWithConstructor(
          colors: <Color>[Color.Black, Color.Blue],
          colorsSet: <Color>{Color.Black, Color.Blue});

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target =
          JsonMapper.deserialize<EnumIterablesWithConstructor>(targetJson);

      // then
      expect(targetJson,
          '{"colors":["Black","Blue"],"colorsSet":["Black","Blue"]}');

      expect(target, TypeMatcher<EnumIterablesWithConstructor>());
      expect(target.colors.length, 2);
      expect(target.colors.first, Color.Black);
      expect(target.colors.last, Color.Blue);

      expect(target.colorsSet.length, 2);
      expect(target.colorsSet.first, Color.Black);
      expect(target.colorsSet.last, Color.Blue);
    });
  });
}
