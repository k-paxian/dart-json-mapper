library json_mapper_mobx;

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:mobx/mobx.dart';

/// Shorthand for ready made decorator instance
final mobXTypeInfoDecorator = MobXTypeInfoDecorator();

/// Type info decorator provides support for MobX types like
/// ObservableList, ObservableMap, ObservableSet
class MobXTypeInfoDecorator extends DefaultTypeInfoDecorator {
  bool isObservableList(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('ObservableList<') == 0;

  bool isObservableMap(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('ObservableMap<') == 0;

  bool isObservableSet(TypeInfo typeInfo) =>
      typeInfo.typeName!.indexOf('ObservableSet<') == 0;

  @override
  TypeInfo decorate(TypeInfo typeInfo) {
    typeInfo = super.decorate(typeInfo);
    typeInfo.isList = typeInfo.isList || isObservableList(typeInfo);
    typeInfo.isSet = typeInfo.isSet || isObservableSet(typeInfo);
    typeInfo.isMap = typeInfo.isMap || isObservableMap(typeInfo);
    typeInfo.isIterable =
        typeInfo.isIterable || typeInfo.isList || typeInfo.isSet;
    typeInfo.genericType = detectGenericType(typeInfo);
    return typeInfo;
  }

  @override
  Type? detectGenericType(TypeInfo typeInfo) {
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

/// Shorthand for ready made converter instance
final observableStringConverter = ObservableStringConverter();

/// [ObservableStringConverter] converter
class ObservableStringConverter
    implements ICustomConverter<Observable<String>?> {
  const ObservableStringConverter() : super();

  @override
  Observable<String>? fromJSON(dynamic jsonValue,
          DeserializationContext context) =>
      jsonValue is String ? Observable<String>(jsonValue) : jsonValue;

  @override
  dynamic toJSON(Observable<dynamic>? object, SerializationContext context) {
    return object!.value is String ? object.value : object.value.toString();
  }
}

/// Shorthand for ready made converter instance
final observableDateTimeConverter = ObservableDateTimeConverter();

/// [ObservableDateTimeConverter] converter
class ObservableDateTimeConverter
    implements ICustomConverter<Observable<DateTime>?> {
  const ObservableDateTimeConverter() : super();

  @override
  Observable<DateTime>? fromJSON(dynamic jsonValue,
          DeserializationContext context) =>
      jsonValue is String
          ? Observable<DateTime>(
              dateConverter.fromJSON(jsonValue, context) as DateTime)
          : jsonValue;

  @override
  dynamic toJSON(Observable<DateTime>? object,
          SerializationContext context) =>
      dateConverter.toJSON(object!.value, context);
}

/// Shorthand for ready made converter instance
final observableNumConverter = ObservableNumConverter();

/// [ObservableNumConverter] converter
class ObservableNumConverter implements ICustomConverter<Observable<num>?> {
  const ObservableNumConverter() : super();

  @override
  Observable<num>? fromJSON(dynamic jsonValue,
          DeserializationContext context) =>
      (jsonValue is String || jsonValue is num)
          ? Observable<num>(numberConverter.fromJSON(jsonValue, context) as num)
          : jsonValue;

  @override
  dynamic toJSON(Observable<num>? object, SerializationContext context) =>
      numberConverter.toJSON(object!.value, context);
}

/// Shorthand for ready made converter instance
final observableIntConverter = ObservableIntConverter();

/// [ObservableIntConverter] converter
class ObservableIntConverter implements ICustomConverter<Observable<int>?> {
  const ObservableIntConverter() : super();

  @override
  Observable<int>? fromJSON(dynamic jsonValue,
          DeserializationContext context) =>
      (jsonValue is String || jsonValue is int)
          ? Observable<int>(numberConverter.fromJSON(jsonValue, context) as int)
          : jsonValue;

  @override
  dynamic toJSON(Observable<int>? object, SerializationContext context) =>
      numberConverter.toJSON(object!.value, context);
}

/// Shorthand for ready made converter instance
final observableDoubleConverter = ObservableDoubleConverter();

/// [ObservableDoubleConverter] converter
class ObservableDoubleConverter
    implements ICustomConverter<Observable<double>?> {
  const ObservableDoubleConverter() : super();

  @override
  Observable<double>? fromJSON(dynamic jsonValue,
          DeserializationContext context) =>
      (jsonValue is String || jsonValue is double)
          ? Observable<double>(
              numberConverter.fromJSON(jsonValue, context) as double)
          : jsonValue;

  @override
  dynamic toJSON(Observable<double>? object, SerializationContext context) =>
      numberConverter.toJSON(object!.value, context);
}

/// Shorthand for ready made converter instance
final observableBoolConverter = ObservableBoolConverter();

/// [ObservableBoolConverter] converter
class ObservableBoolConverter implements ICustomConverter<Observable<bool>?> {
  const ObservableBoolConverter() : super();

  @override
  Observable<bool>? fromJSON(dynamic jsonValue,
          DeserializationContext context) =>
      (jsonValue is String || jsonValue is bool)
          ? Observable<bool>(
              defaultConverter.fromJSON(jsonValue, context) as bool)
          : jsonValue;

  @override
  dynamic toJSON(Observable<bool>? object, SerializationContext context) =>
      defaultConverter.toJSON(object!.value, context);
}

/// Adapter definition, should be passed to the Json Mapper initialization method:
///  initializeJsonMapper(adapters: [mobXAdapter]);
final mobXAdapter = JsonMapperAdapter(
    title: 'MobX Adapter',
    refUrl: 'https://github.com/mobxjs/mobx.dart',
    url:
        'https://github.com/k-paxian/dart-json-mapper/tree/master/adapters/mobx',
    typeInfoDecorators: {
      0: mobXTypeInfoDecorator
    },
    converters: {
      ObservableList: defaultIterableConverter,
      ObservableSet: defaultIterableConverter,
      ObservableMap: mapConverter,

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
