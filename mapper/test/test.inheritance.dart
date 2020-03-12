part of json_mapper.test;

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
