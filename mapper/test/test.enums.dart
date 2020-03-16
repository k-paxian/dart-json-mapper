part of json_mapper.test;

enum ThirdParty { A, B, C }

@jsonSerializable
class EnumIterables {
  @JsonProperty(enumValues: ThirdParty.values)
  ThirdParty party;

  @JsonProperty(enumValues: Color.values)
  Color color;

  @JsonProperty(enumValues: ThirdParty.values)
  List<ThirdParty> parties = [];

  @JsonProperty(enumValues: Color.values)
  List<Color> colors;

  @JsonProperty(enumValues: Color.values)
  Set<Color> colorsSet;

  @JsonProperty(enumValues: Color.values)
  Map<Color, int> colorPriorities = <Color, int>{};

  @JsonProperty(enumValues: ThirdParty.values)
  Map<ThirdParty, int> partyPriorities = <ThirdParty, int>{};
}

@jsonSerializable
class EnumIterablesWithConstructor {
  @JsonProperty(enumValues: Color.values)
  List<Color> colors;

  @JsonProperty(enumValues: Color.values)
  Set<Color> colorsSet;

  EnumIterablesWithConstructor({this.colors, this.colorsSet});
}

void testEnums() {
  group('[Verify Enums cases]', () {
    test('Single Enum Value', () {
      // given
      final instance = Color.Green;

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<Color>(targetJson);

      // then
      expect(targetJson, '"Color.Green"');
      expect(target, Color.Green);
    });

    test('Map<Enum, int> instance', () {
      // given
      final instance = <Color, int>{Color.Black: 1, Color.Blue: 2};

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize(
          targetJson, DeserializationOptions(template: <Color, int>{}));

      // then
      expect(targetJson, '{"Color.Black":1,"Color.Blue":2}');

      expect(target, TypeMatcher<Map<Color, int>>());
      expect(target.containsKey(Color.Black), true);
      expect(target.containsKey(Color.Blue), true);
      expect(target[Color.Black], 1);
      expect(target[Color.Blue], 2);
    });

    test('Enum Iterable instance', () {
      // given
      final instance = <Color>[Color.Black, Color.Blue];

      // when
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<Color>>(): (value) => value.cast<Color>(),
        typeOf<Set<Color>>(): (value) => value.cast<Color>()
      });
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final targetList = JsonMapper.deserialize<List<Color>>(targetJson);
      final targetSet = JsonMapper.deserialize<Set<Color>>(targetJson);

      // then
      expect(targetJson, '["Color.Black","Color.Blue"]');

      expect(targetList, TypeMatcher<List<Color>>());
      expect(targetList.length, 2);
      expect(targetList.first, Color.Black);
      expect(targetList.last, Color.Blue);

      expect(targetSet, TypeMatcher<Set<Color>>());
      expect(targetSet.length, 2);
      expect(targetSet.first, Color.Black);
      expect(targetSet.last, Color.Blue);

      JsonMapper().removeAdapter(adapter);
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
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<Color>>(): (value) => value.cast<Color>(),
        typeOf<Set<Color>>(): (value) => value.cast<Color>()
      });
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<EnumIterables>(targetJson);

      // then
      expect(targetJson,
          '''{"party":"ThirdParty.A","color":"Color.GrayMetallic","parties":["ThirdParty.A","ThirdParty.B"],"colors":["Color.Black","Color.Blue"],"colorsSet":["Color.Black","Color.Blue"],"colorPriorities":{"Color.Black":1,"Color.Blue":2},"partyPriorities":{"ThirdParty.A":1,"ThirdParty.B":2}}''');

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

      JsonMapper().removeAdapter(adapter);
    });

    test('EnumIterablesWithConstructor', () {
      // given
      final instance = EnumIterablesWithConstructor(
          colors: <Color>[Color.Black, Color.Blue],
          colorsSet: <Color>{Color.Black, Color.Blue});

      // when
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<Color>>(): (value) => value.cast<Color>(),
        typeOf<Set<Color>>(): (value) => value.cast<Color>()
      });
      JsonMapper().useAdapter(adapter);

      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target =
          JsonMapper.deserialize<EnumIterablesWithConstructor>(targetJson);

      // then
      expect(targetJson,
          '{"colors":["Color.Black","Color.Blue"],"colorsSet":["Color.Black","Color.Blue"]}');

      expect(target, TypeMatcher<EnumIterablesWithConstructor>());
      expect(target.colors.length, 2);
      expect(target.colors.first, Color.Black);
      expect(target.colors.last, Color.Blue);

      expect(target.colorsSet.length, 2);
      expect(target.colorsSet.first, Color.Black);
      expect(target.colorsSet.last, Color.Blue);

      JsonMapper().removeAdapter(adapter);
    });
  });
}
