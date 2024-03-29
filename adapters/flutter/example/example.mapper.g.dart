// This file has been generated by the dart_json_mapper v2.2.9
// https://github.com/k-paxian/dart-json-mapper
// @dart = 2.12
import 'example.dart' as x0 show FlutterClass;
import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, JsonMapperAdapter, SerializationOptions, DeserializationOptions, typeOf;
// This file has been generated by the reflectable package.
// https://github.com/dart-lang/reflectable.

import 'dart:core';
import 'dart:ui' as prefix2;
import 'example.dart' as prefix1;
import 'package:dart_json_mapper/src/model/annotations.dart' as prefix0;

// ignore_for_file: camel_case_types
// ignore_for_file: implementation_imports
// ignore_for_file: prefer_adjacent_string_concatenation
// ignore_for_file: prefer_collection_literals
// ignore_for_file: unnecessary_const

// ignore:unused_import
import 'package:reflectable/mirrors.dart' as m;
// ignore:unused_import
import 'package:reflectable/src/reflectable_builder_based.dart' as r;
// ignore:unused_import
import 'package:reflectable/reflectable.dart' as r show Reflectable;

final _data = <r.Reflectable, r.ReflectorData>{const prefix0.JsonSerializable(): r.ReflectorData(<m.TypeMirror>[r.NonGenericClassMirrorImpl(r'FlutterClass', r'json_mapper_flutter.example.FlutterClass', 134217735, 0, const prefix0.JsonSerializable(), const <int>[0, 3], const <int>[4, 5, 6, 7, 8, 1, 2], const <int>[], -1, {}, {}, {r'': (bool b) => (color) => b ? prefix1.FlutterClass(color) : null}, -1, 0, const <int>[], const [prefix0.jsonSerializable], null)], <m.DeclarationMirror>[r.VariableMirrorImpl(r'color', 134348805, 0, const prefix0.JsonSerializable(), -1, 1, 1, const <int>[], const []), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 0, 1), r.ImplicitSetterMirrorImpl(const prefix0.JsonSerializable(), 0, 2), r.MethodMirrorImpl(r'', 0, 0, -1, 0, 0, const <int>[], const <int>[0], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'==', 2097154, -1, -1, 2, 2, const <int>[], const <int>[2], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'toString', 2097154, -1, -1, 3, 3, const <int>[], const <int>[], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'noSuchMethod', 524290, -1, -1, -1, -1, const <int>[], const <int>[3], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'hashCode', 2097155, -1, -1, 4, 4, const <int>[], const <int>[], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'runtimeType', 2097155, -1, -1, 5, 5, const <int>[], const <int>[], const prefix0.JsonSerializable(), const [])], <m.ParameterMirror>[r.ParameterMirrorImpl(r'color', 134349830, 3, const prefix0.JsonSerializable(), -1, 1, 1, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'_color', 134348902, 2, const prefix0.JsonSerializable(), -1, 1, 1, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'other', 134348806, 4, const prefix0.JsonSerializable(), -1, 6, 6, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'invocation', 134348806, 6, const prefix0.JsonSerializable(), -1, 7, 7, const <int>[], const [], null, null)], <Type>[prefix1.FlutterClass, prefix2.Color, bool, String, int, Type, Object, Invocation], 1, {r'==': (dynamic instance) => (x) => instance == x, r'toString': (dynamic instance) => instance.toString, r'noSuchMethod': (dynamic instance) => instance.noSuchMethod, r'hashCode': (dynamic instance) => instance.hashCode, r'runtimeType': (dynamic instance) => instance.runtimeType, r'color': (dynamic instance) => instance.color}, {r'color=': (dynamic instance, value) => instance.color = value}, null, [])};


final _memberSymbolMap = null;

void _initializeReflectable(JsonMapperAdapter adapter) {
  if (!adapter.isGenerated) {
    return;
  }
  r.data = adapter.reflectableData!;
  r.memberSymbolMap = adapter.memberSymbolMap;
}

final exampleGeneratedAdapter = JsonMapperAdapter(
  title: 'dart_json_mapper_flutter',
  url: 'asset:dart_json_mapper_flutter/example/example.dart',
  refUrl: 'https://github.com/k-paxian/dart-json-mapper/tree/master/adapters/flutter',
  reflectableData: _data,
  memberSymbolMap: _memberSymbolMap,
  valueDecorators: {
    typeOf<List<x0.FlutterClass>>(): (value) => value.cast<x0.FlutterClass>(),
    typeOf<Set<x0.FlutterClass>>(): (value) => value.cast<x0.FlutterClass>()
},
  enumValues: {

});

Future<JsonMapper> initializeJsonMapperAsync({Iterable<JsonMapperAdapter> adapters = const [], SerializationOptions? serializationOptions, DeserializationOptions? deserializationOptions}) => Future(() => initializeJsonMapper(adapters: adapters, serializationOptions: serializationOptions, deserializationOptions: deserializationOptions));

JsonMapper initializeJsonMapper({Iterable<JsonMapperAdapter> adapters = const [], SerializationOptions? serializationOptions, DeserializationOptions? deserializationOptions}) {
  JsonMapper.globalSerializationOptions = serializationOptions ?? JsonMapper.globalSerializationOptions;
  JsonMapper.globalDeserializationOptions = deserializationOptions ?? JsonMapper.globalDeserializationOptions;    
  JsonMapper.enumerateAdapters([...adapters, exampleGeneratedAdapter], (JsonMapperAdapter adapter) {
    _initializeReflectable(adapter);
    JsonMapper().useAdapter(adapter);
  });
  return JsonMapper();
}