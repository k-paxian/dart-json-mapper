import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

@jsonSerializable
enum BusinessType { Private, Public, Private2, Public2 }

/// Case 1: Using getter only as [discriminatorProperty] ///////////////////////
@jsonSerializable
@Json(discriminatorProperty: 'type')
abstract class Business {
  BusinessType get type;
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.Private)
class Hotel extends Business {
  int stars;

  @override
  BusinessType get type => BusinessType.Private;

  Hotel(this.stars);
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.Public)
class Startup extends Business {
  int userCount;

  @override
  BusinessType get type => BusinessType.Public;

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
@Json(discriminatorValue: BusinessType.Private2)
class Hotel2 extends Business2 {
  int stars;

  Hotel2(this.stars);
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.Public2)
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
      expect(target.businesses[0].type, BusinessType.Public);
      expect(target.businesses[1], TypeMatcher<Hotel>());
      expect(target.businesses[1].type, BusinessType.Private);
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
      expect(target.businesses[0].type, BusinessType.Public2);
      expect(target.businesses[1], TypeMatcher<Hotel2>());
      expect(target.businesses[1].type, BusinessType.Private2);
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
  });
}
