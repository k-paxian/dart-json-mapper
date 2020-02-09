import 'name_casing.dart';

export 'annotations.dart';
export 'converters.dart';
export 'name_casing.dart';
export 'type_info.dart';
export 'value_decorators.dart';

const defaultDeserializationOptions = DeserializationOptions();

class DeserializationOptions {
  /// The most popular ways to combine words into a single string
  /// Based on assumption: That all Dart class fields initially given as CaseStyle.Camel
  final CaseStyle caseStyle;

  /// Scheme to be used
  final dynamic scheme;

  const DeserializationOptions({this.scheme, this.caseStyle});
}

const defaultSerializationOptions = SerializationOptions();

class SerializationOptions extends DeserializationOptions {
  /// Indentation
  final String indent;

  /// Template
  final Map<String, dynamic> template;

  const SerializationOptions({scheme, caseStyle, this.indent, this.template})
      : super(scheme: scheme, caseStyle: caseStyle);
}

class ProcessedObjectDescriptor {
  dynamic object;
  int times = 0;

  ProcessedObjectDescriptor(this.object);
}
