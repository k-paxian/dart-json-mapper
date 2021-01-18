import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import './model/index.dart';

class UnAnnotated {}

enum Sex { Male, Female }

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
  Sex sex = Sex.Female;
}

@jsonSerializable
class ObjectWithRequiredField {
  @JsonProperty(requiredMessage: 'This Value is critically important')
  String value;

  @JsonProperty(notNullMessage: 'This Value2 cannot be null')
  String value2;
}

typedef ErrorGeneratorFunction = dynamic Function();
dynamic catchError(ErrorGeneratorFunction errorGenerator) {
  var targetError;
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

    test('Circular reference detection during serialization', () {
      final car = Car('VW', Color.Blue);
      car.replacement = car;
      expect(catchError(() => JsonMapper.serialize(car)),
          TypeMatcher<CircularReferenceError>());
    });

    test('[Suppress] Circular reference detection during serialization', () {
      final car = MyCar('VW', Color.Blue);
      car.replacement = car;
      expect(catchError(() => JsonMapper.serialize(car, compactOptions)), null);
    });

    test('Allow using same object same level during serialization', () {
      final device = Device();
      final us = UserSettings([device, device]);

      expect(catchError(() => JsonMapper.serialize(us, compactOptions)), null);
    });

    test('Missing annotation on class', () {
      expect(catchError(() => JsonMapper.serialize(UnAnnotated())),
          TypeMatcher<MissingAnnotationOnTypeError>());
    });

    test('Missing annotation on Enum field', () {
      final json = '''{"sex":"Sex.Female"}''';
      // Deserialize unannotated enum should NOT be fine
      expect(
          catchError(() => JsonMapper.deserialize<UnAnnotatedEnumField>(json)),
          TypeMatcher<MissingEnumValuesError>());
    });

    test('Missing target type for deserialization', () {
      expect(catchError(() => JsonMapper.deserialize('{}')),
          TypeMatcher<MissingTypeForDeserializationError>());
    });
  });
}
