part of json_mapper.test;

class UnAnnotated {}

enum Sex { Male, Female }
const sexTypeValues = ["__female", "__male"];

@jsonSerializable
class UnAnnotatedEnumField {
  Sex sex = Sex.Female;
}

@jsonSerializable
class WrongAnnotatedEnumField {
  @JsonProperty(enumValues: sexTypeValues)
  Sex sex = Sex.Female;
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

testErrorHandling() {
  group("[Verify error handling]", () {
    test("Circular reference detection during serialization", () {
      final Car car = Car('VW', Color.Blue);
      car.replacement = car;
      expect(catchError(() => JsonMapper.serialize(car)),
          TypeMatcher<CircularReferenceError>());
    });

    test("Missing annotation on class", () {
      expect(catchError(() => JsonMapper.serialize(UnAnnotated())),
          TypeMatcher<MissingAnnotationOnTypeError>());
    });

    test("Missing annotation on Enum field", () {
      // Serialize unannotated enum should be fine
      final json = '''{"sex":"Sex.Female"}''';
      expect(JsonMapper.serialize(UnAnnotatedEnumField(), ''), json);

      // Deserialize unannotated enum should NOT be fine
      expect(
          catchError(() => JsonMapper.deserialize<UnAnnotatedEnumField>(json)),
          TypeMatcher<MissingEnumValuesError>());
    });

    test("Wrong enumValues in annotation on Enum field", () {
      final json = '{"sex":"Sex.Female"}';
      expect(catchError(() {
        JsonMapper.deserialize<WrongAnnotatedEnumField>(json);
      }), TypeMatcher<MissingEnumValuesError>());
    });

    test("Missing target type for deserialization", () {
      expect(catchError(() => JsonMapper.deserialize("{}")),
          TypeMatcher<MissingTypeForDeserializationError>());
    });
  });
}
