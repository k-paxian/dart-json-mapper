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

@jsonSerializable
class MyCar {
  @JsonProperty(name: 'modelName')
  String model;

  @JsonProperty(enumValues: Color.values)
  Color color;

  MyCar replacement;

  MyCar(this.model, this.color);
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
      final MyCar car = MyCar('VW', Color.Blue);
      car.replacement = car;
      expect(catchError(() => JsonMapper.serialize(car)),
          TypeMatcher<CircularReferenceError>());
    });

    test("Missing annotation on class", () {
      expect(catchError(() => JsonMapper.serialize(UnAnnotated())),
          TypeMatcher<MissingAnnotationOnTypeError>());
    });

    test("Missing annotation on Enum field", () {
      expect(catchError(() => JsonMapper.serialize(UnAnnotatedEnumField())),
          TypeMatcher<MissingEnumValuesError>());
    });

    test("Wrong annotation on Enum field", () {
      final json = '{"sex":"Sex.Female"}';
      expect(catchError(() {
        WrongAnnotatedEnumField target = JsonMapper.deserialize(json);
      }), TypeMatcher<MissingEnumValuesError>());
    });

    test("Missing target type for deserialization", () {
      expect(catchError(() => JsonMapper.deserialize("{}")),
          TypeMatcher<MissingTypeForDeserializationError>());
    });
  });
}
