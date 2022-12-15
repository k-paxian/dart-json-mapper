import 'package:dart_json_mapper/dart_json_mapper.dart';

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
