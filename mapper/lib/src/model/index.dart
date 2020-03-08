import 'name_casing.dart';

export 'adapters.dart';
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

  /// Null class members
  /// will be excluded from serialization process
  final bool ignoreNullMembers;

  /// Template
  final Map<String, dynamic> template;

  const SerializationOptions(
      {scheme, caseStyle, this.indent, this.template, this.ignoreNullMembers})
      : super(scheme: scheme, caseStyle: caseStyle);
}

class SerializationContext {
  final SerializationOptions options;
  final int level;

  const SerializationContext(this.options, [this.level = 0]);
}

class ProcessedObjectDescriptor {
  dynamic object;
  Map<int, int> usages = {}; // level : usagesCounter

  ProcessedObjectDescriptor(this.object);

  int get levelsCount {
    return usages.keys.length;
  }

  void logUsage(int level) {
    if (usages.containsKey(level)) {
      usages[level]++;
    } else {
      usages[level] = 1;
    }
  }

  @override
  String toString() {
    return '$object / $usages';
  }
}
