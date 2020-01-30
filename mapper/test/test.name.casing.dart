part of json_mapper.test;

@jsonSerializable
class NameCaseObject {
  String mainTitle;
  String description;
  bool hasMainProperty;

  NameCaseObject({this.mainTitle, this.description, this.hasMainProperty});
}

void testNameCasing() {
  group('[Verify field names casing styles processing]', () {
    test('Verify CaseStyle.kebab', () {
      // given
      final instance = NameCaseObject(
          mainTitle: 'title', description: 'desc', hasMainProperty: true);
      // when
      final json = JsonMapper.serialize(instance,
          SerializationOptions(indent: '', caseStyle: CaseStyle.Kebab));
      // then
      expect(json,
          '''{"main-title":"title","description":"desc","has-main-property":true}''');
    });

    test('Verify CaseStyle.pascal', () {
      // given
      final instance = NameCaseObject(
          mainTitle: 'title', description: 'desc', hasMainProperty: true);
      // when
      final json = JsonMapper.serialize(instance,
          SerializationOptions(indent: '', caseStyle: CaseStyle.Pascal));
      // then
      expect(json,
          '''{"MainTitle":"title","Description":"desc","HasMainProperty":true}''');
    });

    test('Verify CaseStyle.Snake', () {
      // given
      final instance = NameCaseObject(
          mainTitle: 'title', description: 'desc', hasMainProperty: true);
      // when
      final json = JsonMapper.serialize(instance,
          SerializationOptions(indent: '', caseStyle: CaseStyle.Snake));
      // then
      expect(json,
          '''{"main_title":"title","description":"desc","has_main_property":true}''');
    });

    test('Verify CaseStyle.SnakeAllCaps', () {
      // given
      final instance = NameCaseObject(
          mainTitle: 'title', description: 'desc', hasMainProperty: true);
      // when
      final json = JsonMapper.serialize(instance,
          SerializationOptions(indent: '', caseStyle: CaseStyle.SnakeAllCaps));
      // then
      expect(json,
          '''{"MAIN_TITLE":"title","DESCRIPTION":"desc","HAS_MAIN_PROPERTY":true}''');
    });
  });
}
