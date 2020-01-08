export 'annotations.dart';
export 'converters.dart';
export 'type_info.dart';
export 'value_decorators.dart';

const defaultDeserializationOptions = DeserializationOptions();

class DeserializationOptions {
  /// Scheme to be used
  final dynamic scheme;

  const DeserializationOptions({this.scheme});
}

const defaultSerializationOptions = SerializationOptions();

class SerializationOptions extends DeserializationOptions {
  /// Indentation
  final String indent;

  /// Template
  final Map<String, dynamic> template;

  const SerializationOptions({scheme, this.indent, this.template})
      : super(scheme: scheme);
}

class ProcessedObjectDescriptor {
  dynamic object;
  int times = 0;

  ProcessedObjectDescriptor(this.object);
}
