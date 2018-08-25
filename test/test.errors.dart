part of json_mapper.test;

class UnAnnotated {}

enum Sex { Male, Female }

@jsonSerializable
class UnAnnotatedEnumField {
  Sex sex = Sex.Female;
}

testErrorHandling() {
  group("[Verify error handling]", () {
    test("Circular reference detection during serialization", () {
      // given
      final Car car = Car('VW', Color.Blue);
      car.replacement = car;
      try {
        // when
        JsonMapper.serialize(car);
      } catch (error) {
        // then
        expect(error, TypeMatcher<CircularReferenceError>());
      }
    });

    test("Missing annotation on class", () {
      // given
      try {
        // when
        JsonMapper.serialize(UnAnnotated());
      } catch (error) {
        // then
        expect(error, TypeMatcher<MissingAnnotationOnTypeError>());
      }
    });

    test("Missing annotation on Enum field", () {
      // given
      try {
        // when
        JsonMapper.serialize(UnAnnotatedEnumField());
      } catch (error) {
        // then
        expect(error, TypeMatcher<MissingEnumValuesError>());
      }
    });
  });
}
