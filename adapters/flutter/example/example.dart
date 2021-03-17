library json_mapper_flutter.example;

import 'dart:ui' show Color;

import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable;
import 'package:dart_json_mapper_flutter/dart_json_mapper_flutter.dart'
    show flutterAdapter;

import 'example.mapper.g.dart' show initializeJsonMapper;

@jsonSerializable
class FlutterClass {
  Color color;

  FlutterClass(this.color);
}

void main() {
  initializeJsonMapper(adapters: [flutterAdapter]);

  print(JsonMapper.serialize(FlutterClass(Color(0x003f4f5f))));
}
