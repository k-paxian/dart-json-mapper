library json_mapper.annotations;

import 'package:json_mapper/converters.dart';
import "package:reflectable/reflectable.dart";

class JsonProperty {
  final String name;
  final ICustomConverter converter;
  final bool ignore;
  const JsonProperty({this.name, this.ignore, this.converter});

  String toString() {
    return "JsonProperty name: ${name}, ignore: ${ignore}, converter: ${converter}";
  }
}

class JsonSerializable extends Reflectable {
  const JsonSerializable()
      : super(instanceInvokeCapability, metadataCapability,
      newInstanceCapability, declarationsCapability);
}
