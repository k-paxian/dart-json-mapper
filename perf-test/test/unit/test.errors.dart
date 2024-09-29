import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';
import 'package:unit_testing/unit_testing.dart' show Car, Color, Business;

class UnAnnotated {}

enum Sex { male, female }

@jsonSerializable
@Json(allowCircularReferences: 1)
class MyCar extends Car {
  MyCar(model, color) : super(model, color);
}

@jsonSerializable
class Device {}

@jsonSerializable
class UserSettings {
  List<Device> devices;
  UserSettings(this.devices);
}

@jsonSerializable
class UnAnnotatedEnumField {
  Sex sex = Sex.female;
}

@jsonSerializable
class PartialPerson {
  final String name;
  final int age;
  const PartialPerson(this.age, this.name);
}

@jsonSerializable
class ObjectWithRequiredField {
  @JsonProperty(requiredMessage: 'This Value is critically important')
  String? value;

  @JsonProperty(notNullMessage: 'This Value2 cannot be null')
  String? value2;

  ObjectWithRequiredField({this.value, this.value2});
}

@jsonSerializable
@Json(ignoreNullMembers: true)
class ObjectWithRequiredNullableField {
  @JsonProperty(
      requiredMessage: 'This Value is critically important',
      ignoreForDeserialization: true,
      ignoreForSerialization: true,
      ignoreIfNull: true,
      ignore: true)
  String? value;

  @JsonProperty(
      notNullMessage: 'This Value2 cannot be null',
      required: true,
      ignoreForDeserialization: true,
      ignoreForSerialization: true,
      ignoreIfNull: true,
      ignore: true)
  String? value2;

  ObjectWithRequiredNullableField({this.value, this.value2});
}

typedef ErrorGeneratorFunction = dynamic Function();
dynamic catchError(ErrorGeneratorFunction errorGenerator) {
  dynamic targetError;
  try {
    errorGenerator();
  } catch (error) {
    targetError = error;
  }
  return targetError;
}

void testErrorHandling() {
  group('[Verify error handling]', () {
    test('Required fields presence check during deserialization', () {
      final json = '''{}''';
      // Deserialize w/o satisfied required fields should NOT be fine
      final error = catchError(
          () => JsonMapper.deserialize<ObjectWithRequiredField>(json));
      expect(error.toString(),
          'Field "value" is required. This Value is critically important.');
      expect(error, TypeMatcher<FieldIsRequiredError>());
    });

    test('NotNull fields value check during deserialization', () {
      final json = '''{"value":null,"value2":null}''';
      // Deserialize w/o satisfied notNull fields should NOT be fine
      final error = catchError(
          () => JsonMapper.deserialize<ObjectWithRequiredField>(json));
      expect(error.toString(),
          'Field "value2" cannot be NULL. This Value2 cannot be null.');
      expect(error, TypeMatcher<FieldCannotBeNullError>());
    });

    test('NotNull fields presence & value check during deserialization', () {
      final json = '''{"value":null}''';
      // Deserialize w/o satisfied notNull fields should NOT be fine
      final error = catchError(
          () => JsonMapper.deserialize<ObjectWithRequiredField>(json));
      expect(error.toString(),
          'Field "value2" cannot be NULL. This Value2 cannot be null.');
      expect(error, TypeMatcher<FieldCannotBeNullError>());
    });

    test('NotNull fields presence & value check during serialization', () {
      final instance = ObjectWithRequiredField(value: null, value2: null);
      expect(catchError(() => JsonMapper.serialize(instance)),
          TypeMatcher<FieldCannotBeNullError>());
    });

    test(
        'NotNull fields presence & value check during serialization'
        '[required], [ignore], [ignoreForDeserialization], '
        '[ignoreForSerialization], [ignoreIfNull], '
        '[Json.ignoreNullMembers] has no meaning', () {
      final instance = ObjectWithRequiredNullableField();
      expect(catchError(() => JsonMapper.serialize(instance)),
          TypeMatcher<FieldCannotBeNullError>());
    });

    test(
        'Should be no error if NotNull field has value'
        '[required], [ignore], [ignoreForDeserialization], '
        '[ignoreForSerialization], [ignoreIfNull], '
        '[Json.ignoreNullMembers] has no meaning', () {
      final instance = ObjectWithRequiredNullableField(value2: '');
      final json = JsonMapper.serialize(instance);
      expect(json, '{"value":null,"value2":""}');
      expect(catchError(() => JsonMapper.serialize(instance)), null);
    });

    test('Circular reference detection during serialization', () {
      final car = Car('VW', Color.blue);
      car.replacement = car;
      expect(catchError(() => JsonMapper.serialize(car)),
          TypeMatcher<CircularReferenceError>());
    });

    test('[Suppress] Circular reference detection during serialization', () {
      final car = MyCar('VW', Color.blue);
      car.replacement = car;
      expect(catchError(() => JsonMapper.serialize(car)), null);
    });

    test('Unable to create instance of class error handling - null arguments', () {
      // given
      final json = '{"name":"James"}';

      // when
      final error =
          catchError(() => JsonMapper.deserialize<PartialPerson>(json));

      // then
      expect(
          error.toString(),
          'Unable to instantiate class \'PartialPerson\'\n'
          '  with null positional arguments [age]');
      expect(error, TypeMatcher<CannotCreateInstanceError>());
    });

    test('Unable to create instance of class error handling', () {
      // given
      final json = '{"name":["James"],"age":{}}';

      // when
      final error =
      catchError(() => JsonMapper.deserialize<PartialPerson>(json));

      // then
      expect(
          error.toString(),
          'type \'_Map<String, dynamic>\' is not a subtype of type \'int\'');
      expect(error, TypeMatcher<CannotCreateInstanceError>());
    });

    test('Allow using same object same level during serialization', () {
      final device = Device();
      final us = UserSettings([device, device]);

      expect(catchError(() => JsonMapper.serialize(us)), null);
    });

    test('Missing annotation on class', () {
      expect(catchError(() => JsonMapper.serialize(UnAnnotated())),
          TypeMatcher<MissingAnnotationOnTypeError>());
    });

    test('Missing target type for deserialization', () {
      expect(catchError(() => JsonMapper.deserialize('{}')),
          TypeMatcher<MissingTypeForDeserializationError>());
    });

    test('Discriminator property value is wrong', () {
      // given
      final json = '{"type":"p","a":1}';

      // when
      final error = catchError(() => JsonMapper.deserialize<Business>(json));

      // then
      expect(
          error.toString(),
          '"p" is not a valid discriminator value for type "Business".\n'
          '\n'
          'Valid values are:\n'
          '  - BusinessType.private,\n'
          '  - BusinessType.public');
      expect(error, TypeMatcher<JsonMapperSubtypeError>());
    });
  });
}
