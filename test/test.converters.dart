part of json_mapper.test;

class CustomStringConverter implements ICustomConverter<String> {
  const CustomStringConverter() : super();

  @override
  String fromJSON(dynamic jsonValue, JsonProperty jsonProperty) {
    return jsonValue;
  }

  @override
  dynamic toJSON(String object, JsonProperty jsonProperty) {
    return '_${object}_';
  }
}

@jsonSerializable
class BinaryData {
  Uint8List data;
  BinaryData(this.data);
}

@jsonSerializable
class BigIntData {
  BigInt bigInt;
  BigIntData(this.bigInt);
}

testConverters() {
  group("[Verify converters]", () {
    test("BigInt converter", () {
      // given
      final String rawString = "1234567890000000012345678900";
      final String json = '{"bigInt":"${rawString}"}';

      // when
      String targetJson =
          JsonMapper.serialize(BigIntData(BigInt.parse(rawString)), '');
      // then
      expect(targetJson, json);

      // when
      BigIntData target = JsonMapper.deserialize(json);
      // then
      expect(rawString, target.bigInt.toString());
    });

    test("Uint8List converter", () {
      // given
      final String json = '{"data":"QmFzZTY0IGlzIHdvcmtpbmch"}';
      final String rawString = "Base64 is working!";

      // when
      String targetJson = JsonMapper.serialize(
          BinaryData(Uint8List.fromList(rawString.codeUnits)), '');
      // then
      expect(targetJson, json);

      // when
      BinaryData target = JsonMapper.deserialize(json);
      // then
      expect(rawString, String.fromCharCodes(target.data));
    });

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
