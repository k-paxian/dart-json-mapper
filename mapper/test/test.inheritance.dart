part of json_mapper.test;

enum BusinessType { Private, Public }

@jsonSerializable
@Json(typeNameProperty: 'typeName')
abstract class Business {
  String name;
  @JsonProperty(enumValues: BusinessType.values)
  BusinessType type = BusinessType.Private;
}

@jsonSerializable
class Hotel extends Business {
  int stars;

  Hotel(this.stars);
}

@jsonSerializable
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
  String id;
  DataModel({this.id});
}

abstract class AbstractUser extends DataModel {
  final String email;

  AbstractUser copyWith({
    String id,
    String email,
  });

  factory AbstractUser(String id) = UserImpl.newUser;
}

@jsonSerializable
class UserImpl extends DataModel implements AbstractUser {
  @override
  final String email;

  UserImpl({String id, this.email}) : super(id: id);

  factory UserImpl.newUser(String id) {
    return UserImpl(
      id: id,
    );
  }

  @override
  AbstractUser copyWith({String email, String id}) {
    return UserImpl(id: id ?? this.id, email: email ?? this.email);
  }
}

void testInheritance() {
  group('[Verify inheritance cases]', () {
    test(
        'Should dump typeName to json property when'
        " @Json(typeNameProperty: 'typeName')", () {
      // given
      final jack = Stakeholder('Jack', [Startup(10), Hotel(4)]);

      // when
      final json = JsonMapper.serialize(jack);
      final target = JsonMapper.deserialize<Stakeholder>(json);

      // then
      expect(target.businesses[0], TypeMatcher<Startup>());
      expect(target.businesses[1], TypeMatcher<Hotel>());
    });

    test('implements AbstractUser', () {
      // given
      final user = UserImpl(id: 'xxx', email: 'x@x.com');
      final options = SerializationOptions(typeNameProperty: '@type');

      // when
      final map = JsonMapper.toMap(user, options);
      final newUser = JsonMapper.fromMap<AbstractUser>(map, options);

      // then
      expect(map.containsKey('@type'), true);
      expect(map['@type'], 'UserImpl');

      expect(newUser.id, 'xxx');
      expect(newUser.email, 'x@x.com');
    });
  });
}
