part of json_mapper.test;

class CustomStringConverter implements ICustomConverter {
  const CustomStringConverter() : super();

  @override
  Object fromJSON(dynamic jsonValue, JsonProperty jsonProperty) {
    return jsonValue;
  }

  @override
  dynamic toJSON(Object object, JsonProperty jsonProperty) {
    return '_${object}_';
  }
}

testConverters() {
  group("[Verify converters]", () {
    test("Custom String converter", () {
      // given
      final String json = '''{
 "id": 1,
 "name": "_Bob_",
 "car": {
  "modelName": "_Audi_",
  "color": "Color.Green"
 }
}''';
      JsonMapper.registerConverter(String, CustomStringConverter());

      Immutable i = Immutable(1, 'Bob', Car('Audi', Color.Green));
      // when
      final String target = JsonMapper.serialize(i);
      // then
      expect(target, json);

      JsonMapper.registerConverter(String, defaultConverter);
    });
  });
}
