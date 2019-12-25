library json_mapper_mobx;

import 'package:dart_json_mapper/json_mapper.dart';
import 'package:mobx/mobx.dart';

final mobXTypeInfoDecorator = MobXTypeInfoDecorator();

class MobXTypeInfoDecorator extends DefaultTypeInfoDecorator {
  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    final isObservableList = typeInfo.typeName.indexOf('ObservableList<') == 0;
    final isObservableMap = typeInfo.typeName.indexOf('ObservableMap<') == 0;
    final isObservableSet = typeInfo.typeName.indexOf('ObservableSet<') == 0;
    typeInfo.isSet = typeInfo.isSet || isObservableSet;
    typeInfo.isMap = typeInfo.isMap || isObservableMap;
    typeInfo.isIterable =
        typeInfo.isIterable || isObservableList || isObservableSet;
    typeInfo.scalarType = detectScalarType(typeInfo);
    return typeInfo;
  }
}

final observableMapConverter = ObservableMapConverter();

/// [ObservableMap] converter
class ObservableMapConverter
    implements ICustomConverter<ObservableMap<String, dynamic>> {
  const ObservableMapConverter() : super();

  @override
  ObservableMap<String, dynamic> fromJSON(dynamic jsonValue,
          [JsonProperty jsonProperty]) =>
      ObservableMap<String, dynamic>.of(jsonValue);

  @override
  dynamic toJSON(Object object, [JsonProperty jsonProperty]) {
    return object;
  }
}

final observableStringConverter = ObservableStringConverter();

/// [ObservableStringConverter] converter
class ObservableStringConverter
    implements ICustomConverter<Observable<String>> {
  const ObservableStringConverter() : super();

  @override
  Observable<String> fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) =>
      jsonValue is String ? Observable<String>(jsonValue) : jsonValue;

  @override
  dynamic toJSON(Observable<dynamic> object, [JsonProperty jsonProperty]) {
    return object.value is String ? object.value : object.value.toString();
  }
}

final observableDateTimeConverter = ObservableDateTimeConverter();

/// [ObservableDateTimeConverter] converter
class ObservableDateTimeConverter
    implements ICustomConverter<Observable<DateTime>> {
  const ObservableDateTimeConverter() : super();

  @override
  Observable<DateTime> fromJSON(dynamic jsonValue,
          [JsonProperty jsonProperty]) =>
      jsonValue is String
          ? Observable<DateTime>(
              dateConverter.fromJSON(jsonValue, jsonProperty))
          : jsonValue;

  @override
  dynamic toJSON(Observable<DateTime> object, [JsonProperty jsonProperty]) =>
      dateConverter.toJSON(object.value, jsonProperty);
}

final observableNumConverter = ObservableNumConverter();

/// [ObservableNumConverter] converter
class ObservableNumConverter implements ICustomConverter<Observable<num>> {
  const ObservableNumConverter() : super();

  @override
  Observable<num> fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) =>
      (jsonValue is String || jsonValue is num)
          ? Observable<num>(numberConverter.fromJSON(jsonValue, jsonProperty))
          : jsonValue;

  @override
  dynamic toJSON(Observable<num> object, [JsonProperty jsonProperty]) =>
      numberConverter.toJSON(object.value, jsonProperty);
}

final observableIntConverter = ObservableIntConverter();

/// [ObservableIntConverter] converter
class ObservableIntConverter implements ICustomConverter<Observable<int>> {
  const ObservableIntConverter() : super();

  @override
  Observable<int> fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) =>
      (jsonValue is String || jsonValue is int)
          ? Observable<int>(numberConverter.fromJSON(jsonValue, jsonProperty))
          : jsonValue;

  @override
  dynamic toJSON(Observable<int> object, [JsonProperty jsonProperty]) =>
      numberConverter.toJSON(object.value, jsonProperty);
}

final observableDoubleConverter = ObservableDoubleConverter();

/// [ObservableDoubleConverter] converter
class ObservableDoubleConverter
    implements ICustomConverter<Observable<double>> {
  const ObservableDoubleConverter() : super();

  @override
  Observable<double> fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) =>
      (jsonValue is String || jsonValue is double)
          ? Observable<double>(
              numberConverter.fromJSON(jsonValue, jsonProperty))
          : jsonValue;

  @override
  dynamic toJSON(Observable<double> object, [JsonProperty jsonProperty]) =>
      numberConverter.toJSON(object.value, jsonProperty);
}

final observableBoolConverter = ObservableBoolConverter();

/// [ObservableBoolConverter] converter
class ObservableBoolConverter implements ICustomConverter<Observable<bool>> {
  const ObservableBoolConverter() : super();

  @override
  Observable<bool> fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) =>
      (jsonValue is String || jsonValue is bool)
          ? Observable<bool>(defaultConverter.fromJSON(jsonValue, jsonProperty))
          : jsonValue;

  @override
  dynamic toJSON(Observable<bool> object, [JsonProperty jsonProperty]) =>
      defaultConverter.toJSON(object.value, jsonProperty);
}

void initializeJsonMapperForMobX() {
  JsonMapper.registerTypeInfoDecorator(mobXTypeInfoDecorator);

  // Value decorators for ObservableList variations
  JsonMapper.registerValueDecorator<ObservableList<DateTime>>(
      (value) => ObservableList<DateTime>.of(value.cast<DateTime>()));
  JsonMapper.registerValueDecorator<ObservableList<String>>(
      (value) => ObservableList<String>.of(value.cast<String>()));
  JsonMapper.registerValueDecorator<ObservableList<num>>(
      (value) => ObservableList<num>.of(value.cast<num>()));
  JsonMapper.registerValueDecorator<ObservableList<int>>(
      (value) => ObservableList<int>.of(value.cast<int>()));
  JsonMapper.registerValueDecorator<ObservableList<double>>(
      (value) => ObservableList<double>.of(value.cast<double>()));
  JsonMapper.registerValueDecorator<ObservableList<bool>>(
      (value) => ObservableList<bool>.of(value.cast<bool>()));

  // Value decorators for ObservableSet variations
  JsonMapper.registerValueDecorator<ObservableSet<DateTime>>(
      (value) => ObservableSet<DateTime>.of(value.cast<DateTime>()));
  JsonMapper.registerValueDecorator<ObservableSet<String>>(
      (value) => ObservableSet<String>.of(value.cast<String>()));
  JsonMapper.registerValueDecorator<ObservableSet<num>>(
      (value) => ObservableSet<num>.of(value.cast<num>()));
  JsonMapper.registerValueDecorator<ObservableSet<int>>(
      (value) => ObservableSet<int>.of(value.cast<int>()));
  JsonMapper.registerValueDecorator<ObservableSet<double>>(
      (value) => ObservableSet<double>.of(value.cast<double>()));
  JsonMapper.registerValueDecorator<ObservableSet<bool>>(
      (value) => ObservableSet<bool>.of(value.cast<bool>()));

  // Value converters for ObservableMap variations
  JsonMapper.registerConverter<ObservableMap<String, dynamic>>(
      observableMapConverter);

  // Value converters for Observable variations
  JsonMapper.registerConverter<Observable<String>>(observableStringConverter);
  JsonMapper.registerConverter<Observable<DateTime>>(
      observableDateTimeConverter);
  JsonMapper.registerConverter<Observable<bool>>(observableBoolConverter);
  JsonMapper.registerConverter<Observable<num>>(observableNumConverter);
  JsonMapper.registerConverter<Observable<int>>(observableIntConverter);
  JsonMapper.registerConverter<Observable<double>>(observableDoubleConverter);
}
