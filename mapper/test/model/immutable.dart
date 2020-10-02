import 'package:dart_json_mapper/dart_json_mapper.dart';

import 'model.dart';

@jsonSerializable
class Immutable {
  final int id;
  final String name;
  final Car car;

  const Immutable(this.id, this.name, this.car);
}
