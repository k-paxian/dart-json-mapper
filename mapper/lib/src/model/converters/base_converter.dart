import '../index.dart';

typedef SerializeObjectFunction = dynamic Function(
    Object? object, SerializationContext context);
typedef DeserializeObjectFunction = dynamic Function(
    dynamic object, DeserializationContext context, Type type);
typedef GetConverterFunction = ICustomConverter? Function(
    JsonProperty? jsonProperty, TypeInfo typeInfo);
typedef GetConvertedValueFunction = dynamic Function(
    ICustomConverter converter, dynamic value, DeserializationContext context);

/// Abstract class for custom converters implementations
abstract class ICustomConverter<T> {
  dynamic toJSON(T object, SerializationContext context);
  T fromJSON(dynamic jsonValue, DeserializationContext context);
}

/// Abstract class for custom iterable converters implementations
abstract class ICustomIterableConverter {
  void setIterableInstance(Iterable? instance);
}

/// Abstract class for custom map converters implementations
abstract class ICustomMapConverter {
  void setMapInstance(Map? instance);
}

/// Abstract class for custom Enum converters implementations
abstract class ICustomEnumConverter {
  void setEnumDescriptor(IEnumDescriptor? enumDescriptor);
}

/// Abstract class for composite converters relying on other converters
abstract class ICompositeConverter {
  void setGetConverterFunction(GetConverterFunction getConverter);
  void setGetConvertedValueFunction(
      GetConvertedValueFunction getConvertedValue);
}

/// Abstract class for custom recursive converters implementations
abstract class IRecursiveConverter {
  void setSerializeObjectFunction(SerializeObjectFunction serializeObject);
  void setDeserializeObjectFunction(
      DeserializeObjectFunction deserializeObject);
}

/// Base class for custom type converter having access to parameters provided
/// by the [JsonProperty] meta
class BaseCustomConverter {
  const BaseCustomConverter() : super();
  dynamic getConverterParameter(String name, [JsonProperty? jsonProperty]) {
    return jsonProperty != null && jsonProperty.converterParams != null
        ? jsonProperty.converterParams![name]
        : null;
  }
}