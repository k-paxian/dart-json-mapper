part of json_mapper_mobx.test;

@jsonSerializable
@Json(ignoreNullMembers: true)
class MobX {
  ObservableList<String> stringList = ObservableList<String>();
  ObservableList<num> numList = ObservableList<num>();
  ObservableList<bool> boolList = ObservableList<bool>();
  ObservableList<DateTime> dateTimeList = ObservableList<DateTime>();
  ObservableList<int> intList = ObservableList<int>();
  ObservableList<double> doubleList = ObservableList<double>();

  ObservableSet<String> stringSet = ObservableSet<String>();
  ObservableSet<num> numSet = ObservableSet<num>();
  ObservableSet<bool> boolSet = ObservableSet<bool>();
  ObservableSet<DateTime> dateTimeSet = ObservableSet<DateTime>();
  ObservableSet<int> intSet = ObservableSet<int>();
  ObservableSet<double> doubleSet = ObservableSet<double>();

  ObservableMap<String, dynamic> map = ObservableMap<String, dynamic>();

  Observable<String> stringObservable = Observable<String>('');
  Observable<DateTime> dateTimeObservable =
      Observable<DateTime>(DateTime.now());
  Observable<bool> boolObservable = Observable<bool>(false);
  Observable<num> numObservable = Observable<num>(0);
  Observable<int> intObservable = Observable<int>(0);
  Observable<double> doubleObservable = Observable<double>(0.0);

  MobX(
      {this.stringList,
      this.numList,
      this.boolList,
      this.dateTimeList,
      this.doubleList,
      this.intList,
      this.boolSet,
      this.dateTimeSet,
      this.doubleSet,
      this.intSet,
      this.numSet,
      this.stringSet,
      this.stringObservable,
      this.dateTimeObservable,
      this.numObservable,
      this.intObservable,
      this.doubleObservable,
      this.boolObservable,
      this.map});
}

void testObservables() {
  group('[Verify ObservableList]', () {
    test('ObservableList<String>', () {
      // given
      final json =
          '''{"stringList":["aa@test.com","bb@test.com","cc@test.com"]}''';
      final m = MobX(
          stringList: ObservableList<String>.of(
              ['aa@test.com', 'bb@test.com', 'cc@test.com']));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.stringList, TypeMatcher<ObservableList<String>>());
    });

    test('ObservableList<num>', () {
      // given
      final json = '''{"numList":[1,2.1,3]}''';
      final m = MobX(numList: ObservableList<num>.of([1, 2.1, 3]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.numList, TypeMatcher<ObservableList<num>>());
    });

    test('ObservableList<int>', () {
      // given
      final json = '''{"intList":[1,2,3]}''';
      final m = MobX(intList: ObservableList<int>.of([1, 2, 3]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.intList, TypeMatcher<ObservableList<int>>());
    });

    test('ObservableList<double>', () {
      // given
      final json = '''{"doubleList":[1.0003,2.0,3.0]}''';
      final m = MobX(doubleList: ObservableList<double>.of([1.0003, 2, 3]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.doubleList, TypeMatcher<ObservableList<double>>());
    });

    test('ObservableList<bool>', () {
      // given
      final json = '''{"boolList":[true,false,true]}''';
      final m = MobX(boolList: ObservableList<bool>.of([true, false, true]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.boolList, TypeMatcher<ObservableList<bool>>());
    });

    test('ObservableList<DateTime>', () {
      // given
      final json =
          '''{"dateTimeList":["2003-02-28 00:00:00.000","2013-01-23 00:00:00.000","2014-02-20 00:00:00.000"]}''';
      final m = MobX(
          dateTimeList: ObservableList<DateTime>.of([
        DateTime.parse('2003-02-28 00:00:00.000'),
        DateTime.parse('2013-01-23 00:00:00.000'),
        DateTime.parse('2014-02-20 00:00:00.000')
      ]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.dateTimeList, TypeMatcher<ObservableList<DateTime>>());
    });
  });

  group('[Verify ObservableSet]', () {
    test('ObservableSet<String>', () {
      // given
      final json =
          '''{"stringSet":["bb@test.com","aa@test.com","cc@test.com"]}''';
      final m = MobX(
          stringSet: ObservableSet<String>.of(
              ['aa@test.com', 'bb@test.com', 'cc@test.com']));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.stringSet, TypeMatcher<ObservableSet<String>>());
    });

    test('ObservableSet<num>', () {
      // given
      final json = '''{"numSet":[2.1,1,3]}''';
      final m = MobX(numSet: ObservableSet<num>.of([1, 2.1, 3]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.numSet, TypeMatcher<ObservableSet<num>>());
    });

    test('ObservableSet<int>', () {
      // given
      final json = '''{"intSet":[1,2,3]}''';
      final m = MobX(intSet: ObservableSet<int>.of([1, 2, 3]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.intSet, TypeMatcher<ObservableSet<int>>());
    });

    test('ObservableSet<double>', () {
      // given
      final json = '''{"doubleSet":[1.0003,2.0,3.0]}''';
      final m = MobX(doubleSet: ObservableSet<double>.of([1.0003, 2, 3]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.doubleSet, TypeMatcher<ObservableSet<double>>());
    });

    test('ObservableSet<bool>', () {
      // given
      final json = '''{"boolSet":[false,true]}''';
      final m = MobX(boolSet: ObservableSet<bool>.of([true, false, true]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.boolSet, TypeMatcher<ObservableSet<bool>>());
    });

    test('ObservableSet<DateTime>', () {
      // given
      final json =
          '''{"dateTimeSet":["2014-02-20 00:00:00.000","2013-01-23 00:00:00.000","2003-02-28 00:00:00.000"]}''';
      final m = MobX(
          dateTimeSet: ObservableSet<DateTime>.of([
        DateTime.parse('2003-02-28 00:00:00.000'),
        DateTime.parse('2013-01-23 00:00:00.000'),
        DateTime.parse('2014-02-20 00:00:00.000')
      ]));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.dateTimeSet, TypeMatcher<ObservableSet<DateTime>>());
    });
  });

  group('[Verify ObservableMap]', () {
    test('ObservableMap<String, dynamic>', () {
      // given
      final json = '''{"map":{"x":"xx","y":"yy"}}''';
      final m =
          MobX(map: ObservableMap<String, dynamic>.of({'x': 'xx', 'y': 'yy'}));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.map, TypeMatcher<ObservableMap<String, dynamic>>());
    });
  });

  group('[Verify Observable]', () {
    test('Observable<String>', () {
      // given
      final json = '''{"stringObservable":"xxx"}''';
      final m = MobX(stringObservable: Observable<String>('xxx'));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.stringObservable, TypeMatcher<Observable<String>>());
    });

    test('Observable<DateTime>', () {
      // given
      final json = '''{"dateTimeObservable":"2014-02-20 00:00:00.000"}''';
      final m = MobX(
          dateTimeObservable:
              Observable<DateTime>(DateTime.parse('2014-02-20 00:00:00.000')));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.dateTimeObservable, TypeMatcher<Observable<DateTime>>());
    });

    test('Observable<num>', () {
      // given
      final json = '''{"numObservable":5}''';
      final m = MobX(numObservable: Observable<num>(5));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.numObservable, TypeMatcher<Observable<num>>());
    });

    test('Observable<int>', () {
      // given
      final json = '''{"intObservable":5}''';
      final m = MobX(intObservable: Observable<int>(5));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.intObservable, TypeMatcher<Observable<int>>());
    });

    test('Observable<double>', () {
      // given
      final json = '''{"doubleObservable":5.3}''';
      final m = MobX(doubleObservable: Observable<double>(5.3));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.doubleObservable, TypeMatcher<Observable<double>>());
    });

    test('Observable<bool>', () {
      // given
      final json = '''{"boolObservable":true}''';
      final m = MobX(boolObservable: Observable<bool>(true));
      // when
      final targetJson = JsonMapper.serialize(m, '');
      final instance = JsonMapper.deserialize<MobX>(targetJson);
      // then
      expect(targetJson, json);
      expect(instance, TypeMatcher<MobX>());
      expect(instance.boolObservable, TypeMatcher<Observable<bool>>());
    });
  });
}
