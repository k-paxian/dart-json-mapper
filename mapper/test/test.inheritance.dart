import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

@jsonSerializable
enum BusinessType { Private, Public }

@jsonSerializable
@Json(discriminatorProperty: 'type')
abstract class Business {
  String? name;
  BusinessType? type;
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.Private)
class Hotel extends Business {
  int stars;

  Hotel(this.stars);
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.Public)
class Startup extends Business {
  int userCount;

  Startup(this.userCount);
}

@jsonSerializable
class Stakeholder {
  String fullName;
  List<Business> businesses;

  Stakeholder(this.fullName, this.businesses);
}

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
    test('Should distinguish inherited classes by discriminator property value',
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
