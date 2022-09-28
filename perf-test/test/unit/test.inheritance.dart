import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart' show compactOptions;

@jsonSerializable
enum BusinessType { private, public, private2, public2 }

/// Case 1: Using getter only as [discriminatorProperty] ///////////////////////
@jsonSerializable
@Json(discriminatorProperty: 'type')
abstract class Business {
  BusinessType get type;
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.private)
class Hotel extends Business {
  int stars;

  @override
  BusinessType get type => BusinessType.private;

  Hotel(this.stars);
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.public)
class Startup extends Business {
  int userCount;

  @override
  BusinessType get type => BusinessType.public;

  Startup(this.userCount);
}

@jsonSerializable
class Stakeholder {
  String fullName;
  List<Business> businesses;

  Stakeholder(this.fullName, this.businesses);
}

/// Case 2: Using writable property as [discriminatorProperty] /////////////////
@jsonSerializable
@Json(discriminatorProperty: 'type')
abstract class Business2 {
  BusinessType? type;
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.private2)
class Hotel2 extends Business2 {
  int stars;

  Hotel2(this.stars);
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.public2)
class Startup2 extends Business2 {
  int userCount;

  Startup2(this.userCount);
}

@jsonSerializable
class Stakeholder2 {
  String fullName;
  List<Business2> businesses;

  Stakeholder2(this.fullName, this.businesses);
}

/// Case 3: No [discriminatorProperty] exists on the class /////////////////////
class DataModel {
  String? id;
  DataModel({this.id});
}

@jsonSerializable
@Json(discriminatorProperty: '@type')
abstract class AbstractUser extends DataModel {
  late final String? email;

  AbstractUser copyWith({
    String? id,
    String? email,
  });

  factory AbstractUser(String id) = UserImpl.newUser;
}

@jsonSerializable
class UserImpl extends DataModel implements AbstractUser {
  @override
  late final String? email;

  UserImpl({String? id, this.email}) : super(id: id);

  factory UserImpl.newUser(String id) {
    return UserImpl(
      id: id,
    );
  }

  @override
  AbstractUser copyWith({String? email, String? id}) {
    return UserImpl(id: id ?? this.id, email: email ?? this.email);
  }
}

@jsonSerializable
abstract class MyBaseClass {
  @JsonProperty(name: 'myCustomGetterName')
  String get myGetter;

  @JsonProperty(name: 'myCustomFieldName')
  final String myField = '';
}

@jsonSerializable
class MySuperclass implements MyBaseClass {
  @override
  String get myGetter => 'myGetterValue';

  @override
  final String myField = 'myFieldValue';
}

/// Case 4: Discriminator as of Type type /////////////////////
@JsonSerializable()
@Json(discriminatorProperty: 'type')
abstract class TypedParent {
  @JsonProperty(ignore: true)
  Type get type => runtimeType;

  var a = 1;
}

@JsonSerializable()
class TypedChild extends TypedParent {
  var b = "test";
}

/// Case 5: Discriminator as of type String /////////////////////
@JsonSerializable()
@Json(discriminatorProperty: 'type', discriminatorValue: 'p')
abstract class TypedStringParent {
  String get type => 'p';

  var a = 1;
}

@JsonSerializable()
@Json(discriminatorValue: 'ch')
class TypedStringChild extends TypedStringParent {
  @override
  String get type => 'ch';

  var b = "test";
}

void testInheritance() {
  group('[Verify inheritance cases]', () {
    test(
        'Should distinguish inherited classes by readonly discriminator property value',
        () {
      // given
      final jack = Stakeholder('Jack', [Startup(10), Hotel(4)]);

      // when
      final json = JsonMapper.serialize(jack);
      final target = JsonMapper.deserialize<Stakeholder>(json)!;

      // then
      expect(target.businesses[0], TypeMatcher<Startup>());
      expect(target.businesses[0].type, BusinessType.public);
      expect(target.businesses[1], TypeMatcher<Hotel>());
      expect(target.businesses[1].type, BusinessType.private);
    });

    test(
        'Should distinguish inherited classes by writable discriminator property value',
        () {
      // given
      final jack = Stakeholder2('Jack', [Startup2(10), Hotel2(4)]);

      // when
      final json = JsonMapper.serialize(jack);
      final target = JsonMapper.deserialize<Stakeholder2>(json)!;

      // then
      expect(target.businesses[0], TypeMatcher<Startup2>());
      expect(target.businesses[0].type, BusinessType.public2);
      expect(target.businesses[1], TypeMatcher<Hotel2>());
      expect(target.businesses[1].type, BusinessType.private2);
    });

    test('should inherit annotations from abstract class', () {
      // given
      final instance = MySuperclass();
      final json =
          '{"myCustomFieldName":"myFieldValue","myCustomGetterName":"myGetterValue"}';

      // when
      final targetJson = JsonMapper.serialize(instance, compactOptions);
      final target = JsonMapper.deserialize<MySuperclass>(targetJson)!;

      // then
      expect(targetJson, json);
      expect(target.myField, instance.myField);
      expect(target.myGetter, instance.myGetter);
    });

    test('implements AbstractUser', () {
      // given
      final user = UserImpl(id: 'xxx', email: 'x@x.com');

      // when
      final map = JsonMapper.toMap(user)!;
      final newUser = JsonMapper.fromMap<AbstractUser>(map)!;

      // then
      expect(map.containsKey('@type'), true);
      expect(map['@type'], 'UserImpl');

      expect(newUser.id, 'xxx');
      expect(newUser.email, 'x@x.com');
    });

    test('Discriminator as of Type type', () {
      // given
      final childInstance = TypedChild();

      // when
      final firstJson = JsonMapper.serialize(childInstance, compactOptions);
      final targetInstance = JsonMapper.deserialize<TypedParent>(firstJson);
      final secondJson = JsonMapper.serialize(targetInstance, compactOptions);

      // then
      expect(targetInstance, TypeMatcher<TypedChild>());
      expect(firstJson, secondJson);
    });
    test('Discriminator as of type String', () {
      // given
      final childInstance = TypedStringChild();

      // when
      final firstJson = JsonMapper.serialize(childInstance, compactOptions);
      final targetInstance =
          JsonMapper.deserialize<TypedStringParent>(firstJson);
      final secondJson = JsonMapper.serialize(targetInstance, compactOptions);

      // then
      expect(targetInstance, TypeMatcher<TypedStringChild>());
      expect(firstJson, secondJson);
    });
  });
}
