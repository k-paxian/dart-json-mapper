import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart' show Color;

@jsonSerializable
@Json(caseStyle: CaseStyle.kebab)
class NameCaseObjectOverride {
  String? mainTitle;
  String? description;
  bool? hasMainProperty;
  Color? primaryColor;

  NameCaseObjectOverride(
      {this.mainTitle,
      this.description,
      this.hasMainProperty,
      this.primaryColor});
}

@jsonSerializable
class NameCaseObject {
  String? mainTitle;
  String? description;
  bool? hasMainProperty;
  Color primaryColor;

  NameCaseObject(
      {this.mainTitle,
      this.description,
      this.hasMainProperty,
      this.primaryColor = Color.grayMetallic});
}

void testNameCasing() {
  group('[Verify field names casing styles processing]', () {
    group('[Serialization]', () {
      test('Verify CaseStyle override on class level', () {
        // given
        final instance = NameCaseObjectOverride(
            mainTitle: 'title', description: 'desc', hasMainProperty: true);
        // when
        final json = JsonMapper.serialize(instance);
        // then
        expect(json,
            '''{"main-title":"title","description":"desc","has-main-property":true,"primary-color":null}''');
      });

      test('Verify undefined CaseStyle', () {
        // given
        final instance = NameCaseObject(
            mainTitle: 'title', description: 'desc', hasMainProperty: true);
        // when
        final json = JsonMapper.serialize(instance);
        // then
        expect(json,
            '''{"mainTitle":"title","description":"desc","hasMainProperty":true,"primaryColor":"grayMetallic"}''');
      });

      test('Verify CaseStyle.kebab', () {
        // given
        final instance = NameCaseObject(
            mainTitle: 'title', description: 'desc', hasMainProperty: true);
        // when
        final json = JsonMapper.serialize(instance,
            SerializationOptions(indent: '', caseStyle: CaseStyle.kebab));
        // then
        expect(json,
            '''{"main-title":"title","description":"desc","has-main-property":true,"primary-color":"gray-metallic"}''');
      });

      test('Verify CaseStyle.pascal', () {
        // given
        final instance = NameCaseObject(
            mainTitle: 'title', description: 'desc', hasMainProperty: true);
        // when
        final json = JsonMapper.serialize(instance,
            SerializationOptions(indent: '', caseStyle: CaseStyle.pascal));
        // then
        expect(json,
            '''{"MainTitle":"title","Description":"desc","HasMainProperty":true,"PrimaryColor":"GrayMetallic"}''');
      });

      test('Verify CaseStyle.Snake', () {
        // given
        final instance = NameCaseObject(
            mainTitle: 'title', description: 'desc', hasMainProperty: true);
        // when
        final json = JsonMapper.serialize(instance,
            SerializationOptions(indent: '', caseStyle: CaseStyle.snake));
        // then
        expect(json,
            '''{"main_title":"title","description":"desc","has_main_property":true,"primary_color":"gray_metallic"}''');
      });

      test('Verify CaseStyle.SnakeAllCaps', () {
        // given
        final instance = NameCaseObject(
            mainTitle: 'title', description: 'desc', hasMainProperty: true);
        // when
        final json = JsonMapper.serialize(
            instance,
            SerializationOptions(
                indent: '', caseStyle: CaseStyle.snakeAllCaps));
        // then
        expect(json,
            '''{"MAIN_TITLE":"title","DESCRIPTION":"desc","HAS_MAIN_PROPERTY":true,"PRIMARY_COLOR":"GRAY_METALLIC"}''');
      });
    });

    group('[Deserialization]', () {
      test('Verify CaseStyle.SnakeAllCaps', () {
        // given
        final json =
            '''{"MAIN_TITLE":"title","DESCRIPTION":"desc","HAS_MAIN_PROPERTY":true,"PRIMARY_COLOR":"GRAY_METALLIC"}''';
        // when
        final instance = JsonMapper.deserialize<NameCaseObject>(
            json, DeserializationOptions(caseStyle: CaseStyle.snakeAllCaps))!;
        // then
        expect(instance.mainTitle, 'title');
        expect(instance.description, 'desc');
        expect(instance.hasMainProperty, true);
        expect(instance.primaryColor, Color.grayMetallic);
      });

      test('Verify CaseStyle.Snake', () {
        // given
        final json =
            '''{"main_title":"title","description":"desc","has_main_property":true,"primary_color":"gray_metallic"}''';
        // when
        final instance = JsonMapper.deserialize<NameCaseObject>(
            json, DeserializationOptions(caseStyle: CaseStyle.snake))!;
        // then
        expect(instance.mainTitle, 'title');
        expect(instance.description, 'desc');
        expect(instance.hasMainProperty, true);
        expect(instance.primaryColor, Color.grayMetallic);
      });

      test('Verify CaseStyle.Pascal', () {
        // given
        final json =
            '''{"MainTitle":"title","Description":"desc","HasMainProperty":true,"PrimaryColor":"GrayMetallic"}''';
        // when
        final instance = JsonMapper.deserialize<NameCaseObject>(
            json, DeserializationOptions(caseStyle: CaseStyle.pascal))!;
        // then
        expect(instance.mainTitle, 'title');
        expect(instance.description, 'desc');
        expect(instance.hasMainProperty, true);
        expect(instance.primaryColor, Color.grayMetallic);
      });

      test('Verify CaseStyle.Kebab', () {
        // given
        final json =
            '''{"main-title":"title","description":"desc","has-main-property":true,"primary-color":"gray-metallic"}''';
        // when
        final instance = JsonMapper.deserialize<NameCaseObject>(
            json, DeserializationOptions(caseStyle: CaseStyle.kebab))!;
        // then
        expect(instance.mainTitle, 'title');
        expect(instance.description, 'desc');
        expect(instance.hasMainProperty, true);
        expect(instance.primaryColor, Color.grayMetallic);
      });
    });
  });
}
