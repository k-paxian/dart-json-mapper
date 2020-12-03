import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import './model/index.dart';

enum Scheme { A, B }

@jsonSerializable
@Json(name: 'default')
@Json(name: '_', scheme: Scheme.B)
@Json(name: 'root', scheme: Scheme.A)
class Object {
  @JsonProperty(name: 'title_test', scheme: Scheme.B)
  String title;

  Object(this.title);
}

@jsonSerializable
@Json(name: 'Address')
class Address {
  @JsonProperty(name: 'first_name', scheme: Scheme.B)
  @JsonProperty(name: 'firstname', scheme: Scheme.A)
  String firstName;

  @JsonProperty(name: 'last_name', scheme: Scheme.B)
  @JsonProperty(name: 'lastname', scheme: Scheme.A)
  String lastName;

  @JsonProperty(name: 'email', scheme: Scheme.B)
  @JsonProperty(name: 'email', scheme: Scheme.A)
  String email;

  @JsonProperty(name: 'phone', scheme: Scheme.B)
  @JsonProperty(name: 'telephone', scheme: Scheme.A)
  String phoneNumber;

  @JsonProperty(name: 'country', scheme: Scheme.B)
  @JsonProperty(name: 'country_id', scheme: Scheme.A)
  String country;

  @JsonProperty(name: 'city', scheme: Scheme.B)
  @JsonProperty(name: 'city', scheme: Scheme.A)
  String city;

  @JsonProperty(name: 'postcode', scheme: Scheme.B)
  @JsonProperty(name: 'postcode', scheme: Scheme.A)
  String zipCode;

  @JsonProperty(name: 'address_1', scheme: Scheme.B)
  String street;

  @JsonProperty(name: 'street', scheme: Scheme.A)
  List<String> streetList;

  String id;
  String district;

  static Address fromJson(dynamic jsonValue, {Scheme scheme = Scheme.A}) =>
      JsonMapper.fromJson<Address>(
          jsonValue,
          DeserializationOptions(
              scheme: scheme, processAnnotatedMembersOnly: true));

  @JsonConstructor(scheme: Scheme.B)
  Address.jsonTwo();

  @JsonConstructor(scheme: Scheme.A)
  Address.jsonOne(@JsonProperty(name: 'id', scheme: Scheme.A) int _id,
      this.streetList, this.city)
      : id = _id.toString(),
        street = streetList?.elementAt(0),
        district = city;
}

void testScheme() {
  group('[Verify scheme processing]', () {
    test('Verify scheme A serialize', () {
      // given
      final instance = Object('Scheme A');
      // when
      final json = JsonMapper.serialize(
          instance, SerializationOptions(indent: '', scheme: Scheme.A));
      // then
      expect(json, '''{"root":{"title":"Scheme A"}}''');
    });

    test('Verify scheme A deserialize', () {
      // given
      final json = '''{"root":{"title":"Scheme A"}}''';
      // when
      final instance = JsonMapper.deserialize<Object>(
          json, DeserializationOptions(scheme: Scheme.A));
      // then
      expect(instance, TypeMatcher<Object>());
      expect(instance.title, 'Scheme A');
    });

    test('Verify scheme B serialize', () {
      // given
      final instance = Object('Scheme B');
      // when
      final json = JsonMapper.serialize(
          instance, SerializationOptions(indent: '', scheme: Scheme.B));
      // then
      expect(json, '''{"_":{"title_test":"Scheme B"}}''');
    });

    test('Verify scheme B deserialize', () {
      // given
      final json = '''{"_":{"title_test":"Scheme B"}}''';
      // when
      final instance = JsonMapper.deserialize<Object>(
          json, DeserializationOptions(scheme: Scheme.B));
      // then
      expect(instance, TypeMatcher<Object>());
      expect(instance.title, 'Scheme B');
    });

    test('Verify NO scheme serialize', () {
      // given
      final instance = Object('No Scheme');
      // when
      final json = JsonMapper.serialize(instance, compactOptions);
      // then
      expect(json, '''{"default":{"title":"No Scheme"}}''');
    });

    test('Verify NO scheme deserialize', () {
      // given
      final json = '''{"default":{"title":"No Scheme"}}''';
      // when
      final instance = JsonMapper.deserialize<Object>(json);
      // then
      expect(instance, TypeMatcher<Object>());
      expect(instance.title, 'No Scheme');
    });

    test('Verify two @JsonConstructor', () {
      // given
      final json = '''{"id":5,"email":"a@a.com"}''';

      // when
      final instance = Address.fromJson(json);

      // then
      expect(instance, TypeMatcher<Address>());
    });
  });
}
