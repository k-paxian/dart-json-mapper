library json_mapper_fixnum;

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:fixnum/fixnum.dart' show Int32, Int64;

final fixnumTypeInfoDecorator = FixnumTypeInfoDecorator();

class FixnumTypeInfoDecorator extends DefaultTypeInfoDecorator {
  @override
  Type detectScalarType(TypeInfo typeInfo) {
    final result = super.detectScalarType(typeInfo);
    if (result != null) {
      return result;
    }
    switch (typeInfo.scalarTypeName) {
      case 'Int32':
        return Int32;
      case 'Int64':
        return Int64;
      default:
        return null;
    }
  }
}

final int32Converter = Int32Converter();

/// [Int32] converter
class Int32Converter implements ICustomConverter {
  const Int32Converter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is String ? Int32.parseInt(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object is Int32 ? object.toString() : object;
  }
}

final int64Converter = Int64Converter();

/// [Int64] converter
class Int64Converter implements ICustomConverter {
  const Int64Converter() : super();

  @override
  Object fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue is String ? Int64.parseInt(jsonValue) : jsonValue;
  }

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object is Int64 ? object.toString() : object;
  }
}

void initializeJsonMapperForFixnum() {
  JsonMapper.registerTypeInfoDecorator(fixnumTypeInfoDecorator);

  JsonMapper.registerConverter<Int32>(int32Converter);
  JsonMapper.registerConverter<Int64>(int64Converter);

  JsonMapper.registerValueDecorator<List<Int32>>(
      (value) => value.cast<Int32>());
  JsonMapper.registerValueDecorator<List<Int64>>(
      (value) => value.cast<Int64>());

  JsonMapper.registerValueDecorator<Set<Int32>>((value) => value.cast<Int32>());
  JsonMapper.registerValueDecorator<Set<Int64>>((value) => value.cast<Int64>());
}
