library json_mapper_mobx;

import 'dart:convert' show JsonDecoder;

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:mobx/mobx.dart';

final mobXTypeInfoDecorator = MobXTypeInfoDecorator();

class MobXTypeInfoDecorator extends DefaultTypeInfoDecorator {
  bool isObservableList(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('ObservableList<') == 0;

  bool isObservableMap(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('ObservableMap<') == 0;

  bool isObservableSet(TypeInfo typeInfo) =>
      typeInfo.typeName.indexOf('ObservableSet<') == 0;

  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    typeInfo.isList = typeInfo.isList || isObservableList(typeInfo);
    typeInfo.isSet = typeInfo.isSet || isObservableSet(typeInfo);
    typeInfo.isMap = typeInfo.isMap || isObservableMap(typeInfo);
    typeInfo.isIterable =
        typeInfo.isIterable || typeInfo.isList || typeInfo.isSet;
    typeInfo.scalarType = detectScalarType(typeInfo);
    typeInfo.genericType = detectGenericType(typeInfo);
    return typeInfo;
  }

  @override
  Type detectGenericType(TypeInfo typeInfo) {
    if (isObservableList(typeInfo)) {
      return ObservableList;
    }
    if (isObservableSet(typeInfo)) {
      return ObservableSet;
    }
    if (isObservableMap(typeInfo)) {
      return ObservableMap;
    }
    return super.detectGenericType(typeInfo);
  }
}

final observableMapConverter = ObservableMapConverter();

/// [ObservableMap<K, V>] converter
class ObservableMapConverter
    implements ICustomConverter, IRecursiveConverter, ICustomMapConverter {
  ObservableMapConverter() : super();

  SerializeObjectFunction _serializeObject;
  Map _instance;

  @override
  dynamic fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    var result = jsonValue;
    if (_instance != null && jsonValue is Map && jsonValue != _instance) {
      result = _instance;
    }
    return result;
  }

  @override
  dynamic toJSON(dynamic object, [JsonProperty jsonProperty]) => object.map(
      (key, value) => MapEntry(_serializeObject(key), _serializeObject(value)));

  @override
  void setSerializeObjectFunction(SerializeObjectFunction serializeObject) {
    _serializeObject = serializeObject;
  }

  @override
  void setMapInstance(Map instance) {
    _instance = instance;
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

final iterableConverter = IterableConverter();

/// Iterable converter
class IterableConverter implements ICustomConverter, ICustomIterableConverter {
  IterableConverter() : super();

  static JsonDecoder jsonDecoder = JsonDecoder();

  Iterable _instance;

  @override
  dynamic fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    if (_instance != null && jsonValue is Iterable) {
      if (_instance is List) {
        (_instance as List).clear();
        jsonValue.forEach((item) => (_instance as List).add(item));
      }
      if (_instance is Set) {
        (_instance as Set).clear();
        jsonValue.forEach((item) => (_instance as Set).add(item));
      }
      return _instance;
    }
    return jsonValue;
  }

  @override
  dynamic toJSON(dynamic object, [JsonProperty jsonProperty]) {
    return object;
  }

  @override
  void setIterableInstance(Iterable instance) {
    _instance = instance;
  }
}

final mobXAdapter = JsonMapperAdapter(
    title: 'MobX Adapter',
    refUrl: 'https://github.com/mobxjs/mobx.dart',
    url:
        'https://github.com/k-paxian/dart-json-mapper/tree/master/adapters/mobx',
    typeInfoDecorators: {
      0: mobXTypeInfoDecorator
    },
    converters: {
      ObservableList: iterableConverter,
      ObservableSet: iterableConverter,
      ObservableMap: observableMapConverter,

      // Value converters for Observable variations
      typeOf<Observable<String>>(): observableStringConverter,
      typeOf<Observable<DateTime>>(): observableDateTimeConverter,
      typeOf<Observable<bool>>(): observableBoolConverter,
      typeOf<Observable<num>>(): observableNumConverter,
      typeOf<Observable<int>>(): observableIntConverter,
      typeOf<Observable<double>>(): observableDoubleConverter
    },
    valueDecorators: {
      // Value decorators for ObservableList variations
      typeOf<ObservableList<DateTime>>(): (value) =>
          ObservableList<DateTime>.of(value.cast<DateTime>()),
      typeOf<ObservableList<String>>(): (value) =>
          ObservableList<String>.of(value.cast<String>()),
      typeOf<ObservableList<num>>(): (value) =>
          ObservableList<num>.of(value.cast<num>()),
      typeOf<ObservableList<int>>(): (value) =>
          ObservableList<int>.of(value.cast<int>()),
      typeOf<ObservableList<double>>(): (value) =>
          ObservableList<double>.of(value.cast<double>()),
      typeOf<ObservableList<bool>>(): (value) =>
          ObservableList<bool>.of(value.cast<bool>()),
      // Value decorators for ObservableSet variations
      typeOf<ObservableSet<DateTime>>(): (value) =>
          ObservableSet<DateTime>.of(value.cast<DateTime>()),
      typeOf<ObservableSet<String>>(): (value) =>
          ObservableSet<String>.of(value.cast<String>()),
      typeOf<ObservableSet<num>>(): (value) =>
          ObservableSet<num>.of(value.cast<num>()),
      typeOf<ObservableSet<int>>(): (value) =>
          ObservableSet<int>.of(value.cast<int>()),
      typeOf<ObservableSet<double>>(): (value) =>
          ObservableSet<double>.of(value.cast<double>()),
      typeOf<ObservableSet<bool>>(): (value) =>
          ObservableSet<bool>.of(value.cast<bool>()),
    });
