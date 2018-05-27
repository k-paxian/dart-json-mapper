library json_mapper.annotations;

import 'package:dart_json_mapper/converters.dart';
import "package:reflectable/reflectable.dart";

class JsonProperty {
  final String name;
  final ICustomConverter converter;
  final bool ignore;
  final Type type;
  final List<dynamic> enumValues;

  const JsonProperty(
      {this.name, this.ignore, this.converter, this.type, this.enumValues});

  String toString() {
    return "JsonProperty name: ${name}, "
        "ignore: ${ignore}, "
        "type: ${type}, "
        "enumValues: ${enumValues}, "
        "converter: ${converter}";
  }
}

class JsonSerializable extends Reflectable {
  const JsonSerializable()
      : super(instanceInvokeCapability, metadataCapability,
            newInstanceCapability, declarationsCapability);
}
