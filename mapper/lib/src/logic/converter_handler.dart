import 'package:collection/collection.dart';
import 'package:dart_json_mapper/src/model/index.dart';

import '../mapper.dart';

class ConverterHandler {
  final JsonMapper _mapper;

  Map<Type, ICustomConverter> converters = {};
  final Map<
          ICustomConverter?,
          Map<ConversionDirection,
              Map<DeserializationContext?, Map<dynamic, dynamic>>>>
      convertedValuesCache = {};

  ConverterHandler(this._mapper);

  void clearCache() {
    convertedValuesCache.clear();
  }

  ICustomConverter? getConverter(
      JsonProperty? jsonProperty, TypeInfo typeInfo) {
    final result = jsonProperty?.converter ??
        converters[typeInfo.type!] ??
        converters[typeInfo.genericType] ??
        (_mapper.enumValues[typeInfo.type!] != null
            ? converters[Enum]
            : null) ??
        converters[converters.keys.firstWhereOrNull(
            (Type type) => type.toString() == typeInfo.typeName)];

    if (result is ICustomEnumConverter) {
      (result as ICustomEnumConverter)
          .setEnumDescriptor(getEnumDescriptor(_mapper.enumValues[typeInfo.type!]));
    }
    return result;
  }

  IEnumDescriptor? getEnumDescriptor(dynamic descriptor) {
    if (descriptor is Iterable) {
      return EnumDescriptor(values: descriptor);
    }
    if (descriptor is IEnumDescriptor) {
      return descriptor;
    }
    return null;
  }

  dynamic getConvertedValue(
      ICustomConverter converter, dynamic value, DeserializationContext context) {
    final direction = context.direction;
    if (convertedValuesCache.containsKey(converter) &&
        convertedValuesCache[converter]!.containsKey(direction) &&
        convertedValuesCache[converter]![direction]!.containsKey(context) &&
        convertedValuesCache[converter]![direction]![context]!
            .containsKey(value)) {
      return convertedValuesCache[converter]![direction]![context]![value];
    }

    final computedValue = direction == ConversionDirection.fromJson
        ? converter.fromJSON(value, context)
        : converter.toJSON(value, context as SerializationContext);
    convertedValuesCache.putIfAbsent(
        converter,
        () => {
              direction: {
                context: {value: computedValue}
              }
            });
    convertedValuesCache[converter]!.putIfAbsent(
        direction,
        () => {
              context: {value: computedValue}
            });
    convertedValuesCache[converter]![direction]!
        .putIfAbsent(context, () => {value: computedValue});
    convertedValuesCache[converter]![direction]![context]!
        .putIfAbsent(value, () => computedValue);
    return computedValue;
  }

  void configureConverter(
      ICustomConverter converter, DeserializationContext context,
      {dynamic value}) {
    if (converter is ICompositeConverter) {
      (converter as ICompositeConverter).setGetConverterFunction(getConverter);
      (converter as ICompositeConverter)
          .setGetConvertedValueFunction(getConvertedValue);
    }
    if (converter is ICustomIterableConverter) {
      (converter as ICustomIterableConverter).setIterableInstance(value);
    }
    if (converter is ICustomMapConverter) {
      final instance = value ?? (context.options.template);
      (converter as ICustomMapConverter).setMapInstance(instance);
    }
    if (converter is IRecursiveConverter) {
      (converter as IRecursiveConverter).setSerializeObjectFunction(
          (o, context) => _mapper.serializationHandler.serializeObject(o, context));
      (converter as IRecursiveConverter).setDeserializeObjectFunction((o,
              context, type) =>
          _mapper.deserializationHandler.deserializeObject(o, context.reBuild(typeInfo: _mapper.typeInfoHandler.getTypeInfo(type))));
    }
  }
}